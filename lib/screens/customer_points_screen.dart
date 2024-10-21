import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:diamond_host_admin/widgets/reused_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../constants/styles.dart';
import '../localization/language_constants.dart';

class CustomerPoints extends StatefulWidget {
  const CustomerPoints({super.key});

  @override
  State<CustomerPoints> createState() => _CustomerPointsState();

  static Future<void> addPointsForRating() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      final databaseReference = FirebaseDatabase.instance
          .ref()
          .child('App/CustomerPoints')
          .child(userId);

      final pointsSnapshot = await databaseReference.child('points').get();
      double currentPoints = 0;
      if (pointsSnapshot.exists) {
        currentPoints = (pointsSnapshot.value as num).toDouble();
      }

      await databaseReference.child('points').set(currentPoints + 10);
    }
  }
}

class _CustomerPointsState extends State<CustomerPoints> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('App/CustomerPoints');
  double _totalPoints = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCustomerPoints();
  }

  void _fetchCustomerPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      final pointsRef = _databaseReference.child(userId).child('points');

      // Listen for changes in the points
      pointsRef.onValue.listen((event) {
        if (event.snapshot.exists) {
          setState(() {
            _totalPoints = (event.snapshot.value as num).toDouble();
          });
        } else {
          setState(() {
            _totalPoints = 0.0;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final progressToNextReward = _totalPoints / 1500;
    final nextRewardPoints = _totalPoints >= 1500 ? 3000 : 1500;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF673AB7), Color(0xFFE040FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05, // 5% padding on each side
          vertical: screenHeight * 0.1, // 10% padding from the top
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    getTranslated(context, "Total Points"),
                    style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                      height: screenHeight *
                          0.02), // Spacing based on screen height
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: screenWidth *
                            0.4, // Size of the circle is responsive
                        height: screenWidth * 0.4, // Square size for the circle
                        child: CircularProgressIndicator(
                          value: progressToNextReward > 1
                              ? (progressToNextReward - 1)
                              : progressToNextReward,
                          backgroundColor: Colors.grey[300],
                          color: kConfirmColor,
                          strokeWidth: screenWidth *
                              0.03, // Thickness relative to screen width
                        ),
                      ),
                      Text(
                        '${(progressToNextReward * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize:
                              screenWidth * 0.05, // Font size is responsive
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02), // Spacing
                  Text(
                    '$_totalPoints / $nextRewardPoints ${getTranslated(context, "points")}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045, // Responsive font size
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.015, // Responsive padding
                      horizontal: screenWidth * 0.05,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Text(
                      _totalPoints >= 1500
                          ? getTranslated(context, '10 SR off with 3000 points')
                          : getTranslated(context, '5 SR off with 1500 points'),
                      style: TextStyle(
                        fontSize: screenWidth * 0.045, // Responsive font size
                        color: const Color(0xFF673AB7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.04), // Spacing
            Text(
              getTranslated(context, "How it works?"),
              style: TextStyle(
                fontSize: screenWidth * 0.05, // Responsive font size
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenHeight * 0.01), // Spacing
            Text(
              getTranslated(context,
                  'Earn points by rating and giving feedback to providers. Reach 1500 points to get 5 SR off, and 3000 points to get 10 SR off.'),
              style: TextStyle(
                fontSize: screenWidth * 0.04, // Responsive font size
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
