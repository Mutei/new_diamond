import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/constants/styles.dart';
import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:diamond_host_admin/widgets/reused_elevated_button.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../backend/additional_facility.dart';
import '../backend/booking_services.dart';
import '../backend/rooms.dart';
import '../localization/language_constants.dart';
import '../backend/customer_rate_services.dart';
import '../state_management/general_provider.dart';
import '../utils/success_dialogue.dart';
import '../utils/failure_dialogue.dart'; // Import FailureDialog
import '../widgets/chip_widget.dart';
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
  final String type;

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
    required this.type,
  }) : super(key: key);

  @override
  _ProfileEstateScreenState createState() => _ProfileEstateScreenState();
}

class _ProfileEstateScreenState extends State<ProfileEstateScreen> {
  List<String> _imageUrls = [];
  TimeOfDay? selectedTime;
  DateTime? selectedDate;
  List<Rooms> LstRoomsSelected = [];
  final BookingServices bookingServices =
      BookingServices(); // Instantiate BookingServices
  final _cacheManager = CacheManager(
      Config('customCacheKey', stalePeriod: const Duration(days: 7)));
  double _overallRating = 0.0;
  int _currentImageIndex = 0;
  List<Map<String, dynamic>> _feedbackList = [];

  @override
  void initState() {
    super.initState();
    _fetchImageUrls();
    _fetchUserRatings();
    _fetchFeedback();
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
          text: 'Booking Status',
          text1: 'Your booking is under progress.',
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
          text: 'Booking Status',
          text1: 'Your booking could not be performed. Try Again!',
        ); // Use the custom FailureDialog
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

  @override
  Widget build(BuildContext context) {
    final String displayName =
        Localizations.localeOf(context).languageCode == 'ar'
            ? widget.nameAr
            : widget.nameEn;
    final objProvider = Provider.of<GeneralProvider>(context, listen: true);

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
              Text(displayName, style: kTeritary),
              8.kH,
              Text(widget.location,
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
              16.kH,
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 16),
                  4.kW,
                  Text(
                    _overallRating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  10.kW,
                  const Icon(Icons.monetization_on,
                      color: Colors.grey, size: 16),
                  4.kW,
                  Text(widget.fee,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  10.kW,
                  const Icon(Icons.timer, color: Colors.grey, size: 16),
                  4.kW,
                  Text(widget.deliveryTime,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              16.kH,
              Wrap(
                spacing: 10.0, // Add space between chips
                runSpacing:
                    10.0, // Add space between rows of chips if they overflow
                children: [
                  ChipWidget(
                      icon: Icons.fastfood, label: widget.typeOfRestaurant),
                  ChipWidget(icon: Icons.home, label: widget.sessions),
                  ChipWidget(icon: Icons.grain, label: widget.entry),
                  ChipWidget(
                    icon: Icons.music_note,
                    label: widget.music == "1"
                        ? getTranslated(context, "There is music")
                        : getTranslated(context, "There is no music"),
                  ),
                ],
              ),
              Text(
                getTranslated(context, "Feedback"),
                style: kTeritary,
              ),
              8.kH,
              SizedBox(
                height:
                    150, // Keep the height if you want to restrict the container's size
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _feedbackList.length,
                  itemBuilder: (context, index) {
                    final feedback = _feedbackList[index];
                    return Container(
                      width: 250,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Name with wrap and ellipsis
                          Text(
                            feedback['userName'] ??
                                getTranslated(context, 'Anonymous'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1, // Ensures it doesn't exceed one line
                          ),
                          const SizedBox(height: 5),
                          // Feedback text with controlled overflow
                          Expanded(
                            child: Text(
                              feedback['feedback'] ??
                                  getTranslated(
                                      context, 'No feedback provided'),
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2, // Adjust to fit your design needs
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Wrap layout for icons and ratings
                          Wrap(
                            alignment: WrapAlignment.start,
                            spacing: 10, // Space between items
                            runSpacing:
                                8, // Space between rows if wrapping occurs
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.orange, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Rating: ${feedback['RateForEstate']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.restaurant,
                                      color: Colors.orange, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Food: ${feedback['RateForFoodOrDrink']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.miscellaneous_services,
                                      color: Colors.orange, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Service: ${feedback['RateForServices']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              24.kH,
              Visibility(
                visible: widget.type == "1",
                child: Text(getTranslated(context, "Rooms")),
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
                          title: Text(
                            objProvider.CheckLangValue
                                ? room.nameEn
                                : room.name,
                            style: TextStyle(
                              color: isSelected ? kPrimaryColor : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            objProvider.CheckLangValue ? room.bioEn : room.bio,
                            style: TextStyle(
                              color:
                                  isSelected ? kPrimaryColor : Colors.black54,
                            ),
                          ),
                          leading: const Icon(
                            Icons.single_bed,
                            color: Colors.black,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                room.price,
                                style: TextStyle(
                                    color: kDeepPurpleColor, fontSize: 18),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: kPrimaryColor,
                                  size: 24,
                                ),
                            ],
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomButton(
                      text: getTranslated(context, "Book"),
                      onPressed: () async {
                        if (widget.type == "1") {
                          if (LstRoomsSelected.isEmpty) {
                            objProvider.FunSnackBarPage(
                                "Choose Room Before", context);
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
