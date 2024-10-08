import 'dart:io';
import 'package:diamond_host_admin/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../backend/estate_services.dart';
import '../localization/language_constants.dart';
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

  Future<File> _getCachedImage(String estateId) async {
    // Get the directory where images are stored
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$estateId.jpg';

    // Check if the image is already cached
    final cachedImage = File(filePath);
    if (await cachedImage.exists()) {
      return cachedImage;
    }

    // If not cached, download the image from Firebase Storage
    final storageRef = FirebaseStorage.instance.ref().child('$estateId/0.jpg');
    final imageUrl = await storageRef.getDownloadURL();

    // Download the image and save it locally
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      await cachedImage.writeAsBytes(response.bodyBytes);
    }

    return cachedImage;
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
            // Categories Section (Horizontally scrollable)
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
                  // Icon selection based on category
                  IconData iconData;
                  switch (categories[index]) {
                    case 'Hotel':
                      iconData = AntDesign.home_fill;
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
                            color: kDeepPurpleColor, // Adjust the icon color
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
            // Open Estates Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                getTranslated(context, "Open Estates"),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
                      return _buildEstateCard(
                          context, estate['nameEn'], estate['id']);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // Function to build an estate card, with caching and error handling for images
  Widget _buildEstateCard(BuildContext context, String name, String estateId,
      {bool error = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estate Image
            FutureBuilder<File>(
              future: _getCachedImage(estateId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      color: Colors.grey[200],
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      color: Colors.grey[200],
                    ),
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  );
                } else {
                  return Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      image: DecorationImage(
                        image: FileImage(snapshot.data!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estate Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Example: Rating, Fee, and Time info
                  Row(
                    children: const [
                      Icon(Icons.star, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "4.7",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.monetization_on, color: Colors.grey, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "Free",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.timer, color: Colors.grey, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "20 min",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
