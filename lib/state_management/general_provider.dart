// // lib/state_management/general_provider.dart
//
// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
//
// import '../backend/private_chat_service.dart';
// import '../backend/user_service.dart';
// import '../localization/language_constants.dart';
//
// enum ThemeModeType { system, light, dark }
//
// class GeneralProvider with ChangeNotifier, DiagnosticableTreeMixin {
//   // Existing properties
//   Color color = Color(0xFFE8C75B);
//   bool CheckLangValue = true;
//   bool CheckLoginValue = false;
//   Map UserMap = {};
//   int _newRequestCount = 0;
//   int _chatRequestCount = 0;
//   Map<String, bool> _chatAccessPerEstate = {};
//   int _approvalCount = 0;
//   int _lastSeenApprovalCount = 0;
//   ThemeModeType _themeMode = ThemeModeType.system;
//
//   // New properties for userId and userName
//   String _userId = '';
//   String _userName = '';
//
//   // Getters
//   int get newRequestCount => _newRequestCount;
//   int get chatRequestCount => _chatRequestCount;
//   int get approvalCount => _approvalCount;
//   ThemeModeType get themeMode => _themeMode;
//
//   // Getters for userId and userName
//   String get userId => _userId;
//   String get userName => _userName;
//
//   // New properties for chat request notifications
//   bool _hasNewChatRequest = false;
//   PrivateChatRequest? _latestChatRequest;
//
//   bool get hasNewChatRequest => _hasNewChatRequest;
//   PrivateChatRequest? get latestChatRequest => _latestChatRequest;
//
//   // Stream subscription for chat requests
//   StreamSubscription<List<PrivateChatRequest>>? _privateChatSubscription;
//
//   final PrivateChatService _privateChatService = PrivateChatService();
//
//   // New properties for active timer
//   bool _isButtonsActive = false;
//   String? _activeEstateId;
//   Timer? _buttonTimer;
//   final StreamController<String> _timerExpiredController =
//       StreamController<String>.broadcast();
//
//   // Public getters for timer
//   bool get isButtonsActive => _isButtonsActive;
//   String? get activeEstateId => _activeEstateId;
//
//   Stream<String> get timerExpiredStream => _timerExpiredController.stream;
//
//   GeneralProvider() {
//     loadThemePreference();
//     loadLastSeenApprovalCount();
//     fetchApprovalCount();
//     fetchNewRequestCount();
//     CheckLogin();
//     loadUserInfo(); // Initialize user info from SharedPreferences
//     fetchAndSetUserInfo(); // Fetch user info from Firebase
//     listenToPrivateChatRequests(); // Start listening to chat requests
//     loadActiveTimer(); // Load active timer from SharedPreferences
//   }
//
//   void loadLastSeenApprovalCount() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     _lastSeenApprovalCount =
//         prefs.getInt('lastSeenApprovalCount') ?? 0; // Default to 0
//     print('Last seen approval count loaded: $_lastSeenApprovalCount');
//   }
//
//   void CheckLogin() async {
//     SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
//     if (sharedPreferences.getString("TypeUser") == "1") {
//       CheckLoginValue = false;
//     } else {
//       CheckLoginValue = true;
//     }
//     print('Login status checked: $CheckLoginValue');
//     notifyListeners();
//   }
//
//   void updateLanguage(bool isEnglish) {
//     CheckLangValue = isEnglish;
//     notifyListeners();
//   }
//
//   // Method to load user information from SharedPreferences
//   Future<void> loadUserInfo() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     _userId = prefs.getString('userId') ?? '';
//     _userName = prefs.getString('userName') ?? 'Anonymous';
//     print('User info loaded: $_userId, $_userName');
//     notifyListeners();
//   }
//
//   // Method to fetch user info from Firebase and update state
//   Future<void> fetchAndSetUserInfo() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       print('No user is currently logged in.');
//       return; // No user is logged in
//     }
//
//     try {
//       final userRef = FirebaseDatabase.instance.ref('App/User/${user.uid}');
//       final snapshot = await userRef.get();
//       if (snapshot.exists) {
//         final data = snapshot.value as Map;
//         final userId = data['userId'] ?? '';
//         final firstName = data['FirstName'] ?? 'Anonymous';
//         final lastName = data['LastName'] ?? '';
//
//         // Update userName
//         final userName = '$firstName $lastName';
//
//         // Save in SharedPreferences
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//         await prefs.setString('userId', userId);
//         await prefs.setString('userName', userName);
//
//         // Update provider state
//         _userId = userId;
//         _userName = userName;
//
//         print('User info fetched and set: $_userId, $_userName');
//         notifyListeners();
//       } else {
//         print('User data does not exist in Firebase for UID: ${user.uid}');
//       }
//     } catch (e) {
//       print('Error fetching user info: $e');
//     }
//   }
//
//   // Method to update user information (call this upon user login)
//   Future<void> updateUserInfo(String userId, String userName) async {
//     _userId = userId;
//     _userName = userName;
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString('userId', _userId);
//     await prefs.setString('userName', _userName);
//     print('User info updated: $_userId, $_userName');
//     notifyListeners();
//   }
//
//   // Method to load theme preference
//   void loadThemePreference() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     _themeMode = ThemeModeType.values[prefs.getInt('themeMode') ?? 0];
//     print('Theme mode loaded: $_themeMode');
//     notifyListeners();
//   }
//
//   void toggleTheme(ThemeModeType themeModeType) async {
//     _themeMode = themeModeType;
//     notifyListeners();
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('themeMode', themeModeType.index);
//     print('Theme mode toggled to: $_themeMode');
//   }
//
//   ThemeData getTheme(BuildContext context) {
//     if (_themeMode == ThemeModeType.dark) {
//       return ThemeData.dark();
//     } else if (_themeMode == ThemeModeType.light) {
//       return ThemeData.light();
//     } else {
//       var brightness = MediaQuery.of(context).platformBrightness;
//       return brightness == Brightness.dark
//           ? ThemeData.dark()
//           : ThemeData.light();
//     }
//   }
//
//   void fetchApprovalCount() {
//     FirebaseDatabase.instance
//         .ref("App/Booking/Book")
//         .onValue
//         .listen((DatabaseEvent event) async {
//       int totalApprovals = 0;
//       if (event.snapshot.value != null) {
//         Map bookings = event.snapshot.value as Map;
//         bookings.forEach((key, value) {
//           if (value["Status"] == "2" || value["Status"] == "3") {
//             totalApprovals++;
//           }
//         });
//       }
//       _approvalCount = totalApprovals - _lastSeenApprovalCount;
//       if (_approvalCount < 0) _approvalCount = 0;
//       print('Approval count updated: $_approvalCount');
//       notifyListeners();
//     });
//   }
//
//   void resetApprovalCount() async {
//     _lastSeenApprovalCount += _approvalCount;
//     _approvalCount = 0;
//     saveLastSeenApprovalCount(_lastSeenApprovalCount);
//     print(
//         'Approval count reset. Last seen approval count: $_lastSeenApprovalCount');
//     notifyListeners();
//   }
//
//   void saveLastSeenApprovalCount(int count) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('lastSeenApprovalCount', count);
//     print('Last seen approval count saved: $count');
//   }
//
//   void fetchNewRequestCount() {
//     String? id = FirebaseAuth.instance.currentUser?.uid;
//     if (id != null) {
//       FirebaseDatabase.instance
//           .ref("App/Booking/Book")
//           .orderByChild("IDOwner")
//           .equalTo(id)
//           .onValue
//           .listen((DatabaseEvent event) {
//         int count = 0;
//         if (event.snapshot.value != null) {
//           Map requests = event.snapshot.value as Map;
//           requests.forEach((key, value) {
//             if (value["Status"] == "1") {
//               count++;
//             }
//           });
//         }
//         _newRequestCount = count;
//         print('New request count updated: $_newRequestCount');
//         notifyListeners();
//       });
//     }
//   }
//
//   bool hasChatAccessForEstate(String estateId) {
//     return _chatAccessPerEstate[estateId] ?? false;
//   }
//
//   void updateChatAccessForEstate(String estateId, bool access) {
//     _chatAccessPerEstate[estateId] = access;
//     notifyListeners();
//   }
//
//   void resetNewRequestCount() {
//     _newRequestCount = 0;
//     notifyListeners();
//   }
//
//   void FunSnackBarPage(String hint, BuildContext context) {
//     final snackBar = SnackBar(
//       content: Text(
//         hint,
//         style: TextStyle(
//           color: Colors.deepPurple, // Update with your color constant if needed
//         ),
//       ),
//       action: SnackBarAction(
//         label: 'Undo',
//         onPressed: () {
//           // Some code to undo the change.
//         },
//       ),
//     );
//
//     ScaffoldMessenger.of(context).showSnackBar(snackBar);
//   }
//
//   // -------------------- New Methods for Timer and Chat Request Notifications --------------------
//
//   // Method to activate the timer for Chat and Rate buttons
//   // Inside GeneralProvider
//
// // Method to activate the timer for Chat and Rate buttons
//   Future<void> activateTimer(String estateId, Duration duration) async {
//     // Cancel existing timer if any
//     _buttonTimer?.cancel();
//
//     // Set the active estate ID and buttons active
//     _activeEstateId = estateId;
//     _isButtonsActive = true;
//     notifyListeners();
//
//     // Save the active timer info to SharedPreferences
//     await saveActiveTimer(estateId, DateTime.now(), duration);
//
//     // Start a new timer
//     _buttonTimer = Timer(duration, () async {
//       _isButtonsActive = false;
//       _activeEstateId = null;
//       notifyListeners();
//
//       // Remove the active timer info from SharedPreferences
//       await removeActiveTimer();
//
//       // Emit the timer expired event with estateId
//       _timerExpiredController.add(estateId);
//     });
//   }
//
//   // Method to load active timer info from SharedPreferences
//   Future<void> loadActiveTimer() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? estateId = prefs.getString('activeEstateId');
//     String? scanTimeString = prefs.getString('lastScanTime');
//     int? durationSeconds = prefs.getInt('activeDurationSeconds');
//
//     if (estateId != null && scanTimeString != null && durationSeconds != null) {
//       DateTime scanTime = DateTime.parse(scanTimeString);
//       Duration elapsed = DateTime.now().difference(scanTime);
//       Duration totalDuration = Duration(seconds: durationSeconds);
//
//       if (elapsed < totalDuration) {
//         Duration remaining = totalDuration - elapsed;
//         _activeEstateId = estateId;
//         _isButtonsActive = true;
//         notifyListeners();
//
//         // Start the timer with remaining duration
//         _buttonTimer = Timer(remaining, () async {
//           _isButtonsActive = false;
//           _activeEstateId = null;
//           notifyListeners();
//
//           // Remove the active timer info from SharedPreferences
//           await removeActiveTimer();
//
//           // Emit the timer expired event with estateId
//           _timerExpiredController.add(estateId);
//         });
//       } else {
//         // Timer has already expired
//         await removeActiveTimer();
//       }
//     }
//   }
//
//   // Method to save active timer info to SharedPreferences
//   Future<void> saveActiveTimer(
//       String estateId, DateTime scanTime, Duration duration) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString('activeEstateId', estateId);
//     await prefs.setString('lastScanTime', scanTime.toIso8601String());
//     await prefs.setInt('activeDurationSeconds', duration.inSeconds);
//   }
//
//   // Method to remove active timer info from SharedPreferences
//   Future<void> removeActiveTimer() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.remove('activeEstateId');
//     await prefs.remove('lastScanTime');
//     await prefs.remove('activeDurationSeconds');
//   }
//
//   // -------------------- Existing Methods --------------------
//
//   // Existing methods like listenToPrivateChatRequests etc.
//
//   // Method to listen to incoming private chat requests
//   void listenToPrivateChatRequests() {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId != null) {
//       _privateChatSubscription =
//           _privateChatService.getIncomingRequests(userId).listen((requests) {
//         if (requests.isNotEmpty) {
//           // Assuming you want to notify for the latest request
//           _latestChatRequest = requests.last;
//           _hasNewChatRequest = true;
//           print(
//               'New chat request received from: ${_latestChatRequest!.senderName}');
//           notifyListeners();
//         }
//       }, onError: (error) {
//         print('Error listening to chat requests: $error');
//       });
//     } else {
//       print('No user ID available to listen for chat requests.');
//     }
//   }
//
//   // Method to reset the new chat request flag
//   void resetNewChatRequest() {
//     _hasNewChatRequest = false;
//     _latestChatRequest = null;
//     notifyListeners();
//     print('New chat request flag reset.');
//   }
//
//   @override
//   void dispose() {
//     _privateChatSubscription?.cancel();
//     _timerExpiredController.close();
//     _buttonTimer?.cancel();
//     super.dispose();
//   }
// }
//
// class CustomerType {
//   late String name, type, subtext;
//   late IconData icon; // Change image to IconData
//
//   CustomerType({
//     required this.icon, // Use icon instead of image
//     required this.name,
//     required this.type,
//     required this.subtext,
//   });
// }

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
import '../localization/language_constants.dart';

