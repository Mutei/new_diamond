// notification_screen.dart
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

class _NotificationScreenState extends State<NotificationScreen> {
  final DatabaseReference bookingRef =
      FirebaseDatabase.instance.ref("App").child("Booking").child("Book");
  bool isLoading = true;
  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> filteredBookings = [];
  String? currentUserId;
  String currentFilter = 'under_process';

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });
      _fetchBookings();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchBookings() async {
    if (currentUserId == null) {
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
        _filterBookings();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterBookings() {
    setState(() {
      if (currentFilter == 'under_process') {
        filteredBookings =
            bookings.where((booking) => booking['status'] == '1').toList();
      } else if (currentFilter == 'accepted') {
        filteredBookings =
            bookings.where((booking) => booking['status'] == '2').toList();
      } else if (currentFilter == 'rejected') {
        filteredBookings =
            bookings.where((booking) => booking['status'] == '3').toList();
      } else {
        filteredBookings = [];
      }
    });
  }

  void _changeFilter(String filter) {
    setState(() {
      currentFilter = filter;
      _filterBookings();
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _changeFilter('under_process'),
                    icon: Icon(Icons.hourglass_top),
                    label: Text(
                      getTranslated(context, 'Under Process'),
                      textAlign: TextAlign.center,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      backgroundColor: currentFilter == 'under_process'
                          ? Colors.orange
                          : Colors.grey[200],
                      foregroundColor: currentFilter == 'under_process'
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _changeFilter('accepted'),
                    icon: Icon(Icons.check_circle),
                    label: Text(
                      getTranslated(context, 'Booking Accepted'),
                      textAlign: TextAlign.center,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      backgroundColor: currentFilter == 'accepted'
                          ? Colors.green
                          : Colors.grey[200],
                      foregroundColor: currentFilter == 'accepted'
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _changeFilter('rejected'),
                    icon: Icon(Icons.cancel),
                    label: Text(
                      getTranslated(context, 'Booking Rejected'),
                      textAlign: TextAlign.center,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      backgroundColor: currentFilter == 'rejected'
                          ? Colors.red
                          : Colors.grey[200],
                      foregroundColor: currentFilter == 'rejected'
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: kDeepPurpleColor,
                    ),
                  )
                : filteredBookings.isEmpty
                    ? Center(
                        child: AutoSizeText(
                          getTranslated(context, "No bookings found."),
                          style: const TextStyle(fontSize: 16),
                          maxLines: 1,
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          final String displayName =
                              Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? booking['nameAr']
                                  : booking['nameEn'];
                          return BookingCardWidget(
                            booking: booking,
                            estateName: displayName,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
