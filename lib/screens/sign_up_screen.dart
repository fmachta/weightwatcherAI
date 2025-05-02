import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/user_profile.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

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
  final _activityLevelController = TextEditingController();
  final _fitnessGoalController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _errorMessage = '';

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
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

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
            activityLevel:
                _parseActivityLevel(_activityLevelController.text.trim()),
            fitnessGoal: _parseFitnessGoal(_fitnessGoalController.text.trim()),
          );

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(newUserProfile.toJson());

          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          userProvider.userProfile = newUserProfile;

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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    void navigateToLogin() {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.person_add_alt_1,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Create Your Account',
                    style: textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join us to start your fitness journey!',
                    style: textTheme.bodyLarge
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText:
                          'Min. 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 symbol.',
                      helperMaxLines: 2,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters long';
                      }
                      if (!value.contains(RegExp(r'[A-Z]'))) {
                        return 'Password must contain an uppercase letter';
                      }
                      if (!value.contains(RegExp(r'[a-z]'))) {
                        return 'Password must contain a lowercase letter';
                      }
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return 'Password must contain a number';
                      }
                      if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                        return 'Password must contain a special character';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Age',
                      prefixIcon: const Icon(Icons.cake_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your age';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Please enter a valid age';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
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
                          value: value, child: Text(value));
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your gender';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _currentWeightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,1}'))
                    ],
                    decoration: InputDecoration(
                      labelText: 'Current Weight (kg)',
                      prefixIcon: const Icon(Icons.monitor_weight_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your current weight';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Please enter a valid weight';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _targetWeightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,1}'))
                    ],
                    decoration: InputDecoration(
                      labelText: 'Target Weight (kg)',
                      prefixIcon: const Icon(Icons.flag_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your target weight';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Please enter a valid weight';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _heightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,1}'))
                    ],
                    decoration: InputDecoration(
                      labelText: 'Height (cm)',
                      prefixIcon: const Icon(Icons.height_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your height';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Please enter a valid height';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bodyFatController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,1}'))
                    ],
                    decoration: InputDecoration(
                      labelText: 'Body Fat (%)',
                      prefixIcon: const Icon(Icons.water_drop_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your body fat percentage';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) < 0) {
                        return 'Please enter a valid percentage';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _muscleMassController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,1}'))
                    ],
                    decoration: InputDecoration(
                      labelText: 'Muscle Mass (kg)',
                      prefixIcon: const Icon(Icons.fitness_center_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your muscle mass';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) < 0) {
                        return 'Please enter a valid mass';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
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
                          value: value, child: Text(value));
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Activity Level',
                      prefixIcon: const Icon(Icons.directions_run_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your activity level';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
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
                          value: value, child: Text(value));
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Fitness Goal',
                      prefixIcon: const Icon(Icons.track_changes_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your fitness goal';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Sign Up'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        // Wrap the Text widget with Flexible
                        child: Text(
                          "Already have an account?",
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: navigateToLogin,
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
