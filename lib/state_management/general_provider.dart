// lib/state_management/general_provider.dart

import 'package:diamond_host_admin/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  GeneralProvider() {
    loadThemePreference();
    loadLastSeenApprovalCount();
    fetchApprovalCount();
    fetchNewRequestCount();
    CheckLogin();
    loadUserInfo(); // Initialize user info
  }

  // Existing methods...

  // Method to load user information from SharedPreferences
  Future<void> loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? '';
    _userName = prefs.getString('userName') ?? 'Anonymous';
    notifyListeners();
  }

  // Method to update user information (call this upon user login)
  Future<void> updateUserInfo(String userId, String userName) async {
    _userId = userId;
    _userName = userName;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _userId);
    await prefs.setString('userName', _userName);
    notifyListeners();
  }

  // ... Rest of your GeneralProvider methods

  void loadLastSeenApprovalCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lastSeenApprovalCount =
        prefs.getInt('lastSeenApprovalCount') ?? 0; // Default to 0
  }

  void FunSnackBarPage(String hint, BuildContext context) {
    final snackBar = SnackBar(
      content: Text(
        hint,
        style: TextStyle(
          color: kDeepPurpleColor,
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

  void toggleTheme(ThemeModeType themeModeType) async {
    _themeMode = themeModeType;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', themeModeType.index);
  }

  void loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeModeType.values[prefs.getInt('themeMode') ?? 0];
    notifyListeners();
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
      notifyListeners();
    });
  }

  void resetApprovalCount() async {
    _lastSeenApprovalCount += _approvalCount;
    _approvalCount = 0;
    saveLastSeenApprovalCount(_lastSeenApprovalCount);
    notifyListeners();
  }

  void saveLastSeenApprovalCount(int count) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSeenApprovalCount', count);
  }

  void fetchNewRequestCount() {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      FirebaseDatabase.instance
          .ref("App/Booking/Book")
          .orderByChild("IDOwner")
          .equalTo(id)
          .onValue // Use onValue for real-time updates
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
        notifyListeners(); // Update listeners directly when there's a new request
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

  Future getUer() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    DatabaseReference starCountRef = FirebaseDatabase.instance
        .ref("App")
        .child("User")
        .child(sharedPreferences.getString("ID")!);
    starCountRef.onValue.listen((DatabaseEvent event) {
      UserMap = event.snapshot.value as Map;
    });
    notifyListeners();
  }

  List<CustomerType> TypeService(BuildContext context) {
    List<CustomerType> LstCustomerType = [];

    LstCustomerType.add(CustomerType(
      icon: Icons.restaurant,
      name: getTranslated(context, "Restaurant"), // Key for translation
      type: "3",
      subtext: getTranslated(
          context, "Add your restaurant from here"), // Key for translation
    ));

    LstCustomerType.add(CustomerType(
      icon: Icons.local_cafe,
      name: getTranslated(context, "Coffee"), // Key for translation
      type: "2",
      subtext: getTranslated(
          context, "Add your Coffee from here"), // Key for translation
    ));

    LstCustomerType.add(CustomerType(
      icon: Icons.hotel,
      name: getTranslated(context, "Hotel"), // Key for translation
      type: "1",
      subtext: getTranslated(
          context, "Add your Hotel from here"), // Key for translation
    ));

    return LstCustomerType;
  }

  Future<bool> CheckLang() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? lang = sharedPreferences.getString("Language");
    if (lang == null || lang.isEmpty) {
      CheckLangValue = true;
      return true;
    } else if (lang == "en") {
      CheckLangValue = true;
      return true;
    } else if (lang == "ar") {
      CheckLangValue = false;
      return false;
    }
    return true;
  }

  void updateLanguage(bool isEnglish) {
    CheckLangValue = isEnglish;
    notifyListeners();
  }

  void CheckLogin() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString("TypeUser") == "1") {
      CheckLoginValue = false;
    } else {
      CheckLoginValue = true;
    }
  }

  void resetNewRequestCount() {
    _newRequestCount = 0;
    notifyListeners();
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
