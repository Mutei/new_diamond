import 'package:diamond_host_admin/constants/styles.dart';
import 'package:flutter/material.dart';
import '../localization/language_constants.dart';
import '../widgets/estate_card_widget.dart';
import '../backend/estate_services.dart';
import '../widgets/reused_appbar.dart';
import '../widgets/reused_different_screen_card_widget.dart';
import '../widgets/search_text_form_field.dart';
import 'profile_estate_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../constants/restaurant_options.dart';
import '../widgets/filter_dialog.dart';

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
  final Map<String, dynamic> filterState = {
    'typeOfRestaurant': <String>[],
    'entry': <String>[],
    'sessions': <String>[],
    'additionals': <String>[],
    'music': false,
    'valet': null,
    'kidsArea': false,
  };

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
    searchController.addListener(_filterEstates);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterEstates);
    searchController.dispose();
    super.dispose();
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
        _applyFilters();
      }
    });
  }

  void _applyFilters() {
    setState(() {
      searchActive = true; // Indicate that filtering is active
      filteredEstates = restaurants.where((estate) {
        bool matches = true;

        // Check each filter individually
        if (filterState['typeOfRestaurant'].isNotEmpty) {
          matches = matches &&
              filterState['typeOfRestaurant']
                  .contains(estate['TypeofRestaurant']);
        }
        if (filterState['entry'].isNotEmpty) {
          matches = matches && filterState['entry'].contains(estate['Entry']);
        }
        if (filterState['sessions'].isNotEmpty) {
          matches =
              matches && filterState['sessions'].contains(estate['Sessions']);
        }
        if (filterState['additionals'].isNotEmpty) {
          matches = matches &&
              filterState['additionals'].contains(estate['additionals']);
        }
        if (filterState['music']) {
          matches = matches && estate['Music'] == '1';
        }
        if (filterState['valet'] != null) {
          matches = matches &&
              estate['HasValet'] == (filterState['valet'] ? '1' : '0');
        }
        if (filterState['kidsArea']) {
          matches = matches && estate['HasKidsArea'] == '1';
        }

        return matches;
      }).toList();
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
          'TypeofRestaurant': estateData['TypeofRestaurant']?.toString() ?? '',
          'Entry': estateData['Entry']?.toString() ?? '',
          'Sessions': estateData['Sessions']?.toString() ?? '',
          'additionals': estateData['additionals']?.toString() ?? '',
          'Music': estateData['Music']?.toString() ?? '',
          'HasValet': estateData['HasValet']?.toString() ?? '0',
          'HasKidsArea': estateData['HasKidsArea']?.toString() ?? '0',
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
    return estate['Type'] == '3';
  }

  void _showFilterDialog() async {
    final updatedFilterState = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FilterDialog(
          initialFilterState: filterState,
        );
      },
    );

    if (updatedFilterState != null) {
      setState(() {
        filterState
          ..['typeOfRestaurant'] = updatedFilterState['typeOfRestaurant']
          ..['entry'] = updatedFilterState['entry']
          ..['sessions'] = updatedFilterState['sessions']
          ..['additionals'] = updatedFilterState['additionals']
          ..['music'] = updatedFilterState['music']
          ..['valet'] = updatedFilterState['valet']
          ..['kidsArea'] = updatedFilterState['kidsArea'];
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Restaurants"),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchTextField(
              controller: searchController,
              onClear: () {
                FocusScope.of(context).unfocus();
                searchController.clear();
                setState(() {
                  searchActive = false;
                  filteredEstates = restaurants;
                });
              },
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
                          style: kSecondaryStyle,
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
                                    music: restaurant['Music'] ?? '',
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
