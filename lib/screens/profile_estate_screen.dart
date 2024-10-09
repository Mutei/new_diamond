import 'dart:io';
import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/constants/styles.dart';
import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // Cache manager
import 'package:cached_network_image/cached_network_image.dart'; // Cached image package
import 'package:firebase_storage/firebase_storage.dart';
import '../localization/language_constants.dart';
import '../backend/customer_rate_services.dart';
import '../widgets/chip_widget.dart'; // Import for translations

class ProfileEstateScreen extends StatefulWidget {
  final String nameEn;
  final String nameAr;
  final String estateId;
  final String location;
  final double rating;
  final String fee;
  final String deliveryTime;
  final double price;
  final String typeOfRestaurant;
  final String sessions;
  final String menuLink;
  final String entry;
  final String music;

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
    required this.music,
  }) : super(key: key);

  @override
  _ProfileEstateScreenState createState() => _ProfileEstateScreenState();
}

class _ProfileEstateScreenState extends State<ProfileEstateScreen> {
  List<String> _imageUrls = [];
  List<Map<String, dynamic>> _userRatings =
      []; // To store users and their ratings
  double _overallRating = 0.0; // Overall rating as double
  int _currentImageIndex = 0; // To track the current image index
  final _cacheManager = CacheManager(Config(
    'customCacheKey', // Custom key for cache management
    stalePeriod: const Duration(days: 7), // Cache images for 7 days
  ));

  @override
  void initState() {
    super.initState();
    _fetchImageUrls();
    _fetchUserRatings(); // Fetch user ratings for the estate
  }

  // Fetch multiple images URLs from Firebase Storage
  Future<void> _fetchImageUrls() async {
    int index = 0;
    bool hasMoreImages = true;
    List<String> imageUrls = [];

    while (hasMoreImages) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('${widget.estateId}/$index.jpg');
        final imageUrl = await storageRef.getDownloadURL();
        imageUrls.add(imageUrl);

        // Preload image to ensure it's cached before use
        await _cacheManager.getSingleFile(imageUrl);
      } catch (e) {
        hasMoreImages = false; // No more images available
      }
      index++;
    }

    setState(() {
      _imageUrls = imageUrls;
    });
  }

  // Fetch ratings with user names
  Future<void> _fetchUserRatings() async {
    CustomerRateServices rateServices = CustomerRateServices();
    final ratings =
        await rateServices.fetchEstateRatingWithUsers(widget.estateId);
    double totalRating = 0.0;
    for (var rating in ratings) {
      totalRating += rating['rating']; // Sum all ratings
    }

    setState(() {
      _userRatings = ratings; // Update the list with fetched user ratings
      _overallRating = ratings.isNotEmpty
          ? totalRating / ratings.length
          : 0.0; // Calculate average rating
    });
  }

  @override
  Widget build(BuildContext context) {
    final String displayName =
        Localizations.localeOf(context).languageCode == 'ar'
            ? widget.nameAr
            : widget.nameEn;

    return Scaffold(
      appBar: AppBar(
        iconTheme: kIconTheme,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Carousel with PageView
              _imageUrls.isEmpty
                  ? Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey[200],
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        SizedBox(
                          height: 200,
                          child: PageView.builder(
                            itemCount: _imageUrls.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: CachedNetworkImage(
                                  imageUrl: _imageUrls[index],
                                  cacheManager:
                                      _cacheManager, // Use the cache manager
                                  placeholder: (context, url) =>
                                      Container(color: Colors.grey[300]),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              );
                            },
                          ),
                        ),
                        // Display image indicator at the bottom
                        Positioned(
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1} / ${_imageUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
              16.kH,
              // Estate Name and Location
              Text(
                displayName,
                style: kTeritary,
              ),
              8.kH,
              Text(
                widget.location,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              16.kH,
              // Overall Rating Section
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 16),
                  4.kW,
                  Text(
                    _overallRating.toStringAsFixed(
                        1), // Display the overall rating as a double
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
                    widget.fee,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  10.kW,
                  const Icon(Icons.timer, color: Colors.grey, size: 16),
                  4.kW,
                  Text(
                    widget.deliveryTime,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              16.kH,
              // User Ratings Section
              _userRatings.isEmpty
                  ? const Center(child: Text("No ratings yet"))
                  : SizedBox(
                      height: 120,
                      child: PageView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _userRatings.length,
                        itemBuilder: (context, index) {
                          final userRating = _userRatings[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(
                                    userRating['userName'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (starIndex) => Icon(
                                        starIndex < userRating['rating']
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.orange,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              16.kH,
              Wrap(
                spacing: 10.0,
                children: [
                  IngredientTag(
                      icon: Icons.fastfood, label: widget.typeOfRestaurant),
                  IngredientTag(icon: Icons.home, label: widget.sessions),
                  IngredientTag(icon: Icons.grain, label: widget.entry),
                  IngredientTag(icon: Icons.music_note, label: widget.music),
                ],
              ),
              24.kH,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "\$${widget.price}",
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
                      backgroundColor: kDeepPurpleColor,
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
            ],
          ),
        ),
      ),
    );
  }
}
