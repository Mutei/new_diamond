import 'package:flutter/material.dart';
import '../localization/language_constants.dart';
import 'package:auto_size_text/auto_size_text.dart';

class EstateCard extends StatelessWidget {
  final String nameEn;
  final String nameAr;
  final String estateId;
  final double rating;
  final String imageUrl;
  final String fee;
  final String time;

  const EstateCard({
    super.key,
    required this.nameEn,
    required this.nameAr,
    required this.estateId,
    required this.rating,
    required this.imageUrl,
    required this.fee,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final String displayName =
        Localizations.localeOf(context).languageCode == 'ar' ? nameAr : nameEn;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: SizedBox(
        width: 200,
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          child: SingleChildScrollView(
            // Allow scrolling within the card
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estate Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: Image.network(
                    imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      height: 120,
                      width: double.infinity,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estate Name
                      AutoSizeText(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        minFontSize: 10,
                      ),
                      const SizedBox(height: 4),
                      // Rating Row
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.orange, size: 16),
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
                      // Fee and Time Row with Flexible
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                const Icon(Icons.monetization_on,
                                    color: Colors.grey, size: 16),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    fee,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Row(
                              children: [
                                const Icon(Icons.timer,
                                    color: Colors.grey, size: 16),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    time,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }
}
