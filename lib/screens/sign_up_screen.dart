import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // Import for input formatters

// Import the user_provider.dart
import '../main.dart';
import '../models/user_profile.dart';
import '../providers/user_provider.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _currentWeightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _muscleMassController = TextEditingController();
  final _activityLevelController =
  TextEditingController(); // Use a controller, not a dropdown
  final _fitnessGoalController =
  TextEditingController(); // Use a controller, not a dropdown

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _errorMessage = '';

  // Dropdown options (moved here for better organization)
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _activityLevelOptions = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Extra Active'
  ];
  final List<String> _fitnessGoalOptions = [
    'Weight Loss',
    'Weight Gain',
    'Maintenance'
  ];

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // 1. Create user with email and password using FirebaseAuth
        UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 2. Store user data in Firestore
        if (userCredential.user != null) {
          final newUserProfile = UserProfile(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            age: int.parse(_ageController.text.trim()),
            gender: _genderController.text.trim(),
            currentWeight: double.parse(_currentWeightController.text.trim()),
            targetWeight: double.parse(_targetWeightController.text.trim()),
            height: double.parse(_heightController.text.trim()),
            bodyFat: double.parse(_bodyFatController.text.trim()),
            muscleMass: double.parse(_muscleMassController.text.trim()),
            activityLevel: _parseActivityLevel(
                _activityLevelController.text.trim()), // Parse from string
            fitnessGoal: _parseFitnessGoal(
                _fitnessGoalController.text.trim()), // Parse from string
          );

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(newUserProfile.toJson());

          // 3. Get UserProvider and set the userProfile
          final userProvider =
          Provider.of<UserProvider>(context, listen: false);
          userProvider.userProfile = newUserProfile;

          // 4. Navigate to the main screen after successful signup
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const MainScreen(),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = _handleFirebaseAuthError(e.code);
        });
        print("FirebaseAuthException: ${e.code} - ${e.message}");
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred.';
        });
        print("Error: $e");
      }
    }
  }

  // Helper Methods for Enums
  ActivityLevel _parseActivityLevel(String activityLevel) {
    switch (activityLevel) {
      case 'Sedentary':
        return ActivityLevel.sedentary;
      case 'Lightly Active':
        return ActivityLevel.lightlyActive;
      case 'Moderately Active':
        return ActivityLevel.moderatelyActive;
      case 'Very Active':
        return ActivityLevel.veryActive;
      case 'Extra Active':
        return ActivityLevel.extraActive;
      default:
        return ActivityLevel.sedentary;
    }
  }

  FitnessGoal _parseFitnessGoal(String fitnessGoal) {
    switch (fitnessGoal) {
      case 'Weight Loss':
        return FitnessGoal.weightLoss;
      case 'Maintenance':
        return FitnessGoal.maintenance;
      default:
        return FitnessGoal.maintenance;
    }
  }

  String _handleFirebaseAuthError(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return 'An error occurred during sign up.';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    _heightController.dispose();
    _bodyFatController.dispose();
    _muscleMassController.dispose();
    _activityLevelController.dispose();
    _fitnessGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up', style: GoogleFonts.poppins()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password should be at least 6 characters';
                    }
                    return null;
                  },
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.numberWithOptions(),
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your age';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _genderController.text.isEmpty
                      ? null
                      : _genderController.text,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _genderController.text = newValue;
                      });
                    }
                  },
                  items: _genderOptions
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: GoogleFonts.poppins()),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _currentWeightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Current Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current weight';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _targetWeightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Target Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your target weight';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your height';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _bodyFatController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Body Fat (%)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your body fat percentage';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _muscleMassController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Muscle Mass (kg)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your muscle mass';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _activityLevelController.text.isEmpty
                      ? null
                      : _activityLevelController.text,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _activityLevelController.text = newValue;
                      });
                    }
                  },
                  items: _activityLevelOptions
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: GoogleFonts.poppins()),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Activity Level',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your activity level';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _fitnessGoalController.text.isEmpty
                      ? null
                      : _fitnessGoalController.text,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _fitnessGoalController.text = newValue;
                      });
                    }
                  },
                  items: _fitnessGoalOptions
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: GoogleFonts.poppins()),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Fitness Goal',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your fitness goal';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
