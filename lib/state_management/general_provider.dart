import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeneralProvider with ChangeNotifier, DiagnosticableTreeMixin {
  Color color = Color(0xFFE8C75B);
  bool CheckLangValue = true;
  bool CheckLoginValue = false;
  Map UserMap = {};
  int _newRequestCount = 0;
  int _chatRequestCount = 0;
  Map<String, bool> _chatAccessPerEstate =
      {}; // Map to track chat access per estate
  int _approvalCount = 0; // Tracks new approval/rejection changes for the badge
  int _lastSeenApprovalCount = 0; // Tracks the last known booking status count

  int get newRequestCount => _newRequestCount;
  int get chatRequestCount => _chatRequestCount;
  int get approvalCount => _approvalCount; // Getter for current approval count

  bool isDarkMode = false; // Track theme mode

  GeneralProvider() {
    loadThemePreference(); // Load theme preference on initialization
    loadLastSeenApprovalCount(); // Load last seen status count on initialization
    fetchApprovalCount(); // Start fetching approval/rejection changes in real-time
  }

  // Toggle theme and save the preference
  void toggleTheme() async {
    isDarkMode = !isDarkMode;
    notifyListeners();

    // Save the current theme preference to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  // Load theme preference from SharedPreferences
  void loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('isDarkMode') ?? false; // Default to light mode
    notifyListeners();
  }

  // Load the last seen approval count from SharedPreferences
  void loadLastSeenApprovalCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lastSeenApprovalCount =
        prefs.getInt('lastSeenApprovalCount') ?? 0; // Default to 0
  }

  // Save the current approval count in SharedPreferences
  void saveLastSeenApprovalCount(int count) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSeenApprovalCount', count);
  }

  // Fetch approval count from Firebase in real-time and track new approvals/rejections
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
            totalApprovals++; // Count both accepted and rejected bookings
          }
        });
      }

      // Compare the total approval count with the last seen count
      _approvalCount = totalApprovals - _lastSeenApprovalCount;
      if (_approvalCount < 0)
        _approvalCount = 0; // Ensure it never goes negative

      notifyListeners();
    });
  }

  // Reset the approval count to 0 when the page is opened and save the last seen count
  void resetApprovalCount() async {
    _lastSeenApprovalCount += _approvalCount; // Mark current approvals as seen
    _approvalCount = 0; // Reset the badge count

    // Save the updated last seen approval count to SharedPreferences
    saveLastSeenApprovalCount(_lastSeenApprovalCount);

    notifyListeners();
  }

  // Reset the new request count
  void resetNewRequestCount() {
    _newRequestCount = 0;
    notifyListeners();
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

  List<CustomerType> TypeService() {
    List<CustomerType> LstCustomerType = [];
    LstCustomerType.add(CustomerType(
        image: "assets/images/restaurant.png",
        name: "Restaurant",
        type: "3",
        subtext: "Enjoy our top-rated restaurants."));
    LstCustomerType.add(CustomerType(
        image: "assets/images/coffee.png",
        name: "Coffee",
        type: "2",
        subtext: "Relax and unwind at our cozy cafes."));
    LstCustomerType.add(CustomerType(
        image: "assets/images/hotel.png",
        name: "Hotel",
        type: "1",
        subtext: "Stay at our luxurious hotels."));
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

  void fetchNewRequestCount() {
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      FirebaseDatabase.instance
          .ref("App/Booking/Book")
          .orderByChild("IDOwner")
          .equalTo(id)
          .once()
          .then((DatabaseEvent event) {
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
        notifyListeners();
      });
    }
  }
}

class CustomerType {
  late String name, image, type, subtext;
  CustomerType(
      {required this.image,
      required this.name,
      required this.type,
      required this.subtext});
}
