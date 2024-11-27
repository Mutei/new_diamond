import 'package:diamond_host_admin/localization/language_constants.dart';
import 'package:diamond_host_admin/widgets/hotel_filter_dialog.dart';
import 'package:diamond_host_admin/widgets/reused_appbar.dart';
import 'package:flutter/material.dart';
import '../backend/customer_rate_services.dart';
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
  final CustomerRateServices customerRateServices = CustomerRateServices();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHotels();
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
          'HasMassage': estateData['HasMassage'] ?? '0',
          'HasSwimmingPool': estateData['HasSwimmingPool'] ?? '0',
          'HasBarber': estateData['HasBarber'] ?? '0',
          'IsThereBreakfastLounge': estateData['IsThereBreakfastLounge'] ?? '0',
          'IsThereLaunchLounge': estateData['IsThereLaunchLounge'] ?? '0',
          'IsThereDinnerLounge': estateData['IsThereDinnerLounge'] ?? '0',
          'IsSmokingAllowed': estateData['IsSmokingAllowed'] ?? '0',
          'HasJacuzziInRoom': estateData['HasJacuzziInRoom'] ?? '0',
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
      final parsedEstates = await _parseAndFetchAdditionalData(data);

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

  final Map<String, dynamic> filterState = {
    'entry': <String>[],
    'sessions': <String>[],
    'additionals': <String>[],
    'music': false,
    'valet': null,
    'kidsArea': false,
    'isSmokingAllowed': false,
    'valetWithFees': false,
    'massage': false,
    'gym': false,
    'barber': false,
    'swimmingPool': false,
    'isThereBreakfastLounge': false,
    'isThereLaunchLounge': false,
    'isThereDinnerLounge': false,
    'hasJacuzziInRoom': false,
    'lstMusic': <String>[],
  };
  void _showFilterDialog() async {
    final updatedFilterState = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return HotelFilterDialog(
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
          ..['valetWithFees'] = updatedFilterState['valetWithFees']
          ..['lstMusic'] = updatedFilterState['lstMusic']
          ..['swimmingPool'] = updatedFilterState['swimmingPool']
          ..['gym'] = updatedFilterState['gym']
          ..['barber'] = updatedFilterState['barber']
          ..['massage'] = updatedFilterState['massage']
          ..['isThereBreakfastLounge'] =
              updatedFilterState['isThereBreakfastLounge']
          ..['isThereLaunchLounge'] = updatedFilterState['isThereLaunchLounge']
          ..['isSmokingAllowed'] = updatedFilterState['isSmokingAllowed']
          ..['hasJacuzziInRoom'] = updatedFilterState['hasJacuzziInRoom']
          ..['isThereDinnerLounge'] = updatedFilterState['isThereDinnerLounge'];

        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    setState(() {
      searchActive = true; // Indicate that filtering is active
      filteredEstates = hotels.where((estate) {
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

        // Match Entry filter
        // if (filterState['lstMusic'].isNotEmpty) {
        //   matches = matches &&
        //       filterState['lstMusic'].any((selectedEntry) {
        //         final lstMusicData = parseOptions(estate['Lstmusic']);
        //         return lstMusicData.contains(selectedEntry);
        //       });
        // }

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
        // if (filterState['music']) {
        //   matches = matches && estate['Music'] == '1';
        // }

        // Match Valet filter
        if (filterState['valet'] == true) {
          if (filterState['valetWithFees'] == false) {
            // Show all cafes with valet service (both with and without fees)
            matches = matches && estate['HasValet'] == '1';
          } else {
            // Show only cafes with valet service and no fees
            matches = matches &&
                estate['HasValet'] == '1' &&
                estate['ValetWithFees'] == '0';
          }
        }

        // Match Kids Area filter
        if (filterState['kidsArea']) {
          matches = matches && estate['HasKidsArea'] == '1';
        }
        if (filterState['hasJacuzziInRoom']) {
          matches = matches && estate['HasJacuzziInRoom'] == '1';
        }
        if (filterState['gym']) {
          matches = matches && estate['HasGym'] == '1';
        }
        if (filterState['isSmokingAllowed']) {
          matches = matches && estate['IsSmokingAllowed'] == '1';
        }
        if (filterState['barber']) {
          matches = matches && estate['HasBarber'] == '1';
        }
        if (filterState['massage']) {
          matches = matches && estate['HasMassage'] == '1';
        }
        if (filterState['swimmingPool']) {
          matches = matches && estate['HasSwimmingPool'] == '1';
        }
        if (filterState['isThereBreakfastLounge']) {
          matches = matches && estate['IsThereBreakfastLounge'] == '1';
        }
        if (filterState['isThereLaunchLounge']) {
          matches = matches && estate['IsThereLaunchLounge'] == '1';
        }
        if (filterState['isThereDinnerLounge']) {
          matches = matches && estate['IsThereDinnerLounge'] == '1';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Hotels"),
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
                                    music: hotel['Music'],
                                    typeOfRestaurant:
                                        hotel['TypeofRestaurant'] ?? '',
                                    sessions: hotel['Sessions'] ?? '',
                                    menuLink: hotel['MenuLink'] ?? '',
                                    entry: hotel['Entry'] ?? '',
                                    lstMusic: hotel['Lstmusic'] ?? '',
                                    type: hotel['Type'] ?? '',
                                    hasKidsArea: hotel['HasKidsArea'] ?? '',
                                    hasValet: hotel['HasValet'] ?? '',
                                    valetWithFees: hotel['ValetWithFees'] ?? '',
                                    hasBarber: hotel['HasBarber'] ?? '',
                                    hasGym: hotel['HasGym'] ?? '',
                                    hasMassage: hotel['HasMassage'] ?? '',
                                    hasSwimmingPool:
                                        hotel['HasSwimmingPool'] ?? '',
                                    isSmokingAllowed:
                                        hotel['IsSmokingAllowed'] ?? '',
                                    hasJacuzziInRoom: hotel['HasJacuzziInRoom'],
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
