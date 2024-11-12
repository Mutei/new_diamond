import 'package:diamond_host_admin/localization/language_constants.dart';
import 'package:diamond_host_admin/widgets/reused_appbar.dart';
import 'package:flutter/material.dart';
import '../widgets/estate_card_widget.dart';
import '../backend/estate_services.dart';
import '../widgets/reused_different_screen_card_widget.dart';
import 'profile_estate_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';

class HotelScreen extends StatefulWidget {
  @override
  _HotelScreenState createState() => _HotelScreenState();
}

class _HotelScreenState extends State<HotelScreen> {
  final EstateServices estateServices = EstateServices();
  List<Map<String, dynamic>> hotels = [];

  @override
  void initState() {
    super.initState();
    _fetchHotels();
  }

  Future<void> _fetchHotels() async {
    try {
      final data = await estateServices.fetchEstates();
      final parsedEstates = _parseEstates(data);

      // Process each estate and categorize hotels
      List<Map<String, dynamic>> tempHotels = [];
      for (var estate in parsedEstates) {
        estate = await _addImageToEstate(estate); // Add image to estate
        if (_isHotel(estate)) {
          tempHotels.add(estate);
        }
      }

      setState(() {
        hotels = tempHotels;
      });
    } catch (e) {
      print("Error fetching hotels: $e");
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

  bool _isHotel(Map<String, dynamic> estate) {
    return estate['Type'] == '1'; // Assuming '1' represents a hotel
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Hotels"),
      ),
      body: hotels.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: hotels.length,
              itemBuilder: (context, index) {
                final hotel = hotels[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileEstateScreen(
                          nameEn: hotel['nameEn'],
                          nameAr: hotel['nameAr'],
                          estateId: hotel['id'],
                          location: "Rose Garden",
                          rating: hotel['rating'],
                          fee: hotel['fee'],
                          deliveryTime: hotel['time'],
                          price: 32.0,
                          typeOfRestaurant: hotel['TypeofRestaurant'] ?? '',
                          sessions: hotel['Sessions'] ?? '',
                          menuLink: hotel['MenuLink'] ?? '',
                          entry: hotel['Entry'] ?? '',
                          music: hotel['Lstmusic'] ?? '',
                          type: hotel['Type'],
                        ),
                      ),
                    );
                  },
                  child: DifferentEstateCards(
                    nameEn: hotel['nameEn'],
                    nameAr: hotel['nameAr'],
                    estateId: hotel['id'],
                    rating: hotel['rating'],
                    imageUrl: hotel['imageUrl'],
                    fee: hotel['fee'],
                    time: hotel['time'],
                  ),
                );
              },
            ),
    );
  }
}
