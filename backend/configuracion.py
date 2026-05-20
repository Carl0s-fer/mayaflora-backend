# Configuración de Mayaflora Detector de Orquídeas

import os

# API de Hugging Face
HUGGINGFACE_API_KEY = os.getenv("HUGGINGFACE_API_KEY", "")

# Modelo de Hugging Face
HUGGINGFACE_MODEL = "google/vit-base-patch16-224"
HUGGINGFACE_API_URL = f"https://router.huggingface.co/hf-inference/models/{HUGGINGFACE_MODEL}"

# Configuración del servidor
HOST = "0.0.0.0"
PORT = 8000

# Umbrales de confianza
UMBRAL_CONFIANZA_MINIMO = 0.5

# Palabras clave para detectar enfermedad
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

# Palabras clave que indican que es una planta/hoja
PALABRAS_CLAVE_PLANTA = [
    "orchid", "phalaenopsis", "dendrobium", "cattleya", "vanda",
    "flower", "petal", "blossom", "bloom", "plant", "leaf", "leaves",
    "foliage", "vegetation", "greenery", "herb", "botany", "garden",
    "fern", "tree", "shrub", "grass", "moss", "vine", "succulent",
    "cactus", "tropical", "lily", "tulip", "daisy", "rose", "flora"
]

# Palabras clave que indican que NO es una hoja
PALABRAS_CLAVE_NO_HOJA = [
    "car", "automobile", "vehicle", "truck", "motorcycle", "bus", "bicycle",
    "building", "house", "architecture", "wall", "floor", "ceiling",
    "stone", "rock", "gravel", "sand", "soil", "dirt",
    "person", "human", "face", "hand", "body",
    "cat", "dog", "animal", "bird", "fish", "insect", "spider",
    "food", "plate", "cup", "bottle", "glass", "utensil",
    "furniture", "chair", "table", "desk", "bed", "sofa",
    "computer", "phone", "screen", "electronics", "keyboard",
    "fabric", "cloth", "textile", "shoe", "bag",
    "pot", "vase", "container", "bucket"
]

# Pasos de tratamiento para orquídeas enfermas
PASOS_TRATAMIENTO = [
    {
        "paso": 1,
        "titulo": "Paso 1: Aislamiento y limpieza inicial",
        "instrucciones": "Aísle su orquídea de las demás plantas inmediatamente para evitar contagios. Retire con cuidado las hojas severamente dañadas usando tijeras desinfectadas con alcohol al 70%. Limpie suavemente las hojas afectadas con un paño húmedo con agua templada. No use agua fría directamente sobre las hojas.",
        "icono": "🏥",
        "dias_espera": 3
    },
    {
        "paso": 2,
        "titulo": "Paso 2: Aplicación de fungicida",
        "instrucciones": "Aplique fungicida sistémico (Thiram, Mancozeb o Captan) diluido según las instrucciones del fabricante. Rocíe toda la planta por las mañanas para que se seque durante el día. Evite rociar bajo sol directo o cuando haga mucho calor. Repita cada 3 días durante el período de tratamiento.",
        "icono": "💊",
        "dias_espera": 5
    },
    {
        "paso": 3,
        "titulo": "Paso 3: Control del riego y ventilación",
        "instrucciones": "Reduzca el riego significativamente: solo riegue cuando el sustrato esté completamente seco al tacto. Los hongos prosperan en ambientes húmedos. Mejore la ventilación del área donde se encuentra la orquídea. Si es posible, colóquela cerca de una ventana con buena circulación de aire.",
        "icono": "💨",
        "dias_espera": 7
    },
    {
        "paso": 4,
        "titulo": "Paso 4: Segunda aplicación y revisión de raíces",
        "instrucciones": "Aplique el fungicida por segunda vez. Si no observa mejoría, considere cambiar a otro tipo de fungicida. Revise cuidadosamente la base de la planta y las raíces buscando signos de pudrición (color café oscuro o negro, textura blanda). Las raíces sanas son firmes y de color verde o blanco.",
        "icono": "🔍",
        "dias_espera": 7
    },
    {
        "paso": 5,
        "titulo": "Paso 5: Renovación del sustrato",
        "instrucciones": "Ha llegado el momento de trasplantar su orquídea a sustrato completamente nuevo y fresco (corteza de pino o musgo especial para orquídeas). Al trasplantar, revise todas las raíces y corte con tijeras desinfectadas las que estén blandas y oscuras. Deje secar las raíces cortadas por 30 minutos antes de trasplantar.",
        "icono": "🌱",
        "dias_espera": 10
    },
    {
        "paso": 6,
        "titulo": "Paso 6: Tratamiento especializado",
        "instrucciones": "Su orquídea requiere atención especializada. Le recomendamos consultar con un vivero o experto en orquídeas de su área. También puede probar con bactericidas específicos si sospecha que además del hongo hay una infección bacteriana. No se rinda, muchas orquídeas se recuperan con paciencia y cuidado.",
        "icono": "👨‍🌾",
        "dias_espera": 14
    }
]

# Mensajes especiales
MENSAJE_PLANTA_SANA = "¡Felicitaciones! Su orquídea está en excelente estado de salud. Continúe con sus cuidados habituales y realice monitoreos periódicos para prevenir enfermedades futuras."

MENSAJE_PLANTA_ENFERMA_INICIO = "Hemos detectado signos de enfermedad en su orquídea. No se preocupe, con el tratamiento adecuado su planta puede recuperarse completamente. Siga los pasos indicados con dedicación."

MENSAJE_PLANTA_SE_RECUPERO = "¡Excelente noticia! Su orquídea ha mejorado notablemente y está recuperando su salud. Continúe con los cuidados por algunos días más para asegurar la recuperación completa."

# Configuración de base de datos
NOMBRE_BASE_DATOS = "mayaflora.db"

# Carpeta para guardar imágenes temporales
CARPETA_IMAGENES = "imagenes_escaneos"

# Tamaño máximo de imagen almacenada en DB (en píxeles)
MAX_IMAGE_SIZE = 800
