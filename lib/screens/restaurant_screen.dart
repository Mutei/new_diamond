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
      filteredEstates = restaurants.where((estate) {
        if (filterState['typeOfRestaurant'].isNotEmpty) {
          if (!filterState['typeOfRestaurant']
              .contains(estate['TypeofRestaurant'])) {
            return false;
          }
        }
        if (filterState['entry'].isNotEmpty) {
          if (!filterState['entry'].contains(estate['Entry'])) {
            return false;
          }
        }
        if (filterState['sessions'].isNotEmpty) {
          if (!filterState['sessions'].contains(estate['Sessions'])) {
            return false;
          }
        }
        if (filterState['additionals'].isNotEmpty) {
          if (!filterState['additionals'].contains(estate['additionals'])) {
            return false;
          }
        }
        if (filterState['music'] && estate['Music'] != '1') {
          return false;
        }
        if (filterState['valet'] != null &&
            estate['HasValet'] != (filterState['valet'] ? '1' : '0')) {
          return false;
        }
        if (filterState['kidsArea'] && estate['HasKidsArea'] != '1') {
          return false;
        }
        return true;
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

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    getTranslated(context, "Filters"),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildFilterSection(
                    context,
                    "Type of Restaurant",
                    filterState['typeOfRestaurant'],
                    ["Popular restaurant", "Indian Restaurant", "Seafood"],
                    setModalState,
                  ),
                  _buildFilterSection(
                    context,
                    "Entry",
                    filterState['entry'],
                    ["Single", "Family"],
                    setModalState,
                  ),
                  SwitchListTile(
                    title: Text(getTranslated(context, "Music")),
                    value: filterState['music'],
                    onChanged: (value) {
                      setModalState(() => filterState['music'] = value);
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    child: Text(getTranslated(context, "Apply")),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(
      BuildContext context,
      String title,
      List<String> selectedOptions,
      List<String> options,
      StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslated(context, title),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setModalState(() {
                  if (selected) {
                    selectedOptions.add(option);
                  } else {
                    selectedOptions.remove(option);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
      ],
    );
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
