// lib/screens/profile_estate_screen.dart

import 'dart:async';
import 'dart:math'; // Added for distance calculation
import 'package:diamond_host_admin/constants/coffee_music_options.dart';
import 'package:diamond_host_admin/constants/hotel_entry_options.dart';
import 'package:diamond_host_admin/constants/sessions_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../backend/additional_facility.dart';
import '../backend/booking_services.dart';
import '../backend/rooms.dart';
import '../backend/customer_rate_services.dart';
import '../backend/user_service.dart';
import '../constants/colors.dart';
import '../constants/entry_options.dart';
import '../constants/restaurant_options.dart';
import '../constants/styles.dart';
import '../extension/sized_box_extension.dart';
import '../localization/language_constants.dart';
import '../state_management/general_provider.dart';
import '../utils/success_dialogue.dart';
import '../utils/failure_dialogue.dart';
import '../widgets/chip_widget.dart';
import '../widgets/reused_appbar.dart';
import '../widgets/reused_elevated_button.dart';
import '../widgets/message_bubble.dart';
import 'feedback_dialog_screen.dart';
import 'qr_scanner_screen.dart';
import 'estate_chat_screen.dart';

class ProfileEstateScreen extends StatefulWidget {
  final String nameEn;
  final String nameAr;
  final String estateId;
  final String location;
  final double rating;
  final String fee;
  // final String deliveryTime;
  final double price;
  final String typeOfRestaurant;
  final String sessions;
  final String menuLink;
  final String entry;
  final String lstMusic;
  final String type;
  final String music;
  final String hasKidsArea;
  final String hasValet;
  final String valetWithFees;
  final String hasSwimmingPool;
  final String hasGym;
  final String hasBarber;
  final String hasMassage;
  final String isSmokingAllowed;
  final String hasJacuzziInRoom;
  final double lat;
  final double lon;
  final String city;
  final String country;

  const ProfileEstateScreen({
    Key? key,
    required this.nameEn,
    required this.nameAr,
    required this.estateId,
    required this.location,
    required this.rating,
    required this.fee,
    // required this.deliveryTime,
    required this.price,
    required this.typeOfRestaurant,
    required this.sessions,
    required this.menuLink,
    required this.entry,
    required this.lstMusic,
    required this.type,
    required this.music,
    required this.hasKidsArea,
    required this.hasValet,
    required this.valetWithFees,
    required this.hasBarber,
    required this.hasGym,
    required this.hasMassage,
    required this.hasSwimmingPool,
    required this.isSmokingAllowed,
    required this.hasJacuzziInRoom,
    required this.lon,
    required this.lat,
    required this.country,
    required this.city,
  }) : super(key: key);

  @override
  _ProfileEstateScreenState createState() => _ProfileEstateScreenState();
}

class _ProfileEstateScreenState extends State<ProfileEstateScreen> {
  List<String> _imageUrls = [];
  Map<String, dynamic> estate = {};
  TimeOfDay? selectedTime;
  DateTime? selectedDate;
  List<Rooms> LstRoomsSelected = [];
  final BookingServices bookingServices = BookingServices();
  final UserService _userService = UserService();
  final _cacheManager = CacheManager(
      Config('customCacheKey', stalePeriod: const Duration(days: 7)));
  double _overallRating = 0.0;
  int _currentImageIndex = 0;
  List<Map<String, dynamic>> _feedbackList = [];
  bool isLoadingTypeAccount = true;
  String? typeAccount;

  // Set to keep track of expanded feedback items
  Set<int> _expandedFeedbacks = {};

  @override
  void initState() {
    super.initState();
    _fetchTypeAccount();
    _fetchImageUrls();
    _fetchUserRatings();
    _fetchFeedback();
    // Removed: _loadButtonState(); // Load button state is now handled by provider
  }

