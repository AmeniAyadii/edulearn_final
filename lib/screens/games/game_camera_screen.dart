import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart' as my_auth;  // ← AJOUTER alias
import 'game_result_screen.dart';

class GameCameraScreen extends StatefulWidget {
  final String childId;  // ← AJOUTER pour recevoir childId
  const GameCameraScreen({super.key, required this.childId});  // ← MODIFIER

  @override
  State<GameCameraScreen> createState() => _GameCameraScreenState();
}

class _GameCameraScreenState extends State<GameCameraScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }
  
  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;
    
    _cameraController = CameraController(
      _cameras![0],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    
    await _cameraController!.initialize();
    
    if (mounted) {
      setState(() {
        _isCameraReady = true;
      });
    }
  }
  
  Future<void> _takePicture() async {
    if (_isProcessing || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Vibration au moment de la capture
      if (await Vibrate.canVibrate) {
        Vibrate.feedback(FeedbackType.light);
      }
      
      final XFile picture = await _cameraController!.takePicture();
      final File imageFile = File(picture.path);
      
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      // Utiliser l'alias pour AuthProvider
      final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
      
      final success = await gameProvider.scanAnimal(imageFile, widget.childId);  // ← Utiliser widget.childId
      
      if (!mounted) return;
      
      if (success && gameProvider.currentAnimal != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GameResultScreen(
              imageFile: imageFile,
              childId: widget.childId,  // ← PASSER childId
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(gameProvider.errorMessage ?? "Animal non reconnu. Essaie encore !"),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur photo: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _toggleTorch() async {
    if (_cameraController == null) return;
    _isTorchOn = !_isTorchOn;
    await _cameraController!.setFlashMode(_isTorchOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }
  
  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    // Correction pour LensDirection
    final currentLensDirection = _cameraController!.description.lensDirection;
    final newIndex = currentLensDirection == CameraLensDirection.back ? 1 : 0;
    await _cameraController!.dispose();
    
    _cameraController = CameraController(
      _cameras![newIndex],
      ResolutionPreset.medium,
    );
    
    await _cameraController!.initialize();
    
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cameraController?.resumePreview();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          if (_isCameraReady && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            Container(color: Colors.black),
          
          // Guide overlay
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.crop_free, color: Colors.white, size: 60),
                  const SizedBox(height: 20),
                  Text(
                    'Placez l\'animal dans le cadre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      shadows: [
                        Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 5),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Top bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIconButton(Icons.close, () => Navigator.pop(context)),
                Row(
                  children: [
                    _buildIconButton(Icons.flash_on, _toggleTorch, isActive: _isTorchOn),
                    const SizedBox(width: 12),
                    _buildIconButton(Icons.cameraswitch, _switchCamera),
                  ],
                ),
              ],
            ),
          ),
          
          // Bottom capture button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.black,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          
          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Reconnaissance en cours... 🦁',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildIconButton(IconData icon, VoidCallback onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: isActive ? Border.all(color: Colors.amber, width: 2) : null,
        ),
        child: Icon(icon, color: isActive ? Colors.amber : Colors.white, size: 24),
      ),
    );
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }
}