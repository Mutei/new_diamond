import 'package:flutter/material.dart';
import '../localization/language_constants.dart';

class DifferentEstateCards extends StatelessWidget {
  final String nameEn;
  final String nameAr;
  final String estateId;
  final double rating;
  final String imageUrl;
  final String fee; // New required parameter
  final String time; // New required parameter
  final String city;
  final String country;

  const DifferentEstateCards(
      {super.key,
      required this.nameEn,
      required this.nameAr,
      required this.estateId,
      required this.rating,
      required this.imageUrl,
      required this.fee, // Initialize fee
      required this.time,
      required this.country,
      required this.city // Initialize time
      });

  @override
  Widget build(BuildContext context) {
    final String displayName =
        Localizations.localeOf(context).languageCode == 'ar' ? nameAr : nameEn;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Ensure the column takes minimum space
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estate Image
            Container(
              height: 238, // Slightly reduced height
              width: double
                  .infinity, // Adjust width for better fit in horizontal list
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12.0, vertical: 6.0), // Reduced vertical padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estate Name
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Fee and Time
                  Row(
                    children: [
                      const Icon(Icons.location_city, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "$city, $country",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
