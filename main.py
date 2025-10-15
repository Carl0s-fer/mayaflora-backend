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

app = FastAPI(title="Mayaflora API - Detector de Hongos en Orquídeas")

# Configurar CORS para permitir peticiones desde Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inicializar base de datos
db = BaseDatos(NOMBRE_BASE_DATOS)

# Crear usuario admin automáticamente si no existe
try:
    resultado = db.crear_usuario("admin", "admin123")
    if resultado["exito"]:
        print("✅ Usuario admin creado automáticamente")
    else:
        print("ℹ️ Usuario admin ya existe")
except Exception as e:
    print(f"⚠️ Error al crear admin: {e}")

# Crear carpeta para imágenes si no existe
if not os.path.exists(CARPETA_IMAGENES):
    os.makedirs(CARPETA_IMAGENES)

@app.get("/")
def raiz():
    """Endpoint de bienvenida"""
    return {
        "mensaje": "Bienvenido a Mayaflora API",
        "version": "1.0",
        "descripcion": "Sistema de detección de hongos en hojas de orquídeas"
    }

@app.post("/api/registro")
async def registrar_usuario(nombre_usuario: str = Form(...), contrasena: str = Form(...)):
    """Registra un nuevo usuario"""
    resultado = db.crear_usuario(nombre_usuario, contrasena)
    
    if resultado["exito"]:
        return JSONResponse(content=resultado, status_code=201)
    else:
        return JSONResponse(content=resultado, status_code=400)

@app.post("/api/login")
async def iniciar_sesion(nombre_usuario: str = Form(...), contrasena: str = Form(...)):
    """Verifica las credenciales del usuario"""
    resultado = db.verificar_usuario(nombre_usuario, contrasena)
    
    if resultado["exito"]:
        return JSONResponse(content=resultado, status_code=200)
    else:
        return JSONResponse(content=resultado, status_code=401)

def analizar_colores_hongos(imagen_bytes):
    """
    Analiza los colores de la imagen para detectar señales de hongos
    Retorna un score de 0-100 indicando probabilidad de enfermedad
    """
    try:
        img = Image.open(io.BytesIO(imagen_bytes)).convert('RGB')
        img_array = np.array(img)
        
        r = img_array[:,:,0].astype(float)
        g = img_array[:,:,1].astype(float)
        b = img_array[:,:,2].astype(float)
        
        # Detectar manchas marrones/negras/amarillas (hongos típicos)
        luminosidad = 0.299 * r + 0.587 * g + 0.114 * b
        
        # Manchas oscuras (hongos negros)
        manchas_oscuras = np.sum(luminosidad < 60)
        porc_oscuras = (manchas_oscuras / luminosidad.size) * 100
        
        # Manchas marrones (hongos comunes)
        manchas_marron = np.sum((r > 80) & (r < 150) & (g > 50) & (g < 120) & (b < 80))
        porc_marron = (manchas_marron / luminosidad.size) * 100
        
        # Manchas amarillas (hongos/moho)
        manchas_amarillo = np.sum((r > 180) & (g > 180) & (b < 120))
        porc_amarillo = (manchas_amarillo / luminosidad.size) * 100
        
        # Calcular score de enfermedad
        score = 0
        if porc_oscuras > 10: score += 35
        if porc_marron > 3: score += 40
        if porc_amarillo > 2: score += 25
        
        print(f"🎨 Análisis de color:")
        print(f"   - Manchas oscuras: {porc_oscuras:.2f}%")
        print(f"   - Manchas marrones: {porc_marron:.2f}%")
        print(f"   - Manchas amarillas: {porc_amarillo:.2f}%")
        print(f"   - Score enfermedad: {score}/100")
        
        return {
            "score": score,
            "detalles": {
                "oscuras": porc_oscuras,
                "marrones": porc_marron,
                "amarillas": porc_amarillo
            }
        }
    except Exception as e:
        print(f"⚠️ Error en análisis de color: {str(e)}")
        return {"score": 0, "detalles": {}}

