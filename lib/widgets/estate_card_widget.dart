import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import '../constants/styles.dart';

class EstateCard extends StatelessWidget {
  final String nameEn;
  final String nameAr;
  final String estateId;

  const EstateCard({
    super.key,
    required this.nameEn,
    required this.nameAr,
    required this.estateId,
  });

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
    // Check the current language and use the appropriate name
    final String displayName =
        Localizations.localeOf(context).languageCode == 'ar' ? nameAr : nameEn;

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
                  // Display estate name based on the current language
                  Text(
                    displayName,
                    style: kSecondaryStyle,
                  ),
                  const SizedBox(height: 8),
                  // Rating, Fee, and Time info
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        "4.7", // You can replace this with dynamic rating data
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.monetization_on,
                          color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        "Free", // You can replace this with dynamic fee data
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.timer, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        "20 min", // You can replace this with dynamic time data
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
