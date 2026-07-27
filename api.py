# --- api.py ---
from fastapi import FastAPI, File, UploadFile
import uvicorn
import pickle
import numpy as np
from model_utils import extract_features  # Votre fonction du notebook
from PIL import Image
import io
import os
import json

# 1. Initialiser l'application FastAPI
app = FastAPI(title="Plant Disease API")

# 2. Charger le modèle et le mapping des labels au démarrage
model_path = "model_RForest.pkl"
label_map_path = "label_nom_to_disease_map.json"

model = None
label_map = None

# On charge les fichiers au démarrage du serveur
try:
    with open(model_path, 'rb') as f:
        model = pickle.load(f)
    print("✅ Modèle chargé avec succès.")

    with open(label_map_path, 'r') as f:
        label_map = json.load(f)
    print("✅ Mapping des labels chargé avec succès.")
    
except Exception as e:
    print(f"❌ Erreur lors du chargement des fichiers : {e}")
    exit()

# 3. Définir les endpoints (l'URL que Flutter va appeler)
@app.get("/")
def read_root():
    return {"message": "Plant Disease API is running!"}

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    """
    Endpoint qui reçoit une image et retourne la maladie prédite.
    """
    # Lire le fichier image envoyé par Flutter
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # Sauvegarder temporairement l'image pour le traitement
        temp_image_path = "temp_image.jpg"
        image.save(temp_image_path)

        # Extraire les features de l'image
        features = extract_features(temp_image_path)

        if features is None:
            return {"error": "Erreur lors de l'extraction des features."}

        # Reshaper et prédire
        features = features.reshape(1, -1)
        prediction = int(model.predict(features)[0])
        
        # Récupérer le nom de la maladie
        disease_name = label_map.get(str(prediction), "Maladie inconnue")
        
        # (Optionnel) Obtenir la confiance de la prédiction
        proba = None
        if hasattr(model, "predict_proba"):
            probas = model.predict_proba(features)[0]
            proba = float(probas[prediction])
            # Garder en mémoire le résultat
            print(f"Prédiction: {disease_name} avec {proba:.2%} de confiance")
        
        # Nettoyer
        os.remove(temp_image_path)

        return {
            "prediction": prediction,
            "disease_name": disease_name,
            "confidence": proba
        }

    except Exception as e:
        return {"error": str(e)}

# 4. Lancer le serveur si le script est exécuté directement
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)