# Configuración de Mayaflora Detector de Orquídeas

# API de Hugging Face
import os
HUGGINGFACE_API_KEY = os.getenv("HUGGINGFACE_API_KEY", "")

# Modelo de Hugging Face - Usamos Vision Transformer que funciona
HUGGINGFACE_MODEL = "google/vit-base-patch16-224"

# URL de la API de Hugging Face
HUGGINGFACE_API_URL = f"https://api-inference.huggingface.co/models/{HUGGINGFACE_MODEL}"

# Configuración del servidor
HOST = "0.0.0.0"
PORT = 8000

# Umbrales de confianza
UMBRAL_CONFIANZA_MINIMO = 0.5  # 50% de confianza mínima

# Palabras clave para detectar enfermedad
# Estos son términos que si aparecen en la predicción, indicarían enfermedad
PALABRAS_CLAVE_ENFERMEDAD = [
    "fungus", "fungi", "disease", "diseased", "unhealthy", "sick",
    "infection", "infected", "mold", "mould", "blight", "rot", "decay",
    "hongo", "enfermedad", "enferma", "infectada", "moho", "spot",
    "leaf spot", "rust", "wilt", "brown spot", "black spot", "damaged",
    "dead", "dying", "withered", "bacterial", "virus", "plague",
    "mushroom", "toadstool", "spore"
]

# Palabras clave para planta sana
PALABRAS_CLAVE_SANA = [
    "healthy", "normal", "good", "fresh", "green", "leaf",
    "sana", "saludable", "normal", "verde", "plant", "tree",
    "alive", "growing", "vibrant", "lush"
]

# Configuración de base de datos
NOMBRE_BASE_DATOS = "mayaflora.db"

# Carpeta para guardar imágenes
CARPETA_IMAGENES = "imagenes_escaneos"