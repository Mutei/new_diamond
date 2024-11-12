import 'package:flutter/material.dart';
import '../localization/language_constants.dart';
import '../widgets/estate_card_widget.dart';
import '../backend/estate_services.dart';
import '../widgets/reused_appbar.dart';
import '../widgets/reused_different_screen_card_widget.dart';
import '../widgets/search_text_form_field.dart';
import 'profile_estate_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RestaurantScreen extends StatefulWidget {
  @override
  _RestaurantScreenState createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  final EstateServices estateServices = EstateServices();
  List<Map<String, dynamic>> restaurants = [];
  List<Map<String, dynamic>> filteredEstates = [];
  bool loading = true;
  bool searchActive = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
    searchController.addListener(_filterEstates);
  }

  void _filterEstates() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isNotEmpty) {
        searchActive = true;
        filteredEstates = restaurants.where((estate) {
          final nameEn = estate['nameEn'].toLowerCase();
          final nameAr = estate['nameAr'].toLowerCase();
          return nameEn.contains(query) || nameAr.contains(query);
        }).toList();
      } else {
        searchActive = false;
        filteredEstates = restaurants;
      }
    });
  }

  void _clearSearch() {
    searchController.clear();
    setState(() {
      searchActive = false;
      filteredEstates = restaurants;
    });
  }

  Future<void> _fetchRestaurants() async {
    setState(() => loading = true);
    try {
      final data = await estateServices.fetchEstates();
      final parsedEstates = _parseEstates(data);

      List<Map<String, dynamic>> tempRestaurants = [];
      for (var estate in parsedEstates) {
        estate = await _addImageToEstate(estate);
        if (_isRestaurant(estate)) {
          tempRestaurants.add(estate);
        }
      }

      setState(() {
        restaurants = tempRestaurants;
        filteredEstates = restaurants;
        loading = false;
      });
    } catch (e) {
      print("Error fetching restaurants: $e");
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

  bool _isRestaurant(Map<String, dynamic> estate) {
    return estate['Type'] == '3'; // Assuming '3' represents a restaurant
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Restaurants"),
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
                          final restaurant = filteredEstates[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileEstateScreen(
                                    nameEn: restaurant['nameEn'],
                                    nameAr: restaurant['nameAr'],
                                    estateId: restaurant['id'],
                                    location: "Rose Garden",
                                    rating: restaurant['rating'],
                                    fee: restaurant['fee'],
                                    deliveryTime: restaurant['time'],
                                    price: 32.0,
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
          ),
        ],
      ),
    );
  }
}