def analizar_con_huggingface(imagen_bytes):
    """
    Envía la imagen a Hugging Face para análisis REAL
    """
    headers = {
        "Authorization": f"Bearer {HUGGINGFACE_API_KEY}",
        "Content-Type": "application/octet-stream"
    }
    
    print(f"🔍 Analizando con Hugging Face...")
    print(f"📡 Modelo: {HUGGINGFACE_MODEL}")
    print(f"🔑 API Key: {HUGGINGFACE_API_KEY[:15]}...")
    print(f"📦 Tamaño de imagen: {len(imagen_bytes)} bytes")
    
    try:
        # Verificar que la imagen sea válida
        try:
            img = Image.open(io.BytesIO(imagen_bytes))
            print(f"📸 Imagen válida: {img.format} {img.size}")
            img.verify()
            
            # Reabrir la imagen (verify() la cierra)
            img = Image.open(io.BytesIO(imagen_bytes))
            
            # Convertir a RGB si es necesario
            if img.mode != 'RGB':
                img = img.convert('RGB')
            
            # Guardar en bytes
            buffer = io.BytesIO()
            img.save(buffer, format='JPEG', quality=95)
            imagen_bytes = buffer.getvalue()
            print(f"✅ Imagen procesada: {len(imagen_bytes)} bytes")
            
        except Exception as e:
            print(f"❌ Error al procesar imagen: {str(e)}")
            return {"exito": False, "mensaje": f"Imagen inválida: {str(e)}"}
        
        # Enviar a Hugging Face
        response = requests.post(
            HUGGINGFACE_API_URL,
            headers=headers,
            data=imagen_bytes,
            timeout=60
        )
        
        print(f"📥 Respuesta HTTP: {response.status_code}")
        
        if response.status_code == 200:
            resultado = response.json()
            print(f"✅ Predicciones recibidas:")
            if isinstance(resultado, list) and len(resultado) > 0:
                for pred in resultado[:3]:
                    print(f"   - {pred.get('label', 'N/A')}: {pred.get('score', 0)*100:.2f}%")
            return {"exito": True, "predicciones": resultado}
        elif response.status_code == 503:
            print("⏳ Modelo cargándose, esperando 10 segundos...")
            import time
            time.sleep(10)
            response = requests.post(HUGGINGFACE_API_URL, headers=headers, data=imagen_bytes, timeout=60)
            if response.status_code == 200:
                resultado = response.json()
                print(f"✅ Predicciones recibidas después de espera")
                return {"exito": True, "predicciones": resultado}
            else:
                print(f"❌ Error después de reintento: {response.status_code} - {response.text[:500]}")
                return {"exito": False, "mensaje": f"Modelo no disponible: {response.status_code}"}
        else:
            print(f"❌ Error {response.status_code}: {response.text[:500]}")
            return {
                "exito": False,
                "mensaje": f"Error en Hugging Face: {response.status_code}",
                "detalle": response.text[:500]
            }
    except Exception as e:
        print(f"❌ Excepción: {str(e)}")
        import traceback
        traceback.print_exc()
        return {"exito": False, "mensaje": f"Error al conectar con Hugging Face: {str(e)}"}

def interpretar_resultado(predicciones, analisis_color):
    """
    Interpreta las predicciones combinando Hugging Face + análisis de color
    """
    if not predicciones:
        return {
            "resultado": "Error",
            "confianza": 0.0,
            "mensaje": "No se pudo analizar la imagen"
        }
    
    # Análisis de Hugging Face
    mejor_prediccion = max(predicciones, key=lambda x: x['score'])
    etiqueta = mejor_prediccion['label'].lower()
    confianza_hf = mejor_prediccion['score'] * 100
    
    print(f"🔬 Predicción HF: {etiqueta} ({confianza_hf:.2f}%)")
    
    # Score de color (0-100)
    score_color = analisis_color.get("score", 0)
    
    # Verificar palabras clave
    tiene_enfermedad_hf = any(palabra in etiqueta for palabra in PALABRAS_CLAVE_ENFERMEDAD)
    
    # Combinar análisis
    if score_color > 60:
        confianza_final = min(score_color + 10, 95)
        return {
            "resultado": "Enferma",
            "confianza": round(confianza_final, 2),
            "mensaje": f"Se detectaron manchas sospechosas de hongos (Confianza: {confianza_final:.1f}%)",
            "detalle": f"Análisis de color: {score_color}/100"
        }
    elif tiene_enfermedad_hf and confianza_hf > 30:
        confianza_final = (confianza_hf + score_color) / 2
        return {
            "resultado": "Enferma",
            "confianza": round(confianza_final, 2),
            "mensaje": f"Posible presencia de hongos (Confianza: {confianza_final:.1f}%)",
            "detalle": etiqueta
        }
    elif score_color > 40:
        confianza_final = max(score_color, 60)
        return {
            "resultado": "Enferma",
            "confianza": round(confianza_final, 2),
            "mensaje": f"Se detectaron anomalías en las hojas (Confianza: {confianza_final:.1f}%)",
            "detalle": f"Manchas detectadas"
        }
    else:
        confianza_final = max(100 - score_color, 70)
        return {
            "resultado": "Sana",
            "confianza": round(confianza_final, 2),
            "mensaje": f"La orquídea parece estar sana (Confianza: {confianza_final:.1f}%)",
            "detalle": "No se detectaron anomalías significativas"
        }

