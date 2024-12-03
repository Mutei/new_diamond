// lib/screens/feedback_dialog_screen.dart

import 'dart:async';

import 'package:diamond_host_admin/localization/language_constants.dart';
import 'package:diamond_host_admin/widgets/reused_appbar.dart';
import 'package:diamond_host_admin/widgets/reused_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import if not already imported
import 'package:provider/provider.dart';
import '../state_management/general_provider.dart';
import '../widgets/message_bubble.dart'; // Ensure this is imported
import 'package:cached_network_image/cached_network_image.dart'; // Ensure this is imported

class FeedbackDialogScreen extends StatefulWidget {
  final String estateId;
  final String estateNameEn;
  final String estateNameAr;

  const FeedbackDialogScreen(
      {Key? key,
      required this.estateId,
      required this.estateNameEn,
      required this.estateNameAr})
      : super(key: key);

  @override
  _FeedbackDialogScreenState createState() => _FeedbackDialogScreenState();
}

class _FeedbackDialogScreenState extends State<FeedbackDialogScreen> {
  final _feedbackController = TextEditingController();
  double _rateForEstate = 0.0;
  double _rateForFoodOrDrink = 0.0;
  double _rateForServices = 0.0;

  late StreamSubscription<String> _timerExpiredSubscription;

  @override
  void initState() {
    super.initState();

    // Listen to timer expired events
    final provider = Provider.of<GeneralProvider>(context, listen: false);
    _timerExpiredSubscription =
        provider.timerExpiredStream.listen((expiredEstateId) {
      if (expiredEstateId == widget.estateId) {
        // Timer expired for this estate, navigate back
        Navigator.of(context).pop(); // Close the FeedbackDialogScreen
      }
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _timerExpiredSubscription.cancel(); // Cancel the subscription
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    try {
      // Get the current user's ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final userId = user.uid;

      // Fetch the user's details from Firebase
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('App/User/$userId');
      DataSnapshot userSnapshot = await userRef.get();

      // Construct the username from FirstName, SecondName, and LastName
      String userName = "Anonymous";
      if (userSnapshot.exists) {
        final userData = userSnapshot.value as Map<dynamic, dynamic>;
        String firstName = userData['FirstName'] ?? "";
        String secondName = userData['SecondName'] ?? "";
        String lastName = userData['LastName'] ?? "";
        userName = "$firstName $secondName $lastName".trim();
      }

      // Reference to the CustomerFeedback node
      DatabaseReference feedbackRef =
          FirebaseDatabase.instance.ref('App/CustomerFeedback');

      // Check if feedback exists for this estate and user
      DataSnapshot feedbackSnapshot = await feedbackRef.get();
      String? existingFeedbackKey;
      for (DataSnapshot child in feedbackSnapshot.children) {
        final feedbackData = child.value as Map<dynamic, dynamic>;
        if (feedbackData['EstateID'] == widget.estateId &&
            feedbackData['UserID'] == userId) {
          existingFeedbackKey =
              child.key; // Get the key of the existing feedback
          break;
        }
      }

      if (existingFeedbackKey != null) {
        // Update existing feedback
        await feedbackRef.child(existingFeedbackKey).update({
          'RateForEstate': _rateForEstate,
          'RateForFoodOrDrink': _rateForFoodOrDrink,
          'RateForServices': _rateForServices,
          'feedback': _feedbackController.text.trim(),
          'rating':
              (_rateForEstate + _rateForFoodOrDrink + _rateForServices) / 3,
          'timestamp': DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feedback updated successfully')),
        );
      } else {
        // Create new feedback
        String feedbackKey = feedbackRef.push().key ??
            DateTime.now().millisecondsSinceEpoch.toString();

        final feedbackData = {
          'EstateID': widget.estateId,
          'UserID': userId,
          'userName': userName,
          'RateForEstate': _rateForEstate,
          'RateForFoodOrDrink': _rateForFoodOrDrink,
          'RateForServices': _rateForServices,
          'feedback': _feedbackController.text.trim(),
          'rating':
              (_rateForEstate + _rateForFoodOrDrink + _rateForServices) / 3,
          'timestamp': DateTime.now().toIso8601String(),
        };

        await feedbackRef.child(feedbackKey).set(feedbackData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feedback submitted successfully')),
        );
      }

      // Navigate back with a success result
      Navigator.pop(context, true);
    } catch (e) {
      // Show error message
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayName =
        Localizations.localeOf(context).languageCode == 'ar'
            ? widget.estateNameAr
            : widget.estateNameEn;
    final String rate =
        Localizations.localeOf(context).languageCode == 'ar' ? "قيم" : "Rate";
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Rate ${widget.estateName}'),
      // ),
      appBar: ReusedAppBar(title: "$rate ${displayName}"),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(getTranslated(context, 'Rate the Estate:'),
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _rateForEstate,
                onChanged: (value) {
                  setState(() {
                    _rateForEstate = value;
                  });
                },
                min: 0,
                max: 5,
                divisions: 5,
                label: _rateForEstate.toString(),
              ),
              SizedBox(height: 8),
              Text(getTranslated(context, 'Rate the Food/Drink:'),
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _rateForFoodOrDrink,
                onChanged: (value) {
                  setState(() {
                    _rateForFoodOrDrink = value;
                  });
                },
                min: 0,
                max: 5,
                divisions: 5,
                label: _rateForFoodOrDrink.toString(),
              ),
              SizedBox(height: 8),
              Text(getTranslated(context, 'Rate the Services:'),
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _rateForServices,
                onChanged: (value) {
                  setState(() {
                    _rateForServices = value;
                  });
                },
                min: 0,
                max: 5,
                divisions: 5,
                label: _rateForServices.toString(),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _feedbackController,
                decoration: InputDecoration(
                  labelText: getTranslated(context, 'Your Feedback'),
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 100,
              ),
              SizedBox(height: 16),
              Center(
                child: CustomButton(
                    text: getTranslated(context, "Submit Feedback"),
                    onPressed: _submitFeedback),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
