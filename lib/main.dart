import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

//import Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore
import 'firebase_options.dart';

// Import screens
import 'screens/dashboard_screen.dart';
import 'screens/calorie_tracker_screen.dart';
import 'screens/workout_tracker_screen.dart';
import 'screens/ai_trainer_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart'; // Import LoginScreen
import 'screens/sign_up_screen.dart'; // Import SignUpScreen

// Import models
import 'models/user_profile.dart';
import 'models/food_item.dart';
import 'models/meal.dart';
import 'models/workout.dart';
import 'models/exercise.dart';
import 'models/body_measurement.dart';

// Import providers
import 'providers/user_provider.dart';
import 'providers/nutrition_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/ai_trainer_provider.dart';

// Import services

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the app with providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => AITrainerProvider()),
      ],
      child: const WeightWatcherAI(),
    ),
  );
}

class WeightWatcherAI extends StatelessWidget {
  const WeightWatcherAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weight Watcher AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: ThemeMode.system,
      // home: const SplashScreen(), // Remove SplashScreen as the direct home.
      home: const AuthGate(), // Set AuthGate as the new home.
    );
  }
}

// Splash screen to initialize app data
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize all providers
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
      final aiTrainerProvider = Provider.of<AITrainerProvider>(context, listen: false);

      await userProvider.initialize();
      await nutritionProvider.initialize();
      await workoutProvider.initialize();
      await aiTrainerProvider.initialize();

      // If no user profile exists, create a default one
      if (userProvider.userProfile == null) {
        final defaultProfile = UserProfile(
          name: 'Alex',
          email: 'alex@example.com',
          currentWeight: 75.0,
          targetWeight: 70.0,
          height: 175.0,
          age: 30,
          gender: 'Male',
          bodyFat: 15.0,
          muscleMass: 30.0,
          activityLevel: ActivityLevel.moderatelyActive,
          fitnessGoal: FitnessGoal.maintenance,
        );

        await userProvider.saveUserProfile(defaultProfile);

        // Add a sample body measurement
        final measurement = BodyMeasurement(
          date: DateTime.now().subtract(const Duration(days: 30)),
          weight: 77.0,
          bodyFat: 16.0,
          muscleMass: 29.0,
        );
        await userProvider.saveBodyMeasurement(measurement);

        final currentMeasurement = BodyMeasurement(
          date: DateTime.now(),
          weight: 75.0,
          bodyFat: 15.0,
          muscleMass: 30.0,
        );
        await userProvider.saveBodyMeasurement(currentMeasurement);
      }

      // Update nutrition goals based on user profile
      if (userProvider.userProfile != null) {
        final profile = userProvider.userProfile!;
        final calorieGoal = profile.calculateDailyCalorieGoal();
        await nutritionProvider.updateDailyNutrition(
          calorieGoal,
          profile.macroDistribution ?? profile.defaultMacroDistribution,
        );

        // Add sample data if there's no data
        await _addSampleDataIfNeeded(nutritionProvider, workoutProvider);
      }

      // Navigate to main screen after 1.5 seconds to show splash screen
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          // Removed the direct navigation to MainScreen()
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(builder: (_) => const MainScreen()),
          // );
        });
      }
    } catch (e, stackTrace) {
      // Log error and show error message
      print('Error initializing app: $e');
      print(stackTrace);

      // Still navigate to main screen after a delay
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          // Removed the direct navigation to MainScreen()
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(builder: (_) => const MainScreen()),
          // );
        });
      }
    }
  }

  // Add some sample data for demo purposes
  Future<void> _addSampleDataIfNeeded(
      NutritionProvider nutritionProvider,
      WorkoutProvider workoutProvider,
      ) async {
    final now = DateTime.now();

    // Add a sample meal if no meals exist
    if (nutritionProvider.meals.isEmpty) {
      // Breakfast
      await nutritionProvider.addMeal(
        'Breakfast',
        MealType.breakfast,
        DateTime(now.year, now.month, now.day, 8, 0),
        [
          MealItem(
            foodItem: FoodItem(
              id: 'oatmeal',
              name: 'Oatmeal',
              calories: 150,
              protein: 5,
              carbs: 27,
              fat: 2.5,
              description: 'With honey and banana',
            ),
            quantity: 1.0,
          ),
          MealItem(
            foodItem: FoodItem(
              id: 'greek_yogurt',
              name: 'Greek Yogurt',
              calories: 120,
              protein: 15,
              carbs: 8,
              fat: 0.5,
              description: 'Plain, non-fat',
            ),
            quantity: 1.0,
          ),
        ],
      );

      // Lunch
      await nutritionProvider.addMeal(
        'Lunch',
        MealType.lunch,
        DateTime(now.year, now.month, now.day, 13, 0),
        [
          MealItem(
            foodItem: FoodItem(
              id: 'chicken_salad',
              name: 'Chicken Salad',
              calories: 350,
              protein: 30,
              carbs: 15,
              fat: 20,
              description: 'Grilled chicken with mixed greens',
            ),
            quantity: 1.0,
          ),
          MealItem(
            foodItem: FoodItem(
              id: 'whole_grain_bread',
              name: 'Whole Grain Bread',
              calories: 80,
              protein: 4,
              carbs: 15,
              fat: 1,
              description: 'One slice',
            ),
            quantity: 2.0,
          ),
        ],
      );
    }

    // Add a sample workout if no workouts exist
    if (workoutProvider.workouts.isEmpty) {
      await workoutProvider.addWorkout(
        'Morning Workout',
        DateTime(now.year, now.month, now.day, 10, 0),
        const Duration(minutes: 45),
        WorkoutType.strength,
        [
          Exercise(
            id: 'push_up',
            name: 'Push-ups',
            targetMuscleGroup: 'Chest',
            sets: [
              ExerciseSet(reps: 12),
              ExerciseSet(reps: 12),
              ExerciseSet(reps: 10),
            ],
          ),
          Exercise(
            id: 'squat',
            name: 'Squats',
            targetMuscleGroup: 'Legs',
            sets: [
              ExerciseSet(reps: 15),
              ExerciseSet(reps: 15),
              ExerciseSet(reps: 15),
            ],
          ),
          Exercise(
            id: 'plank',
            name: 'Plank',
            targetMuscleGroup: 'Core',
            duration: const Duration(minutes: 3),
          ),
        ],
        280,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or app icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 64,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Weight Watcher AI',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your personal fitness assistant',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading your fitness data...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// Main screen with bottom navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CalorieTrackerScreen(),
    const WorkoutTrackerScreen(),
    const AITrainerScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Calories',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}

// Extension method to add withAlpha or withOpacity to Color
// This replaces the deprecated method that was in the original code
extension ColorExtension on Color {
  Color withAlpha(int alpha) => withOpacity(alpha / 255);

  Color withValues({int? red, int? green, int? blue, int? alpha}) {
    return Color.fromARGB(
      alpha ?? this.alpha,
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          // User is logged in, fetch user data from Firestore
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, firestoreSnapshot) {
              if (firestoreSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              if (firestoreSnapshot.hasData &&
                  firestoreSnapshot.data!.exists) {
                // Document exists, create UserProfile and set it in UserProvider
                final userData =
                firestoreSnapshot.data!.data() as Map<String, dynamic>;
                final userProfile = UserProfile.fromJson(userData);
                // Update the provider state *after* the build phase
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Provider.of<UserProvider>(context, listen: false)
                      .userProfile = userProfile;
                });

                return const MainScreen(); // Go to main screen
              } else {
                // Document doesn't exist (or error), handle as needed
                // For example:
                // 1.  Go to a "Complete Profile" screen
                // 2.  Show an error message
                // 3.  Go to MainScreen with a null profile (and handle nulls in your UI)

                // For now, let's go to the MainScreen:
                return const MainScreen();
              }
            },
          );
        } else {
          // User is not logged in, show the MainScreen for guest browsing
          // Clear any existing user profile in the provider for the guest session
          WidgetsBinding.instance.addPostFrameCallback((_) {
             Provider.of<UserProvider>(context, listen: false).clearUserProfile();
          });
          return const MainScreen();
        }
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: const Text('Go to Login'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
              child: const Text('Go to Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
