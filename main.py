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

app = FastAPI(title="Mayaflora API")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])
db = BaseDatos(NOMBRE_BASE_DATOS)

try:
    resultado = db.crear_usuario("admin", "admin123")
    print("✅ Admin creado" if resultado["exito"] else "ℹ️ Admin existe")
except: pass

if not os.path.exists(CARPETA_IMAGENES): os.makedirs(CARPETA_IMAGENES)

@app.get("/")
def raiz(): return {"mensaje": "Mayaflora API", "version": "1.0"}

@app.post("/api/registro")
async def registrar_usuario(nombre_usuario: str = Form(...), contrasena: str = Form(...)):
    r = db.crear_usuario(nombre_usuario, contrasena)
    return JSONResponse(content=r, status_code=201 if r["exito"] else 400)

@app.post("/api/login")
async def iniciar_sesion(nombre_usuario: str = Form(...), contrasena: str = Form(...)):
    r = db.verificar_usuario(nombre_usuario, contrasena)
    return JSONResponse(content=r, status_code=200 if r["exito"] else 401)

def analizar_colores_hongos(imagen_bytes):
    try:
        img = Image.open(io.BytesIO(imagen_bytes)).convert('RGB')
        img_array = np.array(img)
        r, g, b = img_array[:,:,0].astype(float), img_array[:,:,1].astype(float), img_array[:,:,2].astype(float)
        lum = 0.299*r + 0.587*g + 0.114*b
        osc = np.sum(lum < 60) / lum.size * 100
        mar = np.sum((r>80)&(r<150)&(g>50)&(g<120)&(b<80)) / lum.size * 100
        ama = np.sum((r>180)&(g>180)&(b<120)) / lum.size * 100
        score = (35 if osc>10 else 0) + (40 if mar>3 else 0) + (25 if ama>2 else 0)
        return {"score": score, "detalles": {"oscuras": osc, "marrones": mar, "amarillas": ama}}
    except: return {"score": 0, "detalles": {}}

def analizar_con_huggingface(imagen_bytes):
    headers = {"Authorization": f"Bearer {HUGGINGFACE_API_KEY}", "Content-Type": "application/octet-stream"}
    try:
        img = Image.open(io.BytesIO(imagen_bytes))
        img.verify()
        img = Image.open(io.BytesIO(imagen_bytes)).convert('RGB')
        buf = io.BytesIO()
        img.save(buf, format='JPEG', quality=95)
        r = requests.post(HUGGINGFACE_API_URL, headers=headers, data=buf.getvalue(), timeout=60)
        if r.status_code == 200: return {"exito": True, "predicciones": r.json()}
        if r.status_code == 503:
            import time
            time.sleep(10)
            r = requests.post(HUGGINGFACE_API_URL, headers=headers, data=buf.getvalue(), timeout=60)
            if r.status_code == 200: return {"exito": True, "predicciones": r.json()}
        return {"exito": False, "mensaje": f"Error {r.status_code}"}
    except Exception as e: return {"exito": False, "mensaje": str(e)}

def interpretar_resultado(preds, ac):
    if not preds: return {"resultado": "Error", "confianza": 0.0, "mensaje": "Error"}
    mp = max(preds, key=lambda x: x['score'])
    et, chf, sc = mp['label'].lower(), mp['score']*100, ac.get("score", 0)
    enf = any(p in et for p in PALABRAS_CLAVE_ENFERMEDAD)
    if sc>60: return {"resultado": "Enferma", "confianza": round(min(sc+10,95),2), "mensaje": f"Manchas detectadas", "detalle": f"Score:{sc}"}
    if enf and chf>30: return {"resultado": "Enferma", "confianza": round((chf+sc)/2,2), "mensaje": "Posible hongo", "detalle": et}
    if sc>40: return {"resultado": "Enferma", "confianza": round(max(sc,60),2), "mensaje": "Anomalías", "detalle": "Manchas"}
    return {"resultado": "Sana", "confianza": round(max(100-sc,70),2), "mensaje": "Sana", "detalle": "Sin anomalías"}

