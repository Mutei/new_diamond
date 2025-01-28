// lib/state_management/general_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../backend/private_chat_service.dart';
import '../backend/user_service.dart';
import '../constants/colors.dart';
import '../localization/language_constants.dart';

enum ThemeModeType { system, light, dark }

// Class to represent post status change events
class PostStatusChangeEvent {
  final String postId;
  final String status; // '1' for approved, '2' for rejected

  PostStatusChangeEvent({required this.postId, required this.status});
}

class GeneralProvider with ChangeNotifier, DiagnosticableTreeMixin {
  // Existing properties
  Color color = Color(0xFFE8C75B);
  bool CheckLangValue = true;
  bool CheckLoginValue = false;
  Map UserMap = {};
  int _newRequestCount = 0;
  int _chatRequestCount = 0;
  Map<String, bool> _chatAccessPerEstate = {};
  int _approvalCount = 0;
  int _lastSeenApprovalCount = 0;
  ThemeModeType _themeMode = ThemeModeType.system;

  // New properties for userId and userName
  String _userId = '';
  String _userName = '';

  // Subscription related properties
  String _subscriptionType = '1'; // Default to Star
  DateTime? _subscriptionExpiryTime;
  Timer? _subscriptionTimer;
  final StreamController<void> _subscriptionExpiredController =
      StreamController<void>.broadcast();

  // StreamController for post status changes
  final StreamController<PostStatusChangeEvent> _postStatusChangeController =
      StreamController<PostStatusChangeEvent>.broadcast();

  // Getter for the post status change stream
  Stream<PostStatusChangeEvent> get postStatusChangeStream =>
      _postStatusChangeController.stream;

  // Map to track the current status of user's posts
  Map<String, String> _userPostStatuses = {};

  // Getters
  int get newRequestCount => _newRequestCount;
  int get chatRequestCount => _chatRequestCount;
  int get approvalCount => _approvalCount;
  ThemeModeType get themeMode => _themeMode;

  // Getters for userId and userName
  String get userId => _userId;
  String get userName => _userName;

  // Subscription Getter
  String get subscriptionType => _subscriptionType;

  // Stream for subscription expiration
  Stream<void> get subscriptionExpiredStream =>
      _subscriptionExpiredController.stream;

  // New properties for chat request notifications
  bool _hasNewChatRequest = false;
  PrivateChatRequest? _latestChatRequest;

  bool get hasNewChatRequest => _hasNewChatRequest;
  PrivateChatRequest? get latestChatRequest => _latestChatRequest;

  // Stream subscription for chat requests
  StreamSubscription<List<PrivateChatRequest>>? _privateChatSubscription;

  final PrivateChatService _privateChatService = PrivateChatService();

  // New properties for active timer
  bool _isButtonsActive = false;
  String? _activeEstateId;
  Timer? _buttonTimer;
  final StreamController<String> _timerExpiredController =
      StreamController<String>.broadcast();

  // Public getters for timer
  bool get isButtonsActive => _isButtonsActive;
  String? get activeEstateId => _activeEstateId;

  Stream<String> get timerExpiredStream => _timerExpiredController.stream;

  // New property to track active timer expiry time
  DateTime? _activeTimerExpiryTime;
  DateTime? get activeTimerExpiryTime => _activeTimerExpiryTime;

  GeneralProvider() {
    loadThemePreference();
    loadLastSeenApprovalCount();
    fetchApprovalCount();
    fetchNewRequestCount();
    CheckLogin();
    listenToAuthChanges(); // Listen to auth changes
    fetchSubscriptionStatus(); // Fetch subscription status
    listenToPrivateChatRequests(); // Start listening to chat requests
    loadLanguagePreference(); // Load language preference
  }

