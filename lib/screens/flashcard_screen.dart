import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_lib;
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import '../theme/app_theme.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with TickerProviderStateMixin {
  // Services
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  late ImageLabeler _imageLabeler;
  final FlutterTts _flutterTts = FlutterTts();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // État
  bool _isScanning = false;
  String _recognizedObject = '';
  bool _hasResult = false;
  File? _capturedImage;
  int _pointsEarned = 0;
  bool _saved = false;
  bool _isCameraActive = false;
  bool _showDescription = true;
  double _confidence = 0.0;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initImageLabeler();
    _initTTS();
    _requestPermissions();
    _preloadSound();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  Future<void> _preloadSound() async {
    await _audioPlayer.setSource(AssetSource('sounds/success.mp3'));
  }

  Future<void> _initImageLabeler() async {
    _imageLabeler = ImageLabeler(options: ImageLabelerOptions());
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.photos.request();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage('fr-FR');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _initCamera() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      return;
    }

    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
      );
      await _cameraController!.initialize();
      setState(() {});
    }
  }

  Future<Database> _getDatabase() async {
    String databasePath = path_lib.join(await getDatabasesPath(), 'edulearn.db');
    return await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE objects(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            object TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            points INTEGER DEFAULT 15
          )
        ''');
      },
    );
  }

  Future<void> _saveToDatabase(String object, int points) async {
    final db = await _getDatabase();
    await db.insert('objects', {
      'object': object,
      'timestamp': DateTime.now().toIso8601String(),
      'points': points,
    });
  }

  Future<void> _playFeedback() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      if (await Vibrate.canVibrate) {
        Vibrate.feedback(FeedbackType.light);
      }
    } catch (e) {}
  }

  void _showAlert(String msg, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    Color bgColor;
    if (isError) bgColor = AppTheme.errorColor;
    else if (isSuccess) bgColor = AppTheme.successColor;
    else bgColor = AppTheme.infoColor;

    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _activateCamera() async {
    setState(() => _isCameraActive = true);
    await _initCamera();
  }

  Future<void> _captureFromCamera() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showAlert('Caméra non disponible', isError: true);
      return;
    }

    setState(() {
      _isScanning = true;
      _hasResult = false;
      _saved = false;
    });
    _pulseController.repeat(reverse: true);

    try {
      final XFile image = await _cameraController!.takePicture();
      _capturedImage = File(image.path);
      await _analyzeImage();
    } catch (e) {
      setState(() {
        _isScanning = false;
        _recognizedObject = 'Erreur: $e';
        _hasResult = true;
      });
      _showAlert('Erreur lors de la capture', isError: true);
    } finally {
      _pulseController.stop();
    }
  }

  Future<void> _importFromGallery() async {
    setState(() {
      _isScanning = true;
      _hasResult = false;
      _saved = false;
    });
    _pulseController.repeat(reverse: true);

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        _capturedImage = File(image.path);
        await _analyzeImage();
      } else {
        setState(() => _isScanning = false);
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _recognizedObject = 'Erreur: $e';
        _hasResult = true;
      });
      _showAlert('Erreur lors de l\'import', isError: true);
    } finally {
      _pulseController.stop();
    }
  }

  Future<void> _analyzeImage() async {
    if (_capturedImage == null) return;
    
    final inputImage = InputImage.fromFile(_capturedImage!);
    final labels = await _imageLabeler.processImage(inputImage);

    if (labels.isNotEmpty) {
      final bestLabel = labels.first;
      setState(() {
        _recognizedObject = bestLabel.label;
        _confidence = bestLabel.confidence;
        _pointsEarned = 15;
      });
      await _playFeedback();
      _showAlert('✅ Objet reconnu avec ${(_confidence * 100).toStringAsFixed(0)}% de confiance', isSuccess: true);
      await _flutterTts.speak(_recognizedObject);
    } else {
      setState(() {
        _recognizedObject = 'Objet non reconnu';
        _pointsEarned = 0;
      });
      _showAlert('Aucun objet détecté', isError: true);
    }

    setState(() {
      _hasResult = true;
      _isScanning = false;
    });
  }

  void _saveRecord() {
    if (_recognizedObject.isNotEmpty && _recognizedObject != 'Objet non reconnu' && !_saved) {
      _saveToDatabase(_recognizedObject, _pointsEarned).then((_) {
        if (mounted) {
          setState(() => _saved = true);
          _showAlert('✅ +$_pointsEarned points enregistrés !', isSuccess: true);
        }
      });
    }
  }

  void _duplicateText() {
    if (_recognizedObject.isNotEmpty && _recognizedObject != 'Objet non reconnu') {
      _showAlert('📋 Objet copié dans le presse-papiers', isSuccess: true);
    }
  }

  void _clearAll() {
    setState(() {
      _hasResult = false;
      _recognizedObject = '';
      _capturedImage = null;
      _saved = false;
      _pointsEarned = 0;
      _isCameraActive = false;
      _confidence = 0.0;
    });
  }

  @override
  Widget build(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          '🃏 Reconnaître un objet',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(ctx),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            onPressed: () => Navigator.pushNamed(ctx, '/history'),
            tooltip: 'Historique',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => setState(() => _showDescription = !_showDescription),
            tooltip: 'Aide',
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone d'affichage
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _hasResult && _capturedImage != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          _capturedImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.black.withOpacity(0.4),
                              ],
                            ),
                          ),
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkCardBackground : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.image,
                                        size: 40,
                                        color: AppTheme.secondaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _recognizedObject.isEmpty
                                          ? 'Aucun objet détecté'
                                          : _recognizedObject,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppTheme.text,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_recognizedObject.isNotEmpty && _recognizedObject != 'Objet non reconnu') ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Text(
                                          'Confiance: ${(_confidence * 100).toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.secondaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          _buildQuickAction(
                                            icon: Icons.volume_up,
                                            label: 'Écouter',
                                            color: AppTheme.secondaryColor,
                                            action: () => _flutterTts.speak(_recognizedObject),
                                          ),
                                          _buildQuickAction(
                                            icon: Icons.save,
                                            label: 'Enregistrer',
                                            color: Colors.green,
                                            action: _saveRecord,
                                          ),
                                          _buildQuickAction(
                                            icon: Icons.copy,
                                            label: 'Copier',
                                            color: Colors.blue,
                                            action: _duplicateText,
                                          ),
                                          _buildQuickAction(
                                            icon: Icons.refresh,
                                            label: 'Nouveau',
                                            color: Colors.orange,
                                            action: _clearAll,
                                          ),
                                        ],
                                      ),
                                      if (_pointsEarned > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '+$_pointsEarned points',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _isCameraActive && _cameraController != null && _cameraController!.value.isInitialized
                      ? Stack(
                          children: [
                            CameraPreview(_cameraController!),
                            if (_isScanning)
                              Container(
                                color: Colors.black54,
                                child: Center(
                                  child: AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (ctx, child) {
                                      return Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.photo_camera,
                                            size: 50,
                                            color: AppTheme.secondaryColor,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Container(
                          color: isDark ? AppTheme.darkCardBackground : Colors.grey.shade100,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_search_outlined,
                                    size: 80,
                                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Reconnaissance d\'objets',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppTheme.text,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Activez la caméra ou choisissez une image',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
            ),
          ),

          // Zone boutons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBackground : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: _hasResult
                ? _buildResultPanel()
                : Column(
                    children: [
                      if (_showDescription)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.lightbulb, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Comment ça marche ?',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '📸 Activez la caméra, prenez une photo d\'un objet, puis écoutez sa reconnaissance !',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: isDark ? Colors.grey.shade400 : AppTheme.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isCameraActive ? _captureFromCamera : _activateCamera,
                          icon: Icon(_isCameraActive ? Icons.camera : Icons.camera_alt),
                          label: Text(_isCameraActive ? '📷 Prendre la photo' : '📷 Activer la caméra'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _importFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('🖼️ Importer depuis la galerie'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.secondaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: AppTheme.secondaryColor),
                        ),
                      ),
                      if (_isScanning) ...[
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          color: AppTheme.primaryColor,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Analyse en cours...',
                          style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback action,
  }) {
    return GestureDetector(
      onTap: action,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _clearAll,
                icon: const Icon(Icons.refresh),
                label: const Text('Nouvelle image'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.secondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: AppTheme.secondaryColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/history'),
            icon: const Icon(Icons.history),
            label: const Text('📜 Voir mon historique'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _imageLabeler.close();
    _flutterTts.stop();
    _pulseController.dispose();
    _fadeController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}