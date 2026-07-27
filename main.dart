// --- lib/main.dart ---
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  //const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Diagnosis',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const DiagnosisScreen(),
    );
  }
}

class DiagnosisScreen extends StatefulWidget {
  //const DiagnosisScreen({Key? key}) : super(key: key);
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  File? _image;
  String _resultText = "Choisissez une image";
  String _resultConfidence = "";

  final ImagePicker _picker = ImagePicker();

  // Fonction pour prendre une photo
  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _image = File(image.path);
        // Réinitialiser le texte quand on prend une nouvelle photo
        _resultText = "Photo prise, appuyez sur Diagnostiquer";
        _resultConfidence = "";
      });
    }
  }

  // Fonction pour envoyer la photo au serveur
  Future<void> _diagnosePlant() async {
    if (_image == null) {
      setState(() {
        _resultText = "Veuillez d'abord prendre une photo.";
      });
      return;
    }

    setState(() {
      _resultText = "Analyse en cours...";
      _resultConfidence = "";
    });

    // Adresse de l'API. Remplacez par l'URL de votre serveur déployé.
    // String url = "http://192.168.X.X:5000/predict"; // URL pour Flask
    String url = "http://192.168.1.64:8000/predict"; // URL pour FastAPI
    // Pour un test local avec un émulateur Android, utilisez 10.0.2.2 au lieu de localhost
    // Ex: "http://10.0.2.2:8000/predict"

    try {
      // 1. Créer une requête multipart/form-data
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(await http.MultipartFile.fromPath(
        'file', // Ce nom ('file') doit correspondre à celui attendu par votre API
        _image!.path,
      ));

      // 2. Envoyer la requête
      var response = await request.send();

      // 3. Traiter la réponse
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        // Décoder le JSON
        Map<String, dynamic> data = Map<String, dynamic>.from(
            json.decode(responseData)
        );

        // Vérifier si la réponse contient 'disease_name'
        String disease = data['disease_name'] ?? "Maladie inconnue";
        String confidence = data['confidence'] != null ?
        " (${(data['confidence'] * 100).toStringAsFixed(1)}%)" : "";

        setState(() {
          _resultText = "🔬 Diagnostiqué : $disease";
          _resultConfidence = confidence;
        });
      } else {
        // En cas d'erreur du serveur
        var errorBody = await response.stream.bytesToString();
        print("Erreur serveur: ${response.statusCode} - $errorBody");
        setState(() {
          _resultText = "Erreur du serveur (${response.statusCode})";
          _resultConfidence = "";
        });
      }
    } catch (e) {
      // En cas d'erreur réseau
      print("Erreur réseau : $e");
      setState(() {
        _resultText = "Erreur de connexion : $e";
        _resultConfidence = "";
      });
    }
  }

  // Interface Utilisateur
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostic de plante')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Affichage de l'image
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _image != null
                    ? Image.file(_image!, fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 100, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              // Bouton pour prendre une photo
              ElevatedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Prendre une photo'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
              ),
              const SizedBox(height: 10),
              // Bouton pour diagnostiquer
              ElevatedButton.icon(
                onPressed: _diagnosePlant,
                icon: const Icon(Icons.health_and_safety),
                label: const Text('Diagnostiquer'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white),
              ),
              const SizedBox(height: 30),
              // Zone de résultat
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      _resultText,
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _resultConfidence,
                      style: const TextStyle(fontSize: 14, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ajouter l'import 'dart:convert' en haut pour json.decode
//import 'dart:convert';