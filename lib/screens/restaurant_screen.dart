import 'package:flutter/material.dart';
import '../localization/language_constants.dart';
import '../widgets/estate_card_widget.dart';
import '../backend/estate_services.dart';
import '../widgets/reused_appbar.dart';
import '../widgets/reused_different_screen_card_widget.dart';
import 'profile_estate_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RestaurantScreen extends StatefulWidget {
  @override
  _RestaurantScreenState createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  final EstateServices estateServices = EstateServices();
  List<Map<String, dynamic>> restaurants = [];

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    try {
      final data = await estateServices.fetchEstates();
      final parsedEstates = _parseEstates(data);

      // Process each estate and categorize restaurants
      List<Map<String, dynamic>> tempRestaurants = [];
      for (var estate in parsedEstates) {
        estate = await _addImageToEstate(estate); // Add image to estate
        if (_isRestaurant(estate)) {
          tempRestaurants.add(estate);
        }
      }

      setState(() {
        restaurants = tempRestaurants;
      });
    } catch (e) {
      print("Error fetching restaurants: $e");
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
          'rating': estateData['Rating'] ?? 0.0,
          'fee': estateData['Fee'] ?? 'Free',
          'time': estateData['Time'] ?? '20 min',
          'Type': estateData['Type'] ?? 'Unknown',
          // Add other necessary fields here
        });
      });
    });
    return estateList;
  }

  Future<Map<String, dynamic>> _addImageToEstate(
      Map<String, dynamic> estate) async {
    final storageRef =
        FirebaseStorage.instance.ref().child('${estate['id']}/0.jpg');
    try {
      estate['imageUrl'] = await storageRef.getDownloadURL();
    } catch (e) {
      estate['imageUrl'] = 'https://via.placeholder.com/150';
    }
    return estate;
  }

  bool _isRestaurant(Map<String, dynamic> estate) {
    return estate['Type'] == '3'; // Assuming '3' represents a restaurant
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Restaurants"),
      ),
      body: restaurants.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileEstateScreen(
                          nameEn: restaurant['nameEn'],
                          nameAr: restaurant['nameAr'],
                          estateId: restaurant['id'],
                          location: "Rose Garden", // Update as needed
                          rating: restaurant['rating'],
                          fee: restaurant['fee'],
                          deliveryTime: restaurant['time'],
                          price: 32.0, // Update as needed or fetch dynamically
                          typeOfRestaurant:
                              restaurant['TypeofRestaurant'] ?? '',
                          sessions: restaurant['Sessions'] ?? '',
                          menuLink: restaurant['MenuLink'] ?? '',
                          entry: restaurant['Entry'] ?? '',
                          music: restaurant['Lstmusic'] ?? '',
                          type: restaurant['Type'],
                        ),
                      ),
                    );
                  },
                  child: DifferentEstateCards(
                    nameEn: restaurant['nameEn'],
                    nameAr: restaurant['nameAr'],
                    estateId: restaurant['id'],
                    rating: restaurant['rating'],
                    imageUrl: restaurant['imageUrl'],
                    fee: restaurant['fee'],
                    time: restaurant['time'],
                  ),
                );
              },
            ),
    );
  }
}
