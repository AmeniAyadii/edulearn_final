import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';

// ============================================================================
// MODÈLES
// ============================================================================

class VoiceNote {
  final String text;
  final DateTime timestamp;
  final String id;

  VoiceNote({
    required this.text,
    required this.timestamp,
    required this.id,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'id': id,
  };

  factory VoiceNote.fromJson(Map<String, dynamic> json) => VoiceNote(
    text: json['text'],
    timestamp: DateTime.parse(json['timestamp']),
    id: json['id'],
  );
}

// ============================================================================
// ÉCRAN PRINCIPAL
// ============================================================================

class SpeechToTextScreen extends StatefulWidget {
  const SpeechToTextScreen({super.key});

  @override
  State<SpeechToTextScreen> createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends State<SpeechToTextScreen>
    with TickerProviderStateMixin { 
  // Services
  late stt.SpeechToText _speech;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // État
  bool _isListening = false;
  String _recognizedText = "";
  bool _isPermissionDenied = false;
  bool _isAvailable = false;
  double _soundLevel = 0.0;
  List<VoiceNote> _history = [];
  bool _showHistory = false;
  
  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _soundLevelController;
  
  // Configuration
  String _selectedLanguage = 'fr_FR';
  final List<Map<String, String>> _languages = [
    {'code': 'fr_FR', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'en_US', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'ar_SA', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'es_ES', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'de_DE', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'it_IT', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'pt_PT', 'name': 'Português', 'flag': '🇵🇹'},
    {'code': 'ru_RU', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'zh_CN', 'name': '中文', 'flag': '🇨🇳'},
    {'code': 'ja_JP', 'name': '日本語', 'flag': '🇯🇵'},
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initSpeech();
    _loadHistory();
    _preloadSounds();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    
    _soundLevelController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  Future<void> _preloadSounds() async {
    await _audioPlayer.setSource(AssetSource('sounds/success.mp3'));
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('voice_notes');
    if (historyString != null) {
      try {
        final List<dynamic> historyData = jsonDecode(historyString);
        _history = historyData
            .map((item) => VoiceNote.fromJson(item as Map<String, dynamic>))
            .toList();
        setState(() {});
      } catch (e) {}
    }
  }

  Future<void> _saveToHistory(String text) async {
    if (text.trim().isEmpty) return;
    
    final note = VoiceNote(
      text: text,
      timestamp: DateTime.now(),
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _history.insert(0, note);
    if (_history.length > 20) _history.removeLast();
    
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _history.map((note) => note.toJson()).toList();
    await prefs.setString('voice_notes', jsonEncode(historyJson));
    setState(() {});
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    await _requestPermission();
  }

  Future<void> _requestPermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    if (status.isGranted) {
      setState(() => _isPermissionDenied = false);
      await _initSpeechRecognizer();
    } else {
      setState(() => _isPermissionDenied = true);
    }
  }

  Future<void> _initSpeechRecognizer() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Statut: $status'),
      onError: (error) => print('Erreur: $error'),
    );
    
    setState(() {
      _isAvailable = available;
      if (!available) {
        _recognizedText = "Reconnaissance vocale non disponible sur cet appareil";
      }
    });
  }

  Future<void> _startListening() async {
    if (_isPermissionDenied) {
      await _requestPermission();
      return;
    }

    if (!_speech.isAvailable) {
      await _initSpeechRecognizer();
    }

    setState(() {
      _isListening = true;
      _recognizedText = "";
    });
    
    _pulseController.forward();
    _playFeedback();

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
        _soundLevelController.forward(from: 0.0);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: _selectedLanguage,
      onSoundLevelChange: (level) {
        setState(() {
          _soundLevel = level;
        });
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _soundLevel = 0.0;
    });
    _pulseController.stop();
    
