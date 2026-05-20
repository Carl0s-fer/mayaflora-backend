from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
from PIL import Image
import io
import requests
import os
from datetime import datetime
import numpy as np
from base_datos import BaseDatos
from configuracion import *
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv
from typing import Optional

load_dotenv()

app = FastAPI(title="Mayaflora API")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("❌ DATABASE_URL no está configurada en las variables de entorno")

db = BaseDatos(DATABASE_URL)

try:
    resultado = db.crear_usuario("admin", "admin123")
    print("✅ Admin creado" if resultado["exito"] else "ℹ️ Admin existe")
except: pass

if not os.path.exists(CARPETA_IMAGENES): os.makedirs(CARPETA_IMAGENES)


# ─── Análisis de imagen ───────────────────────────────────────────────────────

def analizar_colores(imagen_bytes):
    """Analiza colores: enfermedad, dominancia verde, etc."""
    try:
        img = Image.open(io.BytesIO(imagen_bytes)).convert('RGB')
        img_array = np.array(img)
        r = img_array[:,:,0].astype(float)
        g = img_array[:,:,1].astype(float)
        b = img_array[:,:,2].astype(float)
        lum = 0.299*r + 0.587*g + 0.114*b

        oscuras = np.sum(lum < 60) / lum.size * 100
        marrones = np.sum((r>80)&(r<150)&(g>50)&(g<120)&(b<80)) / lum.size * 100
        amarillas = np.sum((r>180)&(g>180)&(b<120)) / lum.size * 100

        # Dominancia verde (indicador de hoja)
        verde_dom = np.sum((g > r * 1.1) & (g > b * 1.1) & (g > 60)) / lum.size * 100

        score_enfermedad = (35 if oscuras > 10 else 0) + (40 if marrones > 3 else 0) + (25 if amarillas > 2 else 0)
        return {
            "score": score_enfermedad,
            "verde_dominante": verde_dom,
            "detalles": {"oscuras": oscuras, "marrones": marrones, "amarillas": amarillas}
        }
    except:
        return {"score": 0, "verde_dominante": 0, "detalles": {}}


def analizar_con_huggingface(imagen_bytes):
    headers = {"Authorization": f"Bearer {HUGGINGFACE_API_KEY}", "Content-Type": "application/octet-stream"}
    try:
        img = Image.open(io.BytesIO(imagen_bytes))
        img.verify()
        img = Image.open(io.BytesIO(imagen_bytes)).convert('RGB')
        buf = io.BytesIO()
        img.save(buf, format='JPEG', quality=95)
        r = requests.post(HUGGINGFACE_API_URL, headers=headers, data=buf.getvalue(), timeout=60)
        if r.status_code == 200:
            return {"exito": True, "predicciones": r.json()}
        if r.status_code == 503:
            import time
            time.sleep(10)
            r = requests.post(HUGGINGFACE_API_URL, headers=headers, data=buf.getvalue(), timeout=60)
            if r.status_code == 200:
                return {"exito": True, "predicciones": r.json()}
        return {"exito": False, "mensaje": f"Error {r.status_code}"}
    except Exception as e:
        return {"exito": False, "mensaje": str(e)}


def detectar_tipo_objeto(predicciones, color_analysis):
    """
    Determina si la imagen es:
    - "hoja_orquidea": una hoja de orquídea (proceder con diagnóstico)
    - "hoja_otra": parece ser una hoja pero no de orquídea claramente
    - "no_hoja": no es ninguna hoja
    """
    if not predicciones:
        return "hoja_orquidea"  # fallback: dejar que el análisis continúe

    top_labels = [(p['label'].lower(), p['score']) for p in predicciones[:5]]
    verde_dom = color_analysis.get("verde_dominante", 0)

    # Calcular scores
    score_no_hoja = sum(s for l, s in top_labels if any(k in l for k in PALABRAS_CLAVE_NO_HOJA))
    score_planta = sum(s for l, s in top_labels if any(k in l for k in PALABRAS_CLAVE_PLANTA))
    top_label, top_score = top_labels[0]

    # Si el objeto más probable con alta confianza es claramente NO planta
    if score_no_hoja > 0.5 or (top_score > 0.4 and any(k in top_label for k in PALABRAS_CLAVE_NO_HOJA)):
        return "no_hoja"

    # Si hay suficiente verde Y alguna predicción de planta → hoja de orquídea
    if verde_dom > 25 or score_planta > 0.15:
        return "hoja_orquidea"

    # Si hay algo de verde pero poca confianza en planta
    if verde_dom > 10:
        return "hoja_otra"

    # Si no es claramente nada conocido
    if score_no_hoja > 0.3:
        return "no_hoja"

    return "hoja_otra"


