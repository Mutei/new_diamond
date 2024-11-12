import 'package:diamond_host_admin/localization/language_constants.dart';
import 'package:diamond_host_admin/widgets/reused_appbar.dart';
import 'package:flutter/material.dart';
import '../widgets/estate_card_widget.dart';
import '../backend/estate_services.dart';
import '../widgets/reused_different_screen_card_widget.dart';
import '../widgets/search_text_form_field.dart';
import 'profile_estate_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';

class HotelScreen extends StatefulWidget {
  @override
  _HotelScreenState createState() => _HotelScreenState();
}

class _HotelScreenState extends State<HotelScreen> {
  final EstateServices estateServices = EstateServices();
  List<Map<String, dynamic>> hotels = [];
  List<Map<String, dynamic>> filteredEstates = [];
  bool loading = true;
  bool searchActive = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHotels();
    searchController.addListener(_filterEstates);
  }

  void _filterEstates() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isNotEmpty) {
        searchActive = true;
        filteredEstates = hotels.where((estate) {
          final nameEn = estate['nameEn'].toLowerCase();
          final nameAr = estate['nameAr'].toLowerCase();
          return nameEn.contains(query) || nameAr.contains(query);
        }).toList();
      } else {
        searchActive = false;
        filteredEstates = hotels;
      }
    });
  }

  void _clearSearch() {
    searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      searchActive = false;
      filteredEstates = hotels;
    });
  }

  Future<void> _fetchHotels() async {
    setState(() => loading = true);
    try {
      final data = await estateServices.fetchEstates();
      final parsedEstates = _parseEstates(data);

      List<Map<String, dynamic>> tempHotels = [];
      for (var estate in parsedEstates) {
        estate = await _addImageToEstate(estate);
        if (_isHotel(estate)) {
          tempHotels.add(estate);
        }
      }

      setState(() {
        hotels = tempHotels;
        filteredEstates = hotels;
        loading = false;
      });
    } catch (e) {
      print("Error fetching hotels: $e");
      setState(() => loading = false);
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchTextField(
              controller: searchController,
              onClear: _clearSearch,
              onChanged: (value) => _filterEstates(),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : searchActive && filteredEstates.isEmpty
                    ? Center(
                        child: Text(
                          getTranslated(context, "No results found"),
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredEstates.length,
                        itemBuilder: (context, index) {
                          final hotel = filteredEstates[index];
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
                                    typeOfRestaurant:
                                        hotel['TypeofRestaurant'] ?? '',
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
          ),
        ],
      ),
    );
  }
}
