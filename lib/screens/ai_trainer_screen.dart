// screens/ai_trainer_screen.dart (updated)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/ai_plan.dart';
import '../models/user_profile.dart';
import '../providers/ai_trainer_provider.dart';
import '../providers/user_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/workout_provider.dart';

class AITrainerScreen extends StatefulWidget {
  const AITrainerScreen({super.key});

  @override
  State<AITrainerScreen> createState() => _AITrainerScreenState();
}

class _AITrainerScreenState extends State<AITrainerScreen> {
  final TextEditingController _questionController = TextEditingController();
  bool _isAnalyzing = false;
  bool _isAskingQuestion = false;
  final List<Map<String, dynamic>> _chatMessages = [];
  String _aiInsight = '';

  @override
  void initState() {
    super.initState();
    // Get an initial AI insight when the screen loads
    _getInitialInsight();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _getInitialInsight() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    final aiTrainerProvider = Provider.of<AITrainerProvider>(context, listen: false);

    if (userProvider.userProfile != null) {
      setState(() {
        _isAnalyzing = true;
      });

      try {
        // Get recent workouts and meals
        final recentWorkouts = workoutProvider.workouts;
        final recentMeals = nutritionProvider.meals;

        // Get an AI-generated insight
        final insight = await aiTrainerProvider.getAIInsight(
          userProvider.userProfile!,
          recentWorkouts,
          recentMeals,
        );

        setState(() {
          _aiInsight = insight;
          _isAnalyzing = false;
        });
      } catch (e) {
        setState(() {
          _aiInsight = 'Based on your recent activity, consider focusing on consistency and recovery to reach your fitness goals.';
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _analyzeUserData() async {
    // Re-get the insight
    await _getInitialInsight();
  }

  void _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _chatMessages.add({
        'message': question,
        'isUser': true,
      });
      _isAskingQuestion = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final aiTrainerProvider = Provider.of<AITrainerProvider>(context, listen: false);

    if (userProvider.userProfile != null) {
      try {
        // Get AI-generated answer to the question
        final answer = await aiTrainerProvider.answerQuestion(
          question,
          userProvider.userProfile!,
        );

        setState(() {
          _chatMessages.add({
            'message': answer,
            'isUser': false,
          });
          _isAskingQuestion = false;
        });
      } catch (e) {
        setState(() {
          _chatMessages.add({
            'message': 'I apologize, but I\'m having trouble processing your question at the moment. Please try again later.',
            'isUser': false,
          });
          _isAskingQuestion = false;
        });
      }
    } else {
      setState(() {
        _chatMessages.add({
          'message': 'Please complete your profile first so I can provide personalized advice.',
          'isUser': false,
        });
        _isAskingQuestion = false;
      });
    }

    _questionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AITrainerProvider, UserProvider>(
      builder: (context, aiTrainerProvider, userProvider, child) {
        final plans = aiTrainerProvider.plans;
        final currentPlan = aiTrainerProvider.currentPlan;
        final isLoading = aiTrainerProvider.isLoading;
        final userProfile = userProvider.userProfile;

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

                // AI Insight Card - Now using OpenAI-generated content
                AIInsightCard(
                  isAnalyzing: _isAnalyzing,
                  onAnalyze: _analyzeUserData,
                  userProfile: userProfile,
                  insightText: _aiInsight,
                ),

                const SizedBox(height: 24),

                // Plans section
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

                      // Current plan or generate plan buttons
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

                      // Ask AI section - Now using OpenAI for responses
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

  Widget _buildGeneratePlanButtons(BuildContext context, UserProfile? userProfile) {
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

  Future<void> _generateWorkoutPlan(BuildContext context, UserProfile userProfile) async {
    final aiTrainerProvider = Provider.of<AITrainerProvider>(context, listen: false);

    // Show a dialog to indicate generation is in progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
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

      // Close the dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close the dialog and show error
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate workout plan. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _generateMealPlan(BuildContext context, UserProfile userProfile) async {
    final aiTrainerProvider = Provider.of<AITrainerProvider>(context, listen: false);

    // Show a dialog to indicate generation is in progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
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

      // Close the dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close the dialog and show error
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate meal plan. Please try again.'),
          ),
        );
      }
    }
  }

  void _navigateToPlanDetails(BuildContext context, AIPlan plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlanDetailsScreen(plan: plan),
      ),
    );
  }

  void _navigateToAllPlans(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AllPlansScreen(),
      ),
    );
  }
}

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
    // Default insight if none is provided
    final displayInsight = insightText.isEmpty
        ? 'Let me analyze your data to provide personalized insights.'
        : insightText;

    // Action button text based on user profile
    String actionButtonText = 'Analyze My Data';

    if (userProfile != null) {
      if (userProfile!.fitnessGoal.name == 'Muscle Gain') {
        actionButtonText = 'Get Muscle Gain Tips';
      } else if (userProfile!.fitnessGoal.name == 'Weight Loss') {
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

    if (now.isBefore(plan.startDate)) {
      return 0.0;
    }

    if (now.isAfter(plan.endDate)) {
      return 1.0;
    }

    final totalDuration = plan.endDate.difference(plan.startDate).inDays;
    final elapsed = now.difference(plan.startDate).inDays;

    return elapsed / totalDuration;
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

            // Chat messages
            if (chatMessages.isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final message = chatMessages[index];
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
          const SizedBox(width: 8),
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
          const SizedBox(width: 8),
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
        ),
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
                      Text(
                        'Start: ${DateFormat('MMM d, yyyy').format(plan.startDate)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'End: ${DateFormat('MMM d, yyyy').format(plan.endDate)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Plan days
          Text(
            'Daily Plan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // List of days
          ...plan.days.map((day) => _buildDayCard(context, day, plan.type)),
        ],
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, PlanDay day, PlanType planType) {
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
                else
                  _buildDayTypeChip(context, day.workout != null ? 'Workout' : 'Nutrition'),
              ],
            ),
            const SizedBox(height: 16),

            // Plan content
            if (day.notes != null)
              Text(day.notes!),

            if (day.workout != null) ...[
              const SizedBox(height: 16),
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
                    const Icon(
                      Icons.circle,
                      size: 8,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exercise.sets != null && exercise.sets!.isNotEmpty
                            ? '${exercise.name}: ${exercise.sets!.length} × ${exercise.sets!.first.reps}${exercise.sets!.first.weight != null ? ' (${exercise.sets!.first.weight}kg)' : ''}'
                            : exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
            ],

            if (day.meals != null && day.meals!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Meals',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...day.meals!.map((meal) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  meal.type == MealType.breakfast
                      ? Icons.wb_sunny
                      : meal.type == MealType.lunch
                      ? Icons.wb_twilight
                      : meal.type == MealType.dinner
                      ? Icons.nights_stay
                      : Icons.fastfood,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(meal.name),
                subtitle: Text(
                  '${meal.totalCalories.toInt()} kcal | P: ${meal.totalProtein.toInt()}g | C: ${meal.totalCarbs.toInt()}g | F: ${meal.totalFat.toInt()}g',
                ),
              )),
            ],
          ],
        ),
      ),
    );
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