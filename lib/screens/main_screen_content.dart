import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../backend/customer_rate_services.dart';
import '../backend/estate_services.dart';
import '../localization/language_constants.dart';
import '../widgets/reused_appbar.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/estate_card_widget.dart';
import '../widgets/search_text_form_field.dart';
import 'profile_estate_screen.dart';
import 'hotel_screen.dart';
import 'restaurant_screen.dart';
import 'coffee_screen.dart';
import 'package:auto_size_text/auto_size_text.dart';

class MainScreenContent extends StatefulWidget {
  const MainScreenContent({super.key});

  @override
  _MainScreenContentState createState() => _MainScreenContentState();
}

class _MainScreenContentState extends State<MainScreenContent> {
  final EstateServices estateServices = EstateServices();
  final CustomerRateServices customerRateServices = CustomerRateServices();

  final List<String> categories = ['Hotel', 'Restaurant', 'Coffee'];
  List<Map<String, dynamic>> estates = [];
  List<Map<String, dynamic>> filteredEstates = [];
  bool loading = true;
  bool searchActive = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEstates();
    searchController.addListener(_filterEstates);
  }

  Future<void> _fetchEstates() async {
    setState(() => loading = true);
    try {
      final data = await estateServices.fetchEstates();
      final parsedEstates = await _parseAndFetchAdditionalData(data);

      setState(() {
        estates = parsedEstates;
        filteredEstates = estates;
        loading = false;
      });
    } catch (e) {
      print("Error fetching estates: $e");
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
          'TypeofRestaurant': estateData['TypeofRestaurant'] ?? 'Unknown Type',
          'Sessions': estateData['Sessions'] ?? 'Unknown Session Type',
          'MenuLink': estateData['MenuLink'] ?? 'No Menu',
          'Entry': estateData['Entry'] ?? 'Empty',
          'Lstmusic': estateData['Lstmusic'] ?? 'No music',
          'Music': estateData['Music'] ?? 'No music',
          'Type': estateData['Type'] ?? 'Unknown',
          'HasKidsArea': estateData['HasKidsArea'] ?? 'No Kids Allowed',
          'HasValet': estateData['HasValet'] ?? "No valet",
          'ValetWithFees': estateData['ValetWithFees'] ?? "No fees",
          'HasBarber': estateData['HasBarber'] ?? "No Barber",
          'HasMassage': estateData['HasMassage'] ?? "No massage",
          'HasSwimmingPool':
              estateData['HasSwimmingPool'] ?? "No Swimming Pool",
          'HasGym': estateData['HasGym'] ?? "No Gym",
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

  void _filterEstates() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isNotEmpty) {
        searchActive = true;
        filteredEstates = estates.where((estate) {
          final nameEn = estate['nameEn'].toLowerCase();
          final nameAr = estate['nameAr'].toLowerCase();
          return nameEn.contains(query) || nameAr.contains(query);
        }).toList();
      } else {
        searchActive = false;
        filteredEstates = estates;
      }
    });
  }

  void _clearSearch() {
    searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      searchActive = false;
      filteredEstates = estates;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Main Screen"),
      ),
      drawer: const CustomDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
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
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!searchActive) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Text(
                                  getTranslated(context, "All Categories"),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.titleLarge?.color,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 130,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  itemCount: categories.length,
                                  itemBuilder: (context, index) {
                                    final category = categories[index];
                                    final iconData = _getCategoryIcon(category);

                                    return GestureDetector(
                                      onTap: () {
                                        switch (category) {
                                          case 'Hotel':
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        HotelScreen()));
                                            break;
                                          case 'Restaurant':
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        RestaurantScreen()));
                                            break;
                                          case 'Coffee':
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        CoffeeScreen()));
                                            break;
                                        }
                                      },
                                      child: Container(
                                        width: 110,
                                        margin:
                                            const EdgeInsets.only(right: 16.0),
                                        child: Column(
                                          children: [
                                            AnimatedContainer(
                                              duration:
                                                  Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: isDarkMode
                                                      ? [
                                                          Colors.deepPurple
                                                              .shade700,
                                                          Colors.indigo.shade700
                                                        ]
                                                      : [
                                                          Colors.deepPurple,
                                                          Colors.indigo
                                                        ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Icon(iconData,
                                                  size: 40,
                                                  color: Colors.white),
                                              padding: EdgeInsets.all(20),
                                            ),
                                            const SizedBox(
                                                height: 4), // Adjusted height
                                            AutoSizeText(
                                              category,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: theme
                                                    .textTheme.bodyLarge?.color,
                                              ),
                                              maxLines: 1,
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            _buildSection(
                                "Hotels",
                                filteredEstates
                                    .where((estate) => estate['Type'] == '1')
                                    .toList()),
                            _buildSection(
                                "Restaurants",
                                filteredEstates
                                    .where((estate) => estate['Type'] == '3')
                                    .toList()),
                            _buildSection(
                                "Cafes",
                                filteredEstates
                                    .where((estate) => estate['Type'] == '2')
                                    .toList()),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> estatesList) {
    if (estatesList.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              getTranslated(context, title),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: estatesList.length,
              itemBuilder: (context, index) {
                final estate = estatesList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileEstateScreen(
                            nameEn: estate['nameEn'],
                            nameAr: estate['nameAr'],
                            estateId: estate['id'],
                            location: "Rose Garden",
                            rating: estate['rating'],
                            fee: estate['fee'],
                            deliveryTime: estate['time'],
                            price: 32.0,
                            typeOfRestaurant: estate['TypeofRestaurant'],
                            sessions: estate['Sessions'],
                            menuLink: estate['MenuLink'],
                            entry: estate['Entry'],
                            lstMusic: estate['Lstmusic'],
                            music: estate['Music'],
                            type: estate['Type'],
                            hasKidsArea: estate['HasKidsArea'],
                            hasValet: estate['HasValet'],
                            valetWithFees: estate['ValetWithFees'],
                            hasGym: estate['HasGym'],
                            hasBarber: estate['HasBarber'],
                            hasMassage: estate['HasMassage'],
                            hasSwimmingPool: estate['HasSwimmingPool']),
                      ),
                    );
                  },
                  child: EstateCard(
                    nameEn: estate['nameEn'],
                    nameAr: estate['nameAr'],
                    estateId: estate['id'],
                    rating: estate['rating'],
                    imageUrl: estate['imageUrl'],
                    fee: estate['fee'],
                    time: estate['time'],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Hotel':
        return Icons.hotel;
      case 'Restaurant':
        return Icons.restaurant;
      case 'Coffee':
        return Icons.local_cafe;
      default:
        return Icons.category;
    }
  }
}
