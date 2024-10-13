import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class BookingServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Function to generate a unique ID for the booking
  String generateUniqueID() {
    var random = Random();
    return (random.nextInt(90000) + 10000)
        .toString(); // Generates a 5-digit number
  }

  // Function to fetch user rating
  Future<double?> fetchUserRating(String userId) async {
    DatabaseReference ratingRef = _dbRef
        .child("App/TotalProviderFeedbackToCustomer/$userId/AverageRating");
    DataSnapshot snapshot = await ratingRef.get();
    if (snapshot.exists) {
      return double.parse(snapshot.value.toString());
    }
    return null; // Return null if no ratings found
  }

  // Function to fetch the estate owner's ID based on estate type (Restaurant, Hotel, Coffee)
  Future<String?> fetchOwnerId(String estateId, String estateType) async {
    String estateTypePath;
    switch (estateType.toLowerCase()) {
      case 'restaurant':
        estateTypePath = 'Restaurant';
        break;
      case 'hotel':
        estateTypePath = 'Hotel';
        break;
      case 'coffee':
        estateTypePath = 'Coffee';
        break;
      default:
        estateTypePath = 'Restaurant'; // Default to Restaurant if unknown
        break;
    }

    DatabaseReference estateRef = _dbRef
        .child("App")
        .child("Estate")
        .child(estateTypePath)
        .child(estateId)
        .child("IDUser");
    DataSnapshot estateSnapshot = await estateRef.get();
    if (estateSnapshot.exists) {
      return estateSnapshot.value?.toString(); // Return the owner ID
    }
    return null;
  }

  // Function to create a booking
  Future<void> createBooking({
    required String estateId,
    required String nameEn,
    required String nameAr,
    required String typeOfRestaurant,
    required DateTime selectedDate,
    required TimeOfDay selectedTime,
    required BuildContext context,
  }) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      // Handle user not logged in
      return;
    }

    // Generate a unique booking ID
    String uniqueID = generateUniqueID();
    String bookingID = uniqueID;

    // Fetch user information
    DatabaseReference userRef = _dbRef.child("App").child("User").child(userId);
    DataSnapshot snapshot = await userRef.get();
    String firstName = snapshot.child("FirstName").value?.toString() ?? "";
    String secondName = snapshot.child("SecondName").value?.toString() ?? "";
    String lastName = snapshot.child("LastName").value?.toString() ?? "";
    String smokerStatus = snapshot.child("IsSmoker").value?.toString() ?? "No";
    String allergies = snapshot.child("Allergies").value?.toString() ?? "";
    String city = snapshot.child("City").value?.toString() ?? "";
    String country = snapshot.child("Country").value?.toString() ?? "";
    String fullName = "$firstName $secondName $lastName";

    // Fetch the estate owner ID
    String? ownerId = await fetchOwnerId(estateId, typeOfRestaurant);
    if (ownerId == null) {
      // Handle error if owner ID cannot be fetched
      return;
    }

    // Format the selected date (only the date, no time)
    String bookingDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Fetch user rating
    double? userRating = await fetchUserRating(userId);
    String registrationDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    String hour = selectedTime.hour.toString().padLeft(2, '0');
    String minute = selectedTime.minute.toString().padLeft(2, '0');

    // Create booking in Firebase
    DatabaseReference bookingRef =
        _dbRef.child("App").child("Booking").child("Book");
    await bookingRef.child(bookingID).set({
      "IDEstate": estateId,
      "IDBook": bookingID,
      "NameEn": nameEn,
      "NameAr": nameAr,
      "Status": "1",
      "IDUser": userId,
      "IDOwner": ownerId,
      "StartDate": bookingDate,
      "EndDate": "",
      "Type": typeOfRestaurant,
      "Country": country,
      "State": "State",
      "City": city,
      "NameUser": fullName,
      "Smoker": smokerStatus,
      "Allergies": allergies,
      "Rating": userRating ?? 0.0,
      "DateOfBooking": registrationDate,
      "Clock": "$hour:$minute",
    });

    // Optionally send notification to provider using FCM (if implemented)
  }
}
