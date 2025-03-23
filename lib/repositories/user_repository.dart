import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/body_measurement.dart';

class UserRepository {
  static const String _userProfileKey = 'user_profile';
  static const String _measurementsKey = 'body_measurements';

  // Save user profile
  Future<void> saveUserProfile(UserProfile userProfile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, jsonEncode(userProfile.toJson()));
  }

  // Get user profile
  Future<UserProfile?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userProfileJson = prefs.getString(_userProfileKey);

    if (userProfileJson != null) {
      return UserProfile.fromJson(jsonDecode(userProfileJson));
    }

    return null;
  }

  // Save body measurement
  Future<void> saveBodyMeasurement(BodyMeasurement measurement) async {
    final prefs = await SharedPreferences.getInstance();
    final measurementsJson = prefs.getStringList(_measurementsKey) ?? [];

    // Add new measurement to the list
    measurementsJson.add(jsonEncode(measurement.toJson()));

    await prefs.setStringList(_measurementsKey, measurementsJson);
  }

  // Get all body measurements
  Future<List<BodyMeasurement>> getBodyMeasurements() async {
    final prefs = await SharedPreferences.getInstance();
    final measurementsJson = prefs.getStringList(_measurementsKey) ?? [];

    return measurementsJson
        .map((json) => BodyMeasurement.fromJson(jsonDecode(json)))
        .toList();
  }

  // Get latest body measurement
  Future<BodyMeasurement?> getLatestBodyMeasurement() async {
    final measurements = await getBodyMeasurements();

    if (measurements.isEmpty) {
      return null;
    }

    // Sort by date (latest first)
    measurements.sort((a, b) => b.date.compareTo(a.date));
    return measurements.first;
  }

  // Delete a body measurement
  Future<void> deleteBodyMeasurement(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final measurementsJson = prefs.getStringList(_measurementsKey) ?? [];

    final measurements = measurementsJson
        .map((json) => BodyMeasurement.fromJson(jsonDecode(json)))
        .toList();

    // Remove the measurement with the given date
    measurements.removeWhere((m) => m.date.isAtSameMomentAs(date));

    // Save the updated list
    await prefs.setStringList(
      _measurementsKey,
      measurements.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }
}