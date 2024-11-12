// lib/screens/coffee_screen.dart

import 'package:flutter/material.dart';
import '../localization/language_constants.dart';
import '../widgets/estate_card_widget.dart';
import '../backend/estate_services.dart';
import '../widgets/reused_appbar.dart';
import '../widgets/reused_different_screen_card_widget.dart';
import 'profile_estate_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CoffeeScreen extends StatefulWidget {
  @override
  _CoffeeScreenState createState() => _CoffeeScreenState();
}

class _CoffeeScreenState extends State<CoffeeScreen> {
  final EstateServices estateServices = EstateServices();
  List<Map<String, dynamic>> coffees = [];

  @override
  void initState() {
    super.initState();
    _fetchCoffees();
  }

  Future<void> _fetchCoffees() async {
    try {
      final data = await estateServices.fetchEstates();
      final parsedEstates = _parseEstates(data);

      // Process each estate and categorize coffees
      List<Map<String, dynamic>> tempCoffees = [];
      for (var estate in parsedEstates) {
        estate = await _addImageToEstate(estate); // Add image to estate
        if (_isCoffee(estate)) {
          tempCoffees.add(estate);
        }
      }

      setState(() {
        coffees = tempCoffees;
      });
    } catch (e) {
      print("Error fetching coffees: $e");
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

  bool _isCoffee(Map<String, dynamic> estate) {
    return estate['Type'] == '2'; // Assuming '4' represents a coffee shop
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Cafes"),
      ),
      body: coffees.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: coffees.length,
              itemBuilder: (context, index) {
                final coffee = coffees[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileEstateScreen(
                          nameEn: coffee['nameEn'],
                          nameAr: coffee['nameAr'],
                          estateId: coffee['id'],
                          location: "Rose Garden", // Update as needed
                          rating: coffee['rating'],
                          fee: coffee['fee'],
                          deliveryTime: coffee['time'],
                          price: 32.0, // Update as needed or fetch dynamically
                          typeOfRestaurant: coffee['TypeofRestaurant'] ?? '',
                          sessions: coffee['Sessions'] ?? '',
                          menuLink: coffee['MenuLink'] ?? '',
                          entry: coffee['Entry'] ?? '',
                          music: coffee['Lstmusic'] ?? '',
                          type: coffee['Type'],
                        ),
                      ),
                    );
                  },
                  child: DifferentEstateCards(
                    nameEn: coffee['nameEn'],
                    nameAr: coffee['nameAr'],
                    estateId: coffee['id'],
                    rating: coffee['rating'],
                    imageUrl: coffee['imageUrl'],
                    fee: coffee['fee'],
                    time: coffee['time'],
                  ),
                );
              },
            ),
    );
  }
}
