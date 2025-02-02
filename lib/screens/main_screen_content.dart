import 'dart:math';
import 'package:diamond_host_admin/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart'; // Added
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool permissionsChecked = false;

  final TextEditingController searchController = TextEditingController();

  // User's current location
  double currentLat = 0.0;
  double currentLon = 0.0;

  // Maximum distance to consider as "nearby" in meters
  static const double maxNearbyDistance = 5000; // 5 kilometers

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterEstates);
    _checkPermissionsAndFetchData();
  }

  Future<void> _initializePermissions() async {
    // Handle notification permissions or any other required permissions here
    PermissionStatus notificationStatus = await Permission.notification.status;
    if (notificationStatus.isDenied || notificationStatus.isRestricted) {
      notificationStatus = await Permission.notification.request();
    }

    if (notificationStatus.isPermanentlyDenied) {
      _showPermissionDialog(
        "Notification Permission Required",
        "Please enable notification permission in settings.",
      );
    }
  }

  void _showPermissionDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPermissionsAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    permissionsChecked = prefs.getBool('permissionsChecked') ?? false;

    if (!permissionsChecked) {
      await _initializePermissions();
      await prefs.setBool('permissionsChecked', true);
    }

    // Fetch the actual current location
    await _fetchCurrentLocation();

    // Fetch estates after obtaining the location
    _fetchEstates();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showPermissionDialog(
          "Location Services Disabled",
          "Please enable location services to use this feature.",
        );
        setState(() {
          currentLat = 0.0;
          currentLon = 0.0;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDialog(
            "Location Permission Denied",
            "Please grant location permission to use this feature.",
          );
          setState(() {
            currentLat = 0.0;
            currentLon = 0.0;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog(
          "Location Permission Permanently Denied",
          "Please enable location permissions in settings.",
        );
        setState(() {
          currentLat = 0.0;
          currentLon = 0.0;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentLat = position.latitude;
        currentLon = position.longitude;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('currentLat', currentLat);
      await prefs.setDouble('currentLon', currentLon);
    } catch (e) {
      print("Error fetching location: $e");
      setState(() {
        currentLat = 0.0;
        currentLon = 0.0;
      });
    }
  }

  /// Calculate estimated time range based on distance
  String calculateTimeRange(double distanceMeters) {
    // Define min and max speed in meters per second
    const double minSpeed = 30 * 1000 / 3600; // 30 km/h
    const double maxSpeed = 50 * 1000 / 3600; // 50 km/h

    double minTimeSec = distanceMeters / maxSpeed;
    double maxTimeSec = distanceMeters / minSpeed;

    int minMinutes = (minTimeSec / 60).ceil();
    int maxMinutes = (maxTimeSec / 60).ceil();

    // Ensure minMinutes is less than or equal to maxMinutes
    if (minMinutes > maxMinutes) {
      var temp = minMinutes;
      minMinutes = maxMinutes;
      maxMinutes = temp;
    }

    return "$minMinutes-$maxMinutes mins";
  }

  Future<void> _fetchEstates() async {
    setState(() => loading = true);
    try {
      final data = await estateServices.fetchEstates();
      final parsedEstates = await _parseAndFetchAdditionalData(data);

      final estatesWithDistance = parsedEstates.map((estate) {
        double estateLat = estate['Lat'] ?? 0.0;
        double estateLon = estate['Lon'] ?? 0.0;
        double distance = calculateDistanceMeters(
            currentLat, currentLon, estateLat, estateLon);

        String timeRange = calculateTimeRange(distance);

        estate['distance'] = distance / 1000; // Keep distance for filtering
        estate['timeRange'] = timeRange; // Add timeRange

        return estate;
      }).toList();

      // Sort estates by distance (ascending)
      estatesWithDistance
          .sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        estates = estatesWithDistance;
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

        if (estateData['IsAccepted'] != "2") {
          continue;
        }

        var estate = {
          'id': estateEntry.key,
          'nameEn': estateData['NameEn'] ?? 'Unknown',
          'nameAr': estateData['NameAr'] ?? 'غير معروف',
          'rating': 0.0,
          'fee': estateData['Fee'] ?? 'Free',
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
          'IsSmokingAllowed':
              estateData['IsSmokingAllowed'] ?? "Smoking is not allowed",
          'HasJacuzziInRoom': estateData['HasJacuzziInRoom'] ?? "No Jacuzzi",
          'Lat': estateData['Lat'] ?? 0.0,
          'Lon': estateData['Lon'] ?? 0.0,
          'City': estateData['City'] ?? "No City",
          'Country': estateData['Country'] ?? "No Country"
        };

        estate = await _addAdditionalEstateData(estate);
        estateList.add(estate);
      }
    }
    return estateList;
  }

  /// Calculates distance between two coordinates in meters
  double calculateDistanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // Earth's radius in meters
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = R * c;
    return distance; // Distance in meters
  }

  double _deg2rad(double deg) {
    return deg * (pi / 180);
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

  Future<void> _refreshData() async {
    setState(() {
      loading = true;
    });
    await _checkPermissionsAndFetchData(); // Re-fetch the data
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
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
                                // Nearby Estates Section
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Text(
                                    getTranslated(context, "Nearby Places"),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.titleLarge?.color,
                                    ),
                                  ),
                                ),
                                _buildNearbyEstatesSection(),
                                const SizedBox(height: 16),

                                // Categories Section
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
                                      final localizedCategory =
                                          getTranslated(context, category);
                                      final iconData =
                                          _getCategoryIcon(category);

                                      return GestureDetector(
                                        onTap: () {
                                          if (category == 'Hotel') {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        HotelScreen()));
                                          } else if (category == 'Restaurant') {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        RestaurantScreen()));
                                          } else if (category == 'Coffee') {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        CoffeeScreen()));
                                          }
                                        },
                                        child: Container(
                                          width: 110,
                                          margin: const EdgeInsets.only(
                                              right: 16.0),
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
                                                            kPurpleColor,
                                                            Colors
                                                                .indigo.shade700
                                                          ]
                                                        : [
                                                            kPurpleColor,
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
                                              const SizedBox(height: 4),
                                              AutoSizeText(
                                                localizedCategory,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: theme.textTheme
                                                      .bodyLarge?.color,
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
                              // Categorized Estates Sections
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
      ),
    );
  }

  /// Builds the "Nearby Estates" section
  Widget _buildNearbyEstatesSection() {
    // Filter estates within the maxNearbyDistance
    List<Map<String, dynamic>> nearbyEstates = filteredEstates
        .where((estate) => estate['distance'] * 1000 <= maxNearbyDistance)
        .toList();

    if (nearbyEstates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          getTranslated(context, "No nearby estates found."),
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: nearbyEstates.length,
        itemBuilder: (context, index) {
          final estate = nearbyEstates[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileEstateScreen(
                    nameEn: estate['nameEn'],
                    nameAr: estate['nameAr'],
                    estateId: estate['id'],
                    location: estate['City'],
                    rating: estate['rating'],
                    fee: estate['fee'],
                    price: 32.0, // Adjust as needed
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
                    hasSwimmingPool: estate['HasSwimmingPool'],
                    isSmokingAllowed: estate['IsSmokingAllowed'],
                    hasJacuzziInRoom: estate['HasJacuzziInRoom'],
                    lat: estate['Lat'] ?? 0.0,
                    lon: estate['Lon'] ?? 0.0,
                    city: estate['City'] ?? "No city",
                    country: estate['Country'] ?? "No Country",
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
              timeRange: estate['timeRange'], // Pass timeRange
              city: estate['City'],
              country: estate['Country'],
            ),
          );
        },
      ),
    );
  }

  /// Builds categorized sections like Hotels, Restaurants, Cafes
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
                          location: estate['City'],
                          rating: estate['rating'],
                          fee: estate['fee'],
                          price: 32.0, // Adjust as needed
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
                          hasSwimmingPool: estate['HasSwimmingPool'],
                          isSmokingAllowed: estate['IsSmokingAllowed'],
                          hasJacuzziInRoom: estate['HasJacuzziInRoom'],
                          lat: estate['Lat'] ?? 0.0,
                          lon: estate['Lon'] ?? 0.0,
                          city: estate['City'] ?? "No city",
                          country: estate['Country'] ?? "No Country",
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
                    timeRange: estate['timeRange'], // Pass timeRange
                    city: estate['City'],
                    country: estate['Country'],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the appropriate icon for a given category
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
