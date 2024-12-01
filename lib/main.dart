import 'package:diamond_host_admin/screens/private_chat_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'state_management/general_provider.dart';
import 'localization/language_constants.dart';
import 'localization/demo_localization.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/welcome_screen.dart';
import 'widgets/reused_appbar.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  print('Firebase Initialized');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GeneralProvider()),
        // Add other providers here if necessary
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
    print("Language from SharedPreferences: $language");
    if (language == null || language.isEmpty) {
      state?.setLocale(newLocale);
      await sharedPreferences.setString("Language", newLocale.languageCode);
      print('New locale saved: ${newLocale.languageCode}');
    } else {
      Locale updatedLocale = Locale(language, "SA");
      state?.setLocale(updatedLocale);
    }
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Locale? _locale;
  late FirebaseAnalytics analytics;
  bool _dialogIsShowing = false; // Flag to prevent multiple dialogs

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeFirebaseAnalytics();
    loadLocale();
    // No need to listen to chat requests here as it's handled by the provider
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void initializeFirebaseAnalytics() async {
    analytics = FirebaseAnalytics.instance;
    print('Firebase Analytics Initialized');
  }

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

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_locale == null) {
      // While loading locale, show a loading indicator
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
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
                  title: "Diamond Host Admin",
                  navigatorKey: navigatorKey, // Attach the navigator key here
                  theme: provider.getTheme(context),
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
                  home: const SplashScreen(),
                  builder: (context, child) {
                    // Listen to provider and show dialog if there's a new chat request
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (provider.hasNewChatRequest && !_dialogIsShowing) {
                        _dialogIsShowing = true; // Prevent multiple dialogs
                        print('New chat request detected. Showing dialog.');

                        final latestRequest = provider.latestChatRequest;
                        if (latestRequest != null) {
                          showDialog(
                            context: navigatorKey.currentContext!,
                            builder: (context) => AlertDialog(
                              title: Text(
                                getTranslated(
                                    context, "New Private Chat Request"),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              content: Text(
                                "${latestRequest.senderName} ${getTranslated(context, "wants to start a private chat with you.")}",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    provider.resetNewChatRequest();
                                    Navigator.of(context).pop();
                                    setState(() {
                                      _dialogIsShowing = false;
                                    });
                                    print('Chat request dialog dismissed.');
                                  },
                                  child:
                                      Text(getTranslated(context, "Dismiss")),
                                ),
                                TextButton(
                                  onPressed: () {
                                    provider.resetNewChatRequest();
                                    Navigator.of(context).pop();
                                    setState(() {
                                      _dialogIsShowing = false;
                                    });
                                    print(
                                        'Navigating to PrivateChatRequestsScreen.');
                                    // Navigate to the PrivateChatRequestsScreen
                                    navigatorKey.currentState!.push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PrivateChatRequestsScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(getTranslated(context, "View")),
                                ),
                              ],
                            ),
                          ).then((_) {
                            setState(() {
                              _dialogIsShowing =
                                  false; // Reset the flag when dialog is closed
                            });
                            print('Chat request dialog closed.');
                          });
                        }
                      }
                    });
                    return child!;
                  },
                );
              },
            ),
          );
        },
      );
    }
  }
}
