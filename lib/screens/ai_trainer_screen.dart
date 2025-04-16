// screens/ai_trainer_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/ai_plan.dart';
import '../models/user_profile.dart';
import '../providers/ai_trainer_provider.dart';
import '../providers/user_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/workout_provider.dart';
import '../models/meal.dart'; // Keep if PlanDetailsScreen needs it, otherwise remove
import '../models/workout.dart'; // Keep if PlanDetailsScreen needs it, otherwise remove
import '../models/exercise.dart'; // Keep if PlanDetailsScreen needs it, otherwise remove
import 'login_screen.dart'; // Import LoginScreen

class AITrainerScreen extends StatefulWidget {
  const AITrainerScreen({super.key});

  @override
  State<AITrainerScreen> createState() => _AITrainerScreenState();
}

class _AITrainerScreenState extends State<AITrainerScreen> {
  // --- Member Variables ---
  final TextEditingController _questionController = TextEditingController();
  bool _isAnalyzing = false;
  bool _isAskingQuestion = false;
  final List<Map<String, dynamic>> _chatMessages = [];
  String _aiInsight = '';

  // --- initState ---
  @override
  void initState() {
    super.initState();
    // Load initial insight only if logged in, after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure the widget is still mounted before accessing context/providers
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isLoggedIn) {
        _getInitialInsight();
      } else {
        // Use mounted check before calling setState
        if (mounted) {
          setState(() {
            _aiInsight = 'Log in to get personalized AI insights and plans.';
          });
        }
      }
    });
  }

  // --- dispose ---
  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  // --- Helper Methods ---
  void _promptLogin(BuildContext context) {
    // Use mounted check before navigation/snackbar
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please log in to use AI features.')),
    );
  }

  Future<void> _getInitialInsight() async {
    if (!mounted) return; // Check if widget is still in the tree
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn) {
      if (mounted) {
        setState(() {
          _aiInsight = 'Log in to get personalized AI insights.';
        });
      }
      return;
    }

    // Proceed only if logged in
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    final aiTrainerProvider = Provider.of<AITrainerProvider>(context, listen: false);

    assert(userProvider.userProfile != null, 'UserProfile is null despite being logged in.');
    if (userProvider.userProfile == null) return; // Added safety check

    if (mounted) {
      setState(() { _isAnalyzing = true; });
    }

    try {
      final recentWorkouts = workoutProvider.workouts;
      final recentMeals = nutritionProvider.meals;
      final insight = await aiTrainerProvider.getAIInsight(
        userProvider.userProfile!, recentWorkouts, recentMeals,
      );
      if (mounted) {
        setState(() { _aiInsight = insight; _isAnalyzing = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiInsight = 'Based on your recent activity, consider focusing on consistency and recovery to reach your fitness goals.';
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _analyzeUserData() async {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn) {
      _promptLogin(context);
      return;
    }
    await _getInitialInsight();
  }

  void _askQuestion() async {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn) {
      _promptLogin(context);
      return;
    }

    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    if (mounted) {
      setState(() {
        _chatMessages.add({'message': question, 'isUser': true});
        _isAskingQuestion = true;
      });
    }

    final aiTrainerProvider = Provider.of<AITrainerProvider>(context, listen: false);
    assert(userProvider.userProfile != null, 'UserProfile is null despite being logged in.');
     if (userProvider.userProfile == null) { // Added safety check
       if (mounted) {
         setState(() { _isAskingQuestion = false; });
       }
       return;
     }


    try {
      final answer = await aiTrainerProvider.answerQuestion(
        question, userProvider.userProfile!,
      );
      if (mounted) {
        setState(() {
          _chatMessages.add({'message': answer, 'isUser': false});
          _isAskingQuestion = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'message': 'I apologize, but I\'m having trouble processing your question at the moment. Please try again later.',
            'isUser': false,
          });
          _isAskingQuestion = false;
        });
      }
    }
    _questionController.clear();
  }

  Future<void> _generateWorkoutPlan(BuildContext context, UserProfile userProfile) async {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn) {
      _promptLogin(context);
      return;
    }
    final aiTrainerProvider = Provider.of<AITrainerProvider>(context, listen: false);

    // Show dialog safely
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog( // Use dialogContext
        title: Text('Generating Your Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating your personalized workout plan using AI...'),
          ],
        ),
      ),
    );

    try {
      await aiTrainerProvider.generateWorkoutPlan(userProfile);
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Close dialog
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate workout plan. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _generateMealPlan(BuildContext context, UserProfile userProfile) async {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn) {
      _promptLogin(context);
      return;
    }
    final aiTrainerProvider = Provider.of<AITrainerProvider>(context, listen: false);

    // Show dialog safely
     showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog( // Use dialogContext
        title: Text('Generating Your Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating your personalized meal plan using AI...'),
          ],
        ),
      ),
    );

    try {
      await aiTrainerProvider.generateMealPlan(userProfile);
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Close dialog
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate meal plan. Please try again.'),
          ),
        );
      }
    }
  }

  void _navigateToPlanDetails(BuildContext context, AIPlan plan) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlanDetailsScreen(plan: plan),
      ),
    );
  }

  void _navigateToAllPlans(BuildContext context) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AllPlansScreen(),
      ),
    );
  }

  Widget _buildGeneratePlanButtons(BuildContext context, UserProfile? userProfile) {
    // This check is technically redundant now due to the main build check, but safe to keep.
    if (userProfile == null) {
      return const Center(
        child: Text('Please complete your profile to generate plans'),
      );
    }

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _generateWorkoutPlan(context, userProfile),
          icon: const Icon(Icons.fitness_center),
          label: const Text('Generate Workout Plan'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _generateMealPlan(context, userProfile),
          icon: const Icon(Icons.restaurant_menu),
          label: const Text('Generate Meal Plan'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  // --- build Method ---
  @override
  Widget build(BuildContext context) {
    return Consumer2<AITrainerProvider, UserProvider>(
      builder: (context, aiTrainerProvider, userProvider, child) {
        final bool isLoggedIn = userProvider.isLoggedIn;
        final UserProfile? userProfile = userProvider.userProfile;
        final plans = aiTrainerProvider.plans;
        final currentPlan = aiTrainerProvider.currentPlan;
        final isLoading = aiTrainerProvider.isLoading;

        // --- Guest View ---
        if (!isLoggedIn) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.smart_toy_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'AI Features Locked',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Log in or sign up to access personalized AI insights, plans, and chat features.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _promptLogin(context),
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
        assert(userProfile != null, 'UserProfile is null despite being logged in.');
        if (userProfile == null) {
          // Fallback in case assertion fails in production or data loading issue
          return const Center(child: Text('Error: User profile not loaded. Please restart the app.'));
        }

        // Main content for logged-in users
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Trainer',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your personalized fitness assistant',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                AIInsightCard(
                  isAnalyzing: _isAnalyzing,
                  onAnalyze: _analyzeUserData,
                  userProfile: userProfile,
                  insightText: _aiInsight,
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: ListView(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Plans',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (plans.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => _navigateToAllPlans(context),
                              icon: const Icon(Icons.list),
                              label: const Text('View All'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (currentPlan != null)
                        PlanCard(
                          plan: currentPlan,
                          onView: () => _navigateToPlanDetails(context, currentPlan),
                        )
                      else
                        _buildGeneratePlanButtons(context, userProfile),

                      const SizedBox(height: 24),

                      AskAICard(
                        controller: _questionController,
                        onAsk: _askQuestion,
                        chatMessages: _chatMessages,
                        isLoading: _isAskingQuestion,
                        onSuggestionTap: (suggestion) {
                          _questionController.text = suggestion;
                          _askQuestion();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} // End of _AITrainerScreenState class

// --- Other Widgets (AIInsightCard, PlanCard, AskAICard, etc.) ---
// Ensure these are defined outside the _AITrainerScreenState class

class AIInsightCard extends StatelessWidget {
  final bool isAnalyzing;
  final VoidCallback onAnalyze;
  final UserProfile? userProfile;
  final String insightText;

  const AIInsightCard({
    super.key,
    required this.isAnalyzing,
    required this.onAnalyze,
    required this.userProfile,
    required this.insightText,
  });

  @override
  Widget build(BuildContext context) {
    final displayInsight = insightText.isEmpty
        ? 'Let me analyze your data to provide personalized insights.'
        : insightText;

    String actionButtonText = 'Analyze My Data';
    if (userProfile != null) {
      // Assuming FitnessGoal is an enum or similar structure
      // Adjust the condition based on your actual FitnessGoal implementation
      if (userProfile!.fitnessGoal.toString().contains('Muscle Gain')) {
        actionButtonText = 'Get Muscle Gain Tips';
      } else if (userProfile!.fitnessGoal.toString().contains('Weight Loss')) {
        actionButtonText = 'Get Weight Loss Tips';
      } else {
        actionButtonText = 'Get Fitness Tips';
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.onTertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'AI Insight',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            isAnalyzing
                ? Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Analyzing your data...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            )
                : Text(
              displayInsight,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isAnalyzing ? null : onAnalyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(actionButtonText),
            ),
          ],
        ),
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  final AIPlan plan;
  final VoidCallback onView;

  const PlanCard({
    super.key,
    required this.plan,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    plan.type == PlanType.workout
                        ? Icons.fitness_center
                        : plan.type == PlanType.nutrition
                        ? Icons.restaurant_menu
                        : Icons.insights,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        plan.type == PlanType.workout
                            ? '${plan.durationInWeeks}-week workout plan'
                            : '${plan.durationInWeeks}-week meal plan',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              plan.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _calculateProgress(plan),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getProgressText(plan),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Ends ${DateFormat('MMM d').format(plan.endDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: onView,
                  child: const Text('View Plan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateProgress(AIPlan plan) {
    final now = DateTime.now();
    if (now.isBefore(plan.startDate)) return 0.0;
    if (now.isAfter(plan.endDate)) return 1.0;
    final totalDuration = plan.endDate.difference(plan.startDate).inDays;
    if (totalDuration <= 0) return 1.0; // Avoid division by zero
    final elapsed = now.difference(plan.startDate).inDays;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }

  String _getProgressText(AIPlan plan) {
    final now = DateTime.now();
    if (now.isBefore(plan.startDate)) {
      return 'Starts ${DateFormat('MMM d').format(plan.startDate)}';
    }
    final progress = _calculateProgress(plan);
    return '${(progress * 100).toInt()}% Complete';
  }
}

class AskAICard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAsk;
  final List<Map<String, dynamic>> chatMessages;
  final bool isLoading;
  final Function(String) onSuggestionTap;

  const AskAICard({
    super.key,
    required this.controller,
    required this.onAsk,
    required this.chatMessages,
    required this.isLoading,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ask AI Trainer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get personalized advice on your fitness journey',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            if (chatMessages.isNotEmpty)
              Container(
                height: 200, // Constrain height
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    reverse: true, // Show latest messages at the bottom
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      // Display messages in reverse order
                      final message = chatMessages[chatMessages.length - 1 - index];
                      return ChatMessage(
                        text: message['message'],
                        isUser: message['isUser'],
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Type your fitness question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onSubmitted: (_) => onAsk(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: isLoading ? null : onAsk,
                  icon: isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text(
              'Suggested questions:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SuggestionChip(
                  label: 'How to improve my bench press?',
                  onTap: () => onSuggestionTap('How to improve my bench press?'),
                ),
                _SuggestionChip(
                  label: 'What should I eat before workout?',
                  onTap: () => onSuggestionTap('What should I eat before workout?'),
                ),
                _SuggestionChip(
                  label: 'How to reduce muscle soreness?',
                  onTap: () => onSuggestionTap('How to reduce muscle soreness?'),
                ),
                _SuggestionChip(
                  label: 'How much protein should I eat daily?',
                  onTap: () => onSuggestionTap('How much protein should I eat daily?'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              radius: 16,
              child: const Icon(
                Icons.smart_toy,
                size: 18,
                color: Colors.white,
              ),
            ),
          if (!isUser) const SizedBox(width: 8), // Add space only for AI messages
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8), // Add space only for user messages
          if (isUser)
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              radius: 16,
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant) // Add subtle border
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Adjust padding
      ),
    );
  }
}

// All Plans Screen
class AllPlansScreen extends StatelessWidget {
  const AllPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Plans'),
      ),
      body: Consumer<AITrainerProvider>(
        builder: (context, aiTrainerProvider, child) {
          final plans = aiTrainerProvider.plans;
          final isLoading = aiTrainerProvider.isLoading;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (plans.isEmpty) {
            return const Center(
              child: Text('No plans generated yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              return PlanCard(
                plan: plans[index],
                onView: () => _navigateToPlanDetails(context, plans[index]),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToPlanDetails(BuildContext context, AIPlan plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlanDetailsScreen(plan: plan),
      ),
    );
  }
}

// Plan Details Screen
class PlanDetailsScreen extends StatelessWidget {
  final AIPlan plan;

  const PlanDetailsScreen({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plan.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Plan header
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          plan.type == PlanType.workout
                              ? Icons.fitness_center
                              : plan.type == PlanType.nutrition
                              ? Icons.restaurant_menu
                              : Icons.insights,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              '${plan.durationInWeeks}-week plan',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    plan.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Start: ${DateFormat('MMM d, yyyy').format(plan.startDate)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'End: ${DateFormat('MMM d, yyyy').format(plan.endDate)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Daily Plan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...plan.days.map((day) => _buildDayCard(context, day, plan.type)),
        ],
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, PlanDay day, PlanType planType) {
    // Build the list of meal widgets separately with proper type checking
    List<Widget> mealWidgets = [];
    if (day.meals != null && day.meals!.isNotEmpty) {
      mealWidgets.add(
        Padding(
          padding: EdgeInsets.only(top: (day.notes != null || day.workout != null) ? 16.0 : 0.0),
          child: Text(
            'Meals',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      );
      mealWidgets.add(const SizedBox(height: 8));

      for (var mealObj in day.meals!) {
        // Assuming mealObj is actually a Meal object based on the build error
        if (mealObj is Meal) {
          final Map<String, dynamic> mealMap = mealObj.toJson(); // Call toJson()
          final mealName = mealMap['name']?.toString() ?? 'Meal';
          // Type needs to be parsed from the map now (it's a String from toJson)
          final mealType = mealMap['type']?.toString() ?? '';
          final calories = (mealMap['totalCalories'] as num?)?.toDouble() ?? 0.0;
          final protein = (mealMap['totalProtein'] as num?)?.toDouble() ?? 0.0;
          final carbs = (mealMap['totalCarbs'] as num?)?.toDouble() ?? 0.0;
          final fat = (mealMap['totalFat'] as num?)?.toDouble() ?? 0.0;

          mealWidgets.add(
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _getMealIcon(mealType),
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(mealName),
              subtitle: Text(
                '${calories.toInt()} kcal | P: ${protein.toInt()}g | C: ${carbs.toInt()}g | F: ${fat.toInt()}g',
              ),
            )
          );
        } else {
          // Log error or handle unexpected type
          print('Error: Unexpected meal object type in PlanDetailsScreen: ${mealObj.runtimeType}');
          // Optionally add a placeholder widget for the error case
          // mealWidgets.add(const Text('Error loading meal data'));
        }
      }
    }


    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Day ${day.dayNumber}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (planType == PlanType.workout)
                  _buildDayTypeChip(context, day.workout != null ? 'Workout' : 'Rest')
                else if (planType == PlanType.nutrition)
                  _buildDayTypeChip(context, 'Nutrition')
                else // Combined plan type
                  _buildDayTypeChip(context, day.workout != null ? 'Workout' : 'Nutrition'),
              ],
            ),
            const SizedBox(height: 16),

            if (day.notes != null) Text(day.notes!),

            if (day.workout != null) ...[
              if (day.notes != null) const SizedBox(height: 16),
              Text(
                'Workout: ${day.workout!.name}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...day.workout!.exercises.map((exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatExerciseDetails(exercise),
                        maxLines: 2, // Allow wrapping
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
            ],

            // Spread the pre-built meal widgets here
            ...mealWidgets,

          ],
        ),
      ),
    );
  }

  String _formatExerciseDetails(Exercise exercise) {
    if (exercise.sets != null && exercise.sets!.isNotEmpty) {
      final firstSet = exercise.sets!.first;
      final weightString = firstSet.weight != null ? ' (${firstSet.weight}kg)' : '';
      return '${exercise.name}: ${exercise.sets!.length} × ${firstSet.reps}$weightString';
    } else if (exercise.duration != null) {
       return '${exercise.name}: ${exercise.duration!.inMinutes} min';
    }
    return exercise.name;
  }

  IconData _getMealIcon(String mealType) {
     if (mealType.toLowerCase().contains('breakfast')) return Icons.wb_sunny;
     if (mealType.toLowerCase().contains('lunch')) return Icons.wb_twilight;
     if (mealType.toLowerCase().contains('dinner')) return Icons.nights_stay;
     return Icons.fastfood; // Default for snacks or other
  }


  Widget _buildDayTypeChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
