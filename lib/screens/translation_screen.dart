import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import '../services/ml_kit_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/activity_history_service.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({Key? key}) : super(key: key);

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> with SingleTickerProviderStateMixin {
  final MLKitService _mlKitService = MLKitService();
  final TextEditingController _sourceController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FocusNode _focusNode = FocusNode();
  
  // Cache pour accélérer les traductions
  final Map<String, String> _translationCache = {};
  
  String _sourceLang = 'fr';
  String _targetLang = 'en';
  String _translatedText = '';
  bool _isTranslating = false;
  bool _isFavorite = false;
  
  // Animations
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Statistiques
  int _totalTranslations = 0;
  int _cacheHits = 0;

  final List<Map<String, String>> _languages = [
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCache();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheString = prefs.getString('translation_cache');
    if (cacheString != null) {
      try {
        final cacheData = jsonDecode(cacheString);
        _translationCache.addAll(cacheData?.cast<String, String>() ?? {});
      } catch (e) {}
    }
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('translation_cache', jsonEncode(_translationCache));
  }

  Future<void> _translate() async {
    final text = _sourceController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('📝 Veuillez entrer du texte à traduire', isError: true);
      return;
    }

    // Vérifier le cache d'abord (ultra rapide)
    final cacheKey = '${_sourceLang}_${_targetLang}_${text.toLowerCase()}';
    if (_translationCache.containsKey(cacheKey)) {
      setState(() {
        _translatedText = _translationCache[cacheKey]!;
        _cacheHits++;
      });
      _showSnackBar('⚡ Traduction instantanée (cache)');
      await _playSoundAndVibrate();
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      final translated = await _mlKitService.translateText(
        text,
        _sourceLang,
        _targetLang,
      );
      
      setState(() {
        _translatedText = translated ?? 'Erreur de traduction';
        _totalTranslations++;
      });

      // Sauvegarder dans le cache
      if (translated != null && translated.isNotEmpty) {
        _translationCache[cacheKey] = translated;
        await _saveCache();
      }

      await _playSoundAndVibrate();
      _showSnackBar('✅ Traduction terminée !');
      
    } catch (e) {
      _showSnackBar('❌ Erreur: $e', isError: true);
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;
      _translatedText = '';
      _sourceController.clear();
      _isFavorite = false;
    });
    _playSoundAndVibrate();
  }

  void _clearText() {
    _sourceController.clear();
    setState(() {
      _translatedText = '';
      _isFavorite = false;
    });
    _focusNode.requestFocus();
    _playSoundAndVibrate();
  }

  void _copyToClipboard() {
    _showSnackBar('📋 Copié dans le presse-papiers');
    _playSoundAndVibrate();
  }

  Future<void> _playSoundAndVibrate() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/click.mp3'));
      if (await Vibrate.canVibrate) {
        Vibrate.feedback(FeedbackType.light);
      }
    } catch (e) {}
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showStats() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '📊 Statistiques',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildStatCard('🌐 Traductions', '$_totalTranslations', 'traductions effectuées'),
            _buildStatCard('⚡ Cache', '$_cacheHits', 'accès cache'),
            _buildStatCard('📦 Cache size', '${_translationCache.length}', 'entrées en cache'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String icon, String value, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF059669).withOpacity(0.1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF059669).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceLang = _languages.firstWhere((l) => l['code'] == _sourceLang);
    final targetLang = _languages.firstWhere((l) => l['code'] == _targetLang);

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5), // Fond vert très clair
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // AppBar moderne avec dégradé vert
              SliverAppBar(
                expandedHeight: 110,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Traduction Pro',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF065F46), // Vert très foncé
                          Color(0xFF059669), // Vert foncé
                          Color(0xFF10B981), // Vert moyen
                        ],
                      ),
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: 0.15,
                        child: const Icon(Icons.translate, size: 80, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.bar_chart, color: Colors.white),
                    onPressed: _showStats,
                    tooltip: 'Statistiques',
                  ),
                ],
              ),
              
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Carte principale
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Sélecteur de langues
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildLanguageCard(
                                    flag: sourceLang['flag']!,
                                    name: sourceLang['name']!,
                                    code: sourceLang['code']!,
                                    isSource: true,
                                    onTap: () => _selectLanguage(isSource: true),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.swap_horiz, size: 22),
                                    onPressed: _swapLanguages,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                                Expanded(
                                  child: _buildLanguageCard(
                                    flag: targetLang['flag']!,
                                    name: targetLang['name']!,
                                    code: targetLang['code']!,
                                    isSource: false,
                                    onTap: () => _selectLanguage(isSource: false),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const Divider(height: 1),
                          
                          // Zone de saisie
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(sourceLang['flag']!, style: const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 10),
                                    Text(
                                      sourceLang['name']!,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                    const Spacer(),
                                    if (_sourceController.text.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 20),
                                        onPressed: _clearText,
                                        color: Colors.grey[400],
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _sourceController,
                                  focusNode: _focusNode,
                                  maxLines: 5,
                                  style: const TextStyle(fontSize: 16, height: 1.4),
                                  decoration: InputDecoration(
                                    hintText: 'Saisissez votre texte à traduire...',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  onChanged: (_) {
                                    if (_translatedText.isNotEmpty) {
                                      setState(() => _translatedText = '');
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_sourceController.text.length} caractères',
                                    style: TextStyle(fontSize: 11, color: const Color(0xFF059669)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const Divider(height: 1),
                          
                          // Bouton de traduction
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isTranslating ? null : _translate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isTranslating)
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    else
                                      const Icon(Icons.auto_awesome, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      _isTranslating ? 'Traduction en cours...' : 'Traduire',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Résultat
                    if (_translatedText.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF059669).withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // En-tête
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Text(targetLang['flag']!, style: const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 10),
                                    Text(
                                      targetLang['name']!,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 20),
                                      onPressed: _copyToClipboard,
                                      color: Colors.grey[600],
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      tooltip: 'Copier',
                                    ),
                                  ],
                                ),
                              ),
                              
                              const Divider(height: 1),
                              
                              // Texte traduit
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: SelectableText(
                                  _translatedText,
                                  style: const TextStyle(fontSize: 16, height: 1.5),
                                ),
                              ),
                              
                              // Badge
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669).withOpacity(0.08),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(28),
                                    bottomRight: Radius.circular(28),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _translationCache.containsKey('${_sourceLang}_${_targetLang}_${_sourceController.text.toLowerCase()}')
                                          ? Icons.speed
                                          : Icons.check_circle,
                                      size: 14,
                                      color: const Color(0xFF059669),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _translationCache.containsKey('${_sourceLang}_${_targetLang}_${_sourceController.text.toLowerCase()}')
                                            ? '⚡ Traduction instantanée (cache)'
                                            : '✓ Traduction terminée',
                                        style: TextStyle(fontSize: 11, color: const Color(0xFF059669)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required String flag,
    required String name,
    required String code,
    required bool isSource,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF059669).withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      code.toUpperCase(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      name,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_drop_down, color: const Color(0xFF059669), size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectLanguage({required bool isSource}) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 15),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Choisir une langue',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ..._languages.map((lang) => ListTile(
              leading: Text(lang['flag']!, style: const TextStyle(fontSize: 32)),
              title: Text(lang['name']!),
              trailing: (isSource ? _sourceLang : _targetLang) == lang['code']
                  ? Icon(Icons.check_circle, color: const Color(0xFF059669))
                  : null,
              onTap: () {
                setState(() {
                  if (isSource) {
                    _sourceLang = lang['code']!;
                  } else {
                    _targetLang = lang['code']!;
                  }
                  _translatedText = '';
                  _sourceController.clear();
                  _isFavorite = false;
                });
                Navigator.pop(context);
                _playSoundAndVibrate();
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _saveActivity(String childId, String type, String title, String description, int points) async {
  final historyService = ActivityHistoryService();
  await historyService.addActivitySimple(
    childId: childId,
    activityType: type,
    title: title,
    description: description,
    points: points,
  );
}
}