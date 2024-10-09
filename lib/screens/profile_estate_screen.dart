import 'dart:io';
import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/constants/styles.dart';
import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/language_constants.dart';
import '../widgets/chip_widget.dart'; // Import for translations

class ProfileEstateScreen extends StatelessWidget {
  final String nameEn;
  final String nameAr;
  final String estateId; // Use estateId to fetch image
  final String location;
  final double rating;
  final String fee;
  final String deliveryTime;
  final double price;
  final String typeOfRestaurant;
  final String sessions;
  final String menuLink;
  final String entry;
  final String music; // Add MenuLink field

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
    required this.typeOfRestaurant,
    required this.sessions,
    required this.menuLink,
    required this.entry,
    required this.music, // Add required field
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

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
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
              16.kH,
              // Estate Name and Location
              Text(
                displayName, // Display the estate name based on language
                style: kTeritary,
              ),
              8.kH,
              Text(
                location,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              16.kH,
              // ListTile(
              //   title: const Text(
              //     "Menu Link",
              //     style: TextStyle(fontWeight: FontWeight.bold),
              //   ),
              //   subtitle: InkWell(
              //     onTap: () async {
              //       final url = menuLink;
              //       try {
              //         await _launchURL(url);
              //       } catch (e) {
              //         ScaffoldMessenger.of(context).showSnackBar(
              //           SnackBar(content: Text('Could not launch $menuLink')),
              //         );
              //       }
              //     },
              //     child: Text(
              //       menuLink,
              //       style: const TextStyle(
              //         color: Colors.blue,
              //         decoration: TextDecoration.underline,
              //       ),
              //     ),
              //   ),
              // ),
              // Rating, Fee, and Time
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 16),
                  4.kW,
                  Text(
                    "$rating", // Dynamic rating
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  10.kW,
                  const Icon(Icons.monetization_on,
                      color: Colors.grey, size: 16),
                  4.kW,
                  Text(
                    fee, // Dynamic fee
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  10.kW,
                  const Icon(Icons.timer, color: Colors.grey, size: 16),
                  4.kW,
                  Text(
                    deliveryTime, // Dynamic delivery time
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              16.kH,
              // Restaurant Type Section
              Wrap(
                spacing: 10.0,
                children: [
                  IngredientTag(icon: Icons.fastfood, label: typeOfRestaurant),
                  IngredientTag(icon: Icons.home, label: sessions),
                  IngredientTag(icon: Icons.grain, label: entry),
                  IngredientTag(icon: Icons.music_note, label: music),
                ],
              ),
              24.kH,
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
              16.kH,
              // Menu Link
            ],
          ),
        ),
      ),
    );
  }
}
