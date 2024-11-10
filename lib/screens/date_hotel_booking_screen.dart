import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../backend/additional.dart';
import '../backend/rooms.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import 'main_screen.dart';

class DateBooking extends StatefulWidget {
  final String Estate; // Changed from Map to String
  final List<Rooms> LstRooms;
  final List<Additional> LstAdditional;
  final String estateID;

  DateBooking(
      {required this.Estate,
      required this.LstRooms,
      required this.LstAdditional,
      required this.estateID});

  @override
  State<DateBooking> createState() =>
      _DateBookingState(Estate, LstAdditional, LstRooms, estateID);
}

class _DateBookingState extends State<DateBooking> {
  DateTimeRange? _selectedDateRange;
  final String estate;
  final List<Rooms> lstRooms;
  final List<Additional> lstAdditional;
  final String estateID;

  _DateBookingState(
      this.estate, this.lstAdditional, this.lstRooms, this.estateID);

  String? fromDate = "x ";
  String? endDate = "x ";
  int? countOfDay = 0;
  double netTotal = 0;

  DatabaseReference bookingRef =
      FirebaseDatabase.instance.ref("App").child("Booking");
  DatabaseReference refRooms =
      FirebaseDatabase.instance.ref("App").child("Booking").child("Room");
  DatabaseReference refAdd =
      FirebaseDatabase.instance.ref("App").child("Booking").child("Additional");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => afterLayoutWidgetBuild());
  }

  void afterLayoutWidgetBuild() async {
    _show();
  }

  void _show() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? result = await showDateRangePicker(
      context: context,
      firstDate:
          DateTime(now.year, now.month, now.day), // Restrict to today or later
      lastDate: DateTime(2030, 12, 31),
      currentDate: now,
      saveText: 'Done',
    );

    if (result != null) {
      setState(() {
        _selectedDateRange = result;
        fromDate = _selectedDateRange!.start.toString();
        endDate = _selectedDateRange!.end.toString();
        countOfDay = _selectedDateRange!.end
            .difference(_selectedDateRange!.start)
            .inDays;
      });
      CalcuTotal();
    }
  }

  String generateUniqueOrderID() {
    var random = Random();
    return (random.nextInt(90000) + 10000)
        .toString(); // Generates a 5-digit number
  }

  Future<double?> fetchAverageUserRating(String userId) async {
    DatabaseReference ratingRef = FirebaseDatabase.instance
        .ref("App/TotalProviderFeedbackToCustomer/$userId/AverageRating");

    DataSnapshot snapshot = await ratingRef.get();
    if (snapshot.exists) {
      return double.parse(snapshot.value.toString());
    }
    return null;
  }

  Future<void> _createBooking() async {
    String uniqueID = generateUniqueOrderID();
    String idBook = uniqueID;
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    // Fetch User Information
    DatabaseReference userRef =
        FirebaseDatabase.instance.ref("App").child("User").child(userId!);
    DataSnapshot snapshot = await userRef.get();
    String firstName = snapshot.child("FirstName").value?.toString() ?? "";
    String secondName = snapshot.child("SecondName").value?.toString() ?? "";
    String lastName = snapshot.child("LastName").value?.toString() ?? "";
    String smokerStatus = snapshot.child("IsSmoker").value?.toString() ?? "No";
    String allergies = snapshot.child("Allergies").value?.toString() ?? "";
    String fullName = "$firstName $secondName $lastName";
    String registrationDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Fetch Hotel Details
    DatabaseReference hotelRef = FirebaseDatabase.instance
        .ref("App")
        .child("Estate")
        .child("Hottel")
        .child(widget.estateID);
    DataSnapshot hotelSnapshot = await hotelRef.get();
    String nameEn = hotelSnapshot.child("NameEn").value?.toString() ?? "Hotel";
    String nameAr = hotelSnapshot.child("NameAr").value?.toString() ?? "فندق";
    String type =
        hotelSnapshot.child("Type").value?.toString() ?? "1"; // Hotel type
    String country = hotelSnapshot.child("Country").value?.toString() ?? "";
    String city = hotelSnapshot.child("City").value?.toString() ?? "";
    String ownerID = hotelSnapshot.child("IDUser").value?.toString() ?? "";

    double? userRating = await fetchAverageUserRating(userId);

    await bookingRef.child("Book").child(idBook).set({
      "IDEstate": widget.Estate,
      "IDBook": idBook,
      "NameEn": nameEn,
      "NameAr": nameAr,
      "Status": "1", // Initial status: "Under Processing"
      "IDUser": userId,
      "IDOwner": ownerID,
      "StartDate": _selectedDateRange?.start.toString(),
      "EndDate": _selectedDateRange?.end.toString(),
      "Type": type,
      "Country": country,
      "City": city,
      "NameUser": fullName,
      "Smoker": smokerStatus,
      "Allergies": allergies,
      "Rating": userRating ?? 0.0,
      "DateOfBooking": registrationDate,
      "Clock": "${DateTime.now().hour}:${DateTime.now().minute}",
    });
    for (var additional in lstAdditional) {
      await refAdd.child(idBook).child(additional.id).set({
        "IDEstate": widget.Estate,
        "IDBook": idBook,
        "NameEn": additional.nameEn,
        "NameAr": additional.name,
        "Price": additional.price,
      });
    }

    String providerId = widget.Estate; // Assuming providerId relates to estate

    DatabaseReference providerTokenRef =
        FirebaseDatabase.instance.ref("App/User/$providerId/Token");
    DataSnapshot tokenSnapshot = await providerTokenRef.get();
    String? providerToken = tokenSnapshot.value?.toString();

    // if (providerToken != null && providerToken.isNotEmpty) {
    //   await _sendNotificationToProvider(
    //     providerToken,
    //     getTranslated(context, "New Booking Request"),
    //     getTranslated(context, "You have a new booking request"),
    //   );
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
        getTranslated(context, "Successfully"),
        style: TextStyle(
          color: kDeepPurpleColor,
        ),
      )),
    );

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => MainScreen()));
    // Further data saving and notifications
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: kIconTheme,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: ListView(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 10, right: 10),
              child: ListTile(
                leading: Image(
                    image: AssetImage(widget.Estate == "1"
                        ? "assets/images/hotel.png"
                        : widget.Estate == "2"
                            ? "assets/images/coffee.png"
                            : "assets/images/restaurant.png")),
                title: Text(
                  "Estate Details", // Display appropriate estate details
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  "Location Info", // Customize as needed
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                    child: ListTile(
                  title: Text("From Date"),
                  subtitle: Text(fromDate!.split(" ")[0]),
                )),
                Expanded(
                    child: ListTile(
                  title: Text("To Date"),
                  subtitle: Text(endDate!.split(" ")[0]),
                ))
              ],
            ),
            Text(
              "Count of Days: $countOfDay",
            ),
            Text(
              getTranslated(context, "Rooms"),
              style: TextStyle(fontSize: 18),
            ),
            Container(
              padding: const EdgeInsets.only(
                bottom: 20,
              ),
              child: ListView.builder(
                  itemCount: lstRooms.length,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      child: ListTile(
                        title: Text(lstRooms[index].name),
                        trailing: Text(lstRooms[index].price),
                      ),
                    );
                  }),
              height: lstRooms.length * 70,
            ),
            Text(
              getTranslated(context, "additional services"),
              style: TextStyle(fontSize: 18),
            ),
            Container(
              padding: const EdgeInsets.only(
                bottom: 20,
              ),
              child: ListView.builder(
                  itemCount: lstAdditional.length,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      child: ListTile(
                        title: Text(lstAdditional[index].name),
                        trailing: Text(lstAdditional[index].price),
                      ),
                    );
                  }),
              height: lstAdditional.length * 70,
            ),
            FutureBuilder<String>(
              future: CalcuTotal(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 50,
                    height: 50,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  return Text(snapshot.data!);
                } else {
                  return const Text('No data available');
                }
              },
            ),
            Container(
              height: 20,
            ),
            Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        child: Container(
                          width: 150.w,
                          height: 6.h,
                          margin: const EdgeInsets.only(
                              right: 20, left: 20, bottom: 20),
                          decoration: BoxDecoration(
                            color: kDeepPurpleColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              getTranslated(context, "Confirm Your Booking"),
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        onTap: () async {
                          await _createBooking();
                        },
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Future<String> CalcuTotal() async {
    double totalDayOfRoom = 0;
    double totalDayOfAdditional = 0;

    for (int i = 0; i < lstRooms.length; i++) {
      totalDayOfRoom += (double.parse(lstRooms[i].price) *
          double.parse(countOfDay.toString()));
    }
    for (int i = 0; i < lstAdditional.length; i++) {
      totalDayOfAdditional += (double.parse(lstAdditional[i].price));
    }
    netTotal = totalDayOfRoom + totalDayOfAdditional;

    return "$totalDayOfRoom\n$totalDayOfAdditional\n$netTotal";
  }
}
