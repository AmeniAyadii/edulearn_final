import 'package:edulearn_final/providers/animation_provider.dart';
import 'package:edulearn_final/providers/child_provider.dart';
import 'package:edulearn_final/providers/game_provider.dart';
import 'package:edulearn_final/providers/guess_game_provider.dart';
import 'package:edulearn_final/providers/text_size_provider.dart';
import 'package:edulearn_final/screens/activities/activities_menu_screen.dart';
import 'package:edulearn_final/screens/child/child_profile_screen.dart';
import 'package:edulearn_final/screens/child/landmark_screen.dart';
import 'package:edulearn_final/screens/games/animal_writing_game.dart';
import 'package:edulearn_final/screens/games/animal_writing_game_mlkit.dart';
import 'package:edulearn_final/screens/games/category_game_screen.dart';
import 'package:edulearn_final/screens/games/color_learning_game.dart';
import 'package:edulearn_final/screens/games/drawing_game_screen.dart';
import 'package:edulearn_final/screens/games/emotion_game_screen.dart';
import 'package:edulearn_final/screens/games/food_learning_game.dart';
import 'package:edulearn_final/screens/games/game_zoo_screen.dart';
import 'package:edulearn_final/screens/games/games_menu_screen.dart';
import 'package:edulearn_final/screens/games/language_mystery_game.dart';
import 'package:edulearn_final/screens/games/rhythm_game_screen.dart';
import 'package:edulearn_final/screens/games/show_object_game_screen.dart';
import 'package:edulearn_final/screens/games/spy_game_screen.dart';
import 'package:edulearn_final/screens/games/translation_flash_game.dart';
import 'package:edulearn_final/screens/guess_screen.dart';
import 'package:edulearn_final/screens/word_history_screen.dart';
import 'package:edulearn_final/services/notifications/notification_service.dart';
import 'package:edulearn_final/test_gemini.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:edulearn_final/screens/auth/child_login_screen.dart';
import 'package:edulearn_final/screens/auth/login_screen.dart';
import 'package:edulearn_final/screens/parent/child_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/language_provider.dart';
import 'screens/home_screen.dart';
import 'screens/lecture_screen.dart';
import 'screens/flashcard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/languages_screen.dart';
import 'screens/smart_reply_screen.dart';
import 'screens/translation_screen.dart';
import 'screens/quiz_game_screen.dart';
import 'screens/document_scanner_screen.dart';
import 'screens/speech_to_text_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/entity_extraction_screen.dart';
import 'screens/text_analysis_screen.dart';
import 'screens/grammar_analysis_screen.dart';
import 'screens/parent/parent_home_screen.dart';
import 'services/sound_service.dart';
import 'services/vibration_service.dart';




//import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await EasyLocalization.ensureInitialized();
  await SoundService().init();
  await VibrationService().init();
  //await NotificationService().init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Initialiser le service de notifications
  await NotificationService.initialize();
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      startLocale: const Locale('fr'),
      saveLocale: true,
      child: const EduLearnApp(),
    ),
  );
}