def interpretar_resultado(preds, ac):
    if not preds:
        return {"resultado": "Error", "confianza": 0.0, "mensaje": "Error"}
    mp = max(preds, key=lambda x: x['score'])
    et, chf, sc = mp['label'].lower(), mp['score'] * 100, ac.get("score", 0)
    enf = any(p in et for p in PALABRAS_CLAVE_ENFERMEDAD)
    if sc > 60:
        return {"resultado": "Enferma", "confianza": round(min(sc+10, 95), 2), "mensaje": "Manchas detectadas", "detalle": f"Score:{sc}"}
    if enf and chf > 30:
        return {"resultado": "Enferma", "confianza": round((chf+sc)/2, 2), "mensaje": "Posible hongo", "detalle": et}
    if sc > 40:
        return {"resultado": "Enferma", "confianza": round(max(sc, 60), 2), "mensaje": "Anomalías detectadas", "detalle": "Manchas"}
    return {"resultado": "Sana", "confianza": round(max(100-sc, 70), 2), "mensaje": "Sin signos de enfermedad", "detalle": "Planta saludable"}


# ─── Endpoints básicos ────────────────────────────────────────────────────────

@app.get("/")
def raiz():
    return {"mensaje": "Mayaflora API", "version": "3.0", "estado": "activo"}


@app.post("/api/registro")
async def registrar_usuario(nombre_usuario: str = Form(...), contrasena: str = Form(...)):
    r = db.crear_usuario(nombre_usuario, contrasena)
    return JSONResponse(content=r, status_code=201 if r["exito"] else 400)


@app.post("/api/login")
async def iniciar_sesion(nombre_usuario: str = Form(...), contrasena: str = Form(...)):
    r = db.verificar_usuario(nombre_usuario, contrasena)
    return JSONResponse(content=r, status_code=200 if r["exito"] else 401)


