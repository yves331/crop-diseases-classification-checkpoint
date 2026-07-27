import cv2
import numpy as np




def extract_features(image_path):
    """
    Transforme une image en vecteur numérique (liste de features).
    
    Paramètre:
        image_path (str) : chemin vers le fichier image
        
    Retourne:
        numpy.array : vecteur de features, ou None si l'image est illisible
    """
    # Lecture de l'image avec OpenCV (format BGR par défaut)
    img = cv2.imread(image_path)
    
    # Vérification : si l'image n'a pas pu être lue, on retourne None
    if img is None:
        return None
    
    features = []   # On va accumuler toutes les features dans cette liste

    # ── Feature 1 : Histogramme de couleurs (3 canaux × 32 bins) ──────────────
    # Un histogramme compte combien de pixels ont chaque niveau d'intensité.
    # On utilise 32 "bacs" (bins) entre 0 et 255 pour chaque canal de couleur.
    # Exemple : beaucoup de pixels avec une forte intensité rouge → plante stressée ?
    for i in range(3):   # i=0 : Bleu, i=1 : Vert, i=2 : Rouge (ordre BGR d'OpenCV)
        hist = cv2.calcHist([img], [i], None, [32], [0, 256])
        features.extend(hist.flatten())   # On aplatit le tableau 2D en liste 1D
    
    # ── Feature 2 : Moments statistiques par canal (moyenne, écart-type, médiane) ─
    # Ces statistiques résument la distribution des couleurs de façon très compacte.
    # Exemple : une plante chlorotique (jaune) aura moins de vert → moyenne canal vert faible
    for i in range(3):
        channel = img[:, :, i]   # Extraction du canal i (matrice 2D de pixels)
        features.extend([
            np.mean(channel),    # Valeur moyenne des pixels du canal
            np.std(channel),     # Écart-type (mesure de la variabilité)
            np.median(channel)   # Valeur médiane (robuste aux valeurs extrêmes)
        ])
    
    # ── Feature 3 : Texture en niveaux de gris ──────────────────────────────────
    # On convertit en niveaux de gris pour analyser la texture indépendamment de la couleur.
    # Une texture irrégulière (taches, lésions) aura un écart-type et une variance élevés.
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    features.extend([
        np.mean(gray),   # Luminosité moyenne
        np.std(gray),    # Variabilité de la luminosité (texture rugueuse = std élevé)
        np.var(gray)     # Variance (carré de l'écart-type)
    ])
    
    # ── Feature 4 : Détection de contours (algorithme de Canny) ─────────────────
    # Canny détecte les bords et transitions de l'image (contours de taches, nervures…).
    # On mesure la "densité" des contours = proportion de pixels qui sont des contours.
    # Une plante très malade peut avoir beaucoup de contours irréguliers.
    edges = cv2.Canny(gray, 50, 150)   # 50 et 150 : seuils bas et haut de détection
    features.append(np.sum(edges) / edges.size)   # Proportion de pixels "contour"
    
    return np.array(features)   # On retourne un tableau numpy de dimension fixe