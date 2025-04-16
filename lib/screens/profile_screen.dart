// screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_profile.dart';
import '../models/body_measurement.dart';
import 'login_screen.dart'; // Import LoginScreen for navigation after logout
// import 'dashboard_screen.dart'; // No longer needed here
import '../main.dart'; // Import main.dart to access AuthGate

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate back to the AuthGate which handles the initial screen logic
      // pushAndRemoveUntil removes all previous routes
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()), // Navigate to AuthGate
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      // Handle potential errors during sign out
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: ${e.toString()}')),
      );
    }
  }

  @override
  // Helper function to navigate to LoginScreen
  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final bool isLoggedIn = userProvider.isLoggedIn;
        final UserProfile? userProfile = userProvider.userProfile;

        // --- Guest View ---
        if (!isLoggedIn) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Login Required',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please log in or sign up to manage your profile and track your progress.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _navigateToLogin(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: const Text('Login / Sign Up'),
                  ),
                ],
              ),
            ),
          );
        }

        // --- Logged-in View ---
        // At this point, isLoggedIn is true, so userProfile should not be null.
        // Add an assertion for safety, though AuthGate logic should prevent this.
        assert(userProfile != null, 'UserProfile is null despite being logged in.');
        if (userProfile == null) {
           // Fallback in case assertion fails in production
           return const Center(child: Text('Error: User profile not loaded.'));
        }


        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your profile and preferences',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Profile card
                _ProfileCard(userProfile: userProfile),

                const SizedBox(height: 24),

                // Current body measurements
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Current Measurements',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddMeasurementSheet(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Measurements cards
                Row(
                  children: [
                    Expanded(
                      child: _MeasurementCard(
                        title: 'Weight',
                        value: '${userProfile.currentWeight.toStringAsFixed(1)} kg',
                        icon: Icons.monitor_weight,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MeasurementCard(
                        title: 'Body Fat',
                        value: '${userProfile.bodyFat.toStringAsFixed(1)}%',
                        icon: Icons.water_drop,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MeasurementCard(
                        title: 'Muscle Mass',
                        value: '${userProfile.muscleMass.toStringAsFixed(1)}%',
                        icon: Icons.fitness_center,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Settings section
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Settings cards
                _SettingsCard(
                  icon: Icons.fitness_center,
                  title: 'Fitness Goals',
                  subtitle: userProfile.fitnessGoal.toString().split('.').last,
                  onTap: () => _showEditGoalsSheet(context, userProfile),
                ),
                const SizedBox(height: 8),
                _SettingsCard(
                  icon: Icons.restaurant_menu,
                  title: 'Nutritional Preferences',
                  subtitle: 'Macros, dietary restrictions, etc.',
                  onTap: () => _showNutritionPreferencesSheet(context, userProfile),
                ),
                const SizedBox(height: 8),
                _SettingsCard(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Reminders, updates, etc.',
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                _SettingsCard(
                  icon: Icons.security,
                  title: 'Privacy',
                  subtitle: 'Data sharing, permissions, etc.',
                  onTap: () {},
                ),
                const SizedBox(height: 8), // Add space before logout
                _SettingsCard(
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  onTap: _logout, // Call the logout function
                ),

                const SizedBox(height: 24),

                // Edit profile button (Only shown when logged in)
                ElevatedButton(
                  onPressed: () => _showEditProfileSheet(context, userProfile), // No need for null check here due to earlier check
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddMeasurementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddMeasurementSheet(),
    );
  }

  void _showEditProfileSheet(BuildContext context, UserProfile userProfile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditProfileSheet(userProfile: userProfile),
    );
  }

  void _showEditGoalsSheet(BuildContext context, UserProfile userProfile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditGoalsSheet(userProfile: userProfile),
    );
  }

  void _showNutritionPreferencesSheet(BuildContext context, UserProfile userProfile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => NutritionPreferencesSheet(userProfile: userProfile),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserProfile userProfile;

  const _ProfileCard({
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                userProfile.name.isNotEmpty ? userProfile.name[0].toUpperCase() : '?',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Profile info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userProfile.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userProfile.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ProfileInfoChip(
                          label: '${userProfile.age} years',
                          icon: Icons.cake,
                        ),
                        const SizedBox(width: 8),
                        _ProfileInfoChip(
                          label: '${userProfile.height.toInt()} cm',
                          icon: Icons.height,
                        ),
                        const SizedBox(width: 8),
                        _ProfileInfoChip(
                          label: userProfile.gender,
                          icon: Icons.person,
                        ),
                      ],
                    ),
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

class _MeasurementCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MeasurementCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ProfileInfoChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Add Measurement Sheet
class AddMeasurementSheet extends StatefulWidget {
  const AddMeasurementSheet({super.key});

  @override
  State<AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<AddMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();
  final TextEditingController _muscleMassController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _muscleMassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Measurement',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weight field
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your weight';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Body fat field
            TextFormField(
              controller: _bodyFatController,
              decoration: const InputDecoration(
                labelText: 'Body Fat (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // Muscle mass field
            TextFormField(
              controller: _muscleMassController,
              decoration: const InputDecoration(
                labelText: 'Muscle Mass (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _saveMeasurement,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Save Measurement'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMeasurement() async {
    if (_formKey.currentState!.validate()) {
      final weight = double.parse(_weightController.text);
      final bodyFat = _bodyFatController.text.isNotEmpty
          ? double.parse(_bodyFatController.text)
          : null;
      final muscleMass = _muscleMassController.text.isNotEmpty
          ? double.parse(_muscleMassController.text)
          : null;

      final measurement = BodyMeasurement(
        date: DateTime.now(),
        weight: weight,
        bodyFat: bodyFat,
        muscleMass: muscleMass,
      );

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.saveBodyMeasurement(measurement);

      // Update current weight in user profile
      if (userProvider.userProfile != null) {
        final updatedProfile = UserProfile(
          name: userProvider.userProfile!.name,
          email: userProvider.userProfile!.email,
          currentWeight: weight,
          targetWeight: userProvider.userProfile!.targetWeight,
          height: userProvider.userProfile!.height,
          age: userProvider.userProfile!.age,
          gender: userProvider.userProfile!.gender,
          bodyFat: bodyFat ?? userProvider.userProfile!.bodyFat,
          muscleMass: muscleMass ?? userProvider.userProfile!.muscleMass,
          activityLevel: userProvider.userProfile!.activityLevel,
          fitnessGoal: userProvider.userProfile!.fitnessGoal,
          macroDistribution: userProvider.userProfile!.macroDistribution,
        );

        await userProvider.saveUserProfile(updatedProfile);
      }

      Navigator.of(context).pop();
    }
  }
}

// Edit Profile Sheet
class EditProfileSheet extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfileSheet({
    super.key,
    required this.userProfile,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;
  late String _gender;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile.name);
    _emailController = TextEditingController(text: widget.userProfile.email);
    _heightController = TextEditingController(text: widget.userProfile.height.toString());
    _ageController = TextEditingController(text: widget.userProfile.age.toString());
    _gender = widget.userProfile.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name field
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
            ),
            const SizedBox(height: 16),

            // Email field
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Height field
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your height';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Age field
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your age';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Gender selection
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Male',
                  child: Text('Male'),
                ),
                DropdownMenuItem(
                  value: 'Female',
                  child: Text('Female'),
                ),
                DropdownMenuItem(
                  value: 'Other',
                  child: Text('Other'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _gender = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final email = _emailController.text;
      final height = double.parse(_heightController.text);
      final age = int.parse(_ageController.text);

      final updatedProfile = UserProfile(
        name: name,
        email: email,
        currentWeight: widget.userProfile.currentWeight,
        targetWeight: widget.userProfile.targetWeight,
        height: height,
        age: age,
        gender: _gender,
        bodyFat: widget.userProfile.bodyFat,
        muscleMass: widget.userProfile.muscleMass,
        activityLevel: widget.userProfile.activityLevel,
        fitnessGoal: widget.userProfile.fitnessGoal,
        macroDistribution: widget.userProfile.macroDistribution,
      );

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.saveUserProfile(updatedProfile);

      Navigator.of(context).pop();
    }
  }
}

// Edit Goals Sheet
class EditGoalsSheet extends StatefulWidget {
  final UserProfile userProfile;

  const EditGoalsSheet({
    super.key,
    required this.userProfile,
  });

  @override
  State<EditGoalsSheet> createState() => _EditGoalsSheetState();
}

class _EditGoalsSheetState extends State<EditGoalsSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _targetWeightController;
  late ActivityLevel _activityLevel;
  late FitnessGoal _fitnessGoal;

  @override
  void initState() {
    super.initState();
    _targetWeightController = TextEditingController(text: widget.userProfile.targetWeight.toString());
    _activityLevel = widget.userProfile.activityLevel;
    _fitnessGoal = widget.userProfile.fitnessGoal;
  }

  @override
  void dispose() {
    _targetWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Fitness Goals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Target weight field
            TextFormField(
              controller: _targetWeightController,
              decoration: const InputDecoration(
                labelText: 'Target Weight (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your target weight';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Activity level selection
            DropdownButtonFormField<ActivityLevel>(
              value: _activityLevel,
              decoration: const InputDecoration(
                labelText: 'Activity Level',
                border: OutlineInputBorder(),
              ),
              items: ActivityLevel.values.map((level) {
                return DropdownMenuItem<ActivityLevel>(
                  value: level,
                  child: Text(level.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _activityLevel = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Fitness goal selection
            DropdownButtonFormField<FitnessGoal>(
              value: _fitnessGoal,
              decoration: const InputDecoration(
                labelText: 'Fitness Goal',
                border: OutlineInputBorder(),
              ),
              items: FitnessGoal.values.map((goal) {
                return DropdownMenuItem<FitnessGoal>(
                  value: goal,
                  child: Text(goal.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _fitnessGoal = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _saveGoals,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Save Goals'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveGoals() async {
    if (_formKey.currentState!.validate()) {
      final targetWeight = double.parse(_targetWeightController.text);

      final updatedProfile = UserProfile(
        name: widget.userProfile.name,
        email: widget.userProfile.email,
        currentWeight: widget.userProfile.currentWeight,
        targetWeight: targetWeight,
        height: widget.userProfile.height,
        age: widget.userProfile.age,
        gender: widget.userProfile.gender,
        bodyFat: widget.userProfile.bodyFat,
        muscleMass: widget.userProfile.muscleMass,
        activityLevel: _activityLevel,
        fitnessGoal: _fitnessGoal,
        macroDistribution: widget.userProfile.macroDistribution,
      );

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.saveUserProfile(updatedProfile);

      Navigator.of(context).pop();
    }
  }
}

// Nutrition Preferences Sheet
class NutritionPreferencesSheet extends StatefulWidget {
  final UserProfile userProfile;

  const NutritionPreferencesSheet({
    super.key,
    required this.userProfile,
  });

  @override
  State<NutritionPreferencesSheet> createState() => _NutritionPreferencesSheetState();
}

class _NutritionPreferencesSheetState extends State<NutritionPreferencesSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  @override
  void initState() {
    super.initState();
    final macros = widget.userProfile.macroDistribution ?? widget.userProfile.defaultMacroDistribution;
    _proteinController = TextEditingController(text: (macros['protein']! * 100).toStringAsFixed(0));
    _carbsController = TextEditingController(text: (macros['carbs']! * 100).toStringAsFixed(0));
    _fatController = TextEditingController(text: (macros['fat']! * 100).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nutrition Preferences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Macro Distribution (%)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Protein field
            TextFormField(
              controller: _proteinController,
              decoration: const InputDecoration(
                labelText: 'Protein (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter protein percentage';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Carbs field
            TextFormField(
              controller: _carbsController,
              decoration: const InputDecoration(
                labelText: 'Carbs (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter carbs percentage';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Fat field
            TextFormField(
              controller: _fatController,
              decoration: const InputDecoration(
                labelText: 'Fat (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter fat percentage';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Text(
              'Note: Percentages should add up to 100%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _saveMacros,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Save Preferences'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMacros() async {
    if (_formKey.currentState!.validate()) {
      final protein = int.parse(_proteinController.text);
      final carbs = int.parse(_carbsController.text);
      final fat = int.parse(_fatController.text);

      // Check if percentages add up to 100%
      if (protein + carbs + fat != 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Percentages must add up to 100%'),
          ),
        );
        return;
      }

      final macros = {
        'protein': protein / 100,
        'carbs': carbs / 100,
        'fat': fat / 100,
      };

      final updatedProfile = UserProfile(
        name: widget.userProfile.name,
        email: widget.userProfile.email,
        currentWeight: widget.userProfile.currentWeight,
        targetWeight: widget.userProfile.targetWeight,
        height: widget.userProfile.height,
        age: widget.userProfile.age,
        gender: widget.userProfile.gender,
        bodyFat: widget.userProfile.bodyFat,
        muscleMass: widget.userProfile.muscleMass,
        activityLevel: widget.userProfile.activityLevel,
        fitnessGoal: widget.userProfile.fitnessGoal,
        macroDistribution: macros,
      );

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.saveUserProfile(updatedProfile);

      Navigator.of(context).pop();
    }
  }
}
