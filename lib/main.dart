import 'package:diamond_host_admin/state_management/general_provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import provider for state management
import 'package:shared_preferences/shared_preferences.dart';
import 'localization/demo_localization.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_screen.dart';
import 'package:sizer/sizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]); // Initialize Firebase
  print('Firebase Initialized'); // Debug: Log for Firebase initialization
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GeneralProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) async {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? language = sharedPreferences.getString("Language");
    print("Language from SharedPreferences: $language"); // Debug: Log language
    if (language == null || language.isEmpty) {
      state?.setLocale(newLocale);
      // Save the newLocale to SharedPreferences
      await sharedPreferences.setString("Language", newLocale.languageCode);
      print('New locale saved: ${newLocale.languageCode}'); // Debug
    } else {
      Locale newLocale = Locale(language, "SA");
      state?.setLocale(newLocale);
    }
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  late FirebaseAnalytics analytics;

  @override
  void initState() {
    super.initState();
    initializeFirebaseAnalytics();
    loadLocale();
  }

  // Initialize Firebase Analytics
  void initializeFirebaseAnalytics() async {
    analytics = FirebaseAnalytics.instance;
    print('Firebase Analytics Initialized');
  }

  // Load Locale from SharedPreferences
  void loadLocale() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? language = sharedPreferences.getString("Language");
    print("Loaded Locale: $language");

    if (language != null && language.isNotEmpty) {
      setLocale(Locale(language, "SA"));
    } else {
      setLocale(const Locale("en", "US"));
      await sharedPreferences.setString("Language", "en");
      print('Default locale set to English and saved.');
    }
  }

  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_locale == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    } else {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return Directionality(
            textDirection: _locale?.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Consumer<GeneralProvider>(
              builder: (context, provider, child) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: "Flutter Localization Demo",
                  theme: ThemeData(
                    brightness: provider.isDarkMode
                        ? Brightness.dark
                        : Brightness.light,
                    colorScheme: provider.isDarkMode
                        ? const ColorScheme.dark()
                        : const ColorScheme.light(),
                    useMaterial3: true,
                    textTheme: GoogleFonts.lailaTextTheme(
                      Theme.of(context).textTheme.apply(
                            bodyColor: provider.isDarkMode
                                ? Colors.white
                                : Colors.black,
                            displayColor: provider.isDarkMode
                                ? Colors.white
                                : Colors.black,
                          ),
                    ),
                  ),
                  locale: _locale,
                  supportedLocales: const [
                    Locale("en", "US"),
                    Locale("ar", "SA"),
                  ],
                  localizationsDelegates: const [
                    DemoLocalization.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  localeResolutionCallback: (locale, supportedLocales) {
                    for (var supportedLocale in supportedLocales) {
                      if (supportedLocale.languageCode ==
                              locale?.languageCode &&
                          supportedLocale.countryCode == locale?.countryCode) {
                        return supportedLocale;
                      }
                    }
                    return supportedLocales.first;
                  },
                  navigatorObservers: [
                    FirebaseAnalyticsObserver(analytics: analytics),
                  ],
                  home: const AuthHandler(),
                );
              },
            ),
          );
        },
      );
    }
  }
}

class AuthHandler extends StatelessWidget {
  const AuthHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return const MainScreen();
        } else {
          return const WelcomeScreen();
        }
      },
    );
  }
}
