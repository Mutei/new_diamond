import 'package:diamond_host_admin/widgets/coffee_filter_dialog.dart';
import 'package:flutter/material.dart';
import '../backend/customer_rate_services.dart';
import '../localization/language_constants.dart';
import '../widgets/estate_card_widget.dart';
import '../backend/estate_services.dart';
import '../widgets/reused_appbar.dart';
import '../widgets/reused_different_screen_card_widget.dart';
import '../widgets/search_text_form_field.dart';
import 'profile_estate_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CoffeeScreen extends StatefulWidget {
  @override
  _CoffeeScreenState createState() => _CoffeeScreenState();
}

class _CoffeeScreenState extends State<CoffeeScreen> {
  final EstateServices estateServices = EstateServices();
  List<Map<String, dynamic>> coffees = [];
  List<Map<String, dynamic>> filteredEstates = [];
  bool loading = true;
  bool searchActive = false;
  final CustomerRateServices customerRateServices = CustomerRateServices();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCoffees();
    searchController.addListener(_filterEstates);
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
          'rating': 0.0, // Initial rating
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
        };

        estate = await _addAdditionalEstateData(estate);
        estateList.add(estate);
      }
    }
    return estateList;
  }

  Future<Map<String, dynamic>> _addAdditionalEstateData(
      Map<String, dynamic> estate) async {
    // Fetch ratings
    final ratings =
        await customerRateServices.fetchEstateRatingWithUsers(estate['id']);
    final totalRating = ratings.isNotEmpty
        ? ratings.map((e) => e['rating'] as double).reduce((a, b) => a + b) /
            ratings.length
        : 0.0;

    // Fetch image URL
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

  void _filterEstates() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isNotEmpty) {
        searchActive = true;

        // Sort results based on the search query
        filteredEstates = coffees.where((estate) {
          final nameEn = estate['nameEn'].toLowerCase();
          final nameAr = estate['nameAr'].toLowerCase();
          return nameEn.contains(query) || nameAr.contains(query);
        }).toList();

        // Sort to prioritize matches starting with the query
        filteredEstates.sort((a, b) {
          final nameEnA = a['nameEn'].toLowerCase();
          final nameArA = a['nameAr'].toLowerCase();
          final nameEnB = b['nameEn'].toLowerCase();
          final nameArB = b['nameAr'].toLowerCase();

          // Prioritize names starting with the query
          if (nameEnA.startsWith(query) || nameArA.startsWith(query)) {
            return -1; // a comes before b
          }
          if (nameEnB.startsWith(query) || nameArB.startsWith(query)) {
            return 1; // b comes before a
          }

          // Otherwise, maintain alphabetical order
          return nameEnA.compareTo(nameEnB);
        });
      } else {
        searchActive = false;
        filteredEstates = coffees;
      }
    });
  }

  void _clearSearch() {
    searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      searchActive = false;
      filteredEstates = coffees;
    });
  }

  Future<void> _fetchCoffees() async {
    setState(() => loading = true);
    try {
      final data = await estateServices.fetchEstates();
      final parsedEstates = await _parseAndFetchAdditionalData(data);

      List<Map<String, dynamic>> tempCoffees = [];
      for (var estate in parsedEstates) {
        estate = await _addImageToEstate(estate);
        if (_isCoffee(estate)) {
          tempCoffees.add(estate);
        }
      }

      setState(() {
        coffees = tempCoffees;
        filteredEstates = coffees;
        loading = false;
      });
    } catch (e) {
      print("Error fetching coffees: $e");
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

  bool _isCoffee(Map<String, dynamic> estate) {
    return estate['Type'] == '2'; // Assuming '2' represents a coffee shop
  }

  final Map<String, dynamic> filterState = {
    'typeOfRestaurant': <String>[],
    'entry': <String>[],
    'sessions': <String>[],
    'additionals': <String>[],
    'music': false,
    'valet': null,
    'kidsArea': false,
    'valetWithFees': false,
  };
  void _applyFilters() {
    setState(() {
      searchActive = true; // Indicate that filtering is active
      filteredEstates = coffees.where((estate) {
        bool matches = true;

        // Helper function to handle both comma-separated strings and lists
        List<String> parseOptions(dynamic data) {
          if (data is List) {
            return data.cast<String>();
          } else if (data is String) {
            return data.split(',').map((e) => e.trim()).toList();
          }
          return [];
        }

        // Match Entry filter
        if (filterState['entry'].isNotEmpty) {
          matches = matches &&
              filterState['entry'].any((selectedEntry) {
                final entryData = parseOptions(estate['Entry']);
                return entryData.contains(selectedEntry);
              });
        }

        // Match Sessions filter
        if (filterState['sessions'].isNotEmpty) {
          matches = matches &&
              filterState['sessions'].any((selectedSession) {
                final sessionsData = parseOptions(estate['Sessions']);
                return sessionsData.contains(selectedSession);
              });
        }

        // Match Additionals filter
        if (filterState['additionals'].isNotEmpty) {
          matches = matches &&
              filterState['additionals'].any((selectedAdditional) {
                final additionalsData = parseOptions(estate['additionals']);
                return additionalsData.contains(selectedAdditional);
              });
        }

        // Match Music filter
        if (filterState['music']) {
          matches = matches && estate['Music'] == '1';
        }

        if (filterState['valetWithFees'] != null) {
          matches = matches &&
              estate['ValetWithFees'] ==
                  (filterState['valetWithFees'] ? '0' : '1');
        }

        // Match Valet filter
        if (filterState['valet'] != null) {
          matches = matches &&
              estate['HasValet'] == (filterState['valet'] ? '1' : '0');
        }

        // Match Kids Area filter
        if (filterState['kidsArea']) {
          matches = matches && estate['HasKidsArea'] == '1';
        }

        return matches;
      }).toList();

      // Sorting Logic: Example by nameEn (alphabetically), then by rating (descending)
      filteredEstates.sort((a, b) {
        final locale = Localizations.localeOf(context).languageCode;
        final nameA = (locale == 'ar' ? a['nameAr'] : a['nameEn']) ?? '';
        final nameB = (locale == 'ar' ? b['nameAr'] : b['nameEn']) ?? '';

        // Primary sorting by name (alphabetical order)
        int nameComparison = nameA.compareTo(nameB);
        if (nameComparison != 0) {
          return nameComparison;
        }

        // Secondary sorting by rating (descending)
        return b['rating'].compareTo(a['rating']);
      });
    });
  }

  void _showFilterDialog() async {
    final updatedFilterState = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CoffeeFilterDialog(
          initialFilterState: filterState,
        );
      },
    );

    if (updatedFilterState != null) {
      setState(() {
        filterState
          ..['entry'] = updatedFilterState['entry']
          ..['sessions'] = updatedFilterState['sessions']
          ..['additionals'] = updatedFilterState['additionals']
          ..['music'] = updatedFilterState['music']
          ..['valet'] = updatedFilterState['valet']
          ..['kidsArea'] = updatedFilterState['kidsArea']
          ..['valetWithFees'] = updatedFilterState['valetWithFees'];
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Cafes"),
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
                          final coffee = filteredEstates[index];
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
                                    price: 32.0, // Update or fetch dynamically
                                    music: coffee['Music'],
                                    typeOfRestaurant:
                                        coffee['TypeofRestaurant'] ?? '',
                                    sessions: coffee['Sessions'] ?? '',
                                    menuLink: coffee['MenuLink'] ?? '',
                                    entry: coffee['Entry'] ?? '',
                                    lstMusic: coffee['Lstmusic'] ?? '',
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
          ),
        ],
      ),
    );
  }
}
