import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/note_service.dart';
import 'screens/auth_wrapper.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAQx1zBGoKv-yKPkbnL93cv2L6MjILoR8E",
      // apiKey: "{firebaseAppConfigKey}",
      authDomain: "logicket.firebaseapp.com",
      projectId: "logicket",
      storageBucket: "logicket.appspot.com",
      messagingSenderId: "85439876807",
      appId: "85439876807",
    ),
  );
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  runApp(const LogicketApp());
}

class LogicketApp extends StatelessWidget {
  const LogicketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => NoteService()),
      ],
      child: MaterialApp(
        title: 'Logicket',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ja', 'JP'),
          Locale('en', 'US'),
        ],
        locale: const Locale('ja', 'JP'),
        theme: ThemeData(
          primarySwatch: _createMaterialColor(const Color(0xFF33A6B8)),
          primaryColor: const Color(0xFF33A6B8),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF33A6B8),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'NotoSansJP', // 日本語フォント指定
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontFamily: 'NotoSansJP'),
            bodyMedium: TextStyle(fontFamily: 'NotoSansJP'),
            bodySmall: TextStyle(fontFamily: 'NotoSansJP'),
            headlineLarge: TextStyle(fontFamily: 'NotoSansJP'),
            headlineMedium: TextStyle(fontFamily: 'NotoSansJP'),
            headlineSmall: TextStyle(fontFamily: 'NotoSansJP'),
            titleLarge: TextStyle(fontFamily: 'NotoSansJP'),
            titleMedium: TextStyle(fontFamily: 'NotoSansJP'),
            titleSmall: TextStyle(fontFamily: 'NotoSansJP'),
            labelLarge: TextStyle(fontFamily: 'NotoSansJP'),
            labelMedium: TextStyle(fontFamily: 'NotoSansJP'),
            labelSmall: TextStyle(fontFamily: 'NotoSansJP'),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF33A6B8),
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              fontFamily: 'NotoSansJP',
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF33A6B8),
            foregroundColor: Colors.white,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Color(0xFF33A6B8),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: TextStyle(fontFamily: 'NotoSansJP'),
            unselectedLabelStyle: TextStyle(fontFamily: 'NotoSansJP'),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(fontFamily: 'NotoSansJP'),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontFamily: 'NotoSansJP'),
            ),
          ),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}
