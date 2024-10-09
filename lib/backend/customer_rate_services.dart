import 'package:firebase_database/firebase_database.dart';

class CustomerRateServices {
  final DatabaseReference databaseRef =
      FirebaseDatabase.instance.ref().child('App').child('CustomerFeedback');

  Future<double> fetchEstateRating(String estateId) async {
    double totalRating = 0.0;
    int count = 0;

    final snapshot = await databaseRef.get();
    if (snapshot.exists) {
      final feedbacks = snapshot.value as Map<dynamic, dynamic>;

      feedbacks.forEach((key, feedback) {
        if (feedback['EstateID'] == estateId) {
          totalRating += (feedback['rating'] as num).toDouble();
          count++;
        }
      });

      if (count > 0) {
        return totalRating / count; // Calculate average rating
      }
    }

    return 0.0; // Default rating if no feedback is found
  }
}