enum ThemeModeType { system, light, dark }

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

  GeneralProvider() {
    loadThemePreference();
    loadLastSeenApprovalCount();
    fetchApprovalCount();
    fetchNewRequestCount();
    CheckLogin();
    loadUserInfo(); // Initialize user info from SharedPreferences
    fetchAndSetUserInfo(); // Fetch user info from Firebase
    fetchSubscriptionStatus(); // Fetch subscription status
    listenToPrivateChatRequests(); // Start listening to chat requests
    loadActiveTimer(); // Load active timer from SharedPreferences
  }

  // Existing methods...
  ThemeData getTheme(BuildContext context) {
    if (_themeMode == ThemeModeType.dark) {
      return ThemeData.dark();
    } else if (_themeMode == ThemeModeType.light) {
      return ThemeData.light();
    } else {
      var brightness = MediaQuery.of(context).platformBrightness;
      return brightness == Brightness.dark
          ? ThemeData.dark()
          : ThemeData.light();
    }
  }

  Future<void> saveActiveTimer(
      String estateId, DateTime scanTime, Duration duration) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeEstateId', estateId);
    await prefs.setString('lastScanTime', scanTime.toIso8601String());
    await prefs.setInt('activeDurationSeconds', duration.inSeconds);
  }

  void toggleTheme(ThemeModeType themeModeType) async {
    _themeMode = themeModeType;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', themeModeType.index);
    print('Theme mode toggled to: $_themeMode');
  }

  void saveLastSeenApprovalCount(int count) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSeenApprovalCount', count);
    print('Last seen approval count saved: $count');
  }

  void updateLanguage(bool isEnglish) {
    CheckLangValue = isEnglish;
    notifyListeners();
  }

  void resetNewChatRequest() {
    _hasNewChatRequest = false;
    _latestChatRequest = null;
    notifyListeners();
    print('New chat request flag reset.');
  }

  void resetApprovalCount() async {
    _lastSeenApprovalCount += _approvalCount;
    _approvalCount = 0;
    saveLastSeenApprovalCount(_lastSeenApprovalCount);
    print(
        'Approval count reset. Last seen approval count: $_lastSeenApprovalCount');
    notifyListeners();
  }

  void loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeModeType.values[prefs.getInt('themeMode') ?? 0];
    print('Theme mode loaded: $_themeMode');
    notifyListeners();
  }

  void loadLastSeenApprovalCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lastSeenApprovalCount =
        prefs.getInt('lastSeenApprovalCount') ?? 0; // Default to 0
    print('Last seen approval count loaded: $_lastSeenApprovalCount');
  }

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

  Future<void> activateTimer(String estateId, Duration duration) async {
    // Cancel existing timer if any
    _buttonTimer?.cancel();

    // Set the active estate ID and buttons active
    _activeEstateId = estateId;
    _isButtonsActive = true;
    notifyListeners();

    // Save the active timer info to SharedPreferences
    await saveActiveTimer(estateId, DateTime.now(), duration);

    // Start a new timer
    _buttonTimer = Timer(duration, () async {
      _isButtonsActive = false;
      _activeEstateId = null;
      notifyListeners();

      // Remove the active timer info from SharedPreferences
      await removeActiveTimer();

      // Emit the timer expired event with estateId
      _timerExpiredController.add(estateId);
    });
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

  Future<void> removeActiveTimer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeEstateId');
    await prefs.remove('lastScanTime');
    await prefs.remove('activeDurationSeconds');
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

  Future<void> loadActiveTimer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? estateId = prefs.getString('activeEstateId');
    String? scanTimeString = prefs.getString('lastScanTime');
    int? durationSeconds = prefs.getInt('activeDurationSeconds');

    if (estateId != null && scanTimeString != null && durationSeconds != null) {
      DateTime scanTime = DateTime.parse(scanTimeString);
      Duration elapsed = DateTime.now().difference(scanTime);
      Duration totalDuration = Duration(seconds: durationSeconds);

      if (elapsed < totalDuration) {
        Duration remaining = totalDuration - elapsed;
        _activeEstateId = estateId;
        _isButtonsActive = true;
        notifyListeners();

        // Start the timer with remaining duration
        _buttonTimer = Timer(remaining, () async {
          _isButtonsActive = false;
          _activeEstateId = null;
          notifyListeners();

          // Remove the active timer info from SharedPreferences
          await removeActiveTimer();

          // Emit the timer expired event with estateId
          _timerExpiredController.add(estateId);
        });
      } else {
        // Timer has already expired
        await removeActiveTimer();
      }
    }
  }

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

  // -------------------- Existing Methods --------------------

  // Method to load user information from SharedPreferences
  Future<void> loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? '';
    _userName = prefs.getString('userName') ?? 'Anonymous';
    print('User info loaded: $_userId, $_userName');
    notifyListeners();
  }

  // Method to fetch user info from Firebase and update state
  Future<void> fetchAndSetUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user is currently logged in.');
      return; // No user is logged in
    }

    try {
      final userRef = FirebaseDatabase.instance.ref('App/User/${user.uid}');
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        final userId = data['userId'] ?? '';
        final firstName = data['FirstName'] ?? 'Anonymous';
        final lastName = data['LastName'] ?? '';

        // Update userName
        final userName = '$firstName $lastName';

        // Save in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
        await prefs.setString('userName', userName);

        // Update provider state
        _userId = userId;
        _userName = userName;

        print('User info fetched and set: $_userId, $_userName');
        notifyListeners();
      } else {
        print('User data does not exist in Firebase for UID: ${user.uid}');
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  // ... Rest of the existing code remains unchanged ...

  @override
  void dispose() {
    _privateChatSubscription?.cancel();
    _timerExpiredController.close();
    _buttonTimer?.cancel();
    _subscriptionExpiredController.close();
    _subscriptionTimer?.cancel();
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
