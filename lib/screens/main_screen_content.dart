// import 'package:diamond_host_admin/widgets/reused_appbar.dart';
// import 'package:diamond_host_admin/widgets/estate_card_widget.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';
// import '../backend/customer_rate_services.dart';
// import '../backend/estate_services.dart';
// import '../backend/firebase_services.dart';
// import '../localization/language_constants.dart';
// import '../state_management/general_provider.dart';
// import '../widgets/custom_drawer.dart';
// import 'profile_estate_screen.dart';
//
// class MainScreenContent extends StatefulWidget {
//   const MainScreenContent({super.key});
//
//   @override
//   _MainScreenContentState createState() => _MainScreenContentState();
// }
//
// class _MainScreenContentState extends State<MainScreenContent> {
//   EstateServices estateServices = EstateServices();
//   CustomerRateServices customerRateServices = CustomerRateServices();
//   List<Map<String, dynamic>> estates = [];
//   FirebaseServices _firebaseServices = FirebaseServices();
//   final List<String> categories = ['Hotel', 'Restaurant', 'Coffee'];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchEstates();
//     _firebaseServices.initMessage(showNotification);
//     _requestPermissionsInSequence();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<GeneralProvider>(context, listen: false).fetchApprovalCount();
//     });
//   }
//
//   void showNotification(RemoteNotification? notification) {
//     if (notification != null) {
//       const AndroidNotificationDetails androidDetails =
//           AndroidNotificationDetails('channel_id', 'channel_name',
//               importance: Importance.high,
//               priority: Priority.high,
//               icon: 'ic_notification');
//       const NotificationDetails generalDetails =
//           NotificationDetails(android: androidDetails);
//       _firebaseServices.flutterLocalNotificationPlugin.show(
//         0,
//         notification.title,
//         notification.body,
//         generalDetails,
//       );
//     }
//   }
//
//   Future<void> _requestPermissionsInSequence() async {
//     await _requestLocationPermission();
//     await _requestNotificationPermission(); // Then request notification permission
//     await _checkNotificationPermissionStatus(); // Ensure the permission status is verified
//   }
//
//   Future<void> _requestLocationPermission() async {
//     PermissionStatus status = await Permission.location.status;
//
//     if (status.isDenied || status.isRestricted) {
//       status = await Permission.location.request();
//     }
//
//     if (status.isPermanentlyDenied) {
//       // Show an alert to guide the user to settings to enable location permissions.
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text(getTranslated(context, "Location Permission Required")),
//           content: Text(getTranslated(context,
//               "Please enable location permission in settings to use the map features.")),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 openAppSettings();
//               },
//               child: Text(getTranslated(context, "Open Settings")),
//             ),
//           ],
//         ),
//       );
//     }
//   }
//
//   Future<void> _requestNotificationPermission() async {
//     FirebaseMessaging messaging = FirebaseMessaging.instance;
//     NotificationSettings settings = await messaging.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//       sound: true,
//     );
//
//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       print('User granted permission for notifications');
//     } else if (settings.authorizationStatus ==
//         AuthorizationStatus.provisional) {
//       print('User granted provisional permission for notifications');
//     } else {
//       print('User declined or has not accepted permission for notifications');
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title:
//               Text(getTranslated(context, "Notification Permission Required")),
//           content: Text(getTranslated(
//               context, "Please enable notification permission in settings.")),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 openAppSettings();
//               },
//               child: Text(getTranslated(context, "Open Settings")),
//             ),
//           ],
//         ),
//       );
//     }
//   }
//
//   Future<void> _checkNotificationPermissionStatus() async {
//     PermissionStatus status = await Permission.notification.status;
//     if (status.isGranted) {
//       print("Notification permission granted.");
//     } else if (status.isDenied) {
//       print("Notification permission denied.");
//     } else if (status.isPermanentlyDenied) {
//       print(
//           "Notification permission permanently denied. Directing user to settings.");
//       openAppSettings();
//     } else {
//       print("Notification permission status unknown.");
//     }
//   }
//
//   Future<void> _fetchEstates() async {
//     try {
//       final data = await estateServices.fetchEstates();
//       if (data != null) {
//         List<Map<String, dynamic>> parsedEstates = _parseEstates(data);
//         setState(() {
//           estates = parsedEstates;
//         });
//       } else {
//         print("No data found in Firebase.");
//       }
//     } catch (e) {
//       print("Error fetching estates: $e");
//     }
//   }
//
//   List<Map<String, dynamic>> _parseEstates(Map<String, dynamic> data) {
//     List<Map<String, dynamic>> estateList = [];
//     List<String> categories = ["Coffee", "Restaurant", "Hottel"];
//
//     for (var category in categories) {
//       if (data.containsKey(category)) {
//         var categoryData = data[category];
//         if (categoryData is List) {
//           for (var estateData in categoryData) {
//             if (estateData != null &&
//                 estateData is Map<dynamic, dynamic> &&
//                 estateData['IsAccepted'] == 2) {
//               estateList.add(
//                   _extractEstateData(Map<String, dynamic>.from(estateData)));
//             }
//           }
//         } else if (categoryData is Map) {
//           for (var estateKey in categoryData.keys) {
//             var estateData = categoryData[estateKey];
//             if (estateData != null && estateData is Map) {
//               estateList.add(
//                   _extractEstateData(Map<String, dynamic>.from(estateData)));
//             }
//           }
//         }
//       }
//     }
//     return estateList;
//   }
//
//   Map<String, dynamic> _extractEstateData(Map<String, dynamic> estateData) {
//     return {
//       'id': estateData['IDEstate'] ?? 'Unknown ID',
//       'nameEn': estateData['NameEn'] ?? 'Unknown',
//       'nameAr': estateData['NameAr'] ?? 'غير معروف',
//       'rating': 0.0,
//       'fee': estateData['Fee'] ?? 'Free',
//       'time': estateData['Time'] ?? '20 min',
//       'TypeofRestaurant': estateData['TypeofRestaurant'] ?? 'Unknown Type',
//       'Sessions': estateData['Sessions'] ?? 'Unknown Session Type',
//       'MenuLink': estateData['MenuLink'] ?? 'No Menu',
//       'Entry': estateData['Entry'] ?? 'Empty',
//       'Lstmusic': estateData['Lstmusic'] ?? 'No music',
//       'Type': estateData['Type'] ?? 'Unknown',
//     };
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: ReusedAppBar(
//         title: getTranslated(context, "Main Screen"),
//       ),
//       drawer: const CustomDrawer(),
//       body: RefreshIndicator(
//         onRefresh: _fetchEstates, // Refresh function to reload estate data
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   getTranslated(context, "All Categories"),
//                   style: const TextStyle(
//                       fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               SizedBox(
//                 height: 120,
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: categories.length,
//                   itemBuilder: (context, index) {
//                     IconData iconData;
//                     switch (categories[index]) {
//                       case 'Hotel':
//                         iconData = Icons.hotel;
//                         break;
//                       case 'Restaurant':
//                         iconData = Icons.restaurant;
//                         break;
//                       case 'Coffee':
//                         iconData = Icons.local_cafe;
//                         break;
//                       default:
//                         iconData = Icons.category;
//                     }
//
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                       child: Column(
//                         children: [
//                           Container(
//                             width: 115,
//                             height: 80,
//                             decoration: BoxDecoration(
//                               color: Colors.grey[200],
//                               shape: BoxShape.circle,
//                             ),
//                             child: Icon(
//                               iconData,
//                               size: 40,
//                               color: Colors.deepPurple,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             categories[index],
//                             style: const TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               estates.isEmpty
//                   ? const Center(child: CircularProgressIndicator())
//                   : ListView.builder(
//                       physics: const NeverScrollableScrollPhysics(),
//                       shrinkWrap: true,
//                       itemCount: estates.length,
//                       itemBuilder: (context, index) {
//                         final estate = estates[index];
//                         return GestureDetector(
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => ProfileEstateScreen(
//                                   nameEn: estate['nameEn'],
//                                   nameAr: estate['nameAr'],
//                                   estateId: estate['id'],
//                                   location: "Rose Garden",
//                                   rating: estate['rating'],
//                                   fee: estate['fee'],
//                                   deliveryTime: estate['time'],
//                                   price: 32.0,
//                                   typeOfRestaurant: estate['TypeofRestaurant'],
//                                   sessions: estate['Sessions'],
//                                   menuLink: estate['MenuLink'],
//                                   entry: estate['Entry'],
//                                   music: estate['Lstmusic'],
//                                   type: estate['Type'],
//                                 ),
//                               ),
//                             );
//                           },
//                           child: EstateCard(
//                             nameEn: estate['nameEn'],
//                             estateId: estate['id'],
//                             nameAr: estate['nameAr'],
//                             rating: estate['rating'],
//                           ),
//                         );
//                       },
//                     ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:diamond_host_admin/widgets/reused_appbar.dart';
import 'package:diamond_host_admin/widgets/estate_card_widget.dart';
import 'package:flutter/material.dart';
import '../backend/customer_rate_services.dart';
import '../backend/estate_services.dart';
import '../localization/language_constants.dart';
import '../widgets/custom_drawer.dart';
import 'profile_estate_screen.dart';

class MainScreenContent extends StatefulWidget {
  const MainScreenContent({super.key});

  @override
  _MainScreenContentState createState() => _MainScreenContentState();
}

class _MainScreenContentState extends State<MainScreenContent> {
  EstateServices estateServices = EstateServices();
  CustomerRateServices customerRateServices = CustomerRateServices();
  List<Map<String, dynamic>> estates = [];
  final List<String> categories = ['Hotel', 'Restaurant', 'Coffee'];

  @override
  void initState() {
    super.initState();
    _fetchEstates();
  }

  Future<void> _fetchEstates() async {
    try {
      final data = await estateServices.fetchEstates();
      List<Map<String, dynamic>> parsedEstates = _parseEstates(data);

      for (var estate in parsedEstates) {
        final ratings =
            await customerRateServices.fetchEstateRatingWithUsers(estate['id']);

        double totalRating = 0;
        if (ratings.isNotEmpty) {
          totalRating = ratings
                  .map((e) => e['rating'] as double)
                  .reduce((a, b) => a + b) /
              ratings.length;
        }

        setState(() {
          estate['rating'] = totalRating;
          estate['ratingsList'] = ratings;
        });
      }

      setState(() {
        estates = parsedEstates;
      });
    } catch (e) {
      print("Error fetching estates: $e");
    }
  }

  List<Map<String, dynamic>> _parseEstates(Map<String, dynamic> data) {
    List<Map<String, dynamic>> estateList = [];
    data.forEach((key, value) {
      value.forEach((estateID, estateData) {
        estateList.add({
          'id': estateID,
          'nameEn': estateData['NameEn'] ?? 'Unknown',
          'nameAr': estateData['NameAr'] ?? 'غير معروف',
          'rating': 0.0,
          'fee': estateData['Fee'] ?? 'Free',
          'time': estateData['Time'] ?? '20 min',
          'TypeofRestaurant': estateData['TypeofRestaurant'] ?? 'Unknown Type',
          'Sessions': estateData['Sessions'] ?? 'Unknown Session Type',
          'MenuLink': estateData['MenuLink'] ?? 'No Menu',
          'Entry': estateData['Entry'] ?? 'Empty',
          'Lstmusic': estateData['Lstmusic'] ?? 'No music',
          'Type': estateData['Type'] ?? 'Unknown',
        });
      });
    });
    return estateList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Main Screen"),
      ),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                getTranslated(context, "All Categories"),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  IconData iconData;
                  switch (categories[index]) {
                    case 'Hotel':
                      iconData = Icons.hotel;
                      break;
                    case 'Restaurant':
                      iconData = Icons.restaurant;
                      break;
                    case 'Coffee':
                      iconData = Icons.local_cafe;
                      break;
                    default:
                      iconData = Icons.category;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        Container(
                          width: 115,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            iconData,
                            size: 40,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          categories[index],
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            estates.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: estates.length,
                    itemBuilder: (context, index) {
                      final estate = estates[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileEstateScreen(
                                nameEn: estate['nameEn'],
                                nameAr: estate['nameAr'],
                                estateId: estate['id'],
                                location: "Rose Garden",
                                rating: estate['rating'],
                                fee: estate['fee'],
                                deliveryTime: estate['time'],
                                price: 32.0,
                                typeOfRestaurant: estate['TypeofRestaurant'],
                                sessions: estate['Sessions'],
                                menuLink: estate['MenuLink'],
                                entry: estate['Entry'],
                                music: estate['Lstmusic'],
                                type: estate['Type'],
                              ),
                            ),
                          );
                        },
                        child: EstateCard(
                          nameEn: estate['nameEn'],
                          estateId: estate['id'],
                          nameAr: estate['nameAr'],
                          rating: estate['rating'],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
