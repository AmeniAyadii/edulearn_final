import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

// Modèle d'entité amélioré
class ExtractedEntity {
  final String text;
  final EntityType type;
  final int startIndex;
  final int endIndex;
  final double confidence;

  ExtractedEntity({
    required this.text,
    required this.type,
    required this.startIndex,
    required this.endIndex,
    this.confidence = 1.0,
  });
}

enum EntityType {
  date, time, location, person, organization, email, phone, url, number, other
}

class EntityExtractionScreen extends StatefulWidget {
  const EntityExtractionScreen({super.key});

  @override
  State<EntityExtractionScreen> createState() => _EntityExtractionScreenState();
}

class _EntityExtractionScreenState extends State<EntityExtractionScreen>
    with TickerProviderStateMixin {
  // Services
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  
  // État
  List<ExtractedEntity> _entities = [];
  List<ExtractedEntity> _filteredEntities = [];
  bool _isProcessing = false;
  bool _hasAnalyzed = false;
  String _selectedFilter = 'Tous';
  String? _extractedImageText;
  File? _capturedImage;
  bool _isProcessingImage = false;
  
  // Animations
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Statistiques
  int _totalEntities = 0;
  Map<EntityType, int> _entityStats = {};
  
  // Options de filtre
  final List<String> _filterOptions = ['Tous', 'Dates', 'Personnes', 'Lieux', 'Contacts', 'URLs', 'Nombres'];
  
  // Configuration des entités
  final Map<EntityType, EntityConfig> _entityConfig = {
    EntityType.date: EntityConfig(
      label: 'Date',
      icon: Icons.calendar_today,
      color: const Color(0xFF4CAF50),
      emoji: '📅',
      description: 'Dates et heures',
    ),
    EntityType.time: EntityConfig(
      label: 'Heure',
      icon: Icons.access_time,
      color: const Color(0xFFFF9800),
      emoji: '⏰',
      description: 'Horaires et durées',
    ),
    EntityType.location: EntityConfig(
      label: 'Lieu',
      icon: Icons.location_on,
      color: const Color(0xFF2196F3),
      emoji: '📍',
      description: 'Adresses et lieux',
    ),
    EntityType.person: EntityConfig(
      label: 'Personne',
      icon: Icons.person,
      color: const Color(0xFF9C27B0),
      emoji: '👤',
      description: 'Noms et prénoms',
    ),
    EntityType.organization: EntityConfig(
      label: 'Organisation',
      icon: Icons.business,
      color: const Color(0xFF607D8B),
      emoji: '🏢',
      description: 'Entreprises et institutions',
    ),
    EntityType.email: EntityConfig(
      label: 'Email',
      icon: Icons.email,
      color: const Color(0xFFE91E63),
      emoji: '📧',
      description: 'Adresses email',
    ),
    EntityType.phone: EntityConfig(
      label: 'Téléphone',
      icon: Icons.phone,
      color: const Color(0xFF00BCD4),
      emoji: '📞',
      description: 'Numéros de téléphone',
    ),
    EntityType.url: EntityConfig(
      label: 'URL',
      icon: Icons.link,
      color: const Color(0xFF3F51B5),
      emoji: '🔗',
      description: 'Liens web',
    ),
    EntityType.number: EntityConfig(
      label: 'Nombre',
      icon: Icons.numbers,
      color: const Color(0xFFFF6B35),
      emoji: '🔢',
      description: 'Valeurs numériques',
    ),
    EntityType.other: EntityConfig(
      label: 'Autre',
      icon: Icons.help_outline,
      color: const Color(0xFF9E9E9E),
      emoji: '📌',
      description: 'Autres entités',
    ),
  };

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _requestPermissions();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.photos.request();
  }

  Future<void> _extractEntitiesFromText(String text) async {
    if (text.trim().isEmpty) {
      _showSnackBar('📝 Aucun texte à analyser', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _hasAnalyzed = false;
    });

    await _playSoundAndVibrate();
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final entities = await _performEntityExtraction(text);
      
      setState(() {
        _entities = entities;
        _filteredEntities = entities;
        _hasAnalyzed = true;
        _updateStatistics();
      });

      await _playSoundAndVibrate();
      _showSnackBar('✅ ${entities.length} entité${entities.length > 1 ? 's' : ''} détectée${entities.length > 1 ? 's' : ''} !');
      
    } catch (e) {
      _showSnackBar('❌ Erreur lors de l\'analyse: $e', isError: true);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _extractEntities() async {
    await _extractEntitiesFromText(_textController.text);
  }

  Future<void> _captureImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la capture', isError: true);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'import', isError: true);
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessingImage = true;
      _capturedImage = imageFile;
      _extractedImageText = null;
    });

    _pulseController.repeat(reverse: true);

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final extractedText = recognizedText.text.trim();
      
      setState(() {
        _extractedImageText = extractedText;
        _textController.text = extractedText;
      });

      await _extractEntitiesFromText(extractedText);
      
      if (extractedText.isEmpty) {
        _showSnackBar('Aucun texte détecté dans l\'image', isError: true);
      } else {
        _showSnackBar('✅ Texte extrait avec succès !', isSuccess: true);
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'extraction du texte', isError: true);
    } finally {
      setState(() {
        _isProcessingImage = false;
      });
      _pulseController.stop();
    }
  }

  Future<List<ExtractedEntity>> _performEntityExtraction(String text) async {
    final entities = <ExtractedEntity>[];
    
    final patterns = {
      EntityType.email: r'\b[\w\.-]+@[\w\.-]+\.\w+\b',
      EntityType.phone: r'(\+?\d{1,3}[-.]?)?\(?\d{1,4}\)?[-.]?\d{1,4}[-.]?\d{1,9}\b',
      EntityType.url: r'https?://[^\s]+|www\.[^\s]+',
      EntityType.date: r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b|\b\d{1,2}\s+(?:janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)\s+\d{4}\b',
      EntityType.number: r'\b\d+(?:[.,]\d+)?\b(?!\s*(?:€|\$|%|ans|euros))',
    };
    
    patterns.forEach((type, pattern) {
      final regex = RegExp(pattern, caseSensitive: false);
      final matches = regex.allMatches(text);
      for (var match in matches) {
        entities.add(ExtractedEntity(
          text: match.group(0)!,
          type: type,
          startIndex: match.start,
          endIndex: match.end,
        ));
      }
    });
    
    final locations = ['paris', 'londres', 'new york', 'tokyo', 'berlin', 'madrid', 'rome', 'lyon', 'marseille', 'bordeaux', 'nice'];
    for (var location in locations) {
      final regex = RegExp(r'\b' + location + r'\b', caseSensitive: false);
      final matches = regex.allMatches(text);
      for (var match in matches) {
        entities.add(ExtractedEntity(
          text: match.group(0)!,
          type: EntityType.location,
          startIndex: match.start,
          endIndex: match.end,
        ));
      }
    }
    
    final namePatterns = [
      r"je m'appelle\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)",
      r"mon nom est\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)",
      r"prénom\s+([A-Z][a-z]+)",
    ];
    for (var pattern in namePatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        entities.add(ExtractedEntity(
          text: match.group(1)!,
          type: EntityType.person,
          startIndex: match.start,
          endIndex: match.end,
        ));
      }
    }
    
    entities.sort((a, b) => a.startIndex.compareTo(b.startIndex));
    return entities;
  }

  void _updateStatistics() {
    _totalEntities = _entities.length;
    _entityStats = {};
    for (var entity in _entities) {
      _entityStats[entity.type] = (_entityStats[entity.type] ?? 0) + 1;
    }
  }

  void _filterEntities(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'Tous') {
        _filteredEntities = _entities;
      } else if (filter == 'Dates') {
        _filteredEntities = _entities.where((e) => e.type == EntityType.date || e.type == EntityType.time).toList();
      } else if (filter == 'Personnes') {
        _filteredEntities = _entities.where((e) => e.type == EntityType.person).toList();
      } else if (filter == 'Lieux') {
        _filteredEntities = _entities.where((e) => e.type == EntityType.location).toList();
      } else if (filter == 'Contacts') {
        _filteredEntities = _entities.where((e) => e.type == EntityType.email || e.type == EntityType.phone).toList();
      } else if (filter == 'URLs') {
        _filteredEntities = _entities.where((e) => e.type == EntityType.url).toList();
      } else if (filter == 'Nombres') {
        _filteredEntities = _entities.where((e) => e.type == EntityType.number).toList();
      }
    });
  }

  Future<void> _playSoundAndVibrate() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/click.mp3'));
      if (await Vibrate.canVibrate) {
        Vibrate.feedback(FeedbackType.light);
      }
    } catch (e) {}
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    Color backgroundColor;
    if (isError) backgroundColor = Colors.red;
    else if (isSuccess) backgroundColor = Colors.green;
    else backgroundColor = Colors.deepPurple;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : (isSuccess ? Icons.check_circle : Icons.info), color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearText() {
    _textController.clear();
    setState(() {
      _entities = [];
      _filteredEntities = [];
      _hasAnalyzed = false;
      _totalEntities = 0;
      _entityStats = {};
      _extractedImageText = null;
      _capturedImage = null;
    });
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Extraction d\'entités',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.deepPurple, Colors.deepPurple.shade800],
                    ),
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: 0.1,
                      child: const Icon(Icons.data_usage, size: 80, color: Colors.white),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _clearText,
                  tooltip: 'Effacer',
                ),
              ],
            ),
            
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildInputCard(),
                  const SizedBox(height: 16),
                  
                  if (_isProcessingImage) _buildImageProcessingCard(),
                  if (_capturedImage != null && _extractedImageText != null) _buildCapturedImageCard(isDarkMode),
                  
                  if (_hasAnalyzed && _entities.isNotEmpty) _buildStatsCard(),
                  if (_hasAnalyzed && _entities.isNotEmpty) _buildFilterChips(),
                  if (_hasAnalyzed && _filteredEntities.isNotEmpty) _buildResultsCard(),
                  if (_hasAnalyzed && _filteredEntities.isEmpty) _buildEmptyStateCard(),
                  
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: 6,
              style: GoogleFonts.poppins(fontSize: 16, height: 1.5, color: isDarkMode ? Colors.white : Colors.grey[800]),
              decoration: InputDecoration(
                hintText: '📝 Saisissez votre texte ici...\n\nExemple: Je suis né le 15/05/1990 à Paris...',
                hintStyle: GoogleFonts.poppins(color: isDarkMode ? Colors.grey[500] : Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _extractEntities,
                        icon: _isProcessing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome),
                        label: Text(_isProcessing ? 'Analyse en cours...' : '🔍 Extraire les entités'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _captureImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('📷 Appareil photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: const BorderSide(color: Colors.deepPurple),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImageFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('🖼️ Galerie'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: const BorderSide(color: Colors.deepPurple),
                        ),
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

  Widget _buildImageProcessingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.image_search, size: 40, color: Colors.white),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Extraction du texte en cours...',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            backgroundColor: Colors.deepPurple.withOpacity(0.2),
            color: Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedImageCard(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.image, size: 20, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Image analysée',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Image.file(
              _capturedImage!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics, color: Colors.deepPurple),
              ),
              const SizedBox(width: 12),
              const Text(
                'Statistiques',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_totalEntities entité${_totalEntities > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _entityStats.entries.map((entry) {
              final config = _entityConfig[entry.key]!;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: config.color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(config.icon, size: 14, color: config.color),
                    const SizedBox(width: 4),
                    Text(
                      '${config.label}: ${entry.value}',
                      style: TextStyle(fontSize: 12, color: config.color),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (_) => _filterEntities(filter),
                backgroundColor: Colors.white,
                selectedColor: Colors.deepPurple.withOpacity(0.1),
                checkmarkColor: Colors.deepPurple,
                labelStyle: GoogleFonts.poppins(
                  color: isSelected ? Colors.deepPurple : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.list_alt, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Entités détectées',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filteredEntities.length} résultat${_filteredEntities.length > 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredEntities.length,
            separatorBuilder: (context, index) => Divider(color: isDarkMode ? Colors.grey[800] : Colors.grey[100]),
            itemBuilder: (context, index) {
              final entity = _filteredEntities[index];
              final config = _entityConfig[entity.type]!;
              return _buildEntityTile(entity, config, isDarkMode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEntityTile(ExtractedEntity entity, EntityConfig config, bool isDarkMode) {
    return InkWell(
      onTap: () => _showSnackBar('📋 "${entity.text}" copié !', isSuccess: true),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [config.color.withOpacity(0.1), config.color.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(config.icon, color: config.color, size: 24),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entity.text,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: config.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          config.label,
                          style: GoogleFonts.poppins(fontSize: 10, color: config.color),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        config.description,
                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 12, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${(entity.confidence * 100).toInt()}%',
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.green[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune entité trouvée',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec un texte contenant des dates,\n des emails, des numéros de téléphone...',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class EntityConfig {
  final String label;
  final IconData icon;
  final Color color;
  final String emoji;
  final String description;

  EntityConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.emoji,
    required this.description,
  });
}