@app.post("/api/analizar")
async def analizar_imagen(
    imagen: UploadFile = File(...),
    usuario_id: int = Form(...),
    nombre_usuario: str = Form(...)
):
    """
    Analiza una imagen de orquídea para detectar hongos en las hojas
    """
    try:
        # Leer la imagen
        contenido_imagen = await imagen.read()
        
        # Validar que sea una imagen
        try:
            img = Image.open(io.BytesIO(contenido_imagen))
            img.verify()
        except Exception:
            raise HTTPException(status_code=400, detail="El archivo no es una imagen válida")
        
        # Guardar imagen con timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        nombre_archivo = f"escaneo_{usuario_id}_{timestamp}.jpg"
        ruta_imagen = os.path.join(CARPETA_IMAGENES, nombre_archivo)
        
        with open(ruta_imagen, "wb") as f:
            f.write(contenido_imagen)
        
        # Analizar con Hugging Face REAL
        print("🔍 Iniciando análisis con Hugging Face...")
        resultado_hf = analizar_con_huggingface(contenido_imagen)
        
        if not resultado_hf["exito"]:
            raise HTTPException(status_code=500, detail=resultado_hf["mensaje"])
        
        # Analizar colores para detectar hongos
        print("🎨 Analizando colores...")
        analisis_color = analizar_colores_hongos(contenido_imagen)
        
        # Interpretar resultado combinado
        analisis = interpretar_resultado(resultado_hf["predicciones"], analisis_color)
        
        # Guardar en base de datos
        db.guardar_escaneo(
            usuario_id=usuario_id,
            nombre_usuario=nombre_usuario,
            ruta_imagen=ruta_imagen,
            resultado=analisis["resultado"],
            confianza=analisis["confianza"]
        )
        
        return JSONResponse(content={
            "exito": True,
            "resultado": analisis["resultado"],
            "confianza": analisis["confianza"],
            "mensaje": analisis["mensaje"],
            "detalle": analisis.get("detalle", "")
        })
        
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al analizar imagen: {str(e)}")

@app.get("/api/historial/{usuario_id}")
async def obtener_historial(usuario_id: int):
    """
    Obtiene el historial de escaneos de un usuario
    """
    resultado = db.obtener_historial(usuario_id)
    
    if resultado["exito"]:
        return JSONResponse(content=resultado, status_code=200)
    else:
        return JSONResponse(content=resultado, status_code=500)

@app.get("/api/estadisticas/{usuario_id}")
async def obtener_estadisticas(usuario_id: int):
    """
    Obtiene estadísticas del usuario
    """
    historial = db.obtener_historial(usuario_id)
    
    if not historial["exito"]:
        return JSONResponse(content={"exito": False, "mensaje": "Error al obtener estadísticas"}, status_code=500)
    
    total_escaneos = len(historial["historial"])
    escaneos_enfermos = sum(1 for e in historial["historial"] if e["resultado"] == "Enferma")
    escaneos_sanos = total_escaneos - escaneos_enfermos
    
    return JSONResponse(content={
        "exito": True,
        "estadisticas": {
            "total_escaneos": total_escaneos,
            "plantas_enfermas": escaneos_enfermos,
            "plantas_sanas": escaneos_sanos
        }
    })

if __name__ == "__main__":
    print("🌺 Iniciando servidor Mayaflora API...")
    print(f"📍 Servidor corriendo en http://{HOST}:{PORT}")
    print(f"📚 Documentación disponible en http://{HOST}:{PORT}/docs")
    uvicorn.run(app, host=HOST, port=PORT)