import 'package:diamond_host_admin/widgets/reused_appbar.dart';
import 'package:diamond_host_admin/widgets/estate_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../backend/customer_rate_services.dart';
import '../backend/estate_services.dart';
import '../localization/language_constants.dart';
import '../state_management/general_provider.dart';
import '../widgets/custom_drawer.dart';
import 'profile_estate_screen.dart';

class MainScreenContent extends StatefulWidget {
  const MainScreenContent({super.key});

  @override
  _MainScreenContentState createState() => _MainScreenContentState();
}

class _MainScreenContentState extends State<MainScreenContent> {
  EstateServices estateServices = EstateServices();
  CustomerRateServices customerRateServices = CustomerRateServices();
  List<Map<String, dynamic>> estates = [];
  final List<String> categories = ['Hotel', 'Restaurant', 'Coffee'];

  @override
  void initState() {
    super.initState();
    _fetchEstates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GeneralProvider>(context, listen: false).fetchApprovalCount();
    });
  }

  Future<void> _fetchEstates() async {
    try {
      final data = await estateServices.fetchEstates();
      if (data != null) {
        List<Map<String, dynamic>> parsedEstates = _parseEstates(data);
        setState(() {
          estates = parsedEstates;
        });
      } else {
        print("No data found in Firebase.");
      }
    } catch (e) {
      print("Error fetching estates: $e");
    }
  }

  List<Map<String, dynamic>> _parseEstates(Map<String, dynamic> data) {
    List<Map<String, dynamic>> estateList = [];
    List<String> categories = ["Coffee", "Restaurant", "Hottel"];

    for (var category in categories) {
      if (data.containsKey(category)) {
        var categoryData = data[category];
        if (categoryData is List) {
          for (var estateData in categoryData) {
            if (estateData != null && estateData is Map<dynamic, dynamic>) {
              estateList.add(
                  _extractEstateData(Map<String, dynamic>.from(estateData)));
            }
          }
        } else if (categoryData is Map) {
          for (var estateKey in categoryData.keys) {
            var estateData = categoryData[estateKey];
            if (estateData != null && estateData is Map) {
              estateList.add(
                  _extractEstateData(Map<String, dynamic>.from(estateData)));
            }
          }
        }
      }
    }
    return estateList;
  }

  Map<String, dynamic> _extractEstateData(Map<String, dynamic> estateData) {
    return {
      'id': estateData['IDEstate'] ?? 'Unknown ID',
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
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Main Screen"),
      ),
      drawer: const CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchEstates, // Refresh function to reload estate data
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  getTranslated(context, "All Categories"),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
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
                                fontSize: 16, fontWeight: FontWeight.bold),
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
                            rating: estate['rating'],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
