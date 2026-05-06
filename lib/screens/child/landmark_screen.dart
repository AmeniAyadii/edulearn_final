// lib/screens/child/landmark_screen.dart (version complète avec les 3 corrections)
import 'dart:io';
import 'package:edulearn_final/screens/history/history_screen.dart';
import 'package:edulearn_final/services/landmark_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../../services/advanced_landmark_service.dart';
import '../../services/firestore_service.dart';
import '../../services/audio_service.dart';
import '../../widgets/confetti_widget.dart';
import 'dart:math';

class LandmarkScreen extends StatefulWidget {
  final String childId;
  final String? childName;  // ← AJOUTER CETTE LIGNE
  
  const LandmarkScreen({
    super.key,
    required this.childId,
    this.childName,  // ← AJOUTER CETTE LIGNE
  });

  @override
  State<LandmarkScreen> createState() => _LandmarkScreenState();
}

class _LandmarkScreenState extends State<LandmarkScreen>
    with SingleTickerProviderStateMixin {
  late LandmarkDetectionService _landmarkService;
  late FirestoreService _firestoreService;
  late AudioService _audioService;
  
  // États
  File? _selectedImage;
  ProcessedLandmarkResult? _result;
  bool _isProcessing = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Animations
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  
  // Statistiques
  int _totalDetections = 0;
  int _rewardsEarned = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
    _loadStatistics();
  }
  
  Future<void> _initializeServices() async {
    _landmarkService = LandmarkDetectionService();
    _firestoreService = FirestoreService();
    _audioService = AudioService();
  }
  
  void _setupAnimations() {
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }
  
  Future<void> _loadStatistics() async {
    setState(() {
      _totalDetections = 42;
      _rewardsEarned = 1250;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _result = null;
          _hasError = false;
          _errorMessage = '';
        });
        
        await _audioService.playScanSound();
        await _detectLandmarks();
      }
    } catch (e) {
      _showError('Erreur lors de la sélection de l\'image: $e');
    }
  }
  
  Future<void> _detectLandmarks() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isProcessing = true;
      _hasError = false;
    });
    
    try {
      final result = await _landmarkService.processImage(_selectedImage!);
      
      setState(() {
        _result = result;
        _isProcessing = false;
      });
      
      if (result.success && result.info != null) {
        await _audioService.playSuccessSound();
        await _saveDetectionToFirestore(result);
        HapticFeedback.lightImpact();
        _showConfetti();
      } else if (result.success && result.needsCustomInfo) {
        await _audioService.playInfoSound();
        _showCustomInfoDialog();
      } else {
        await _audioService.playErrorSound();
        _showError('Aucun monument reconnu. Essayez une autre photo !');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _hasError = true;
        _errorMessage = 'Erreur de detection: ${e.toString()}';
      });
      await _audioService.playErrorSound();
    }
  }
  
  Future<void> _saveDetectionToFirestore(ProcessedLandmarkResult result) async {
  try {
    await _firestoreService.saveLandmarkDetection(
      childId: widget.childId,
      landmarkName: result.landmarkName!,
      location: result.location!,
      confidence: result.confidence,
      imageUrl: await _uploadImage(),
      pointsEarned: 15,
    );
    
    // Sauvegarder dans l'historique Firebase
    try {
      final historyService = HistoryFirebaseService();  // Utiliser la bonne classe
      await historyService.saveHistoryItem(
        HistoryItem(
          id: '${widget.childId}_${DateTime.now().millisecondsSinceEpoch}',
          type: 'landmark',
          category: 'activity',  // ← AJOUTER CETTE LIGNE
          title: result.landmarkName!,
          subtitle: result.location!,
          imageUrl: await _uploadImage(),
          timestamp: DateTime.now(),
          points: 15,
          details: {
            'Confiance': '${result.confidence}%',
            'Catégorie': 'Monument',
          },
          childId: widget.childId,
          childName: widget.childName ?? 'Enfant',
        ),
      );
    } catch (e) {
      print('Erreur sauvegarde historique: $e');
    }
    
    setState(() {
      _totalDetections++;
      _rewardsEarned += 15;
    });
  } catch (e) {
    print('Erreur sauvegarde: $e');
  }
}
  
  Future<String> _uploadImage() async {
    return 'https://example.com/photo.jpg';
  }
  
  void _showConfetti() {
    OverlayState? overlayState = Overlay.of(context);
    
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => ConfettiWidget(
        duration: const Duration(seconds: 3),
        onComplete: () {
          overlayEntry.remove();
        },
      ),
    );
    
    overlayState?.insert(overlayEntry);
  }
  
  void _showCustomInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau monument !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Intéressant ! Pouvez-vous nous en dire plus ?'),
            const SizedBox(height: 16),
            Text(
              'Monument détecté: ${_result?.landmarkName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('En apprenant de nouveaux monuments, '
                'vous gagnez des points et des badges !'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }
  
  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _shareResult() {
    if (_result == null || !_result!.success) return;
    
    final shareText = '''
🌟 Découverte EduLearn ! 🌟

J'ai identifié le monument : ${_result!.landmarkName}
📍 Localisation : ${_result!.location}
🎯 Confiance : ${_result!.confidence}%

${_result!.info?.funFact ?? ''}

Apprenez en vous amusant avec EduLearn !
    ''';
    
    Share.share(shareText);
  }
  
  @override
