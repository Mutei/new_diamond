import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../backend/customer_rate_services.dart';
import '../backend/estate_services.dart';
import '../localization/language_constants.dart';
import '../widgets/reused_appbar.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/estate_card_widget.dart';
import 'profile_estate_screen.dart';
import 'hotel_screen.dart'; // Import hotel screen
import 'restaurant_screen.dart'; // Import restaurant screen
import 'coffee_screen.dart'; // Import coffee screen

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
  List<Map<String, dynamic>> hotels = [];
  List<Map<String, dynamic>> restaurants = [];
  List<Map<String, dynamic>> cafes = [];

  @override
  void initState() {
    super.initState();
    _fetchEstates();
  }

  Future<void> _fetchEstates() async {
    try {
      final data = await estateServices.fetchEstates();
      final parsedEstates = _parseEstates(data);

      for (var estate in parsedEstates) {
        estate = await _addAdditionalEstateData(estate);
        _categorizeEstates(estate);
      }

      setState(() {
        estates = parsedEstates;
      });
    } catch (e) {
      print("Error fetching estates: $e");
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
          'rating': 0.0,
          'fee': estateData['Fee'] ?? 'Free',
          'time': estateData['Time'] ?? '20 min',
          'TypeofRestaurant': estateData['TypeofRestaurant'] ?? 'Unknown Type',
          'Sessions': estateData['Sessions'] ?? 'Unknown Session Type',
          'MenuLink': estateData['MenuLink'] ?? 'No Menu',
          'Entry': estateData['Entry'] ?? 'Empty',
          'Lstmusic': estateData['Lstmusic'] ?? 'No music',
          'Type': estateData['Type'] ?? 'Unknown',
        });
      });
    });
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

  void _categorizeEstates(Map<String, dynamic> estate) {
    switch (estate['Type']) {
      case '1':
        hotels.add(estate);
        break;
      case '3':
        restaurants.add(estate);
        break;
      case '2':
        cafes.add(estate);
        break;
      default:
        break;
    }
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

  @override
  Widget build(BuildContext context) {
    // Access current theme
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Main Screen"),
      ),
      drawer: const CustomDrawer(),
      backgroundColor:
          theme.scaffoldBackgroundColor, // Use theme's background color
      body: estates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      getTranslated(context, "All Categories"),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge
                            ?.color, // Use theme's text color
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final iconData = _getCategoryIcon(category);

                        return GestureDetector(
                          onTap: () {
                            // Directly push to the respective screen
                            switch (category) {
                              case 'Hotel':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HotelScreen(),
                                  ),
                                );
                                break;
                              case 'Restaurant':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RestaurantScreen(),
                                  ),
                                );
                                break;
                              case 'Coffee':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CoffeeScreen(),
                                  ),
                                );
                                break;
                              default:
                                break;
                            }
                          },
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 16.0),
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDarkMode
                                          ? [
                                              Colors.deepPurple.shade700,
                                              Colors.indigo.shade700
                                            ]
                                          : [
                                              Colors.deepPurple,
                                              Colors.indigo,
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(iconData,
                                      size: 40, color: Colors.white),
                                  padding: EdgeInsets.all(20),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSection("Hotels", hotels),
                  _buildSection("Restaurants", restaurants),
                  _buildSection("Cafes", cafes),
                  const SizedBox(height: 16),
                ],
              ),
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
                          music: estate['Lstmusic'],
                          type: estate['Type'],
                        ),
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
}
