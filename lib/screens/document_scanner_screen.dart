import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // AJOUTER CET IMPORT
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
// IMPORTS POUR L'HISTORIQUE FIREBASE
import '../screens/history/history_screen.dart'; // Pour HistoryItem et HistoryFirebaseService

// ============================================================================
// MODÈLES
// ============================================================================

class ScannedDocument {
  final File image;
  final String text;
  final DateTime timestamp;
  final String fileName;

  ScannedDocument({
    required this.image,
    required this.text,
    required this.timestamp,
    required this.fileName,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'fileName': fileName,
  };
}

// ============================================================================
// ÉCRAN PRINCIPAL
// ============================================================================

class DocumentScannerScreen extends StatefulWidget {
  final String? childId;
  final String? childName;
  
  const DocumentScannerScreen({
    super.key, 
    this.childId,
    this.childName,
  });

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen>
    with SingleTickerProviderStateMixin {
  // Services
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // État
  File? _scannedImage;
  String _extractedText = '';
  List<ScannedDocument> _history = [];
  bool _isScanning = false;
  bool _isExtracting = false;
  bool _textExtracted = false;
  bool _showHistory = false;
  bool _isFromCamera = true;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initTTS();
    _preloadSound();
    _loadHistory();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _preloadSound() async {
    await _audioPlayer.setSource(AssetSource('sounds/success.mp3'));
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage('fr-FR');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('scanned_documents');
    if (historyString != null) {
      try {
        final List<dynamic> historyData = jsonDecode(historyString);
        _history = [];
      } catch (e) {}
    }
  }

  Future<void> _saveToHistory(String text) async {
    if (_scannedImage != null && text.isNotEmpty) {
      final doc = ScannedDocument(
        image: _scannedImage!,
        text: text,
        timestamp: DateTime.now(),
        fileName: 'document_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      _history.insert(0, doc);
      if (_history.length > 10) _history.removeLast();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('scanned_documents', jsonEncode([]));
    }
  }

  // ============================================================================
  // SAUVEGARDE DANS FIREBASE HISTORY
  // ============================================================================
  
  Future<void> _saveToFirebaseHistory(String text, int points) async {
    // Vérifier que childId est valide
    if (widget.childId == null || widget.childId!.isEmpty) {
      print('⚠️ Pas de childId, sauvegarde Firebase ignorée');
      return;
    }
    
    try {
      final historyService = HistoryFirebaseService();
      
      // Calculer le nombre de mots et de caractères
      final wordCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
      final charCount = text.length;
      
      // Créer un titre et sous-titre
      final title = '📄 Scan de document';
      final subtitle = text.length > 50 ? '${text.substring(0, 50)}...' : text;
      
      await historyService.saveHistoryItem(
        HistoryItem(
          id: 'scan_${DateTime.now().millisecondsSinceEpoch}_${widget.childId}',
          type: 'document_scanner',
          category: 'activity',
          title: title,
          subtitle: subtitle,
          imageUrl: _scannedImage?.path,
          timestamp: DateTime.now(),
          points: points,
          details: {
            'wordCount': wordCount,
            'charCount': charCount,
            'source': _isFromCamera ? 'caméra' : 'galerie',
            'fullText': text.length > 200 ? text.substring(0, 200) : text,
          },
          childId: widget.childId!,
          childName: widget.childName ?? 'Mon enfant',
        ),
      );
      
      print('✅ Scan sauvegardé dans Firebase History: ${text.length} caractères, +$points points');
    } catch (e) {
      print('❌ Erreur sauvegarde Firebase: $e');
    }
  }

  Future<void> _scanFromCamera() async {
    setState(() {
      _isScanning = true;
      _textExtracted = false;
      _extractedText = '';
      _isFromCamera = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      
      if (image != null) {
        _scannedImage = File(image.path);
        await _playFeedback();
        _showMessage('✅ Photo prise avec succès !', isSuccess: true);
        await _extractText();
      } else {
        setState(() => _isScanning = false);
      }
    } catch (e) {
      setState(() => _isScanning = false);
      _showMessage('Erreur: $e', isError: true);
    }
  }

  Future<void> _scanFromGallery() async {
    setState(() {
      _isScanning = true;
      _textExtracted = false;
      _extractedText = '';
      _isFromCamera = false;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      
      if (image != null) {
        _scannedImage = File(image.path);
        await _playFeedback();
        _showMessage('✅ Image importée avec succès !', isSuccess: true);
        await _extractText();
      } else {
        setState(() => _isScanning = false);
      }
    } catch (e) {
      setState(() => _isScanning = false);
      _showMessage('Erreur: $e', isError: true);
    }
  }

  Future<void> _extractText() async {
    if (_scannedImage == null) return;

    setState(() {
      _isExtracting = true;
      _textExtracted = false;
    });

    try {
      final inputImage = InputImage.fromFile(_scannedImage!);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final text = recognizedText.text.trim();
      
      // Calculer les points (5 points par mot, minimum 10 points)
      final wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
      final points = text.isEmpty ? 0 : (wordCount * 5);
      
      setState(() {
        _extractedText = text.isEmpty ? 'Aucun texte détecté' : text;
        _isExtracting = false;
        _textExtracted = true;
      });

      if (text.isNotEmpty) {
        await _playFeedback();
        await _saveToHistory(text);
        
        // 🔥 SAUVEGARDE DANS FIREBASE HISTORY
        await _saveToFirebaseHistory(text, points);
        
        _showMessage('📝 ${text.length} caractères, $wordCount mots | +$points points !', isSuccess: true);
      } else {
        _showMessage('Aucun texte détecté dans l\'image', isError: true);
      }
    } catch (e) {
      setState(() {
        _isExtracting = false;
        _extractedText = 'Erreur lors de l\'extraction';
      });
      _showMessage('Erreur: $e', isError: true);
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _speakText() async {
    if (_extractedText.isNotEmpty && _extractedText != 'Aucun texte détecté') {
      await _flutterTts.speak(_extractedText);
    }
  }

  Future<void> _copyToClipboard() async {
    if (_extractedText.isNotEmpty && _extractedText != 'Aucun texte détecté') {
      await Clipboard.setData(ClipboardData(text: _extractedText));
      _showMessage('📋 Texte copié dans le presse-papiers', isSuccess: true);
      await _playFeedback();
    }
  }

  Future<void> _playFeedback() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      if (await Vibrate.canVibrate) {
        Vibrate.feedback(FeedbackType.light);
      }
    } catch (e) {}
  }

  void _showMessage(String message, {bool isError = false, bool isSuccess = false}) {
    Color backgroundColor;
    if (isError) backgroundColor = AppTheme.errorColor;
    else if (isSuccess) backgroundColor = AppTheme.successColor;
    else backgroundColor = AppTheme.infoColor;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _reset() {
    setState(() {
      _scannedImage = null;
      _extractedText = '';
      _textExtracted = false;
    });
  }

  void _shareResult() {
    if (_extractedText.isNotEmpty && _extractedText != 'Aucun texte détecté') {
      _showMessage('📤 Texte prêt à être partagé', isSuccess: true);
    }
  }
  
  void _navigateToHistory() {
    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DocumentScannerScreen(
      childId: widget.childId, // ou votre variable childId
      childName: widget.childName,
    ),
  ),
);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('📄 Scanner Pro'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToHistory,
            tooltip: 'Voir l\'historique',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'share') _shareResult();
              if (value == 'clear') _reset();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'share', child: Text('📤 Partager')),
              const PopupMenuItem(value: 'clear', child: Text('🗑️ Effacer')),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Carte d'information
              _buildInfoCard(),
              const SizedBox(height: 20),

              // Boutons d'action
              _buildActionButtons(),
              const SizedBox(height: 20),

              // Image scannée
              if (_scannedImage != null) _buildScannedImageCard(),
              if (_scannedImage != null) const SizedBox(height: 20),

              // Texte extrait
              if (_textExtracted) _buildExtractedTextCard(),
              if (_textExtracted) const SizedBox(height: 20),

              // Historique local
              if (_showHistory && _history.isNotEmpty) _buildHistoryCard(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.document_scanner, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scanner intelligent',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prenez une photo ou importez une image pour extraire le texte',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                if (widget.childId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_sync, size: 12, color: AppTheme.successColor),
                          const SizedBox(width: 4),
                          Text(
                            'Sauvegarde automatique',
                            style: TextStyle(fontSize: 10, color: AppTheme.successColor),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isScanning ? null : _scanFromCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('📷 Caméra'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isScanning ? null : _scanFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('🖼️ Galerie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScannedImageCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.image, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  '📸 Document scanné',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Image.file(
              _scannedImage!,
              width: double.infinity,
              height: 280,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedTextCard() {
    final wordCount = _extractedText.isEmpty || _extractedText == 'Aucun texte détecté' 
        ? 0 
        : _extractedText.trim().split(RegExp(r'\s+')).length;
    final points = wordCount * 5;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.text_fields, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  '📝 Texte extrait',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _isExtracting
                ? const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Extraction du texte en cours...'),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: SelectableText(
                          _extractedText.isEmpty 
                              ? 'Aucun texte détecté' 
                              : _extractedText,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ),
                      if (_extractedText.isNotEmpty && _extractedText != 'Aucun texte détecté') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '+$points points gagnés ! (${wordCount} mots × 5 pts)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _speakText,
                              icon: const Icon(Icons.volume_up),
                              label: const Text('🔊 Lire'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _copyToClipboard,
                              icon: const Icon(Icons.copy),
                              label: const Text('📋 Copier'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _reset,
                              icon: const Icon(Icons.refresh),
                              label: const Text('🔄 Nouveau scan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
            ),
          
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.history, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  '📜 Historique récent',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _history.take(5).length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final doc = _history[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    (index + 1).toString(),
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
                title: Text(
                  doc.text.length > 50 ? '${doc.text.substring(0, 50)}...' : doc.text,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  '${doc.timestamp.day}/${doc.timestamp.month}/${doc.timestamp.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: () {
                    _scannedImage = doc.image;
                    _extractedText = doc.text;
                    _textExtracted = true;
                    setState(() {});
                    _showMessage('Document restauré', isSuccess: true);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton.icon(
              onPressed: _navigateToHistory,
              icon: const Icon(Icons.cloud_queue),
              label: const Text('Voir tout l\'historique'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    _textRecognizer.close();
    super.dispose();
  }
}