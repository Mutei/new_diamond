import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../backend/customer_rate_services.dart';
import '../backend/estate_services.dart';
import '../localization/language_constants.dart';
import '../widgets/reused_appbar.dart';
import '../widgets/reused_different_screen_card_widget.dart';
import '../widgets/search_text_form_field.dart';
import 'profile_estate_screen.dart';
import '../widgets/filter_dialog.dart';
import '../constants/restaurant_options.dart';

class RestaurantScreen extends StatefulWidget {
  @override
  _RestaurantScreenState createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  final EstateServices estateServices = EstateServices();
  final CustomerRateServices customerRateServices = CustomerRateServices();

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
    'valetWithFees': false,
    'isSmokingAllowed': false,
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

  String mapArabicToEnglish(String arabicLabel) {
    final match = restaurantOptions.firstWhere(
      (option) => option['labelAr'] == arabicLabel,
      orElse: () => {},
    );
    return match.isNotEmpty ? match['label'] as String : arabicLabel;
  }

  void _applyFilters() {
    setState(() {
      searchActive = true;
      filteredEstates = restaurants.where((estate) {
        bool matches = true;

        List<String> parseOptions(dynamic data) {
          if (data is List) {
            return data.cast<String>();
          } else if (data is String) {
            return data.split(',').map((e) => e.trim()).toList();
          }
          return [];
        }

        if (filterState['typeOfRestaurant'].isNotEmpty) {
          matches = matches &&
              filterState['typeOfRestaurant'].any((selectedEntry) {
                final selectedEnglishEntry = mapArabicToEnglish(selectedEntry);
                final entryData = parseOptions(estate['TypeofRestaurant']);
                return entryData.contains(selectedEnglishEntry);
              });
        }

        if (filterState['entry'].isNotEmpty) {
          matches = matches &&
              filterState['entry'].any((selectedEntry) {
                final entryData = parseOptions(estate['Entry']);
                return entryData.contains(selectedEntry);
              });
        }

        if (filterState['sessions'].isNotEmpty) {
          matches = matches &&
              filterState['sessions'].any((selectedSession) {
                final sessionsData = parseOptions(estate['Sessions']);
                return sessionsData.contains(selectedSession);
              });
        }

        if (filterState['additionals'].isNotEmpty) {
          matches = matches &&
              filterState['additionals'].any((selectedAdditional) {
                final additionalsData = parseOptions(estate['additionals']);
                return additionalsData.contains(selectedAdditional);
              });
        }

        if (filterState['music']) {
          matches = matches && estate['Music'] == '1';
        }

        if (filterState['valet'] == true) {
          if (filterState['valetWithFees'] == false) {
            matches = matches && estate['HasValet'] == '1';
          } else {
            matches = matches &&
                estate['HasValet'] == '1' &&
                estate['ValetWithFees'] == '0';
          }
        }

        if (filterState['kidsArea']) {
          matches = matches && estate['HasKidsArea'] == '1';
        }
        if (filterState['isSmokingAllowed']) {
          matches = matches && estate['IsSmokingAllowed'] == '1';
        }

        return matches;
      }).toList();

      filteredEstates.sort((a, b) {
        final locale = Localizations.localeOf(context).languageCode;
        final nameA = (locale == 'ar' ? a['nameAr'] : a['nameEn']) ?? '';
        final nameB = (locale == 'ar' ? b['nameAr'] : b['nameEn']) ?? '';

        int nameComparison = nameA.compareTo(nameB);
        if (nameComparison != 0) {
          return nameComparison;
        }

        return b['rating'].compareTo(a['rating']);
      });
    });
  }

  Future<void> _fetchRestaurants() async {
    setState(() => loading = true);
    try {
      final data = await estateServices.fetchEstates();
      final parsedEstates = await _parseAndFetchAdditionalData(data);

      List<Map<String, dynamic>> tempRestaurants =
          parsedEstates.where((estate) => _isRestaurant(estate)).toList();

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

  Future<List<Map<String, dynamic>>> _parseAndFetchAdditionalData(
      Map<String, dynamic> data) async {
    List<Map<String, dynamic>> estateList = [];
    for (var entry in data.entries) {
      for (var estateEntry in entry.value.entries) {
        var estateData = estateEntry.value;
        var estate = {
          'id': estateEntry.key,
          'nameEn': estateData['NameEn'] ?? 'Unknown',
          'nameAr': estateData['NameAr'] ?? 'غير معروف',
          'rating': 0.0,
          'fee': estateData['Fee'] ?? 'Free',
          'time': estateData['Time'] ?? '20 min',
          'Type': estateData['Type'] ?? 'Unknown',
          'TypeofRestaurant': estateData['TypeofRestaurant'] ?? '',
          'Entry': estateData['Entry'] ?? '',
          'Sessions': estateData['Sessions'] ?? '',
          'additionals': estateData['additionals'] ?? '',
          'Music': estateData['Music'] ?? '',
          'HasValet': estateData['HasValet'] ?? '0',
          'HasKidsArea': estateData['HasKidsArea'] ?? '0',
          'ValetWithFees': estateData['ValetWithFees'] ?? '0',
          'IsSmokingAllowed': estateData['IsSmokingAllowed'] ?? '0',
        };

        estate = await _addAdditionalEstateData(estate);
        estateList.add(estate);
      }
    }
    return estateList;
  }

  Future<Map<String, dynamic>> _addAdditionalEstateData(
      Map<String, dynamic> estate) async {
    final ratings =
        await customerRateServices.fetchEstateRatingWithUsers(estate['id']);
    final totalRating = ratings.isNotEmpty
        ? ratings.map((e) => e['rating'] as double).reduce((a, b) => a + b) /
            ratings.length
        : 0.0;

    final storageRef =
        FirebaseStorage.instance.ref().child('${estate['id']}/0.jpg');
    String imageUrl;
    try {
      imageUrl = await storageRef.getDownloadURL();
    } catch (e) {
      imageUrl = 'https://via.placeholder.com/150';
    }

    return estate
      ..['rating'] = totalRating
      ..['ratingsList'] = ratings
      ..['imageUrl'] = imageUrl;
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
          ..['valetWithFees'] = updatedFilterState['valetWithFees']
          ..['isSmokingAllowed'] = updatedFilterState['isSmokingAllowed']
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
                                    lstMusic: restaurant['Lstmusic'] ?? '',
                                    music: restaurant['Music'],
                                    type: restaurant['Type'],
                                    hasKidsArea: restaurant['HasKidsArea'],
                                    hasValet: restaurant['HasValet'],
                                    valetWithFees: restaurant['ValetWithFees'],
                                    hasBarber: restaurant['HasBarber'] ?? '',
                                    hasGym: restaurant['HasGym'] ?? '',
                                    hasMassage: restaurant['HasMassage'] ?? '',
                                    hasSwimmingPool:
                                        restaurant['HasSwimmingPool'] ?? '',
                                    isSmokingAllowed:
                                        restaurant['IsSmokingAllowed'] ?? '',
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
