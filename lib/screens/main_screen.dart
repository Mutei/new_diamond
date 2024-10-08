import 'package:flutter/material.dart';
import '../backend/estate_services.dart';
import '../localization/language_constants.dart';
import '../widgets/estate_card_widget.dart';
import '../widgets/reused_appbar.dart';
import 'custom_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  EstateServices estateServices = EstateServices();
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
      setState(() {
        estates = _parseEstates(data);
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
          'imageUrl': estateData['FacilityImageUrl'] ?? '',
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
                            color: Colors.deepPurple, // Adjust the icon color
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
                      return EstateCard(
                        name: estate['nameEn'],
                        estateId: estate['id'],
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
