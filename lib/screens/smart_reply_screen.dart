import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import '../services/smart_reply_service.dart';
import '../theme/app_theme.dart';

// ============================================================================
// MODÈLES ET CONSTANTES
// ============================================================================

enum MessageRole { user, assistant, system }

class ConversationMessage {
  final String id;
  final String text;
  final MessageRole role;
  final DateTime timestamp;
  final String? reply;
  bool isFavorite;

  ConversationMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
    this.reply,
    this.isFavorite = false,
  });

  factory ConversationMessage.user(String text, {String? reply}) {
    return ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      reply: reply,
    );
  }

  factory ConversationMessage.assistant(String text) {
    return ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );
  }

  ConversationMessage copyWith({
    String? id,
    String? text,
    MessageRole? role,
    DateTime? timestamp,
    String? reply,
    bool? isFavorite,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      reply: reply ?? this.reply,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'role': role.index,
    'timestamp': timestamp.toIso8601String(),
    'reply': reply,
    'isFavorite': isFavorite,
  };

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'],
      text: json['text'],
      role: MessageRole.values[json['role']],
      timestamp: DateTime.parse(json['timestamp']),
      reply: json['reply'],
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}

class CategoryModel {
  final String name;
  final String emoji;
  final List<String> questions;
  final Color color;

  const CategoryModel({
    required this.name,
    required this.emoji,
    required this.questions,
    required this.color,
  });
}

// ============================================================================
// ÉCRAN PRINCIPAL
// ============================================================================

class SmartReplyScreen extends StatefulWidget {
  const SmartReplyScreen({super.key});

  @override
  State<SmartReplyScreen> createState() => _SmartReplyScreenState();
}

