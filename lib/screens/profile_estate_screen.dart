import 'dart:io';
import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import '../localization/language_constants.dart'; // Import for translations

class ProfileEstateScreen extends StatelessWidget {
  final String nameEn;
  final String nameAr;
  final String estateId; // Use estateId to fetch image
  final String location;
  final double rating;
  final String fee;
  final String deliveryTime;
  final double price;

  const ProfileEstateScreen({
    Key? key,
    required this.nameEn,
    required this.nameAr,
    required this.estateId,
    required this.location,
    required this.rating,
    required this.fee,
    required this.deliveryTime,
    required this.price,
  }) : super(key: key);

  Future<File> _getCachedImage(String estateId) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$estateId.jpg';
    final cachedImage = File(filePath);

    if (await cachedImage.exists()) {
      return cachedImage;
    }

    final storageRef = FirebaseStorage.instance.ref().child('$estateId/0.jpg');
    final imageUrl = await storageRef.getDownloadURL();
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode == 200) {
      await cachedImage.writeAsBytes(response.bodyBytes);
    }

    return cachedImage;
  }

  @override
  Widget build(BuildContext context) {
    // Check the current language and use the appropriate name
    final String displayName =
        Localizations.localeOf(context).languageCode == 'ar' ? nameAr : nameEn;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          displayName, // Use the translated name here
          style: kTeritary,
        ),
        centerTitle: true,
        iconTheme: kIconTheme,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estate Image
              FutureBuilder<File>(
                future: _getCachedImage(estateId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey[200],
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey[200],
                      ),
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    );
                  } else {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: FileImage(snapshot.data!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              // Estate Name and Location
              Text(
                displayName, // Display the estate name based on language
                style: kTeritary,
              ),
              const SizedBox(height: 8),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              // Rating, Fee, and Time
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "$rating", // Dynamic rating
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.monetization_on,
                      color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    fee, // Dynamic fee
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.timer, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    deliveryTime, // Dynamic delivery time
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Size Selector (You can modify this section as needed)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSizeOption("10\""),
                  _buildSizeOption("14\""),
                  _buildSizeOption("16\""),
                ],
              ),
              const SizedBox(height: 16),
              // Ingredients Section (icons or tags)
              Wrap(
                spacing: 10.0,
                children: [
                  _buildIngredientTag(Icons.fastfood, "Cheese"),
                  _buildIngredientTag(Icons.local_pizza, "Pepperoni"),
                  _buildIngredientTag(Icons.grain, "Lettuce"),
                  _buildIngredientTag(Icons.whatshot, "Hot Sauce"),
                ],
              ),
              const SizedBox(height: 24),
              // Price and Add to Cart Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "\$$price", // Dynamic price
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Add to cart functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          kDeepPurpleColor, // Adjust to match the design
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 32,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "ADD TO CART",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for size options
  Widget _buildSizeOption(String size) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: kDeepPurpleColor,
          child: Text(
            size,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          size,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Helper widget for ingredient tags
  Widget _buildIngredientTag(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, color: Colors.white),
      label: Text(label),
      backgroundColor: kDeepPurpleColor,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }
}
