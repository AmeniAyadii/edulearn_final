import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class TestGeminiScreen extends StatefulWidget {
  const TestGeminiScreen({super.key});

  @override
  State<TestGeminiScreen> createState() => _TestGeminiScreenState();
}

class _TestGeminiScreenState extends State<TestGeminiScreen> {
  String _result = "Cliquez sur 'Tester' pour vérifier votre clé API et les modèles";
  bool _isLoading = false;
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Gemini API'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'Entrez votre clé API Gemini',
                border: OutlineInputBorder(),
                hintText: 'AIzaSy...',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _testApi(_apiKeyController.text),
              child: const Text('Tester la clé API'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _listModels(_apiKeyController.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Lister les modèles disponibles'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testApi(String apiKey) async {
    if (apiKey.isEmpty) {
      setState(() => _result = "❌ Veuillez entrer une clé API");
      return;
    }

    setState(() {
      _isLoading = true;
      _result = "🔄 Test de la clé API...";
    });

    try {
      // Tester avec le modèle gemini-1.5-flash
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
      
      final response = await model.generateContent([
        Content.text("Say 'Hello, API is working!' in one sentence."),
      ]);
      
      setState(() {
        _result = """
✅ Clé API VALIDE !

Réponse du modèle:
${response.text}

Modèle utilisé: gemini-1.5-flash
Votre clé fonctionne parfaitement !
""";
      });
    } catch (e) {
      setState(() {
        _result = """
❌ Erreur avec la clé API: $e

Vérifiez que:
1. La clé API est correcte
2. L'API Gemini est activée sur Google Cloud Console
3. Vous avez entré la clé sans espaces
""";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _listModels(String apiKey) async {
    if (apiKey.isEmpty) {
      setState(() => _result = "❌ Veuillez entrer une clé API");
      return;
    }

    setState(() {
      _isLoading = true;
      _result = "🔄 Récupération des modèles...";
    });

    try {
      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey"
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List;
        
        final modelsList = models.map((m) {
          final name = m['name'] as String;
          final supportedMethods = m['supportedGenerationMethods'] as List?;
          return "📦 $name\n   Supporte: ${supportedMethods?.join(', ') ?? 'aucune méthode'}\n";
        }).join('\n');
        
        setState(() {
          _result = """
✅ Modèles disponibles pour votre clé API:

$modelsList

💡 Recommandation: Utilisez 'gemini-1.5-flash' pour une réponse rapide
💡 Utilisez 'gemini-1.5-pro' pour des réponses plus détaillées
""";
        });
      } else {
        setState(() {
          _result = """
❌ Impossible de lister les modèles
Status: ${response.statusCode}
Message: ${response.body}

Vérifiez que votre clé API est correcte.
""";
        });
      }
    } catch (e) {
      setState(() {
        _result = "❌ Erreur: $e\n\nAssurez-vous d'avoir ajouté 'import'package:http/http.dart' as http;' et 'dart:convert'";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}