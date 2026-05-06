// lib/screens/grammar_analysis_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/grammar_analysis_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class GrammarAnalysisScreen extends StatefulWidget {
  const GrammarAnalysisScreen({super.key});

  @override
  State<GrammarAnalysisScreen> createState() => _GrammarAnalysisScreenState();
}

class _GrammarAnalysisScreenState extends State<GrammarAnalysisScreen>
    with TickerProviderStateMixin {
  final GrammarAnalysisService _grammarService = GrammarAnalysisService();
  final ImagePicker _imagePicker = ImagePicker();
  final SoundService _soundService = SoundService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _textController = TextEditingController();

  File? _selectedImage;
  String _extractedText = '';
  List<WordGrammar> _analysisResults = [];
  bool _isProcessing = false;
  bool _hasResults = false;
  bool _showTutorial = true;
  bool _isTextInputMode = false;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Couleurs Orange
  static const Color primaryOrange = Color(0xFFE65100);
  static const Color lightOrange = Color(0xFFFF9800);
  static const Color pastelOrange = Color(0xFFFFE0B2);
  static const Color darkOrange = Color(0xFFBF360C);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _preloadSound();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  Future<void> _preloadSound() async {
    await _audioPlayer.setSourceAsset('assets/sounds/success.mp3');
  }

  Future<void> _playClickSound() async {
    await _soundService.playClick();
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('assets/sounds/success.mp3'));
      if (await Vibrate.canVibrate) {
        await Vibrate.feedback(FeedbackType.light);
      }
    } catch (e) {}
  }

  Future<void> _analyzeTextFromInput() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showMessage('Veuillez entrer un texte à analyser', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _hasResults = false;
      _selectedImage = null;
      _extractedText = text;
      _analysisResults = [];
    });

    try {
      final results = await _grammarService.analyzeText(text);
      
      setState(() {
        _analysisResults = results;
        _hasResults = true;
        _isProcessing = false;
      });
      
      await _playSuccessSound();
      _showMessage('✨ ${results.length} mots analysés avec succès !', isSuccess: true);
      
    } catch (e) {
      _showMessage('Erreur lors de l\'analyse', isError: true);
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    await _playClickSound();
    setState(() => _isTextInputMode = false);
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      _showMessage('Erreur lors de la sélection', isError: true);
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _hasResults = false;
      _selectedImage = imageFile;
      _extractedText = '';
      _analysisResults = [];
      _textController.clear();
    });

    try {
      final extractedText = await _grammarService.extractTextFromImage(imageFile);
      
      if (extractedText.isEmpty) {
        _showMessage('Aucun texte détecté', isError: true);
        setState(() => _isProcessing = false);
        return;
      }
      
      setState(() => _extractedText = extractedText);
      
      final results = await _grammarService.analyzeText(extractedText);
      
      setState(() {
        _analysisResults = results;
        _hasResults = true;
        _isProcessing = false;
      });
      
      await _playSuccessSound();
      _showMessage('✨ ${results.length} mots analysés avec succès !', isSuccess: true);
      
    } catch (e) {
      _showMessage('Erreur lors de l\'analyse', isError: true);
      setState(() => _isProcessing = false);
    }
  }

  void _showMessage(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : (isSuccess ? Colors.green : primaryOrange),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _reset() {
    _playClickSound();
    setState(() {
      _selectedImage = null;
      _extractedText = '';
      _analysisResults = [];
      _hasResults = false;
      _isTextInputMode = false;
      _textController.clear();
    });
    _fadeController.forward(from: 0);
    _slideController.forward(from: 0);
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _extractedText));
    _showMessage('📋 Texte copié dans le presse-papiers', isSuccess: true);
  }

  void _speakText() {
    _showMessage('🔊 Lecture du texte...', isSuccess: true);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text(
          '🔍 Analyse grammaticale',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: _reset,
            tooltip: 'Nouvelle analyse',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => setState(() => _showTutorial = !_showTutorial),
            tooltip: 'Aide',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Zone d'import avec sélecteur de mode
              _buildImportSection(isDarkMode),
              
              // Zone des résultats
              Expanded(
                child: _isProcessing
                    ? _buildLoadingSection()
                    : _hasResults
                        ? _buildResultsSection(isDarkMode, isTablet)
                        : _isTextInputMode
                            ? _buildTextInputSection(isDarkMode)
                            : _buildEmptyState(isDarkMode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sélecteur de mode
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: pastelOrange.withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _playClickSound();
                      setState(() => _isTextInputMode = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isTextInputMode ? primaryOrange : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 18,
                            color: !_isTextInputMode ? Colors.white : primaryOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scanner',
                            style: TextStyle(
                              color: !_isTextInputMode ? Colors.white : primaryOrange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _playClickSound();
                      setState(() => _isTextInputMode = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isTextInputMode ? primaryOrange : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 18,
                            color: _isTextInputMode ? Colors.white : primaryOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Saisir',
                            style: TextStyle(
                              color: _isTextInputMode ? Colors.white : primaryOrange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_showTutorial && !_isTextInputMode)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [pastelOrange, pastelOrange.withOpacity(0.5)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lightbulb, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isTextInputMode ? 'Comment analyser ?' : 'Comment scanner ?',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryOrange,
                          ),
                        ),
                        Text(
                          _isTextInputMode
                              ? 'Saisissez ou collez un texte à analyser'
                              : 'Prenez une photo d\'un texte ou importez une image',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          if (!_isTextInputMode)
            Row(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: const Text('📷 Appareil photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('🖼️ Galerie'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: primaryOrange),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTextInputSection(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryOrange.withOpacity(0.05),
                  lightOrange.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: pastelOrange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_note, size: 20, color: primaryOrange),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Saisissez votre texte',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Champ de saisie de texte
                TextField(
                  controller: _textController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Exemple : Le chat mange une pomme rouge...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _analyzeTextFromInput,
                        icon: const Icon(Icons.analytics_rounded),
                        label: const Text('Analyser le texte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        _textController.clear();
                        _playClickSound();
                      },
                      icon: const Icon(Icons.clear_all_rounded),
                      tooltip: 'Effacer',
                      style: IconButton.styleFrom(
                        backgroundColor: pastelOrange,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Exemples de texte
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pastelOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📝 Exemples de textes :',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildExampleChip('Le chien aboie bruyamment'),
                          _buildExampleChip('La belle fleur bleue'),
                          _buildExampleChip('Je mange une pomme'),
                          _buildExampleChip('Il court rapidement'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleChip(String example) {
    return ActionChip(
      label: Text(
        example,
        style: const TextStyle(fontSize: 11),
      ),
      onPressed: () {
        _textController.text = example;
        _playClickSound();
      },
      backgroundColor: pastelOrange,
      side: BorderSide.none,
    );
  }

  Widget _buildLoadingSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: pastelOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                    strokeWidth: 3,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Analyse en cours...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reconnaissance du texte et analyse grammaticale',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: pastelOrange.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isTextInputMode ? Icons.edit_note_rounded : Icons.text_fields_rounded,
                size: 64,
                color: primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isTextInputMode ? 'Saisissez un texte' : 'Analyse grammaticale',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isTextInputMode
                  ? 'Saisissez ou collez un texte à analyser\npour découvrir la nature grammaticale de chaque mot'
                  : 'Prenez une photo d\'un texte ou importez une image\npour analyser la nature grammaticale de chaque mot',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(bool isDarkMode, bool isTablet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image analysée (si disponible)
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryOrange.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  _selectedImage!,
                  height: isTablet ? 200 : 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          // Carte du texte analysé
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryOrange.withOpacity(0.05),
                  lightOrange.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: pastelOrange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.text_fields, size: 20, color: primaryOrange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Texte analysé',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: _copyToClipboard,
                          tooltip: 'Copier',
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up, size: 18),
                          onPressed: _speakText,
                          tooltip: 'Lire',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _extractedText,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      height: 1.5,
                      color: isDarkMode ? Colors.grey.shade300 : const Color(0xFF4A4A4A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Résultats grammaticaux
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryOrange.withOpacity(0.05),
                  lightOrange.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: pastelOrange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.format_list_bulleted, size: 20, color: primaryOrange),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Analyse grammaticale',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_analysisResults.length} mots',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: primaryOrange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (isTablet)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: _analysisResults.length,
                    itemBuilder: (context, index) {
                      return _buildWordCard(_analysisResults[index], isDarkMode);
                    },
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _analysisResults.length,
                    itemBuilder: (context, index) {
                      return _buildWordCard(_analysisResults[index], isDarkMode);
                    },
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Légende
          _buildLegend(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWordCard(WordGrammar word, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: pastelOrange),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                word.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.word,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildTagChip(
                      label: _grammarService.getPOSLabel(word.pos),
                      color: primaryOrange,
                    ),
                    if (_grammarService.getSemanticLabel(word.semantic).isNotEmpty)
                      _buildTagChip(
                        label: _grammarService.getSemanticLabel(word.semantic),
                        color: lightOrange,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLegend() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: pastelOrange.withOpacity(0.3),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📖 Légende des couleurs',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryOrange,
          ),
        ),
        const SizedBox(height: 8),
        // Utilisation de Wrap au lieu de Row pour éviter le débordement
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildLegendItem('Nom', primaryOrange),
            _buildLegendItem('Verbe', lightOrange),
            _buildLegendItem('Adjectif', darkOrange),
            _buildLegendItem('Autre', Colors.grey),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _grammarService.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}