    if (_recognizedText.trim().isNotEmpty) {
      await _saveToHistory(_recognizedText);
      await _playFeedback();
      _showMessage('✅ Texte enregistré !', isSuccess: true);
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearText() {
    setState(() {
      _recognizedText = "";
    });
    _playFeedback();
  }

  void _copyToClipboard() {
    if (_recognizedText.isNotEmpty) {
      _showMessage('📋 Texte copié dans le presse-papiers', isSuccess: true);
    }
  }

  void _deleteFromHistory(int index) {
    setState(() {
      _history.removeAt(index);
    });
    final prefs = SharedPreferences.getInstance();
    prefs.then((prefs) {
      final historyJson = _history.map((note) => note.toJson()).toList();
      prefs.setString('voice_notes', jsonEncode(historyJson));
    });
    _showMessage('🗑️ Note supprimée', isSuccess: true);
  }

  void _restoreFromHistory(VoiceNote note) {
    setState(() {
      _recognizedText = note.text;
      _showHistory = false;
    });
    _showMessage('📝 Note restaurée', isSuccess: true);
    _playFeedback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar moderne
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              elevation: 0,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  '🎙️ Dictée Magique',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: 0.1,
                      child: const Icon(Icons.mic, size: 100, color: Colors.white),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () => setState(() => _showHistory = !_showHistory),
                  tooltip: 'Historique',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'clear') _clearText();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'clear', child: Text('🗑️ Effacer le texte')),
                  ],
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Zone de texte
                  _buildTextArea(),
                  const SizedBox(height: 20),
                  
                  // Historique
                  if (_showHistory) _buildHistorySection(),
                  if (_showHistory) const SizedBox(height: 20),
                  
                  // Zone de contrôle
                  _buildControlSection(),
                  const SizedBox(height: 20),
                  
                  // Actions
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextArea() {
    return Container(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isListening ? Colors.red.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isListening ? Icons.mic : Icons.lightbulb,
                      size: 14,
                      color: _isListening ? Colors.red : AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isListening ? 'Écoute en cours...' : 'Texte transcrit',
                      style: TextStyle(
                        fontSize: 10,
                        color: _isListening ? Colors.red : AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_recognizedText.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: _copyToClipboard,
                  tooltip: 'Copier',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                _recognizedText.isEmpty 
                    ? "👋 Appuyez sur le micro et parlez...\n\nVotre texte apparaîtra ici."
                    : _recognizedText,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  height: 1.5,
                  color: _recognizedText.isEmpty ? Colors.grey.shade400 : AppTheme.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSection() {
    return Column(
      children: [
        // Langue
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              const Icon(Icons.language, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              const Text('Langue :'),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _languages.map((lang) {
                    return DropdownMenuItem(
                      value: lang['code'],
                      child: Text('${lang['flag']} ${lang['name']}'),
                    );
                  }).toList(),
                  onChanged: _isListening ? null : (value) {
                    if (value != null) {
                      setState(() => _selectedLanguage = value);
                      _initSpeechRecognizer();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Niveau sonore
        if (_isListening)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _soundLevel,
                    backgroundColor: Colors.grey.shade200,
                    color: AppTheme.primaryColor,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Parlez...',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        
        // Bouton micro animé
        GestureDetector(
          onTap: _isListening ? _stopListening : _startListening,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.red : AppTheme.primaryColor).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: _isListening ? Colors.red : AppTheme.primaryColor,
                    child: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      size: 45,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearText,
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Effacer'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _recognizedText.isNotEmpty ? () async {
              await _saveToHistory(_recognizedText);
              _showMessage('✅ Texte enregistré !', isSuccess: true);
            } : null,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: AppTheme.secondaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                  '📜 Historique des notes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(),
          if (_history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Aucune note enregistrée'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final note = _history[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Icon(Icons.note, size: 16, color: AppTheme.primaryColor),
                  ),
                  title: Text(
                    note.text.length > 40 ? '${note.text.substring(0, 40)}...' : note.text,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    '${note.timestamp.day}/${note.timestamp.month}/${note.timestamp.year} ${note.timestamp.hour}:${note.timestamp.minute}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore, size: 20),
                        onPressed: () => _restoreFromHistory(note),
                        tooltip: 'Restaurer',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deleteFromHistory(index),
                        tooltip: 'Supprimer',
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();
    _soundLevelController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}