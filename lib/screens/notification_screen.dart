import 'package:firebase_auth/firebase_auth.dart';
import 'package:diamond_host_admin/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/localization/language_constants.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../widgets/booking_card_widget.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  final DatabaseReference bookingRef =
      FirebaseDatabase.instance.ref("App").child("Booking").child("Book");
  bool isLoading = true;
  List<Map<String, dynamic>> bookings = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late AnimationController _animationController;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    // Fetch the current user's ID using FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });
      _fetchBookings();
    } else {
      // Handle the case when the user is not authenticated
      setState(() {
        isLoading = false;
      });
      // Optionally, navigate to the login screen
    }
  }

  Future<void> _fetchBookings() async {
    if (currentUserId == null) {
      // If user ID is not available, do not proceed
      setState(() {
        isLoading = false;
      });
      return;
    }

    DatabaseEvent event = await bookingRef.once();
    Map<dynamic, dynamic>? bookingsData = event.snapshot.value as Map?;

    if (bookingsData != null) {
      List<Map<String, dynamic>> loadedBookings =
          bookingsData.entries.where((entry) {
        final bookingData = entry.value as Map<dynamic, dynamic>;
        return bookingData["IDUser"]?.toString() == currentUserId;
      }).map((entry) {
        final bookingData = entry.value as Map<dynamic, dynamic>;
        return {
          "bookingId": entry.key ?? "",
          "status": bookingData["Status"]?.toString() ?? "Unknown",
          "nameEn": bookingData["NameEn"] ?? "Unnamed Estate",
          "nameAr": bookingData["NameAr"] ?? "منشأة بدون اسم",
          "startDate": bookingData["StartDate"]?.toString() ?? "N/A",
          "clock": bookingData["Clock"]?.toString() ?? "N/A",
          "type": bookingData["Type"]?.toString() ?? "N/A",
        };
      }).toList();

      setState(() {
        bookings = loadedBookings;
        isLoading = false;
        _populateList();
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _populateList() {
    Future.delayed(const Duration(milliseconds: 300), () {
      for (var i = 0; i < bookings.length; i++) {
        _listKey.currentState
            ?.insertItem(i, duration: const Duration(milliseconds: 400));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AutoSizeText(
          getTranslated(context, "Booking Status"),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kDeepPurpleColor,
          ),
          maxLines: 1,
        ),
        iconTheme: kIconTheme,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: kDeepPurpleColor,
              ),
            )
          : bookings.isEmpty
              ? Center(
                  child: AutoSizeText(
                    getTranslated(context, "No bookings found."),
                    style: const TextStyle(fontSize: 16),
                    maxLines: 1,
                  ),
                )
              : AnimatedList(
                  key: _listKey,
                  initialItemCount: bookings.length,
                  itemBuilder: (context, index, animation) {
                    if (index < bookings.length) {
                      final booking = bookings[index];
                      final String displayName =
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? booking['nameAr']
                              : booking['nameEn'];
                      return BookingCardWidget(
                        booking: booking,
                        animation: animation,
                        estateName: displayName,
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
