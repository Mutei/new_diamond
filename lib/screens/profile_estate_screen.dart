import 'dart:io';
import 'dart:math';
import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/constants/styles.dart';
import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:diamond_host_admin/widgets/reused_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // Cache manager
import 'package:cached_network_image/cached_network_image.dart'; // Cached image package
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../localization/language_constants.dart';
import '../backend/customer_rate_services.dart';
import '../widgets/chip_widget.dart'; // Import for translations
import 'package:provider/provider.dart';

class ProfileEstateScreen extends StatefulWidget {
  final String nameEn;
  final String nameAr;
  final String estateId;
  final String location;
  final double rating;
  final String fee;
  final String deliveryTime;
  final double price;
  final String typeOfRestaurant;
  final String sessions;
  final String menuLink;
  final String entry;
  final String music;

  const ProfileEstateScreen({
    Key? key,
    required this.nameEn,
    required this.nameAr,
    required this.estateId,
    required this.location,
    required this.rating,
    required this.fee,
    required this.deliveryTime,
    required this.price,
    required this.typeOfRestaurant,
    required this.sessions,
    required this.menuLink,
    required this.entry,
    required this.music,
  }) : super(key: key);

  @override
  _ProfileEstateScreenState createState() => _ProfileEstateScreenState();
}

class _ProfileEstateScreenState extends State<ProfileEstateScreen> {
  List<String> _imageUrls = [];
  late final Map estate;
  TimeOfDay? sTime = TimeOfDay.now();
  List<Map<String, dynamic>> _userRatings =
      []; // To store users and their ratings
  double _overallRating = 0.0; // Overall rating as double
  int _currentImageIndex = 0; // To track the current image index
  final _cacheManager = CacheManager(Config(
    'customCacheKey', // Custom key for cache management
    stalePeriod: const Duration(days: 7), // Cache images for 7 days
  ));

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    _fetchImageUrls();
    _fetchUserRatings(); // Fetch user ratings for the estate
  }

  Future<double?> fetchUserRating(String userId) async {
    DatabaseReference ratingRef = FirebaseDatabase.instance
        .ref("App/TotalProviderFeedbackToCustomer/$userId/AverageRating");

    DataSnapshot snapshot = await ratingRef.get();
    if (snapshot.exists) {
      return double.parse(snapshot.value.toString());
    }
    return null; // Return null if no ratings found
  }

  // Fetch multiple images URLs from Firebase Storage
  Future<void> _fetchImageUrls() async {
    int index = 0;
    bool hasMoreImages = true;
    List<String> imageUrls = [];

    while (hasMoreImages) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('${widget.estateId}/$index.jpg');
        final imageUrl = await storageRef.getDownloadURL();
        imageUrls.add(imageUrl);

        // Preload image to ensure it's cached before use
        await _cacheManager.getSingleFile(imageUrl);
      } catch (e) {
        hasMoreImages = false; // No more images available
      }
      index++;
    }

    setState(() {
      _imageUrls = imageUrls;
    });
  }

  // Fetch ratings with user names
  Future<void> _fetchUserRatings() async {
    CustomerRateServices rateServices = CustomerRateServices();
    final ratings =
        await rateServices.fetchEstateRatingWithUsers(widget.estateId);
    double totalRating = 0.0;
    for (var rating in ratings) {
      totalRating += rating['rating']; // Sum all ratings
    }

    setState(() {
      _userRatings = ratings; // Update the list with fetched user ratings
      _overallRating = ratings.isNotEmpty
          ? totalRating / ratings.length
          : 0.0; // Calculate average rating
    });
  }

  // Function to pick a date
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  // Function to pick a time
  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  String generateUniqueID() {
    var random = Random();
    return (random.nextInt(90000) + 10000)
        .toString(); // Generates a 5-digit number
  }

  // Show confirmation dialog
  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must confirm to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(getTranslated(context, 'Confirm Booking')),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(getTranslated(context, 'Are you sure you want to book?')),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(getTranslated(context, 'Cancel')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(getTranslated(context, 'Confirm')),
              onPressed: () {
                Navigator.of(context).pop();
                _createBooking(); // Call booking method
              },
            ),
          ],
        );
      },
    );
  }

  // Helper function to format the selected date and time
  String _formatSelectedDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date); // Only format the date
  }

  // Fetch the estate owner's ID based on estate type (Restaurant, Hotel, Coffee)
  Future<String?> _fetchOwnerId() async {
    String estateTypePath;
    switch (widget.typeOfRestaurant.toLowerCase()) {
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

    DatabaseReference estateRef = FirebaseDatabase.instance
        .ref("App")
        .child("Estate")
        .child(estateTypePath)
        .child(widget.estateId)
        .child("IDUser");

    DataSnapshot estateSnapshot = await estateRef.get();
    if (estateSnapshot.exists) {
      return estateSnapshot.value?.toString(); // Return the owner ID
    }
    return null;
  }

  // Create the booking (Firebase method)
  Future<void> _createBooking() async {
    if (selectedDate == null || selectedTime == null) {
      // Handle error (e.g., show a Snackbar or error message)
      return;
    }

    String uniqueID = generateUniqueID();
    String IDBook = uniqueID;

    DatabaseReference ref =
        FirebaseDatabase.instance.ref("App").child("Booking").child("Book");
    String? id = FirebaseAuth.instance.currentUser?.uid;

    // Fetch user information
    DatabaseReference userRef =
        FirebaseDatabase.instance.ref("App").child("User").child(id!);
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
    String? ownerId =
        await _fetchOwnerId(); // Get owner ID based on estate type
    if (ownerId == null) {
      // Handle error if owner ID cannot be fetched
      return;
    }

    // Format the selected date (only the date, no time)
    String bookingDate = _formatSelectedDate(selectedDate!);

    // Fetch user rating
    double? userRating = await fetchUserRating(id);
    String registrationDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    String? hour = sTime?.hour.toString().padLeft(2, '0');
    String? minute = sTime?.minute.toString().padLeft(2, '0');

    // Create booking in Firebase
    await ref.child(IDBook.toString()).set({
      "IDEstate": widget.estateId,
      "IDBook": IDBook,
      "NameEn": widget.nameEn,
      "NameAr": widget.nameAr,
      "Status": "1",
      "IDUser": id,
      "IDOwner":
          ownerId, // Now using the owner's ID fetched based on estate type
      "StartDate": bookingDate, // Only the date is saved
      "EndDate": "",
      "Type": widget.typeOfRestaurant,
      "Country": country, // Modify as per data
      "State": "State", // Modify as per data
      "City": city, // Modify as per data
      "NameUser": fullName,
      "Smoker": smokerStatus,
      "Allergies": allergies,
      "Rating": userRating ?? 0.0,
      "DateOfBooking": registrationDate,
      "Clock": "${hour!}:${minute!}",
    });

    // Fetch provider's FCM token and send notification (if required)
    DatabaseReference providerTokenRef =
        FirebaseDatabase.instance.ref("App/User/$ownerId/Token");
    DataSnapshot tokenSnapshot = await providerTokenRef.get();
    String? providerToken = tokenSnapshot.value?.toString();

    // if (providerToken != null && providerToken is notEmpty) {
    //   await FirebaseServices().sendNotificationToProvider(
    //     providerToken,
    //     getTranslated(context, "New Booking Request"),
    //     getTranslated(context, "You have a new booking request"),
    //   );
    // }

    // Show success message or navigate to another screen
  }

  @override
  Widget build(BuildContext context) {
    final String displayName =
        Localizations.localeOf(context).languageCode == 'ar'
            ? widget.nameAr
            : widget.nameEn;

    return Scaffold(
      appBar: AppBar(
        iconTheme: kIconTheme,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Carousel with PageView
              _imageUrls.isEmpty
                  ? Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey[200],
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        SizedBox(
                          height: 200,
                          child: PageView.builder(
                            itemCount: _imageUrls.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: CachedNetworkImage(
                                  imageUrl: _imageUrls[index],
                                  cacheManager: _cacheManager,
                                  placeholder: (context, url) =>
                                      Container(color: Colors.grey[300]),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1} / ${_imageUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
              16.kH,
              // Estate Name and Location
              Text(
                displayName,
                style: kTeritary,
              ),
              8.kH,
              Text(
                widget.location,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              16.kH,
              // Overall Rating Section
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 16),
                  4.kW,
                  Text(
                    _overallRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  10.kW,
                  const Icon(Icons.monetization_on,
                      color: Colors.grey, size: 16),
                  4.kW,
                  Text(
                    widget.fee,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  10.kW,
                  const Icon(Icons.timer, color: Colors.grey, size: 16),
                  4.kW,
                  Text(
                    widget.deliveryTime,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              16.kH,
              // User Ratings Section
              _userRatings.isEmpty
                  ? const Center(child: Text("No ratings yet"))
                  : SizedBox(
                      height: 120,
                      child: PageView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _userRatings.length,
                        itemBuilder: (context, index) {
                          final userRating = _userRatings[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(
                                    userRating['userName'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (starIndex) => Icon(
                                        starIndex < userRating['rating']
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.orange,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              16.kH,
              Wrap(
                spacing: 10.0,
                children: [
                  IngredientTag(
                      icon: Icons.fastfood, label: widget.typeOfRestaurant),
                  IngredientTag(icon: Icons.home, label: widget.sessions),
                  IngredientTag(icon: Icons.grain, label: widget.entry),
                  IngredientTag(icon: Icons.music_note, label: widget.music),
                ],
              ),
              24.kH,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomButton(
                      text: getTranslated(context, "Book"),
                      onPressed: () async {
                        await _pickDate(); // First select a date
                        if (selectedDate != null) {
                          await _pickTime(); // Then select a time
                          if (selectedTime != null) {
                            _showConfirmationDialog(); // Finally show confirmation dialog
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              16.kH,
            ],
          ),
        ),
      ),
    );
  }
}
