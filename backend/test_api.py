import requests

import os
API_KEY = os.getenv("HUGGINGFACE_API_KEY", "")

# Modelos específicos de enfermedades de plantas
modelos = [
    "Yash5/PlantDiseaseDetector",
    "chrisfil/Plant_Disease_Detection",
    "ayoubkirouane/Plant-Disease-Classifier",
    "Deevyam/plant-disease-identifier",
]

headers = {"Authorization": f"Bearer {API_KEY}"}

print("🔍 Probando modelos de enfermedades de plantas...\n")

for modelo in modelos:
    url = f"https://api-inference.huggingface.co/models/{modelo}"
    print(f"📡 Modelo: {modelo}")
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            print(f"   ✅ FUNCIONA!\n")
        elif response.status_code == 503:
            print(f"   ⏳ Modelo cargándose (se puede usar)\n")
        else:
            print(f"   ❌ Error: {response.text[:100]}\n")
    except Exception as e:
        print(f"   ❌ Excepción: {str(e)}\n")

print("\n" + "="*50)
print("Prueba completada")