  Future<void> _fetchTypeAccount() async {
    try {
      // Fetch the currently authenticated user
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        String userId = currentUser.uid;
        DatabaseReference userRef =
            FirebaseDatabase.instance.ref('App/User/$userId/TypeAccount');
        DataSnapshot snapshot = await userRef.get();

        if (snapshot.exists) {
          setState(() {
            typeAccount = snapshot.value.toString();
          });
        }
      }
    } catch (e) {
      print('Error fetching TypeAccount: $e');
    } finally {
      setState(() {
        isLoadingTypeAccount = false; // Loading complete
      });
    }
  }

  void _launchMaps() async {
    print('Latitude: ${widget.lat}, Longitude: ${widget.lon}');
    String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=${widget.lat},${widget.lon}';

    try {
      bool launched = await launch(googleUrl, forceWebView: false);
      print('Launch successful: $launched');
    } catch (e) {
      print('Error launching maps: $e');
    }
  }

  @override
  void dispose() {
    // Removed: _buttonTimer?.cancel(); // Timer is now managed by provider
    super.dispose();
  }

  /// Determines the duration for which the buttons remain active
  Duration getButtonActiveDuration() {
    if (widget.type == "1") {
      // Hotel
      return Duration(minutes: 2);
    } else {
      return Duration(minutes: 1);
    }
  }

  Future<void> _fetchFeedback() async {
    try {
      DatabaseReference feedbackRef =
          FirebaseDatabase.instance.ref('App/CustomerFeedback');
      DataSnapshot snapshot = await feedbackRef.get();
      if (snapshot.exists) {
        List<Map<String, dynamic>> feedbacks = [];
        snapshot.children.forEach((child) {
          final data = Map<String, dynamic>.from(child.value as Map);
          if (data['EstateID'] == widget.estateId) {
            feedbacks.add(data);
          }
        });
        setState(() {
          _feedbackList = feedbacks;
        });
      }
    } catch (e) {
      print('Error fetching feedback: $e');
    }
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
        hasMoreImages = false;
      }
      index++;
    }

    setState(() {
      _imageUrls = imageUrls;
    });
  }

  // Fetch user ratings
  Future<void> _fetchUserRatings() async {
    CustomerRateServices rateServices = CustomerRateServices();
    final ratings =
        await rateServices.fetchEstateRatingWithUsers(widget.estateId);
    double totalRating = 0.0;
    for (var rating in ratings) {
      totalRating += rating['rating'];
    }

    setState(() {
      _overallRating = ratings.isNotEmpty ? totalRating / ratings.length : 0.0;
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

  /// Method to get the translated value of typeOfRestaurant
  String getTranslatedTypeOfRestaurant(BuildContext context, String types) {
    // Check the current locale
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Split the types by comma and trim whitespace
    List<String> typeList =
        types.split(',').map((type) => type.trim()).toList();

    // Translate each type in the list
    List translatedTypes = typeList.map((type) {
      final match = restaurantOptions.firstWhere(
        (option) => option['label'] == type,
        orElse: () => {'label': type, 'labelAr': type}, // Provide a default map
      );
      return isArabic ? match['labelAr'] : match['label'];
    }).toList();

    // Join the translated types back with a comma
    return translatedTypes.join(', ');
  }

  String getTranslatedHotelEntry(BuildContext context, String types) {
    // Check the current locale
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Split the types by comma and trim whitespace
    List<String> typeList =
        types.split(',').map((type) => type.trim()).toList();

    // Translate each type in the list
    List translatedTypes = typeList.map((type) {
      final match = hotelEntryOptions.firstWhere(
        (option) => option['label'] == type,
        orElse: () => {'label': type, 'labelAr': type}, // Provide a default map
      );
      return isArabic ? match['labelAr'] : match['label'];
    }).toList();

    // Join the translated types back with a comma
    return translatedTypes.join(', ');
  }

  String getTranslatedEntry(BuildContext context, String types) {
    // Check the current locale
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Split the types by comma and trim whitespace
    List<String> typeList =
        types.split(',').map((type) => type.trim()).toList();

    // Translate each type in the list
    List translatedTypes = typeList.map((type) {
      final match = entryOptions.firstWhere(
        (option) => option['label'] == type,
        orElse: () => {'label': type, 'labelAr': type}, // Provide a default map
      );
      return isArabic ? match['labelAr'] : match['label'];
    }).toList();

    // Join the translated types back with a comma
    return translatedTypes.join(', ');
  }

  String getTranslatedSessions(BuildContext context, String types) {
    // Check the current locale
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Split the types by comma and trim whitespace
    List<String> typeList =
        types.split(',').map((type) => type.trim()).toList();

    // Translate each type in the list
    List translatedTypes = typeList.map((type) {
      final match = sessionsOptions.firstWhere(
        (option) => option['label'] == type,
        orElse: () => {'label': type, 'labelAr': type}, // Provide a default map
      );
      return isArabic ? match['labelAr'] : match['label'];
    }).toList();

    // Join the translated types back with a comma
    return translatedTypes.join(', ');
  }

  String getTranslatedCoffeeMusicOptions(BuildContext context, String types) {
    // Check the current locale
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Split the types by comma and trim whitespace
    List<String> typeList =
        types.split(',').map((type) => type.trim()).toList();

    // Translate each type in the list
    List translatedTypes = typeList.map((type) {
      final match = coffeeMusicOptions.firstWhere(
        (option) => option['label'] == type,
        orElse: () => {'label': type, 'labelAr': type}, // Provide a default map
      );
      return isArabic ? match['labelAr'] : match['label'];
    }).toList();

    // Join the translated types back with a comma
    return translatedTypes.join(', ');
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

  // Show confirmation dialog
  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            getTranslated(context, 'Confirm Booking'),
            style: TextStyle(
              color: kPurpleColor,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  getTranslated(context, 'Are you sure you want to book?'),
                  style: TextStyle(
                    color: kDeepPurpleColor,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                getTranslated(context, 'Cancel'),
                style: const TextStyle(
                  color: kErrorColor,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                getTranslated(context, 'Confirm'),
                style: const TextStyle(
                  color: kConfirmColor,
                ),
              ),
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

  // Show success dialog after booking confirmation
  Future<void> _showBookingInProgressDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevent the dialog from closing if tapped outside
      builder: (BuildContext context) {
        return SuccessDialog(
          text: getTranslated(context, 'Booking Status'),
          text1: getTranslated(context, 'Your booking is under progress.'),
        ); // Use the custom SuccessDialog
      },
    );
  }

  // Show failure dialog if booking fails
  Future<void> _showBookingFailureDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevent the dialog from closing if tapped outside
      builder: (BuildContext context) {
        return FailureDialog(
          text: getTranslated(context, 'Booking Status'),
          text1: getTranslated(
              context, 'Your booking could not be performed. Try Again!'),
        ); // Use the custom FailureDialog
      },
    );
  }

  // New method to show the invalid QR scan failure dialog
  Future<void> _showInvalidQRScanFailureDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing on outside tap
      builder: (BuildContext context) {
        return FailureDialog(
          text: getTranslated(context, 'Error'),
          text1: getTranslated(context, 'Invalid QR code scanned.'),
        );
      },
    );
  }

  // New method to show the failure dialog when no rooms are selected
  Future<void> _showChooseRoomFailureDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing on outside tap
      builder: (BuildContext context) {
        return FailureDialog(
          text: getTranslated(context, 'Error'),
          text1: getTranslated(
              context, 'Please select at least one room before booking.'),
        );
      },
    );
  }

  // New method to show the proximity failure dialog
  Future<void> _showProximityFailureDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing on outside tap
      builder: (BuildContext context) {
        return FailureDialog(
          text: getTranslated(context, 'Error'),
          text1: getTranslated(context,
              'You are not within the required distance to perform this action.'),
        );
      },
    );
  }

  // Create the booking using the BookingServices class
  Future<void> _createBooking() async {
    if (selectedDate != null && selectedTime != null) {
      try {
        await bookingServices.createBooking(
          estateId: widget.estateId,
          nameEn: widget.nameEn,
          nameAr: widget.nameAr,
          typeOfRestaurant: widget.typeOfRestaurant,
          selectedDate: selectedDate!,
          selectedTime: selectedTime!,
          context: context,
        );
        // Show booking in progress dialog after successful booking
        _showBookingInProgressDialog();
      } catch (e) {
        // If booking fails, show the failure dialog
        _showBookingFailureDialog();
      }
    }
  }

  // Widget to display star ratings
  Widget _buildStarRating(double rating, {double size = 16}) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: Colors.orange, size: size);
        } else if (index == fullStars && hasHalfStar) {
          return Icon(Icons.star_half, color: Colors.orange, size: size);
        } else {
          return Icon(Icons.star_border, color: Colors.orange, size: size);
        }
      }),
    );
  }

  /// Calculates distance between two coordinates in meters
  double _calculateDistanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // Earth's radius in meters
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = R * c;
    return distance;
  }

  double _deg2rad(double deg) {
    return deg * (pi / 180);
  }

  // Method to check proximity based on estate type
  Future<bool> _checkProximity() async {
    final prefs = await SharedPreferences.getInstance();
    final double? currentLat = prefs.getDouble('currentLat');
    final double? currentLon = prefs.getDouble('currentLon');

    if (currentLat == null || currentLon == null) {
      print('Current latitude or longitude is null.');
      return false;
    }

    final double distance = _calculateDistanceMeters(
        currentLat, currentLon, widget.lat, widget.lon);

    print(
        'Calculated distance: $distance meters (User: [$currentLat, $currentLon], Estate: [${widget.lat}, ${widget.lon}])');

    if (widget.type == '1') {
      // Hotel: 50 to 100 meters
      bool isValid = distance >= 50 && distance <= 100;
      print('Proximity for Hotel is valid: $isValid');
      return isValid;
    } else if (widget.type == '2' || widget.type == '3') {
      // Coffee or Restaurant: 50 to 1000 meters
      bool isValid = distance >= 50 && distance <= 1000;
      print('Proximity for Restaurant/Coffee is valid: $isValid');
      return isValid;
    }

    // For other types, assume invalid
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final String displayName =
        Localizations.localeOf(context).languageCode == 'ar'
            ? widget.nameAr
            : widget.nameEn;
    final objProvider = Provider.of<GeneralProvider>(context, listen: true);
    final bool isButtonsActive = objProvider.isButtonsActive;
    final String? activeEstateId = objProvider.activeEstateId;

    return Scaffold(
      appBar: isLoadingTypeAccount
          ? AppBar(
              title: CircularProgressIndicator(),
              centerTitle: true, // Temporary app bar during loading
            )
          : ReusedAppBar(
              title: displayName,
              actions: [
                // Rate Button
                TextButton(
                  child: Text(
                    getTranslated(context, "Rate"),
                    style: TextStyle(
                      color:
                          isButtonsActive && activeEstateId == widget.estateId
                              ? Colors.green
                              : kDeepPurpleColor,
                    ),
                  ),
                  onPressed: () async {
                    if (isButtonsActive && activeEstateId == widget.estateId) {
                      // Within the active duration, allow direct feedback
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FeedbackDialogScreen(
                            estateId: widget.estateId,
                            estateNameEn: widget.nameEn,
                            estateNameAr: widget.nameAr,
                          ),
                        ),
                      );

                      if (result == true) {
                        await _fetchFeedback();
                        await _fetchUserRatings();
                      }
                      return;
                    }

                    // If not active or time expired, require scanning
                    final scanResult = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QRScannerScreen(
                          expectedEstateId: widget.estateId,
                        ),
                      ),
                    );

                    if (scanResult == true) {
                      final isProximityValid = await _checkProximity();
                      if (isProximityValid) {
                        // If QR code is valid and proximity is valid, activate the timer before navigating
                        final duration = getButtonActiveDuration();
                        await objProvider.activateTimer(
                            widget.estateId, duration);

                        // **Add the user to activeUsers in Firebase with the desired structure**
                        await objProvider
                            .addActiveUserToDatabase(widget.estateId);

                        // Navigate to Feedback Dialog Screen
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeedbackDialogScreen(
                              estateId: widget.estateId,
                              estateNameEn: widget.nameEn,
                              estateNameAr: widget.nameAr,
                            ),
                          ),
                        );

                        if (result == true) {
                          await _fetchFeedback();
                          await _fetchUserRatings();
                          // Timer remains active until it expires
                        }
                      } else {
                        // Show proximity failure dialog
                        await _showProximityFailureDialog();
                      }
                    } else if (scanResult == false) {
                      // Show FailureDialog notifying the user of the invalid scan
                      await _showInvalidQRScanFailureDialog();
                    }
                  },
                ),

                // Map Button
                InkWell(
                  child: Icon(Icons.map_outlined),
                  onTap: () {
                    _launchMaps();
                  },
                ),

                // Chat Button
                if (typeAccount != "1")
                  IconButton(
                    icon: Icon(
                      Icons.chat,
                      color:
                          isButtonsActive && activeEstateId == widget.estateId
                              ? Colors.green
                              : kDeepPurpleColor,
                    ),
                    onPressed: () async {
                      if (isButtonsActive &&
                          activeEstateId == widget.estateId) {
                        // Within the active duration, allow direct chat
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EstateChatScreen(
                              estateId: widget.estateId,
                              estateNameEn: widget.nameEn,
                              estateNameAr: widget.nameAr,
                            ),
                          ),
                        );
                        return;
                      }

                      // If not active or time expired, require scanning
                      final scanResult = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QRScannerScreen(
                            expectedEstateId: widget.estateId,
                          ),
                        ),
                      );

                      if (scanResult == true) {
                        final isProximityValid = await _checkProximity();
                        if (isProximityValid) {
                          // If QR code is valid and proximity is valid, activate the timer before navigating
                          final duration = getButtonActiveDuration();
                          await objProvider.activateTimer(
                              widget.estateId, duration);

                          // **Add the user to activeUsers in Firebase with the desired structure**
                          await objProvider
                              .addActiveUserToDatabase(widget.estateId);

                          // Navigate to EstateChatScreen
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EstateChatScreen(
                                estateId: widget.estateId,
                                estateNameEn: widget.nameEn,
                                estateNameAr: widget.nameAr,
                              ),
                            ),
                          );
                        } else {
                          // Show proximity failure dialog
                          await _showProximityFailureDialog();
                        }
                      } else if (scanResult == false) {
                        // Show FailureDialog notifying the user of the invalid scan
                        await _showInvalidQRScanFailureDialog();
                      }
                    },
                  )
              ],
            ),
      body: SafeArea(
        // Added SafeArea for better UI
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0).copyWith(bottom: 80.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
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

                // Display Name
                AutoSizeText(
                  displayName,
                  style: kTeritary,
                  maxLines: 1,
                  minFontSize: 12,
                ),
                AutoSizeText(
                  "${widget.city}, ${widget.country}",
                  style: kSecondaryStyle,
                  maxLines: 1,
                  minFontSize: 12,
                ),
                8.kH,

                // Location
                // AutoSizeText(
                //   widget.location,
                //   style: const TextStyle(fontSize: 16, color: Colors.grey),
                //   maxLines: 1,
                //   minFontSize: 12,
                // ),
                16.kH,

                // Ratings, Fee, Delivery Time
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        _buildStarRating(_overallRating),
                        const SizedBox(width: 4),
                        Flexible(
                          child: AutoSizeText(
                            _overallRating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            minFontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    );
                  },
                ),
                16.kH,

                // Chips Section
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    if (widget.type == "3")
                      ChipWidget(
                        icon: Icons.fastfood,
                        label: getTranslatedTypeOfRestaurant(
                          context,
                          estate['TypeofRestaurant'] ?? widget.typeOfRestaurant,
                        ),
                      ),
                    if (widget.type == "3" || widget.type == "2")
                      ChipWidget(
                        icon: Icons.home,
                        label: getTranslatedSessions(
                          context,
                          estate['Sessions'] ?? widget.sessions,
                        ),
                      ),
                    ChipWidget(
                      icon: Icons.grain,
                      label: widget.type == "1"
                          ? getTranslatedHotelEntry(
                              context,
                              estate['Entry'] ?? widget.entry,
                            )
                          : getTranslatedEntry(
                              context,
                              estate['Entry'] ?? widget.entry,
                            ),
                    ),
                    ChipWidget(
                      icon: Icons.music_note,
                      label: (widget.type == "3" || widget.type == "1")
                          ? ((estate['Music'] ?? widget.music) == "1"
                              ? getTranslated(context, "There is music")
                              : getTranslated(context, "There is no music"))
                          : (widget.type == "2"
                              ? ((estate['Music'] ?? widget.music) == "1"
                                  ? getTranslatedCoffeeMusicOptions(
                                      context,
                                      estate['Lstmusic'] ?? widget.lstMusic,
                                    )
                                  : getTranslated(context, "There is no music"))
                              : getTranslated(context, "There is no music")),
                    ),
                    if (widget.type != "1")
                      ChipWidget(
                        icon: Icons.boy,
                        label: (estate['HasKidsArea'] ?? widget.hasKidsArea) ==
                                "1"
                            ? getTranslated(context, "We have kids area")
                            : getTranslated(context, "We dont have kids area"),
                      ),
                    if (widget.type == "1")
                      ChipWidget(
                        icon: Icons.bathtub,
                        label: (estate['HasJacuzziInRoom'] ??
                                    widget.hasJacuzziInRoom) ==
                                "1"
                            ? getTranslated(context, "We have jacuzzi")
                            : getTranslated(context, "We dont have jacuzzi"),
                      ),
                    ChipWidget(
                      icon: Icons.car_rental,
                      label: (estate['HasValet'] ?? widget.hasValet) == "1"
                          ? getTranslated(context, "Valet service available")
                          : getTranslated(
                              context, "No valet service available"),
                    ),
                    if ((estate['HasValet'] ?? widget.hasValet) == "1")
                      ChipWidget(
                        icon: Icons.money,
                        label:
                            (estate['ValetWithFees'] ?? widget.valetWithFees) ==
                                    "1"
                                ? getTranslated(context, "Valet is not free")
                                : getTranslated(context, "Valet is free"),
                      ),
                    if (widget.type == "1")
                      ChipWidget(
                        icon: Icons.pool,
                        label: (estate['HasSwimmingPool'] ??
                                    widget.hasSwimmingPool) ==
                                "1"
                            ? getTranslated(context, "We have swimming pool")
                            : getTranslated(
                                context, "We dont have swimming pool"),
                      ),
                    if (widget.type == "1")
                      ChipWidget(
                        icon: Icons.spa,
                        label: (estate['HasMassage'] ?? widget.hasMassage) ==
                                "1"
                            ? getTranslated(context, "We have massage")
                            : getTranslated(context, "We dont have massage"),
                      ),
                    if (widget.type == "1")
                      ChipWidget(
                        icon: Icons.fitness_center,
                        label: (estate['HasGym'] ?? widget.hasGym) == "1"
                            ? getTranslated(context, "We have Gym")
                            : getTranslated(context, "We dont have Gym"),
                      ),
                    if (widget.type == "1")
                      ChipWidget(
                        icon: Icons.content_cut,
                        label: (estate['HasBarber'] ?? widget.hasBarber) == "1"
                            ? getTranslated(context, "We have barber")
                            : getTranslated(context, "We dont have barber"),
                      ),
                    ChipWidget(
                      icon: Icons.smoking_rooms,
                      label: (estate['IsSmokingAllowed'] ??
                                  widget.isSmokingAllowed) ==
                              "1"
                          ? getTranslated(context, "Smoking is allowed")
                          : getTranslated(context, "Smoking is not allowed"),
                    ),
                  ],
                ),

                // Feedback Section
                24.kH,

                // Rooms Section
                Visibility(
                  visible: widget.type == "1",
                  child: AutoSizeText(
                    getTranslated(context, "Rooms"),
                    style: kTeritary,
                    maxLines: 1,
                    minFontSize: 12,
                  ),
                ),
                Visibility(
                  visible: widget.type == "1",
                  child: FirebaseAnimatedList(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    defaultChild:
                        const Center(child: CircularProgressIndicator()),
                    itemBuilder: (context, snapshot, animation, index) {
                      Map map = snapshot.value as Map;
                      map['Key'] = snapshot.key;
                      Rooms room = Rooms(
                        id: map['ID'],
                        name: map['Name'],
                        nameEn: map['Name'],
                        price: map['Price'],
                        bio: map['BioAr'],
                        bioEn: map['BioEn'],
                        color: Colors.white,
                      );

                      bool isSelected = LstRoomsSelected.any(
                          (element) => element.id == room.id);

                      return GestureDetector(
                        onTap: () async {
                          setState(() {
                            if (isSelected) {
                              LstRoomsSelected.removeWhere(
                                  (element) => element.id == room.id);
                            } else {
                              LstRoomsSelected.add(room);
                            }
                          });
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 70,
                          color: isSelected ? Colors.blue[100] : Colors.white,
                          child: ListTile(
                            title: AutoSizeText(
                              objProvider.CheckLangValue
                                  ? room.nameEn
                                  : room.name,
                              style: TextStyle(
                                color:
                                    isSelected ? kPrimaryColor : Colors.black,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              minFontSize: 12,
                            ),
                            subtitle: AutoSizeText(
                              objProvider.CheckLangValue
                                  ? room.bioEn
                                  : room.bio,
                              style: TextStyle(
                                color:
                                    isSelected ? kPrimaryColor : Colors.black54,
                              ),
                              maxLines: 2,
                              minFontSize: 10,
                            ),
                            leading: const Icon(
                              Icons.single_bed,
                              color: Colors.black,
                            ),
                            trailing: LayoutBuilder(
                              builder: (context, constraints) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: AutoSizeText(
                                        room.price,
                                        style: TextStyle(
                                            color: kDeepPurpleColor,
                                            fontSize: 18),
                                        maxLines: 1,
                                        minFontSize: 12,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: kPrimaryColor,
                                        size: 24,
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    query: FirebaseDatabase.instance
                        .ref("App")
                        .child("Rooms")
                        .child(widget.estateId.toString()),
                  ),
                ),

                16.kH,
                AutoSizeText(
                  getTranslated(context, "Feedback"),
                  style: kTeritary,
                  maxLines: 1,
                  minFontSize: 12,
                ),
                8.kH,

                // Modified Feedback Section to scroll horizontally
                _feedbackList.isEmpty
                    ? const Center(child: Text("No feedback available."))
                    : Container(
                        height: 300, // Set a fixed height for consistent layout
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal, // Horizontal scroll
                          itemCount: _feedbackList.length,
                          itemBuilder: (context, index) {
                            final feedback = _feedbackList[index];

                            return Container(
                              margin: const EdgeInsets.only(right: 16.0),
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: Card(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? kDarkModeColor
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 25,
                                            backgroundColor: kDeepPurpleColor,
                                            backgroundImage: feedback[
                                                            'profileImageUrl'] !=
                                                        null &&
                                                    feedback['profileImageUrl']
                                                        .toString()
                                                        .isNotEmpty
                                                ? CachedNetworkImageProvider(
                                                    feedback['profileImageUrl'])
                                                : AssetImage(
                                                        'assets/images/default_avatar.png')
                                                    as ImageProvider,
                                            child: feedback['profileImageUrl'] ==
                                                        null ||
                                                    feedback['profileImageUrl']
                                                        .toString()
                                                        .isEmpty
                                                ? Text(
                                                    (feedback['userName'] !=
                                                                null &&
                                                            (feedback['userName']
                                                                    as String)
                                                                .isNotEmpty)
                                                        ? (feedback['userName']
                                                                as String)[0]
                                                            .toUpperCase()
                                                        : '?',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                AutoSizeText(
                                                  feedback['userName'] ??
                                                      getTranslated(
                                                          context, 'Anonymous'),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  minFontSize: 12,
                                                ),
                                                Text(
                                                  feedback['feedbackDate'] !=
                                                          null
                                                      ? DateFormat.yMMMd()
                                                          .format(DateTime
                                                              .parse(feedback[
                                                                  'feedbackDate']))
                                                      : '',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      _buildStarRating(
                                        (feedback['RateForEstate'] ?? 0)
                                            .toDouble(),
                                        size: 16,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Estate Rating: ${feedback['RateForEstate'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      AutoSizeText(
                                        feedback['feedback'] ??
                                            getTranslated(context,
                                                'No feedback provided'),
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 10,
                                        minFontSize: 10,
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.restaurant,
                                                      color: Colors.orange,
                                                      size: 16),
                                                  const SizedBox(width: 4),
                                                  _buildStarRating(
                                                    (feedback['RateForFoodOrDrink'] ??
                                                            0)
                                                        .toDouble(),
                                                    size: 16,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Food Rating: ${feedback['RateForFoodOrDrink'] ?? 'N/A'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                      Icons
                                                          .miscellaneous_services,
                                                      color: Colors.orange,
                                                      size: 16),
                                                  const SizedBox(width: 4),
                                                  _buildStarRating(
                                                    (feedback['RateForServices'] ??
                                                            0)
                                                        .toDouble(),
                                                    size: 16,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Service Rating: ${feedback['RateForServices'] ?? 'N/A'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 50, // Adjust height as needed
          child: CustomButton(
            text: getTranslated(context, "Book"),
            onPressed: () async {
              if (widget.type == "1") {
                if (LstRoomsSelected.isEmpty) {
                  // Replace SnackBar with FailureDialog
                  await _showChooseRoomFailureDialog();
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AdditionalFacility(
                        CheckState: "",
                        CheckIsBooking: true,
                        estate: widget.type, // estate as String
                        IDEstate: widget.estateId.toString(),
                        Lstroom: LstRoomsSelected,
                      ),
                    ),
                  );
                }
              } else {
                await _pickDate();
                if (selectedDate != null) {
                  await _pickTime();
                  if (selectedTime != null) {
                    _showConfirmationDialog();
                  }
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
