import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  // Getters
  int get newRequestCount => _newRequestCount;
  int get chatRequestCount => _chatRequestCount;
  int get approvalCount => _approvalCount;
  ThemeModeType get themeMode => _themeMode;

  // Getters for userId and userName
  String get userId => _userId;
  String get userName => _userName;

  // New properties for chat request notifications
  bool _hasNewChatRequest = false;
  PrivateChatRequest? _latestChatRequest;

  bool get hasNewChatRequest => _hasNewChatRequest;
  PrivateChatRequest? get latestChatRequest => _latestChatRequest;

  // Stream subscription for chat requests
  StreamSubscription<List<PrivateChatRequest>>? _privateChatSubscription;

  final PrivateChatService _privateChatService = PrivateChatService();

  GeneralProvider() {
    loadThemePreference();
    loadLastSeenApprovalCount();
    fetchApprovalCount();
    fetchNewRequestCount();
    CheckLogin();
    loadUserInfo(); // Initialize user info from SharedPreferences
    fetchAndSetUserInfo(); // Fetch user info from Firebase
    listenToPrivateChatRequests(); // Start listening to chat requests
  }

  void loadLastSeenApprovalCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lastSeenApprovalCount =
        prefs.getInt('lastSeenApprovalCount') ?? 0; // Default to 0
    print('Last seen approval count loaded: $_lastSeenApprovalCount');
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

  void updateLanguage(bool isEnglish) {
    CheckLangValue = isEnglish;
    notifyListeners();
  }

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

  // Method to update user information (call this upon user login)
  Future<void> updateUserInfo(String userId, String userName) async {
    _userId = userId;
    _userName = userName;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _userId);
    await prefs.setString('userName', _userName);
    print('User info updated: $_userId, $_userName');
    notifyListeners();
  }

  // Method to load theme preference
  void loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeModeType.values[prefs.getInt('themeMode') ?? 0];
    print('Theme mode loaded: $_themeMode');
    notifyListeners();
  }

  void toggleTheme(ThemeModeType themeModeType) async {
    _themeMode = themeModeType;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', themeModeType.index);
    print('Theme mode toggled to: $_themeMode');
  }

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

  void resetApprovalCount() async {
    _lastSeenApprovalCount += _approvalCount;
    _approvalCount = 0;
    saveLastSeenApprovalCount(_lastSeenApprovalCount);
    print(
        'Approval count reset. Last seen approval count: $_lastSeenApprovalCount');
    notifyListeners();
  }

  void saveLastSeenApprovalCount(int count) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSeenApprovalCount', count);
    print('Last seen approval count saved: $count');
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

  bool hasChatAccessForEstate(String estateId) {
    return _chatAccessPerEstate[estateId] ?? false;
  }

  void updateChatAccessForEstate(String estateId, bool access) {
    _chatAccessPerEstate[estateId] = access;
    notifyListeners();
  }

  void resetNewRequestCount() {
    _newRequestCount = 0;
    notifyListeners();
  }

  void FunSnackBarPage(String hint, BuildContext context) {
    final snackBar = SnackBar(
      content: Text(
        hint,
        style: TextStyle(
          color: Colors.deepPurple, // Update with your color constant if needed
        ),
      ),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // -------------------- New Methods for Chat Request Notifications --------------------

  // Method to listen to incoming private chat requests
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

  // Method to reset the new chat request flag
  void resetNewChatRequest() {
    _hasNewChatRequest = false;
    _latestChatRequest = null;
    notifyListeners();
    print('New chat request flag reset.');
  }

  @override
  void dispose() {
    _privateChatSubscription?.cancel();
    super.dispose();
  }

// -----------------------------------------------------------------------------------
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
