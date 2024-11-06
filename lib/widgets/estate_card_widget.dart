import 'package:flutter/material.dart';

class EstateCard extends StatelessWidget {
  final String nameEn;
  final String nameAr;
  final String estateId;
  final double rating;
  final String imageUrl; // Add imageUrl parameter

  const EstateCard({
    super.key,
    required this.nameEn,
    required this.nameAr,
    required this.estateId,
    required this.rating,
    required this.imageUrl, // Initialize imageUrl
  });

  @override
  Widget build(BuildContext context) {
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
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                image: DecorationImage(
                  image: NetworkImage(imageUrl), // Load image from URL
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display estate name based on the current language
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Rating, Fee, and Time info
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1), // Display dynamic rating
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.monetization_on,
                          color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        "Free", // Replace with dynamic fee data
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.timer, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        "20 min", // Replace with dynamic time data
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
