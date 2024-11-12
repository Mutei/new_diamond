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
  List<Map<String, dynamic>> filteredEstates = [];
  bool loading = true;
  bool searchActive = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCoffees();
    searchController.addListener(_filterEstates);
  }

  void _filterEstates() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isNotEmpty) {
        searchActive = true;
        filteredEstates = coffees.where((estate) {
          final nameEn = estate['nameEn'].toLowerCase();
          final nameAr = estate['nameAr'].toLowerCase();
          return nameEn.contains(query) || nameAr.contains(query);
        }).toList();
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
      final parsedEstates = _parseEstates(data);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Cafes"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: getTranslated(context, "Search"),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
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
                                    typeOfRestaurant:
                                        coffee['TypeofRestaurant'] ?? '',
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
          ),
        ],
      ),
    );
  }
}