class EduLearnApp extends StatelessWidget {
  const EduLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    return MultiProvider(
      providers: [
        //ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..listenToThemeChanges()), // Appeler listenToThemeChanges
        ChangeNotifierProvider(create: (_) => AnimationProvider()), // ✅ Ajouter
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),  // ← AJOUTER CETTE LIGNE
        ChangeNotifierProvider(create: (_) => GuessGameProvider()), // ← AJOUTER
        ChangeNotifierProvider(create: (_) => TextSizeProvider()), // ✅ Ajouter
        ChangeNotifierProvider(create: (_) => ChildProvider()), // ← AJOUTER CETTE LIGNE
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // ✅ Récupérer le TextSizeProvider ici
          final textSizeProvider = Provider.of<TextSizeProvider>(context);
          return MaterialApp(
            title: 'EduLearn',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            // ✅ Application globale de la taille du texte - CORRIGÉ
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textSizeProvider.textScaleFactor),
                ),
                child: child!,
              );
            },
            
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasData) {
                  return const ParentHomeScreen();
                } else {
                  return const LoginScreen();
                }
              },
            ),
            routes: {
              '/home': (context) => const HomeScreen(),
              //'/lecture': (context) => const LectureScreen(),
              '/flashcard': (context) => const FlashcardScreen(),
              '/history': (context) => const HistoryScreen(),
              '/languages': (context) => const LanguageScreen(),
              '/smart_reply': (context) => const SmartReplyScreen(),
              '/translation': (context) => const TranslationScreen(),
              '/quiz': (context) => const QuizGameScreen(),
              //'/document_scanner': (context) => const DocumentScannerScreen(),
              '/speech': (context) => const SpeechToTextScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/child_login': (context) => const ChildLoginScreen(parentId: ''),
              '/child_dashboard': (context) => const ChildDashboardScreen(child: {}),
              '/entity_extraction': (context) => const EntityExtractionScreen(),
              '/text_analysis': (context) => const TextAnalysisScreen(),
              '/grammar_analysis': (context) => const GrammarAnalysisScreen(),
              '/word_history': (context) => const WordHistoryScreen(),
              '/emotion_game': (context) => const EmotionGameScreen(),
              '/show_object_game': (context) => const ShowObjectGameScreen(),
              '/translation_flash': (context) => const TranslationFlashGame(),
              '/category_game': (context) => const CategoryGameScreen(),
              '/drawing_game': (context) => const DrawingGameScreen(),
              '/language_mystery': (context) => const LanguageMysteryGame(),
              '/rhythm_game': (context) => const RhythmGameScreen(),
              '/spy_game': (context) => const SpyGameScreen(),
              '/polyglot_animal': (context) => const GameZooScreen(),
              '/animal_writing': (context) => const AnimalWritingGame(),
              '/food_learning': (context) => const FoodLearningGame(),
              '/color_learning': (context) => const ColorLearningGame(),
              '/test_gemini': (context) => const TestGeminiScreen(),
              '/animal_game_mlkit': (context) => const AnimalWritingGameMLKit(),
              // Dans main.dart, la route serait probablement :
'/child_profile': (context) {
  final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
  return ChildProfileScreen(
    childId: args?['childId'] ?? '',
    childName: args?['childName'] ?? '',
  );
},

              '/guess_game': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return GuessScreen(
        sessionId: args?['sessionId'] ?? '',
        childId: args?['childId'] ?? '',
      );
    },

    '/activities_menu': (context) => const ActivitiesMenuScreen(),
              
              '/landmark': (context) => LandmarkScreen(
              childId: ModalRoute.of(context)?.settings.arguments as String? ?? '',
            ),
            // Dans main.dart, modifiez la route '/document_scanner' :

'/document_scanner': (context) {
  // Gérer les deux types possibles : String ou Map
  final args = ModalRoute.of(context)?.settings.arguments;
  
  String? childId;
  String? childName;
  
  if (args is Map<String, String>) {
    childId = args['childId'];
    childName = args['childName'];
  } else if (args is String) {
    // Si c'est une String, l'utiliser comme childId
    childId = args;
    childName = 'Enfant';
  }
  
  return DocumentScannerScreen(
    childId: childId,
    childName: childName,
  );
},
// Dans main.dart, modifiez la route '/lecture' :
'/lecture': (context) {
  final args = ModalRoute.of(context)?.settings.arguments;
  print('📱 Route /lecture - type d\'argument reçu: ${args.runtimeType}');
  print('📱 Argument: $args');
  
  String? childId;
  String? childName;
  
  if (args is Map<String, String>) {
    childId = args['childId'];
    childName = args['childName'];
  } else if (args is String) {
    childId = args;
    childName = 'Enfant';
  } else if (args != null) {
    // Si c'est autre chose, essayons de le convertir
    childId = args.toString();
    childName = 'Enfant';
  }
  
  print('📱 childId extrait: $childId');
  print('📱 childName extrait: $childName');
  
  return LectureScreen(
    childId: childId,
    childName: childName,
  );
},


            },

            onGenerateRoute: (settings) {
              // Gestion des routes avec paramètres supplémentaires
              if (settings.name == '/lecture_with_params') {
                final args = settings.arguments as Map<String, String>?;
                return MaterialPageRoute(
                  builder: (context) => LectureScreen(
                    childId: args?['childId'],
                    childName: args?['childName'],
                  ),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}