@app.post("/api/analizar")
async def analizar_imagen(imagen: UploadFile = File(...), usuario_id: int = Form(...), nombre_usuario: str = Form(...)):
    try:
        cont = await imagen.read()
        Image.open(io.BytesIO(cont)).verify()
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        ruta = os.path.join(CARPETA_IMAGENES, f"escaneo_{usuario_id}_{ts}.jpg")
        with open(ruta, "wb") as f: f.write(cont)
        ac = analizar_colores(cont)
        rhf = analizar_con_huggingface(cont)
        if not rhf["exito"]:
            raise HTTPException(status_code=500, detail=rhf["mensaje"])
        tipo = detectar_tipo_objeto(rhf["predicciones"], ac)
        an = interpretar_resultado(rhf["predicciones"], ac)
        db.guardar_escaneo(usuario_id, nombre_usuario, ruta, an["resultado"], an["confianza"])
        return JSONResponse(content={
            "exito": True,
            "resultado": an["resultado"],
            "confianza": an["confianza"],
            "mensaje": an["mensaje"],
            "detalle": an.get("detalle", ""),
            "tipo_objeto": tipo
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/historial/{usuario_id}")
async def obtener_historial(usuario_id: int):
    r = db.obtener_historial(usuario_id)
    return JSONResponse(content=r, status_code=200 if r["exito"] else 500)


@app.get("/api/estadisticas/{usuario_id}")
async def obtener_estadisticas(usuario_id: int):
    h = db.obtener_historial(usuario_id)
    if not h["exito"]:
        return JSONResponse(content={"exito": False}, status_code=500)
    t = len(h["historial"])
    e = sum(1 for x in h["historial"] if x["resultado"] == "Enferma")
    return JSONResponse(content={"exito": True, "estadisticas": {"total_escaneos": t, "plantas_enfermas": e, "plantas_sanas": t-e}})


# ─── Endpoints de Carpetas ────────────────────────────────────────────────────

@app.get("/api/carpetas/{usuario_id}")
async def obtener_carpetas(usuario_id: int):
    r = db.obtener_carpetas(usuario_id)
    return JSONResponse(content=r, status_code=200 if r["exito"] else 500)


@app.post("/api/carpetas")
async def crear_carpeta(usuario_id: int = Form(...), nombre: str = Form(...)):
    r = db.crear_carpeta(usuario_id, nombre)
    return JSONResponse(content=r, status_code=201 if r["exito"] else 500)


@app.put("/api/carpetas/{carpeta_id}")
async def actualizar_carpeta(carpeta_id: int, nombre: str = Form(...)):
    r = db.actualizar_carpeta(carpeta_id, nombre)
    return JSONResponse(content=r, status_code=200 if r["exito"] else 500)


@app.delete("/api/carpetas/{carpeta_id}")
async def eliminar_carpeta(carpeta_id: int):
    r = db.eliminar_carpeta(carpeta_id)
    return JSONResponse(content=r, status_code=200 if r["exito"] else 500)


# ─── Endpoints de Plantas ─────────────────────────────────────────────────────

@app.get("/api/plantas/carpeta/{carpeta_id}")
async def obtener_plantas(carpeta_id: int):
    r = db.obtener_plantas(carpeta_id)
    return JSONResponse(content=r, status_code=200 if r["exito"] else 500)


@app.get("/api/plantas/{planta_id}")
async def obtener_planta(planta_id: int):
    r = db.obtener_planta(planta_id)
    return JSONResponse(content=r, status_code=200 if r["exito"] else 404)


@app.post("/api/plantas")
async def crear_planta(
    carpeta_id: int = Form(...),
    usuario_id: int = Form(...),
    nombre: str = Form(...),
    foto_perfil: Optional[UploadFile] = File(None)
):
    foto_bytes = None
    if foto_perfil:
        foto_bytes = await foto_perfil.read()
    r = db.crear_planta(carpeta_id, usuario_id, nombre, foto_bytes)
    return JSONResponse(content=r, status_code=201 if r["exito"] else 500)


@app.put("/api/plantas/{planta_id}")
async def actualizar_planta(
    planta_id: int,
    nombre: Optional[str] = Form(None),
    foto_perfil: Optional[UploadFile] = File(None)
):
    foto_bytes = None
    if foto_perfil:
        foto_bytes = await foto_perfil.read()
    r = db.actualizar_planta(planta_id, nombre=nombre, foto_perfil_bytes=foto_bytes)
    return JSONResponse(content=r, status_code=200 if r["exito"] else 500)


@app.delete("/api/plantas/{planta_id}")
async def eliminar_planta(planta_id: int):
    r = db.eliminar_planta(planta_id)
    return JSONResponse(content=r, status_code=200 if r["exito"] else 500)


@app.put("/api/plantas/{planta_id}/notificaciones")
async def actualizar_notificaciones(planta_id: int, activas: bool = Form(...)):
    r = db.actualizar_notificaciones_planta(planta_id, activas)
    return JSONResponse(content=r, status_code=200 if r["exito"] else 500)


# ─── Endpoints de escaneos de plantas ────────────────────────────────────────

@app.post("/api/plantas/{planta_id}/escanear")
async def escanear_planta(
    planta_id: int,
    imagen: UploadFile = File(...),
    es_foto_seguimiento: bool = Form(False)
):
    """
    Analiza una foto de una planta específica.
    Detecta tipo de objeto, si es hoja de orquídea, y si está sana o enferma.
    Guarda el resultado en el historial de la planta.
    """
    try:
        cont = await imagen.read()
        Image.open(io.BytesIO(cont)).verify()

        ac = analizar_colores(cont)
        rhf = analizar_con_huggingface(cont)

        if not rhf["exito"]:
            raise HTTPException(status_code=500, detail=rhf["mensaje"])

        tipo = detectar_tipo_objeto(rhf["predicciones"], ac)

        # Si no es una hoja, no analizamos
        if tipo == "no_hoja":
            return JSONResponse(content={
                "exito": False,
                "tipo_objeto": "no_hoja",
                "mensaje": "No se detectó ninguna hoja. Por favor tome una foto de una hoja de orquídea."
            })

        if tipo == "hoja_otra":
            return JSONResponse(content={
                "exito": False,
                "tipo_objeto": "hoja_otra",
                "mensaje": "No se aprecia bien la hoja de orquídea. Por favor tome una nueva foto más cercana y clara."
            })

        # Es una hoja de orquídea, analizar salud
        planta_info = db.obtener_planta(planta_id)
        paso_actual = 0
        if planta_info["exito"]:
            paso_actual = planta_info["planta"]["paso_tratamiento_actual"] or 0

        an = interpretar_resultado(rhf["predicciones"], ac)
        resultado = an["resultado"]

        # Determinar instrucciones y paso
        if resultado == "Sana":
            instrucciones = MENSAJE_PLANTA_SANA
            nuevo_paso = 0
        else:
            if es_foto_seguimiento and paso_actual > 0:
                # Planta sigue enferma, avanzar al siguiente paso
                nuevo_paso = min(paso_actual + 1, len(PASOS_TRATAMIENTO))
            else:
                nuevo_paso = 1
            if nuevo_paso <= len(PASOS_TRATAMIENTO):
                paso_info = PASOS_TRATAMIENTO[nuevo_paso - 1]
                instrucciones = paso_info["instrucciones"]
            else:
                instrucciones = PASOS_TRATAMIENTO[-1]["instrucciones"]
                nuevo_paso = len(PASOS_TRATAMIENTO)

        r = db.guardar_escaneo_planta(
            planta_id, cont, resultado, an["confianza"],
            instrucciones, nuevo_paso, es_foto_seguimiento
        )

        if not r["exito"]:
            raise HTTPException(status_code=500, detail=r["mensaje"])

        respuesta = {
            "exito": True,
            "tipo_objeto": "hoja_orquidea",
            "resultado": resultado,
            "confianza": an["confianza"],
            "instrucciones": instrucciones,
            "paso_numero": nuevo_paso,
            "escaneo_id": r["escaneo_id"]
        }

        if resultado == "Sana" and es_foto_seguimiento:
            respuesta["mensaje_especial"] = MENSAJE_PLANTA_SE_RECUPERO
        elif resultado == "Sana":
            respuesta["mensaje_especial"] = MENSAJE_PLANTA_SANA
        else:
            titulo_paso = PASOS_TRATAMIENTO[nuevo_paso - 1]["titulo"] if nuevo_paso <= len(PASOS_TRATAMIENTO) else "Tratamiento"
            respuesta["titulo_paso"] = titulo_paso
            respuesta["mensaje_especial"] = MENSAJE_PLANTA_ENFERMA_INICIO if not es_foto_seguimiento else "Su planta aún necesita cuidados. Continúe con el siguiente paso del tratamiento."

        return JSONResponse(content=respuesta)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/plantas/{planta_id}/historial")
async def obtener_historial_planta(planta_id: int):
    r = db.obtener_historial_planta(planta_id)
    return JSONResponse(content=r, status_code=200 if r["exito"] else 500)


@app.put("/api/escaneos/{escaneo_id}/completar")
async def marcar_tratamiento_completado(escaneo_id: int):
    r = db.marcar_tratamiento_completado(escaneo_id)
    return JSONResponse(content=r, status_code=200 if r["exito"] else 500)


@app.get("/api/pasos-tratamiento")
async def obtener_pasos_tratamiento():
    return JSONResponse(content={"exito": True, "pasos": PASOS_TRATAMIENTO})


# ─── Endpoints de administración ─────────────────────────────────────────────

@app.get("/api/admin/usuarios")
async def listar_todos_usuarios():
    try:
        c = db.obtener_conexion()
        cu = c.cursor(cursor_factory=RealDictCursor)
        cu.execute("""
            SELECT u.id, u.nombre_usuario, u.fecha_creacion,
                   COUNT(h.id) as total_escaneos
            FROM usuarios u
            LEFT JOIN historial_escaneos h ON u.id = h.usuario_id
            GROUP BY u.id, u.nombre_usuario, u.fecha_creacion
            ORDER BY u.fecha_creacion DESC
        """)
        us = cu.fetchall()
        cu.close()
        c.close()
        return JSONResponse(content={"exito": True, "usuarios": [
            {"id": u["id"], "nombre_usuario": u["nombre_usuario"],
             "fecha_creacion": u["fecha_creacion"].isoformat(),
             "total_escaneos": u["total_escaneos"]} for u in us
        ]})
    except Exception as e:
        return JSONResponse(content={"exito": False, "mensaje": str(e)}, status_code=500)


@app.delete("/api/admin/usuarios/{usuario_id}")
async def eliminar_usuario(usuario_id: int):
    try:
        c = db.obtener_conexion()
        cu = c.cursor(cursor_factory=RealDictCursor)
        cu.execute("SELECT nombre_usuario FROM usuarios WHERE id=%s", (usuario_id,))
        u = cu.fetchone()
        if u and u["nombre_usuario"].lower() == "admin":
            cu.close()
            c.close()
            return JSONResponse(content={"exito": False, "mensaje": "No eliminar admin"}, status_code=400)
        cu.execute("DELETE FROM usuarios WHERE id=%s", (usuario_id,))
        c.commit()
        cu.close()
        c.close()
        return JSONResponse(content={"exito": True, "mensaje": "Eliminado"})
    except Exception as e:
        return JSONResponse(content={"exito": False, "mensaje": str(e)}, status_code=500)


@app.put("/api/admin/usuarios/{usuario_id}/contrasena")
async def cambiar_contrasena_usuario(usuario_id: int, nueva_contrasena: str = Form(...)):
    try:
        c = db.obtener_conexion()
        cu = c.cursor()
        ce = db.encriptar_contrasena(nueva_contrasena)
        cu.execute("UPDATE usuarios SET contrasena=%s WHERE id=%s", (ce, usuario_id))
        c.commit()
        cu.close()
        c.close()
        return JSONResponse(content={"exito": True, "mensaje": "Actualizada"})
    except Exception as e:
        return JSONResponse(content={"exito": False, "mensaje": str(e)}, status_code=500)


@app.get("/api/admin/historial-completo")
async def obtener_historial_completo():
    try:
        c = db.obtener_conexion()
        cu = c.cursor(cursor_factory=RealDictCursor)
        cu.execute("SELECT * FROM historial_escaneos ORDER BY fecha_escaneo DESC")
        es = cu.fetchall()
        cu.close()
        c.close()
        return JSONResponse(content={"exito": True, "historial": [
            {"id": e["id"], "usuario_id": e["usuario_id"], "nombre_usuario": e["nombre_usuario"],
             "resultado": e["resultado"], "confianza": e["confianza"],
             "fecha_escaneo": e["fecha_escaneo"].isoformat()} for e in es
        ]})
    except Exception as e:
        return JSONResponse(content={"exito": False, "mensaje": str(e)}, status_code=500)


@app.delete("/api/admin/historial/limpiar-todo")
async def limpiar_historial_completo():
    try:
        c = db.obtener_conexion()
        cu = c.cursor()
        cu.execute("DELETE FROM historial_escaneos")
        filas = cu.rowcount
        c.commit()
        cu.close()
        c.close()
        return JSONResponse(content={"exito": True, "mensaje": f"Se eliminaron {filas} registros"})
    except Exception as e:
        return JSONResponse(content={"exito": False, "mensaje": str(e)}, status_code=500)


@app.delete("/api/admin/historial/{escaneo_id}")
async def eliminar_registro_historial(escaneo_id: int):
    try:
        c = db.obtener_conexion()
        cu = c.cursor()
        cu.execute("DELETE FROM historial_escaneos WHERE id=%s", (escaneo_id,))
        c.commit()
        cu.close()
        c.close()
        return JSONResponse(content={"exito": True, "mensaje": "Registro eliminado"})
    except Exception as e:
        return JSONResponse(content={"exito": False, "mensaje": str(e)}, status_code=500)


if __name__ == "__main__":
    print("🌺 Mayaflora API v3.0 - PostgreSQL")
    print(f"🔗 DATABASE_URL: {'✅' if DATABASE_URL else '❌'}")
    uvicorn.run(app, host=HOST, port=PORT)
