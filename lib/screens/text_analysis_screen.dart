import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import '../services/text_analysis_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class TextAnalysisScreen extends StatefulWidget {
  const TextAnalysisScreen({super.key});

  @override
  State<TextAnalysisScreen> createState() => _TextAnalysisScreenState();
}

class _TextAnalysisScreenState extends State<TextAnalysisScreen>
    with TickerProviderStateMixin {
  final TextAnalysisService _analysisService = TextAnalysisService();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SoundService _soundService = SoundService();
  final TextEditingController _textController = TextEditingController();

  File? _selectedImage;
  String _extractedText = '';
  List<WordCategory> _analysisResults = [];
  List<WordCategory> _filteredResults = [];
  bool _isProcessing = false;
  bool _hasResults = false;
  bool _showTutorial = true;
  bool _isTextInputMode = false;
  String _searchWord = '';
  CategoryType? _selectedCategoryFilter;

  Map<CategoryType, int> _categoryStats = {};

  // Couleurs rouges
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color lightRed = Color(0xFFFF5252);
  static const Color pastelRed = Color(0xFFFFCDD2);
  static const Color darkRed = Color(0xFFB71C1C);
  static const Color gradientStart = Color(0xFFE53935);
  static const Color gradientEnd = Color(0xFFC62828);

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

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
      _filteredResults = [];
    });

    try {
      final results = await _analysisService.analyzeText(text);
      
      setState(() {
        _analysisResults = results;
        _filteredResults = List.from(results);
        _hasResults = true;
        _isProcessing = false;
        _updateStatistics();
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
      _filteredResults = [];
      _searchWord = '';
      _textController.clear();
    });

    try {
      final extractedText = await _analysisService.extractTextFromImage(imageFile);

      if (extractedText.isEmpty) {
        _showMessage('Aucun texte détecté dans l\'image', isError: true);
        setState(() => _isProcessing = false);
        return;
      }

      setState(() {
        _extractedText = extractedText;
      });

      final results = await _analysisService.analyzeText(extractedText);

      setState(() {
        _analysisResults = results;
        _filteredResults = List.from(results);
        _hasResults = true;
        _isProcessing = false;
        _updateStatistics();
      });

      await _playSuccessSound();
      _showMessage('✅ ${results.length} mots analysés !', isSuccess: true);
    } catch (e) {
      _showMessage('Erreur lors de l\'analyse', isError: true);
      setState(() => _isProcessing = false);
    }
  }

  void _updateStatistics() {
    _categoryStats = {};
    for (var result in _analysisResults) {
      final type = result.type;
      _categoryStats[type] = (_categoryStats[type] ?? 0) + 1;
    }
  }

  void _filterResults(String query) {
    setState(() {
      _searchWord = query;
      if (query.isEmpty && _selectedCategoryFilter == null) {
        _filteredResults = List.from(_analysisResults);
      } else {
        _filteredResults = _analysisResults.where((item) {
          bool matchesSearch = query.isEmpty || item.word.toLowerCase().contains(query.toLowerCase());
          bool matchesCategory = _selectedCategoryFilter == null || item.type == _selectedCategoryFilter;
          return matchesSearch && matchesCategory;
        }).toList();
      }
    });
  }

  void _filterByCategory(CategoryType? type) {
    setState(() {
      _selectedCategoryFilter = type;
      _filterResults(_searchWord);
    });
  }

  void _reset() {
    _playClickSound();
    setState(() {
      _selectedImage = null;
      _extractedText = '';
      _analysisResults = [];
      _filteredResults = [];
      _hasResults = false;
      _categoryStats = {};
      _searchWord = '';
      _selectedCategoryFilter = null;
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
        backgroundColor: isError ? Colors.red : (isSuccess ? Colors.green : primaryRed),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      //backgroundColor: isDarkMode ? const Color(0xFF121212) : pastelRed.withOpacity(0.3),
      backgroundColor: const Color.fromARGB(255, 232, 206, 215), // Rose pastel (Lavender Blush)
      appBar: AppBar(
        title: Text(
          '🔍 Analyse de Texte',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryRed,
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
              color: pastelRed.withOpacity(0.3),
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
                        color: !_isTextInputMode ? primaryRed : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 18,
                            color: !_isTextInputMode ? Colors.white : primaryRed,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scanner',
                            style: TextStyle(
                              color: !_isTextInputMode ? Colors.white : primaryRed,
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
                        color: _isTextInputMode ? primaryRed : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 18,
                            color: _isTextInputMode ? Colors.white : primaryRed,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Saisir',
                            style: TextStyle(
                              color: _isTextInputMode ? Colors.white : primaryRed,
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
          
          if (_showTutorial && !_isTextInputMode && !_hasResults && !_isProcessing)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [pastelRed, pastelRed.withOpacity(0.5)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryRed,
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
                          'Comment analyser ?',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryRed,
                          ),
                        ),
                        Text(
                          'Prenez une photo ou importez une image contenant du texte',
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
                            backgroundColor: primaryRed,
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
                      foregroundColor: primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: primaryRed),
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
                  primaryRed.withOpacity(0.05),
                  lightRed.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: pastelRed),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_note, size: 20, color: primaryRed),
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
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _analyzeTextFromInput,
                        icon: const Icon(Icons.analytics_rounded),
                        label: const Text('Analyser le texte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
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
                        backgroundColor: pastelRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
                    color: pastelRed,
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
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
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Extraction et classification des mots',
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
                color: pastelRed.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isTextInputMode ? Icons.edit_note_rounded : Icons.text_fields_rounded,
                size: 64,
                color: primaryRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isTextInputMode ? 'Saisissez un texte' : 'Analyse de texte',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isTextInputMode
                  ? 'Saisissez ou collez un texte à analyser'
                  : 'Prenez une photo ou importez une image contenant du texte',
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
    return Column(
      children: [
        // Barre de recherche
        Container(
          margin: const EdgeInsets.all(16),
          child: TextField(
            onChanged: _filterResults,
            decoration: InputDecoration(
              hintText: '🔍 Rechercher un mot...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchWord.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _filterResults(''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        
        // Filtres par catégorie
        Container(
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: CategoryType.values.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return FilterChip(
                  label: const Text('Tous'),
                  selected: _selectedCategoryFilter == null,
                  onSelected: (_) => _filterByCategory(null),
                  selectedColor: primaryRed.withOpacity(0.2),
                  checkmarkColor: primaryRed,
                  labelStyle: TextStyle(
                    color: _selectedCategoryFilter == null ? primaryRed : Colors.grey,
                  ),
                );
              }
              final type = CategoryType.values[index - 1];
              final label = _analysisService.getCategoryLabel(type);
              final color = _analysisService.getCategoryColor(type);
              return FilterChip(
                label: Text(label),
                selected: _selectedCategoryFilter == type,
                onSelected: (_) => _filterByCategory(type),
                selectedColor: color.withOpacity(0.2),
                checkmarkColor: color,
                labelStyle: TextStyle(
                  color: _selectedCategoryFilter == type ? color : Colors.grey,
                ),
              );
            },
          ),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Image analysée
                if (_selectedImage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryRed.withOpacity(0.2),
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
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryRed.withOpacity(0.05),
                        lightRed.withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: pastelRed),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.text_fields, size: 20, color: primaryRed),
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

                // Statistiques
                if (_categoryStats.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryRed.withOpacity(0.05),
                          lightRed.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: pastelRed),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.analytics, size: 20),
                            SizedBox(width: 8),
                            Text('Statistiques', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categoryStats.entries.map((entry) {
                            final label = _analysisService.getCategoryLabel(entry.key);
                            final color = _analysisService.getCategoryColor(entry.key);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: color.withOpacity(0.3)),
                              ),
                              child: Text(
                                '$label: ${entry.value}',
                                style: GoogleFonts.poppins(fontSize: 12, color: color),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                // Liste des mots
                if (_filteredResults.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryRed.withOpacity(0.05),
                          lightRed.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: pastelRed),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.format_list_bulleted, size: 20),
                              const SizedBox(width: 8),
                              const Text('Mots trouvés', style: TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_filteredResults.length} mots',
                                  style: TextStyle(fontSize: 12, color: primaryRed),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredResults.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            return _buildWordTile(_filteredResults[index], isDarkMode);
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWordTile(WordCategory item, bool isDarkMode) {
    final color = _analysisService.getCategoryColor(item.type);
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.word,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _analysisService.getCategoryLabel(item.type),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.definition,
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _audioPlayer.dispose();
    _analysisService.dispose();
    super.dispose();
  }
}