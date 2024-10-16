import 'package:flutter/material.dart';
import '../backend/customer_rate_services.dart';
import '../backend/estate_services.dart';
import '../localization/language_constants.dart';
import '../widgets/estate_card_widget.dart';
import '../widgets/reused_appbar.dart';
import '../widgets/custom_drawer.dart';
import 'profile_estate_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  EstateServices estateServices = EstateServices();
  CustomerRateServices customerRateServices = CustomerRateServices();
  List<Map<String, dynamic>> estates = [];
  final List<String> categories = ['Hotel', 'Restaurant', 'Coffee'];

  @override
  void initState() {
    super.initState();
    _fetchEstates();
  }

  Future<void> _fetchEstates() async {
    try {
      final data = await estateServices.fetchEstates();
      List<Map<String, dynamic>> parsedEstates = _parseEstates(data);

      // Fetch ratings for each estate
      for (var estate in parsedEstates) {
        final ratings =
            await customerRateServices.fetchEstateRatingWithUsers(estate['id']);

        // Calculate average rating
        double totalRating = 0;
        if (ratings.isNotEmpty) {
          totalRating = ratings
                  .map((e) => e['rating'] as double)
                  .reduce((a, b) => a + b) /
              ratings.length;
        }

        setState(() {
          estate['rating'] =
              totalRating; // Update estate with the average rating
          estate['ratingsList'] = ratings; // Save the list of ratings
        });
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
          'nameAr': estateData['NameAr'] ?? 'غير معروف', // Arabic fallback
          'rating': 0.0, // Will be updated with actual rating later
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Main Screen"),
      ),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                getTranslated(context, "All Categories"),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  IconData iconData;
                  switch (categories[index]) {
                    case 'Hotel':
                      iconData = Icons.hotel;
                      break;
                    case 'Restaurant':
                      iconData = Icons.restaurant;
                      break;
                    case 'Coffee':
                      iconData = Icons.local_cafe;
                      break;
                    default:
                      iconData = Icons.category;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        Container(
                          width: 115,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            iconData,
                            size: 40,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          categories[index],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            estates.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: estates.length,
                    itemBuilder: (context, index) {
                      final estate = estates[index];
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
                          estateId: estate['id'],
                          nameAr: estate['nameAr'],
                          rating: estate['rating'], // Pass dynamic rating
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