Widget build(BuildContext context) {
  // Obtenir la largeur de l'écran
  final screenWidth = MediaQuery.of(context).size.width;
  
  return Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: _buildAppBar(),
    body: SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
        ),
        child: IntrinsicHeight(
          child: Column(
            children: [
              _buildStatsHeader(),
              _buildMainContent(),
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    ),
  );
}
  
  PreferredSizeWidget _buildAppBar() {
  return AppBar(
    titleSpacing: 0,
    title: Row(
      children: [
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.landscape, color: Colors.green, size: 24),
        ),
        const SizedBox(width: 10),
        // CORRECTION: Ajouter Expanded pour éviter le débordement
        Expanded(
          child: Text(
            'Détection de Monuments',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    ),
    backgroundColor: Theme.of(context).primaryColor,
    elevation: 0,
    actions: [
      IconButton(
        icon: const Icon(Icons.history),
        onPressed: () => _showHistory(),
        tooltip: 'Historique',
      ),
      IconButton(
        icon: const Icon(Icons.help_outline),
        onPressed: () => _showHelpDialog(),
        tooltip: 'Aide',
      ),
    ],
  );
}
  
  Widget _buildStatsHeader() {
  return Container(
    margin: const EdgeInsets.all(12), // Réduire la marge
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), // Réduire le padding
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.green.shade400, Colors.green.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.green.shade200,
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Changé de spaceAround à spaceEvenly
      children: [
        Expanded( // Ajouter Expanded
          child: _buildStatItem(
            icon: Icons.photo_camera,
            value: _totalDetections.toString(),
            label: 'Découv',
            color: Colors.white,
          ),
        ),
        Container(
          height: 25,
          width: 1,
          color: Colors.white.withOpacity(0.3),
        ),
        Expanded( // Ajouter Expanded
          child: _buildStatItem(
            icon: Icons.emoji_events,
            value: _rewardsEarned.toString(),
            label: 'Points',
            color: Colors.amber.shade300,
          ),
        ),
        Container(
          height: 25,
          width: 1,
          color: Colors.white.withOpacity(0.3),
        ),
        Expanded( // Ajouter Expanded
          child: _buildStatItem(
            icon: Icons.local_fire_department,
            value: DateTime.now().day.toString(),
            label: 'Jour',
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

Widget _buildStatItem({
  required IconData icon,
  required String value,
  required String label,
  required Color color,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min, // Ajouter pour réduire la taille
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    ],
  );
}
  
  
  Widget _buildMainContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildImageArea(),
          const SizedBox(height: 24),
          _buildResultArea(),
        ],
      ),
    );
  }
  
  Widget _buildImageArea() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_selectedImage != null)
              Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
              )
            else
              _buildPlaceholder(),
            
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/scanning.json',
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Analyse en cours...',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ],
                ),
              ),
            
            if (_selectedImage != null && !_isProcessing)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                      _result = null;
                    });
                  },
                ),
              ),
            
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.green,
                          Colors.transparent,
                        ],
                        stops: [
                          max(0.0, _scanAnimation.value - 0.2),
                          _scanAnimation.value,
                          min(1.0, _scanAnimation.value + 0.2),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/camera.json',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 16),
          Text(
            'Prenez une photo d\'un monument',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tour Eiffel, Pyramides, Colisée...',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultArea() {
    if (_isProcessing) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyse en cours...'),
          ],
        ),
      );
    }
    
    if (_result == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 50,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'En attente de photo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prenez ou choisissez une photo pour identifier le monument',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    if (!_result!.success) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Monument non reconnu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Essayez avec une photo plus claire du monument',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600),
            ),
          ],
        ),
      );
    }
    
    return _buildSuccessResult();
  }
  
  Widget _buildSuccessResult() {
  final result = _result!;
  final info = result.info;
  
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16), // Ajouter une marge
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.green.shade50, Colors.blue.shade50],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.green.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête
        Container(
          padding: const EdgeInsets.all(16), // Réduire le padding
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.landscape, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded( // Important pour éviter le débordement
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.landmarkName!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Flexible( // Utiliser Flexible au lieu de Expanded
                          child: Text(
                            result.location!,
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${result.confidence}%',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.green, size: 20),
                onPressed: _shareResult,
              ),
            ],
          ),
        ),
        
        // Contenu
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (info != null) ...[
                _buildSectionTitle('📚 Faits', Icons.history_edu, fontSize: 14),
                const SizedBox(height: 8),
                ...info.facts.map((fact) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fact,
                          style: const TextStyle(fontSize: 12),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                )),
                
                const SizedBox(height: 16),
                
                _buildSectionTitle('🧠 Quiz', Icons.quiz, fontSize: 14),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        info.question,
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showAnswerDialog(info.question, info.answer),
                        icon: const Icon(Icons.lightbulb_outline, size: 16),
                        label: const Text('Voir la réponse'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

// Ajouter une version modifiée de _buildSectionTitle avec taille personnalisable
Widget _buildSectionTitle(String title, IconData icon, {double fontSize = 14}) {
  return Row(
    children: [
      Icon(icon, color: Colors.green.shade700, size: fontSize + 2),
      const SizedBox(width: 6),
      Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade700,
        ),
      ),
    ],
  );
}
  
  
  
  Widget _buildActionButtons() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt, size: 18),  // Réduire taille icône
            label: const Text('Prendre une photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),  // Réduire padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),  // Réduire l'espacement
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library, size: 18),  // Réduire taille icône
            label: const Text('Galerie'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              padding: const EdgeInsets.symmetric(vertical: 12),  // Réduire padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
  void _showAnswerDialog(String question, String answer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réponse au quiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(answer),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
  
  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Historique des découvertes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.landscape, color: Colors.green),
                        title: Text(['Tour Eiffel', 'Colisée', 'Pyramides'][index % 3]),
                        subtitle: Text('Découvert le ${DateTime.now().subtract(Duration(days: index)).toString().substring(0, 10)}'),
                        trailing: const Chip(label: Text('+15'), backgroundColor: Colors.amber),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comment utiliser cette fonction ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpStep('1', 'Prenez une photo', 'Photo du monument que vous souhaitez identifier'),
            const SizedBox(height: 12),
            _buildHelpStep('2', 'Attendez l\'analyse', 'L\'IA analyse votre photo et identifie le monument'),
            const SizedBox(height: 12),
            _buildHelpStep('3', 'Découvrez', 'Lisez les informations éducatives et gagnez des points'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('🎯 Conseils :', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('• Prenez une photo nette et bien éclairée'),
            const Text('• Cadrez bien le monument'),
            const Text('• Évitez les foules ou objets gênants'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris !'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHelpStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _landmarkService.dispose();
    _scanController.dispose();
    super.dispose();
  }
}