class _SmartReplyScreenState extends State<SmartReplyScreen>
    with SingleTickerProviderStateMixin {
  // Services
  late final SmartReplyService _smartReplyService;
  late final FlutterTts _flutterTts;
  late final AudioPlayer _audioPlayer;
  
  // Controllers
  late final TextEditingController _questionController;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  
  // Animation
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  
  // État
  List<ConversationMessage> _conversationHistory = [];
  List<String> _currentSuggestions = [];
  bool _isLoading = false;
  bool _showHistory = true;
  String _currentQuestion = '';
  int _totalQueries = 0;
  int _totalPoints = 0;

  // Catégories
  static const List<CategoryModel> _categories = [
    CategoryModel(
      name: 'Fruits & Légumes',
      emoji: '🍎',
      questions: [
        'Quel fruit est connu pour être rouge et rond ?',
        'Comment s\'appelle le fruit jaune et allongé ?',
        'Quel légume fait pleurer quand on le coupe ?',
        'Quel fruit est vert à l\'extérieur et rouge à l\'intérieur ?',
      ],
      color: Colors.red,
    ),
    CategoryModel(
      name: 'Animaux',
      emoji: '🐾',
      questions: [
        'Quel animal est surnommé le roi de la jungle ?',
        'Quel animal marin peut nager des kilomètres ?',
        'Quel est le plus grand animal du monde ?',
        'Quel animal fait "miaou" ?',
      ],
      color: Colors.orange,
    ),
    CategoryModel(
      name: 'Sciences',
      emoji: '🔬',
      questions: [
        'Pourquoi le ciel est-il bleu ?',
        'Quelle est la planète la plus proche du soleil ?',
        'Comment fonctionne l\'arc-en-ciel ?',
        'Qu\'est-ce que la photosynthèse ?',
      ],
      color: Colors.blue,
    ),
    CategoryModel(
      name: 'Mathématiques',
      emoji: '🧮',
      questions: [
        'Combien de côtés a un hexagone ?',
        'Comment calculer l\'aire d\'un cercle ?',
        'Qu\'est-ce qu\'un nombre premier ?',
        'Combien font 144 divisé par 12 ?',
      ],
      color: Colors.green,
    ),
    CategoryModel(
      name: 'Langues',
      emoji: '🌍',
      questions: [
        'Comment dit-on "merci" en japonais ?',
        'Quelle est la différence entre "savoir" et "connaître" ?',
        'Comment conjuguer le verbe "être" au passé composé ?',
        'Qu\'est-ce qu\'un homonyme ?',
      ],
      color: Colors.purple,
    ),
    CategoryModel(
      name: 'Art & Culture',
      emoji: '🎨',
      questions: [
        'Qui a peint la Joconde ?',
        'Qu\'est-ce que le cubisme ?',
        'Comment reconnaître une œuvre impressionniste ?',
        'Quels sont les instruments de l\'orchestre ?',
      ],
      color: Colors.pink,
    ),
  ];

  // ============================================================================
  // CYCLE DE VIE
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeControllers();
    _initializeAnimations();
    _loadData();
  }

  void _initializeServices() {
    _smartReplyService = SmartReplyService();
    _flutterTts = FlutterTts();
    _audioPlayer = AudioPlayer();
    _initTTS();
    _preloadSounds();
  }

  void _initializeControllers() {
    _questionController = TextEditingController();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage('fr-FR');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _preloadSounds() async {
    try {
      await _audioPlayer.setSource(AssetSource('sounds/success.mp3'));
      await _audioPlayer.setSource(AssetSource('sounds/click.mp3'));
    } catch (e) {
      // Ignorer les erreurs de son si les fichiers n'existent pas
    }
  }

  // ============================================================================
  // GESTION DES DONNÉES
  // ============================================================================

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Charger historique
    final historyString = prefs.getString('conversation_history_v2');
    if (historyString != null) {
      try {
        final List<dynamic> historyData = jsonDecode(historyString);
        setState(() {
          _conversationHistory = historyData
              .map((item) => ConversationMessage.fromJson(item as Map<String, dynamic>))
              .toList();
        });
      } catch (e) {
        // Ignorer les erreurs de parsing
      }
    }
    
    // Charger statistiques
    _totalQueries = prefs.getInt('total_queries') ?? 0;
    _totalPoints = prefs.getInt('total_points') ?? 0;
    
    setState(() {});
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _conversationHistory.map((item) => item.toJson()).toList();
    await prefs.setString('conversation_history_v2', jsonEncode(historyJson));
    await prefs.setInt('total_queries', _totalQueries);
    await prefs.setInt('total_points', _totalPoints);
  }

  // ============================================================================
  // LOGIQUE MÉTIER
  // ============================================================================

  Future<void> _generateReplies() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      _showSnackBar('Veuillez entrer une question 📝', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _currentQuestion = question;
    });

    try {
      final suggestions = await _smartReplyService.suggestReplies(question);
      final pointsEarned = suggestions.length * 5;

      setState(() {
        _currentSuggestions = suggestions;
        _isLoading = false;
        _totalQueries++;
        _totalPoints += pointsEarned;
      });

      // Ajouter à l'historique
      final userMessage = ConversationMessage.user(
        question,
        reply: suggestions.isNotEmpty ? suggestions.first : '',
      );
      _conversationHistory.insert(0, userMessage);
      
      for (final suggestion in suggestions.take(3)) {
        _conversationHistory.insert(0, ConversationMessage.assistant(suggestion));
      }
      
      if (_conversationHistory.length > 50) {
        _conversationHistory = _conversationHistory.take(50).toList();
      }
      
      await _saveData();
      await _playSuccessFeedback();
      _questionController.clear();
      
      _showSnackBar(
        '✨ +$pointsEarned points ! ${suggestions.length} réponses générées',
        isSuccess: true,
      );
      
      // Scroll automatique vers le haut
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur: ${e.toString()}', isError: true);
    }
  }

  Future<void> _playSuccessFeedback() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      if (await Vibrate.canVibrate) {
        Vibrate.feedback(FeedbackType.light);
      }
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  Future<void> _speakText(String text) async {
    await _flutterTts.speak(text);
    _showSnackBar('🔊 Lecture en cours...', isSuccess: true);
  }

  void _toggleFavorite(ConversationMessage message) {
    final index = _conversationHistory.indexOf(message);
    if (index != -1) {
      setState(() {
        _conversationHistory[index] = message.copyWith(
          isFavorite: !message.isFavorite,
        );
      });
      _saveData();
      _showSnackBar(
        message.isFavorite ? '⭐ Retiré des favoris' : '⭐ Ajouté aux favoris',
        isSuccess: true,
      );
    }
  }

  void _deleteMessage(ConversationMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildDeleteSheet(message),
    );
  }

  Widget _buildDeleteSheet(ConversationMessage message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Icon(Icons.delete_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Supprimer ce message ?',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message.text.length > 50 ? '${message.text.substring(0, 50)}...' : message.text,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _conversationHistory.remove(message);
                    });
                    _saveData();
                    Navigator.pop(context);
                    _showSnackBar('🗑️ Message supprimé', isSuccess: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Supprimer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _shareConversation() {
    if (_conversationHistory.isEmpty) {
      _showSnackBar('Aucune conversation à partager', isError: true);
      return;
    }
    
    final conversationText = _conversationHistory.reversed.map((msg) {
      final prefix = msg.role == MessageRole.user ? '👤 Moi' : '🤖 Assistant';
      return '$prefix: ${msg.text}';
    }).join('\n\n');
    
    Clipboard.setData(ClipboardData(text: conversationText));
    _showSnackBar('📋 Conversation copiée dans le presse-papier !', isSuccess: true);
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Effacer l\'historique'),
        content: const Text('Voulez-vous vraiment supprimer tout l\'historique des conversations ?\n\nCette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              setState(() => _conversationHistory.clear());
              await _saveData();
              Navigator.pop(context);
              _showSnackBar('🧹 Historique effacé', isSuccess: true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Effacer tout'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    Color backgroundColor;
    if (isError) {
      backgroundColor = AppTheme.errorColor;
    } else if (isSuccess) {
      backgroundColor = AppTheme.successColor;
    } else {
      backgroundColor = AppTheme.infoColor;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCategoryQuestions(CategoryModel category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Text(category.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Text(
                  category.name,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: category.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Questions suggérées :',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: category.questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: category.color.withOpacity(0.3)),
                    ),
                    child: InkWell(
                      onTap: () {
                        _questionController.text = category.questions[index];
                        Navigator.pop(context);
                        _generateReplies();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: category.color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: category.color,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                category.questions[index],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Icon(Icons.arrow_forward, color: category.color),
                          ],
                        ),
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

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'à l\'instant';
    }
  }

  // ============================================================================
  // UI - BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isLoading ? _buildLoadingState() : _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assistant Intelligent',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Apprends avec l\'IA 🤖',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '$_totalPoints',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'share') _shareConversation();
                  if (value == 'clear') _clearHistory();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'share', child: Text('📤 Partager conversation')),
                  const PopupMenuItem(value: 'clear', child: Text('🗑️ Effacer historique', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'L\'IA réfléchit... 🤔',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Génération des réponses intelligentes',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
  return SingleChildScrollView(
    controller: _scrollController,
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.only(bottom: 40),
    child: Column(
      children: [
        _buildHistoryToggle(),
        if (_showHistory && _conversationHistory.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildConversationHistory(),
        ],
        const SizedBox(height: 16),
        _buildInputCard(),
        const SizedBox(height: 16),
        _buildCategoriesGrid(),
        const SizedBox(height: 16),
        if (_currentSuggestions.isNotEmpty) 
          _buildResultsSection(),
        const SizedBox(height: 32),
      ],
    ),
  );
}

  Widget _buildHistoryToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '📜 Activité récente',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showHistory = !_showHistory),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    _showHistory ? 'Masquer' : 'Afficher',
                    style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showHistory ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationHistory() {
  final favorites = _conversationHistory.where((m) => m.isFavorite).toList();
  final recent = _conversationHistory.take(10).toList();
  final displayList = favorites.isNotEmpty ? favorites : recent;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          '📜 ${favorites.isNotEmpty ? "Favoris" : "Derniers messages"}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      const SizedBox(height: 8),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displayList.length,
        itemBuilder: (context, index) {
          final message = displayList[index];
          final isUser = message.role == MessageRole.user;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isUser 
                  ? AppTheme.primaryColor.withOpacity(0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: message.isFavorite ? Colors.amber : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Avatar - avec largeur fixe
                Container(
                  width: 50,
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: isUser 
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : AppTheme.secondaryColor.withOpacity(0.1),
                    child: Icon(
                      isUser ? Icons.person : Icons.auto_awesome,
                      size: 18,
                      color: isUser ? AppTheme.primaryColor : AppTheme.secondaryColor,
                    ),
                  ),
                ),
                
                // Contenu texte - prend tout l'espace disponible
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                
                // Boutons d'action - avec Wrap pour éviter l'overflow
                Wrap(
                  spacing: 0,
                  children: [
                    IconButton(
                      icon: Icon(
                        message.isFavorite ? Icons.star : Icons.star_border,
                        size: 18,
                        color: message.isFavorite ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () => _toggleFavorite(message),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, size: 18),
                      onPressed: () => _speakText(message.text),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _deleteMessage(message),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _questionController,
              focusNode: _focusNode,
              maxLines: 3,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Pose ta question ici... 💭',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: _questionController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _questionController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _generateReplies,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome),
                        SizedBox(width: 8),
                        Text('Générer des réponses'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildCategoriesGrid() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          '📚 Explorer par catégorie',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 100, // Hauteur fixe pour les catégories
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return GestureDetector(
              onTap: () => _showCategoryQuestions(category),
              child: Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      category.color.withOpacity(0.1),
                      category.color.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: category.color.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(category.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: category.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}
  Widget _buildResultsSection() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: AppTheme.cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lightbulb, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(  // ✅ Important pour éviter l'overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Réponses intelligentes',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Clique sur une réponse pour l\'écouter',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Suggestions - Utiliser Wrap au lieu de Row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _currentSuggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final reply = entry.value;
            final colors = [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
              AppTheme.accentColor,
            ];

            final color = colors[index % colors.length];
            
            //Navigator.pushNamed(context, '/test_gemini');
            return Material(
              elevation: 1,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => _speakText(reply),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.reply, size: 14, color: color),
                      const SizedBox(width: 6),
                      Text(
                        reply.length > 30 ? '${reply.substring(0, 27)}...' : reply,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.volume_up, size: 14, color: color),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 16),
        
        // Boutons d'action
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _currentSuggestions = []);
                  _questionController.clear();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Nouvelle question', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: AppTheme.primaryColor),
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareConversation,
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Partager', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  // ============================================================================
  // NETTOYAGE
  // ============================================================================

  @override
  void dispose() {
    _questionController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}