import 'dart:io';
import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import '../constants/styles.dart';

class EstateCard extends StatelessWidget {
  final String name;
  final String estateId;

  const EstateCard({
    super.key,
    required this.name,
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
                    style: kSecondaryStyle,
                  ),
                  8.kH,
// Example: Rating, Fee, and Time info
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      4.kW,
                      const Text(
                        "4.7",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      10.kW,
                      const Icon(Icons.monetization_on,
                          color: Colors.grey, size: 16),
                      4.kW,
                      const Text(
                        "Free",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      10.kW,
                      const Icon(Icons.timer, color: Colors.grey, size: 16),
                      4.kW,
                      const Text(
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