@app.post("/api/analizar")
async def analizar_imagen(imagen: UploadFile = File(...), usuario_id: int = Form(...), nombre_usuario: str = Form(...)):
    try:
        cont = await imagen.read()
        Image.open(io.BytesIO(cont)).verify()
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        ruta = os.path.join(CARPETA_IMAGENES, f"escaneo_{usuario_id}_{ts}.jpg")
        with open(ruta, "wb") as f: f.write(cont)
        rhf = analizar_con_huggingface(cont)
        if not rhf["exito"]: raise HTTPException(status_code=500, detail=rhf["mensaje"])
        ac = analizar_colores_hongos(cont)
        an = interpretar_resultado(rhf["predicciones"], ac)
        db.guardar_escaneo(usuario_id, nombre_usuario, ruta, an["resultado"], an["confianza"])
        return JSONResponse(content={"exito": True, "resultado": an["resultado"], "confianza": an["confianza"], "mensaje": an["mensaje"], "detalle": an.get("detalle","")})
    except Exception as e: raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/historial/{usuario_id}")
async def obtener_historial(usuario_id: int):
    r = db.obtener_historial(usuario_id)
    return JSONResponse(content=r, status_code=200 if r["exito"] else 500)

@app.get("/api/estadisticas/{usuario_id}")
async def obtener_estadisticas(usuario_id: int):
    h = db.obtener_historial(usuario_id)
    if not h["exito"]: return JSONResponse(content={"exito": False}, status_code=500)
    t = len(h["historial"])
    e = sum(1 for x in h["historial"] if x["resultado"]=="Enferma")
    return JSONResponse(content={"exito": True, "estadisticas": {"total_escaneos": t, "plantas_enfermas": e, "plantas_sanas": t-e}})

@app.get("/api/admin/usuarios")
async def listar_todos_usuarios():
    try:
        c = db.obtener_conexion()
        cu = c.cursor()
        cu.execute("SELECT id, nombre_usuario, fecha_creacion, (SELECT COUNT(*) FROM historial_escaneos WHERE usuario_id=usuarios.id) as total_escaneos FROM usuarios ORDER BY fecha_creacion DESC")
        us = cu.fetchall()
        c.close()
        return JSONResponse(content={"exito": True, "usuarios": [{"id": u["id"], "nombre_usuario": u["nombre_usuario"], "fecha_creacion": u["fecha_creacion"], "total_escaneos": u["total_escaneos"]} for u in us]})
    except Exception as e: return JSONResponse(content={"exito": False, "mensaje": str(e)}, status_code=500)

@app.delete("/api/admin/usuarios/{usuario_id}")
async def eliminar_usuario(usuario_id: int):
    try:
        c = db.obtener_conexion()
        cu = c.cursor()
        cu.execute("SELECT nombre_usuario FROM usuarios WHERE id=?", (usuario_id,))
        u = cu.fetchone()
        if u and u["nombre_usuario"].lower()=="admin": return JSONResponse(content={"exito": False, "mensaje": "No eliminar admin"}, status_code=400)
        cu.execute("DELETE FROM usuarios WHERE id=?", (usuario_id,))
        cu.execute("DELETE FROM historial_escaneos WHERE usuario_id=?", (usuario_id,))
        c.commit()
        c.close()
        return JSONResponse(content={"exito": True, "mensaje": "Eliminado"})
    except Exception as e: return JSONResponse(content={"exito": False, "mensaje": str(e)}, status_code=500)

@app.put("/api/admin/usuarios/{usuario_id}/contrasena")
async def cambiar_contrasena_usuario(usuario_id: int, nueva_contrasena: str = Form(...)):
    try:
        c = db.obtener_conexion()
        cu = c.cursor()
        ce = db.encriptar_contrasena(nueva_contrasena)
        cu.execute("UPDATE usuarios SET contrasena=? WHERE id=?", (ce, usuario_id))
        c.commit()
        c.close()
        return JSONResponse(content={"exito": True, "mensaje": "Actualizada"})
    except Exception as e: return JSONResponse(content={"exito": False, "mensaje": str(e)}, status_code=500)

@app.get("/api/admin/historial-completo")
async def obtener_historial_completo():
    try:
        c = db.obtener_conexion()
        cu = c.cursor()
        cu.execute("SELECT * FROM historial_escaneos ORDER BY fecha_escaneo DESC")
        es = cu.fetchall()
        c.close()
        return JSONResponse(content={"exito": True, "historial": [{"id": e["id"], "usuario_id": e["usuario_id"], "nombre_usuario": e["nombre_usuario"], "resultado": e["resultado"], "confianza": e["confianza"], "fecha_escaneo": e["fecha_escaneo"]} for e in es]})
    except Exception as e: return JSONResponse(content={"exito": False, "mensaje": str(e)}, status_code=500)

if __name__ == "__main__":
    print("🌺 Mayaflora API")
    uvicorn.run(app, host=HOST, port=PORT)