  void CheckLogin() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString("TypeUser") == "1") {
      CheckLoginValue = false;
    } else {
      CheckLoginValue = true;
    }
    print('Login status checked: $CheckLoginValue');
    notifyListeners();
  }

  void fetchNewRequestCount() {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      FirebaseDatabase.instance
          .ref("App/Booking/Book")
          .orderByChild("IDOwner")
          .equalTo(id)
          .onValue
          .listen((DatabaseEvent event) {
        int count = 0;
        if (event.snapshot.value != null) {
          Map requests = event.snapshot.value as Map;
          requests.forEach((key, value) {
            if (value["Status"] == "1") {
              count++;
            }
          });
        }
        _newRequestCount = count;
        print('New request count updated: $_newRequestCount');
        notifyListeners();
      });
    }
  }

  // Listen to authentication changes
  void listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        // User is signed in
        _userId = user.uid;
        print('User signed in: $_userId');
        await loadActiveTimer(); // Load timer for the new user
        // Fetch user info if needed
        await fetchUserInfoFromFirebase(user);
      } else {
        // User is signed out
        print('User signed out.');
        await removeActiveTimer(); // Remove timer on logout
        _isButtonsActive = false;
        _activeEstateId = null;
        _activeTimerExpiryTime = null;
        _userId = '';
        _userName = '';
        notifyListeners();
      }
    });
  }

  // New method to load language preference
  Future<void> loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? language = prefs.getString("Language");
    if (language != null) {
      if (language == "en") {
        CheckLangValue = true;
      } else if (language == "ar") {
        CheckLangValue = false;
      } else {
        CheckLangValue = true; // Default to English if unknown
      }
      print('Language preference loaded: $language');
    } else {
      CheckLangValue = true; // Default to English if not set
      print('No language preference found. Defaulting to English.');
    }
    notifyListeners();
  }

  // Function to remove user from activeUsers
  Future<void> removeActiveUserFromDatabase(String estateId) async {
    if (_userId.isEmpty) {
      print('Cannot remove active user: userId is empty.');
      return;
    }

    try {
      DatabaseReference activeUserRef = FirebaseDatabase.instance
          .ref('App/EstateChats/$estateId/activeUsers/$_userId');
      await activeUserRef.remove();
      print('User $_userId removed from activeUsers for EstateId=$estateId');
    } catch (e) {
      print('Error removing active user from database: $e');
    }
  }

  // Existing methods...
  ThemeData getTheme(BuildContext context) {
    switch (_themeMode) {
      case ThemeModeType.dark:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: kDarkModeColor,
          primaryColor: kDarkModeColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: kDarkModeColor,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor:
                kPurpleColor, // Using the custom purple color as the seed
            brightness: Brightness.dark,
          ),
          textTheme: ThemeData.dark().textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
        );
      case ThemeModeType.light:
        return ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor:
                kPurpleColor, // Using the custom purple color as the seed
            brightness: Brightness.light,
          ),
        );
      case ThemeModeType.system:
      default:
        var brightness = MediaQuery.of(context).platformBrightness;
        if (brightness == Brightness.dark) {
          return ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: kDarkModeColor,
            primaryColor: kDarkModeColor,
            appBarTheme: const AppBarTheme(
              backgroundColor: kDarkModeColor,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor:
                  kPurpleColor, // Using the custom purple color as the seed
              brightness: Brightness.dark,
            ),
            textTheme: ThemeData.dark().textTheme.apply(
                  bodyColor: Colors.white,
                  displayColor: Colors.white,
                ),
          );
        } else {
          return ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor:
                  kPurpleColor, // Using the custom purple color as the seed
              brightness: Brightness.light,
            ),
          );
        }
    }
  }

  // Function to save active timer with userId
  Future<void> saveActiveTimer(
      String estateId, DateTime scanTime, Duration duration) async {
    if (_userId.isEmpty) {
      print('Cannot save timer: userId is empty.');
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeEstateId_$_userId', estateId);
    await prefs.setString('lastScanTime_$_userId', scanTime.toIso8601String());
    await prefs.setInt('activeDurationSeconds_$_userId', duration.inSeconds);
    print('Active timer saved for user $_userId: EstateId=$estateId');
  }

  // Function to remove active timer with userId
  Future<void> removeActiveTimer() async {
    if (_userId.isEmpty) {
      print('Cannot remove timer: userId is empty.');
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeEstateId_$_userId');
    await prefs.remove('lastScanTime_$_userId');
    await prefs.remove('activeDurationSeconds_$_userId');
    print('Active timer removed for user $_userId');
  }

  // Function to load active timer with userId
  Future<void> loadActiveTimer() async {
    if (_userId.isEmpty) {
      // No userId available, do not load any timer
      print('No userId available. Skipping loadActiveTimer.');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? estateId = prefs.getString('activeEstateId_$_userId');
    String? scanTimeString = prefs.getString('lastScanTime_$_userId');
    int? durationSeconds = prefs.getInt('activeDurationSeconds_$_userId');

    if (estateId != null && scanTimeString != null && durationSeconds != null) {
      DateTime scanTime = DateTime.parse(scanTimeString);
      Duration elapsed = DateTime.now().difference(scanTime);
      Duration totalDuration = Duration(seconds: durationSeconds);

      if (elapsed < totalDuration) {
        Duration remaining = totalDuration - elapsed;
        _activeEstateId = estateId;
        _isButtonsActive = true;
        _activeTimerExpiryTime = scanTime.add(totalDuration);
        notifyListeners();
        print(
            'Active timer loaded for user $_userId: EstateId=$estateId, Remaining=${remaining.inSeconds} seconds');

        // Start the timer with remaining duration
        _buttonTimer = Timer(remaining, () async {
          _isButtonsActive = false;
          _activeEstateId = null;
          _activeTimerExpiryTime = null;
          notifyListeners();

          // Remove the active timer info from SharedPreferences with userId
          await removeActiveTimer();

          // Emit the timer expired event with estateId
          _timerExpiredController.add(estateId);
          print('Active timer expired for user $_userId: EstateId=$estateId');
        });
      } else {
        // Timer has already expired
        await removeActiveTimer();
        print('Active timer already expired for user $_userId');
      }
    }
  }

  // Function to toggle theme
  void toggleTheme(ThemeModeType themeModeType) async {
    _themeMode = themeModeType;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', themeModeType.index);
    print('Theme mode toggled to: $_themeMode');
  }

  // Function to save last seen approval count
  void saveLastSeenApprovalCount(int count) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSeenApprovalCount', count);
    print('Last seen approval count saved: $count');
  }

  // Function to update language
  void updateLanguage(bool isEnglish) {
    CheckLangValue = isEnglish;
    notifyListeners();
  }

  // Function to reset new chat request
  void resetNewChatRequest() {
    _hasNewChatRequest = false;
    _latestChatRequest = null;
    notifyListeners();
    print('New chat request flag reset.');
  }

  // Function to reset approval count
  void resetApprovalCount() async {
    _lastSeenApprovalCount += _approvalCount;
    _approvalCount = 0;
    saveLastSeenApprovalCount(_lastSeenApprovalCount);
    print(
        'Approval count reset. Last seen approval count: $_lastSeenApprovalCount');
    notifyListeners();
  }

  // Function to load theme preference
  void loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeModeType.values[prefs.getInt('themeMode') ?? 0];
    print('Theme mode loaded: $_themeMode');
    notifyListeners();
  }

  // Function to load last seen approval count
  void loadLastSeenApprovalCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lastSeenApprovalCount =
        prefs.getInt('lastSeenApprovalCount') ?? 0; // Default to 0
    print('Last seen approval count loaded: $_lastSeenApprovalCount');
  }

  // Function to fetch approval count
  void fetchApprovalCount() {
    FirebaseDatabase.instance
        .ref("App/Booking/Book")
        .onValue
        .listen((DatabaseEvent event) async {
      int totalApprovals = 0;
      if (event.snapshot.value != null) {
        Map bookings = event.snapshot.value as Map;
        bookings.forEach((key, value) {
          if (value["Status"] == "2" || value["Status"] == "3") {
            totalApprovals++;
          }
        });
      }
      _approvalCount = totalApprovals - _lastSeenApprovalCount;
      if (_approvalCount < 0) _approvalCount = 0;
      print('Approval count updated: $_approvalCount');
      notifyListeners();
    });
  }

  // Function to activate timer
  Future<void> activateTimer(String estateId, Duration duration) async {
    if (_userId.isEmpty) {
      print('Cannot activate timer: userId is empty.');
      return;
    }

    // Cancel existing timer if any
    _buttonTimer?.cancel();

    // Set the active estate ID and buttons active
    _activeEstateId = estateId;
    _isButtonsActive = true;
    notifyListeners();

    // Save the active timer info to SharedPreferences with userId
    await saveActiveTimer(estateId, DateTime.now(), duration);

    // Set the expiry time
    _activeTimerExpiryTime = DateTime.now().add(duration);

    // Start a new timer
    _buttonTimer = Timer(duration, () async {
      _isButtonsActive = false;
      _activeEstateId = null;
      _activeTimerExpiryTime = null;
      notifyListeners();

      // Remove the active timer info from SharedPreferences with userId
      await removeActiveTimer();

      // Emit the timer expired event with estateId
      _timerExpiredController.add(estateId);

      // Remove user from activeUsers in the database
      await removeActiveUserFromDatabase(estateId);

      print('Active timer expired for user $_userId: EstateId=$estateId');
    });
    print(
        'Active timer activated for user $_userId: EstateId=$estateId, Duration=${duration.inSeconds} seconds');
  }

  // Function to fetch user info from Firebase
  Future<void> fetchUserInfoFromFirebase(User user) async {
    try {
      final userRef = FirebaseDatabase.instance.ref('App/User/${user.uid}');
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final firstName = data['FirstName'] ?? 'Anonymous';
        final lastName = data['LastName'] ?? '';
        final userName = '$firstName $lastName';

        _userName = userName;
        print('User info fetched: $_userName');
        notifyListeners();
      } else {
        print('User data does not exist in Firebase for UID: ${user.uid}');
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  // Function to listen to private chat requests
  void listenToPrivateChatRequests() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _privateChatSubscription =
          _privateChatService.getIncomingRequests(userId).listen((requests) {
        if (requests.isNotEmpty) {
          // Assuming you want to notify for the latest request
          _latestChatRequest = requests.last;
          _hasNewChatRequest = true;
          print(
              'New chat request received from: ${_latestChatRequest!.senderName}');
          notifyListeners();
        }
      }, onError: (error) {
        print('Error listening to chat requests: $error');
      });
    } else {
      print('No user ID available to listen for chat requests.');
    }
  }

  // -------------------- Subscription Methods --------------------

  Future<void> fetchSubscriptionStatus() async {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      DatabaseReference ref =
          FirebaseDatabase.instance.ref().child('App').child('User').child(id);
      DatabaseEvent event = await ref.once();
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        _subscriptionType = data['TypeAccount'] ?? '1';
        String? expiryTimeString = data['SubscriptionExpiryTime'];
        if (expiryTimeString != null) {
          _subscriptionExpiryTime = DateTime.parse(expiryTimeString);
          if (_subscriptionType != '1' &&
              _subscriptionExpiryTime!.isAfter(DateTime.now())) {
            Duration remaining =
                _subscriptionExpiryTime!.difference(DateTime.now());
            startSubscriptionTimer(remaining);
          } else if (_subscriptionType != '1' &&
              _subscriptionExpiryTime!.isBefore(DateTime.now())) {
            // Subscription expired, revert to '1'
            await ref
                .update({'TypeAccount': '1', 'SubscriptionExpiryTime': null});
            _subscriptionType = '1';
            notifyListeners();
            // Notify subscription expired
            _subscriptionExpiredController.add(null);
          }
        }
      }
    }
  }

  Future<void> startSubscription(String newType, Duration duration) async {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      DateTime expiryTime = DateTime.now().add(duration);
      String formattedExpiryDate =
          DateFormat('yyyy-MM-dd').format(expiryTime); // Format the date
      DatabaseReference ref =
          FirebaseDatabase.instance.ref().child('App').child('User').child(id);
      try {
        await ref.update({
          'TypeAccount': newType,
          'SubscriptionExpiryTime': formattedExpiryDate // Save as a normal date
        });
        _subscriptionType = newType;
        _subscriptionExpiryTime = expiryTime;
        startSubscriptionTimer(duration);
        notifyListeners();
      } catch (e) {
        // Handle error
        print('Error starting subscription: $e');
      }
    }
  }

  void startSubscriptionTimer(Duration duration) {
    _subscriptionTimer?.cancel();
    _subscriptionTimer = Timer(duration, onSubscriptionExpired);
  }

  Future<void> onSubscriptionExpired() async {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      DatabaseReference ref =
          FirebaseDatabase.instance.ref().child('App').child('User').child(id);
      try {
        await ref.update({'TypeAccount': '1', 'SubscriptionExpiryTime': null});
        _subscriptionType = '1';
        notifyListeners();
        // Notify subscribers
        _subscriptionExpiredController.add(null);
      } catch (e) {
        print('Error reverting subscription: $e');
      }
    }
  }

  @override
  void dispose() {
    _privateChatSubscription?.cancel();
    _timerExpiredController.close();
    _buttonTimer?.cancel();
    _subscriptionExpiredController.close();
    _subscriptionTimer?.cancel();
    _postStatusChangeController.close();
    // Remove user from activeUsers when the app is closed
    if (_activeEstateId != null) {
      removeActiveUserFromDatabase(_activeEstateId!);
    } // Close the post status controller
    super.dispose();
  }
}

class CustomerType {
  late String name, type, subtext;
  late IconData icon; // Change image to IconData

  CustomerType({
    required this.icon, // Use icon instead of image
    required this.name,
    required this.type,
    required this.subtext,
  });
}
