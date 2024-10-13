import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/localization/language_constants.dart';
import '../widgets/booking_card_widget.dart'; // Import the reusable BookingCard widget

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  final DatabaseReference bookingRef = FirebaseDatabase.instance
      .ref("App")
      .child("Booking")
      .child("Book"); // Firebase path
  bool isLoading = true;
  List<Map<String, dynamic>> bookings = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchBookings();
  }

  // Fetch the booking status from Firebase
  Future<void> _fetchBookings() async {
    DatabaseEvent event = await bookingRef.once();
    Map<dynamic, dynamic>? bookingsData = event.snapshot.value as Map?;

    if (bookingsData != null) {
      List<Map<String, dynamic>> loadedBookings =
          bookingsData.entries.map((entry) {
        return {
          "bookingId": entry.key,
          "status": entry.value["Status"].toString(),
          "name": entry.value["NameEn"], // Add other fields if needed
          "startDate": entry.value["StartDate"].toString(),
          "clock": entry.value["Clock"].toString(),
          "type": entry.value["Type"].toString(),
        };
      }).toList();

      setState(() {
        bookings = loadedBookings;
        isLoading = false;
        _populateList(); // Animate the list population
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Populate the AnimatedList with entries
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
        title: Text(getTranslated(context, 'Notifications')),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: kPrimaryColor,
              ),
            )
          : bookings.isEmpty
              ? Center(
                  child: Text(
                    getTranslated(context, 'No bookings found.'),
                    style: const TextStyle(fontSize: 16),
                  ),
                )
              : AnimatedList(
                  key: _listKey,
                  initialItemCount: bookings.length,
                  itemBuilder: (context, index, animation) {
                    // Ensure the index is within range
                    if (index < bookings.length) {
                      final booking = bookings[index];
                      return BookingCardWidget(
                        booking: booking,
                        animation: animation,
                      );
                    } else {
                      // Return an empty widget if index is out of range
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
