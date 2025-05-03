// screens/workout_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../providers/user_provider.dart'; // Import UserProvider
import 'login_screen.dart'; // Import LoginScreen

class WorkoutTrackerScreen extends StatefulWidget {
  const WorkoutTrackerScreen({super.key});

  @override
  State<WorkoutTrackerScreen> createState() => _WorkoutTrackerScreenState();
}

class _WorkoutTrackerScreenState extends State<WorkoutTrackerScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    // Load data for today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkouts();
    });
  }

  Future<void> _loadWorkouts() async {
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    await workoutProvider.changeSelectedDate(_selectedDate);
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });

      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      await workoutProvider.changeSelectedDate(_selectedDate);
    }
  }

  // Helper function to prompt login
  void _promptLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    // Optionally show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please log in to perform this action.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, child) {
        final workouts = workoutProvider.workouts;
        final isLoading = workoutProvider.isLoading;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workout Tracker',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            DateFormat('MMMM d, yyyy').format(_selectedDate),
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _loadWorkouts,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Workout summary card
                const WorkoutSummaryCard(),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Your Workouts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _navigateToAddWorkout(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Workout'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Display the list of workouts
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : workouts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fitness_center_outlined,
                                    size: 64,
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No workouts recorded yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _navigateToAddWorkout(context),
                                    child:
                                        const Text('Record Your First Workout'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: workouts.length,
                              itemBuilder: (context, index) {
                                return WorkoutCard(
                                  workout: workouts[index],
                                  onEdit: () => _navigateToEditWorkout(
                                      context, workouts[index]),
                                  onDelete: () => _deleteWorkout(
                                      context, workouts[index].id),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToAddWorkout(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn) {
      _promptLogin(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddWorkoutScreen(selectedDate: _selectedDate),
      ),
    );
  }

  void _navigateToEditWorkout(BuildContext context, Workout workout) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn) {
      _promptLogin(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditWorkoutScreen(workout: workout),
      ),
    );
  }

  Future<void> _deleteWorkout(BuildContext context, String workoutId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn) {
      _promptLogin(context);
      return;
    }

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Workout'),
            content:
                const Text('Are you sure you want to delete this workout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldDelete) {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      await workoutProvider.deleteWorkout(workoutId);
    }
  }
}

class WorkoutSummaryCard extends StatelessWidget {
  const WorkoutSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, child) {
        final workouts = workoutProvider.workouts;

        // Calculate total workout time, calories, and exercises
        int totalMinutes = 0;
        int totalCalories = 0;
        int totalExercises = 0;

        for (final workout in workouts) {
          totalMinutes += workout.duration.inMinutes;
          totalCalories += workout.caloriesBurned;
          totalExercises += workout.exercises.length;
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _WorkoutStat(
                      icon: Icons.fitness_center,
                      value: workouts.length.toString(),
                      label: 'Workouts',
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    Container(
                      height: 50,
                      width: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer
                          .withOpacity(0.2),
                    ),
                    _WorkoutStat(
                      icon: Icons.timer,
                      value: totalMinutes > 0
                          ? totalMinutes >= 60
                              ? '${totalMinutes ~/ 60}h ${totalMinutes % 60}m'
                              : '${totalMinutes}m'
                          : '0m',
                      label: 'Total Time',
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    Container(
                      height: 50,
                      width: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer
                          .withOpacity(0.2),
                    ),
                    _WorkoutStat(
                      icon: Icons.local_fire_department,
                      value: totalCalories.toString(),
                      label: 'Calories',
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WorkoutStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _WorkoutStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.8),
              ),
        ),
      ],
    );
  }
}

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WorkoutCard({
    super.key,
    required this.workout,
    required this.onEdit,
    required this.onDelete,
  });

  String _getWorkoutTypeLabel(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return 'Strength';
      case WorkoutType.cardio:
        return 'Cardio';
      case WorkoutType.hiit:
        return 'HIIT';
      case WorkoutType.flexibility:
        return 'Flexibility';
      case WorkoutType.balance:
        return 'Balance';
      case WorkoutType.sports:
        return 'Sports';
      case WorkoutType.rest:
        return 'Rest';
      case WorkoutType.other:
        return 'Other';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  workout.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getWorkoutTypeLabel(workout.type),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _WorkoutDetail(
                  icon: Icons.timer,
                  label: 'Duration',
                  value: _formatDuration(workout.duration),
                ),
                const SizedBox(width: 24),
                _WorkoutDetail(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: workout.caloriesBurned.toString(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Exercises',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...workout.exercises.map((exercise) {
              final firstSet = exercise.sets?.isNotEmpty == true
                  ? exercise.sets!.first
                  : null;
              final reps = firstSet?.reps ?? 0;
              final weight = firstSet?.weight ?? 0.0;

              // Use exercise.duration only — not from set
              final duration = exercise.duration;

              // Improved regex – more inclusive
              final isNonWeighted = RegExp(
                r'\b(yoga|hiit|plank|crunch|pull.?ups?|push.?ups?|run|walk|burpee|climber|jumping jack|bodyweight|stretch|mobility|recovery|cardio|sit.?ups?|mountain climbers?)\b',
                caseSensitive: false,
              ).hasMatch(exercise.name);

              final showWeight = !isNonWeighted && weight > 0;
              final weightDisplay =
                  showWeight ? ' (${weight.toStringAsFixed(1)}kg)' : '';

              final durationDisplay = duration != null && duration.inSeconds > 0
                  ? ' – ${duration.inMinutes} min'
                  : '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${exercise.name}: ${exercise.sets?.length ?? 1} × $reps$weightDisplay$durationDisplay',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit workout',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete workout',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WorkoutDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

// Add Workout Screen
class AddWorkoutScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddWorkoutScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _durationController =
      TextEditingController(text: '30');
  final TextEditingController _caloriesController = TextEditingController();

  WorkoutType _selectedWorkoutType = WorkoutType.strength;
  final List<Exercise> _selectedExercises = [];
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Workout'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Workout name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workout Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a workout name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Workout type dropdown
            DropdownButtonFormField<WorkoutType>(
              value: _selectedWorkoutType,
              decoration: const InputDecoration(
                labelText: 'Workout Type',
                border: OutlineInputBorder(),
              ),
              items: WorkoutType.values.map((type) {
                return DropdownMenuItem<WorkoutType>(
                  value: type,
                  child: Text(_getWorkoutTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedWorkoutType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Time picker
            ListTile(
              title: const Text('Time'),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null && picked != _selectedTime) {
                  setState(() {
                    _selectedTime = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Duration field
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter workout duration';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Please enter a valid duration';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Calories burned field
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories Burned (estimated)',
                border: OutlineInputBorder(),
                hintText: 'Leave empty for automatic calculation',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Exercises section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exercises',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // List of selected exercises
                    if (_selectedExercises.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('No exercises added yet'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _selectedExercises[index];
                          return ListTile(
                            title: Text(exercise.name),
                            subtitle: exercise.sets != null &&
                                    exercise.sets!.isNotEmpty
                                ? Text(
                                    '${exercise.sets!.length} sets × ${exercise.sets!.first.reps} reps')
                                : Text(exercise.targetMuscleGroup ??
                                    'No target specified'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red,
                              onPressed: () {
                                setState(() {
                                  _selectedExercises.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),

                    // Add exercise button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToAddExercise(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Exercise'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _saveWorkout,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Save Workout'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddExercise(BuildContext context) async {
    final result = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => const AddExerciseScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedExercises.add(result);
      });
    }
  }

  Future<void> _saveWorkout() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a workout name')),
      );
      return;
    }

    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    final exercise = Exercise(
      id: const Uuid().v4(),
      name: _nameController.text,
      targetMuscleGroup: 'Full Body',
      description: _getWorkoutTypeDescription(_selectedWorkoutType),
      sets:
          _selectedExercises.isNotEmpty ? List.from(_selectedExercises) : null,
      duration: Duration(minutes: int.tryParse(_durationController.text) ?? 0),
      caloriesBurnedPerMinute: _getCaloriesPerMinute(_selectedWorkoutType),
    );

    final caloriesBurned = int.tryParse(_caloriesController.text) ?? 0;
    await workoutProvider.addWorkout(
      _nameController.text,
      widget.selectedDate,
      Duration(minutes: int.tryParse(_durationController.text) ?? 0),
      _selectedWorkoutType,
      [exercise],
      caloriesBurned,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _getWorkoutTypeLabel(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return 'Strength';
      case WorkoutType.cardio:
        return 'Cardio';
      case WorkoutType.hiit:
        return 'HIIT';
      case WorkoutType.flexibility:
        return 'Flexibility';
      case WorkoutType.balance:
        return 'Balance';
      case WorkoutType.sports:
        return 'Sports';
      case WorkoutType.other:
        return 'Other';
      case WorkoutType.rest:
        return 'Rest';
    }
  }

  String _getWorkoutTypeDescription(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return 'Weight training and resistance exercises';
      case WorkoutType.cardio:
        return 'Aerobic exercises for cardiovascular health';
      case WorkoutType.hiit:
        return 'High-intensity interval training';
      case WorkoutType.flexibility:
        return 'Stretching and mobility exercises';
      case WorkoutType.balance:
        return 'Balance and stability exercises';
      case WorkoutType.sports:
        return 'Sports-specific training';
      case WorkoutType.rest:
        return 'Rest and recovery';
      case WorkoutType.other:
        return 'Other types of physical activity';
    }
  }

  double _getCaloriesPerMinute(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return 8.0;
      case WorkoutType.cardio:
        return 10.0;
      case WorkoutType.hiit:
        return 12.0;
      case WorkoutType.flexibility:
        return 3.0;
      case WorkoutType.balance:
        return 4.0;
      case WorkoutType.sports:
        return 9.0;
      case WorkoutType.rest:
        return 1.0;
      case WorkoutType.other:
        return 6.0;
    }
  }
}

// Edit Workout Screen
class EditWorkoutScreen extends StatefulWidget {
  final Workout workout;

  const EditWorkoutScreen({
    super.key,
    required this.workout,
  });

  @override
  State<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends State<EditWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _durationController;
  late TextEditingController _caloriesController;

  late WorkoutType _selectedWorkoutType;
  late List<Exercise> _selectedExercises;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workout.name);
    _notesController = TextEditingController(text: widget.workout.notes);
    _durationController = TextEditingController(
        text: widget.workout.duration.inMinutes.toString());
    _caloriesController =
        TextEditingController(text: widget.workout.caloriesBurned.toString());
    _selectedWorkoutType = widget.workout.type;
    _selectedExercises = List.from(widget.workout.exercises);
    _selectedTime = TimeOfDay(
      hour: widget.workout.dateTime.hour,
      minute: widget.workout.dateTime.minute,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Workout'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Workout name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workout Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a workout name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Workout type dropdown
            DropdownButtonFormField<WorkoutType>(
              value: _selectedWorkoutType,
              decoration: const InputDecoration(
                labelText: 'Workout Type',
                border: OutlineInputBorder(),
              ),
              items: WorkoutType.values.map((type) {
                return DropdownMenuItem<WorkoutType>(
                  value: type,
                  child: Text(_getWorkoutTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedWorkoutType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Time picker
            ListTile(
              title: const Text('Time'),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null && picked != _selectedTime) {
                  setState(() {
                    _selectedTime = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Duration field
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter workout duration';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Please enter a valid duration';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Calories burned field
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories Burned',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter calories burned';
                }
                if (double.tryParse(value) == null || double.parse(value) < 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Exercises section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exercises',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // List of selected exercises
                    if (_selectedExercises.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('No exercises added yet'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _selectedExercises[index];
                          return ListTile(
                            title: Text(exercise.name),
                            subtitle: exercise.sets != null &&
                                    exercise.sets!.isNotEmpty
                                ? Text(
                                    '${exercise.sets!.length} sets × ${exercise.sets!.first.reps} reps')
                                : Text(exercise.targetMuscleGroup ??
                                    'No target specified'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red,
                              onPressed: () {
                                setState(() {
                                  _selectedExercises.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),

                    // Add exercise button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToAddExercise(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Exercise'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Update button
            ElevatedButton(
              onPressed: _updateWorkout,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Update Workout'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddExercise(BuildContext context) async {
    final result = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => const AddExerciseScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedExercises.add(result);
      });
    }
  }

  void _updateWorkout() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedExercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one exercise'),
          ),
        );
        return;
      }

      // Create DateTime with original date and selected time
      final originalDate = widget.workout.dateTime;
      final dateTime = DateTime(
        originalDate.year,
        originalDate.month,
        originalDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Update workout
      final updatedWorkout = Workout(
        id: widget.workout.id,
        name: _nameController.text,
        dateTime: dateTime,
        duration: Duration(minutes: int.parse(_durationController.text)),
        type: _selectedWorkoutType,
        exercises: _selectedExercises,
        caloriesBurned: int.parse(_caloriesController.text),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      await workoutProvider.updateWorkout(updatedWorkout);

      Navigator.of(context).pop();
    }
  }

  String _getWorkoutTypeLabel(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return 'Strength';
      case WorkoutType.cardio:
        return 'Cardio';
      case WorkoutType.hiit:
        return 'HIIT';
      case WorkoutType.flexibility:
        return 'Flexibility';
      case WorkoutType.balance:
        return 'Balance';
      case WorkoutType.sports:
        return 'Sports';
      case WorkoutType.rest:
        return 'Rest';
      case WorkoutType.other:
        return 'Other';
    }
  }
}

// Add Exercise Screen
class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final TextEditingController _searchController = TextEditingController();

  Exercise? _selectedExercise;
  List<Exercise> _searchResults = [];
  bool _isLoading = false;
  bool _isCustomExercise = false;
  final Uuid _uuid = const Uuid();

  // Controllers for custom exercise
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _muscleGroupController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();

  // Strength training set fields
  bool _hasStrengthSets = false;
  final TextEditingController _setsController =
      TextEditingController(text: '3');
  final TextEditingController _repsController =
      TextEditingController(text: '12');
  final TextEditingController _weightController =
      TextEditingController(text: '0');
  final TextEditingController _durationController =
      TextEditingController(text: '0');

  final WorkoutType _selectedType = WorkoutType.strength;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
    });

    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    _searchResults = workoutProvider.searchExercises('');

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _muscleGroupController.dispose();
    _caloriesController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Exercise'),
        actions: [
          IconButton(
            icon: Icon(_isCustomExercise ? Icons.list : Icons.add),
            onPressed: () {
              setState(() {
                _isCustomExercise = !_isCustomExercise;
              });
            },
            tooltip:
                _isCustomExercise ? 'Search Exercise' : 'Add Custom Exercise',
          ),
        ],
      ),
      body: _isCustomExercise
          ? _buildCustomExerciseForm()
          : _buildSearchExerciseForm(),
    );
  }

  Widget _buildSearchExerciseForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Exercise',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searchExercises,
              ),
            ),
            onSubmitted: (_) => _searchExercises(),
          ),
        ),

        // Results or loading indicator
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
                  ? const Center(child: Text('No exercises found'))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final exercise = _searchResults[index];
                        return ListTile(
                          title: Text(exercise.name),
                          subtitle: Text(exercise.targetMuscleGroup ??
                              'No target specified'),
                          onTap: () {
                            setState(() {
                              _selectedExercise = exercise;
                            });
                            _showExerciseDetailsDialog(context, exercise);
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCustomExerciseForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Custom Exercise',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Name field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Exercise Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Description field
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Target muscle group field
          TextFormField(
            controller: _muscleGroupController,
            decoration: const InputDecoration(
              labelText: 'Target Muscle Group',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Calories burned field
          TextFormField(
            controller: _caloriesController,
            decoration: const InputDecoration(
              labelText: 'Calories Burned per Minute (Optional)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),

          // Strength training switch
          SwitchListTile(
            title: const Text('Strength Training (sets & reps)'),
            value: _hasStrengthSets,
            onChanged: (value) {
              setState(() {
                _hasStrengthSets = value;
              });
            },
          ),

          // Strength training fields
          if (_hasStrengthSets) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                // Sets field
                Expanded(
                  child: TextFormField(
                    controller: _setsController,
                    decoration: const InputDecoration(
                      labelText: 'Sets',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),

                // Reps field
                Expanded(
                  child: TextFormField(
                    controller: _repsController,
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weight field
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (kg, optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],

          const SizedBox(height: 24),

          // Add button
          ElevatedButton(
            onPressed: _addCustomExercise,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Add Custom Exercise'),
          ),
        ],
      ),
    );
  }

  void _searchExercises() {
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    setState(() {
      _searchResults = workoutProvider.searchExercises(_searchController.text);
    });
  }

  void _showExerciseDetailsDialog(BuildContext context, Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exercise.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (exercise.description != null) ...[
                Text(
                  'Description:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(exercise.description!),
                const SizedBox(height: 16),
              ],
              Text(
                'Target Muscle Group:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(exercise.targetMuscleGroup ?? 'Not specified'),

              const SizedBox(height: 16),

              // Strength training fields
              SwitchListTile(
                title: const Text('Add Sets & Reps'),
                value: _hasStrengthSets ?? false,
                onChanged: (value) {
                  setState(() {
                    _hasStrengthSets = value;
                  });
                  Navigator.of(context).pop();
                  _showExerciseDetailsDialog(context, exercise);
                },
              ),

              if (_hasStrengthSets) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Sets field
                    Expanded(
                      child: TextFormField(
                        controller: _setsController,
                        decoration: const InputDecoration(
                          labelText: 'Sets',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Reps field
                    Expanded(
                      child: TextFormField(
                        controller: _repsController,
                        decoration: const InputDecoration(
                          labelText: 'Reps',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Weight field
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg, optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Create a copy of the exercise with sets if needed
              Exercise selectedExercise;

              if (_hasStrengthSets) {
                final sets = int.tryParse(_setsController.text) ?? 3;
                final reps = int.tryParse(_repsController.text) ?? 12;
                final weight = double.tryParse(_weightController.text);

                // Create exercise sets
                final exerciseSets = List.generate(
                  sets,
                  (_) => ExerciseSet(
                    reps: reps,
                    weight: weight,
                  ),
                );

                selectedExercise = Exercise(
                  id: exercise.id,
                  name: exercise.name,
                  description: exercise.description,
                  targetMuscleGroup: exercise.targetMuscleGroup,
                  caloriesBurnedPerMinute: exercise.caloriesBurnedPerMinute,
                  sets: exerciseSets,
                );
              } else {
                selectedExercise = exercise;
              }

              Navigator.of(context).pop();
              Navigator.of(context).pop(selectedExercise);
            },
            child: const Text('Add Exercise'),
          ),
        ],
      ),
    );
  }

  void _addCustomExercise() async {
    // Validate inputs
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an exercise name'),
        ),
      );
      return;
    }

    // Create custom exercise
    final id = 'custom_${_uuid.v4()}';
    final name = _nameController.text;
    final description = _descriptionController.text.isEmpty
        ? null
        : _descriptionController.text;
    final targetMuscleGroup = _muscleGroupController.text.isEmpty
        ? null
        : _muscleGroupController.text;
    final caloriesBurnedPerMinute = double.tryParse(_caloriesController.text);

    // Create exercise sets if needed
    List<ExerciseSet>? exerciseSets;
    if (_hasStrengthSets) {
      final sets = int.tryParse(_setsController.text) ?? 3;
      final reps = int.tryParse(_repsController.text) ?? 12;
      final weight = double.tryParse(_weightController.text);

      exerciseSets = List.generate(
        sets,
        (_) => ExerciseSet(
          reps: reps,
          weight: weight,
        ),
      );
    }

    final customExercise = Exercise(
      id: id ?? const Uuid().v4(),
      name: name ?? '',
      description: description,
      targetMuscleGroup: targetMuscleGroup ?? 'Not specified',
      caloriesBurnedPerMinute: caloriesBurnedPerMinute,
      sets: exerciseSets,
    );

    // Save custom exercise
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    await workoutProvider.addCustomExercise(customExercise);

    // Navigate back with the new exercise
    if (mounted) {
      Navigator.of(context).pop(customExercise);
    }
  }

  String _getWorkoutTypeIcon(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return '💪';
      case WorkoutType.cardio:
        return '🏃';
      case WorkoutType.hiit:
        return '⚡';
      case WorkoutType.flexibility:
        return '🧘';
      case WorkoutType.balance:
        return '⚖️';
      case WorkoutType.sports:
        return '⚽';
      case WorkoutType.rest:
        return '😴';
      case WorkoutType.other:
        return '🏋️';
    }
  }

  String _getWorkoutTypeLabel(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return 'Strength';
      case WorkoutType.cardio:
        return 'Cardio';
      case WorkoutType.hiit:
        return 'HIIT';
      case WorkoutType.flexibility:
        return 'Flexibility';
      case WorkoutType.balance:
        return 'Balance';
      case WorkoutType.sports:
        return 'Sports';
      case WorkoutType.rest:
        return 'Rest';
      case WorkoutType.other:
        return 'Other';
    }
  }

  String _getWorkoutTypeDescription(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return 'Weight training and resistance exercises';
      case WorkoutType.cardio:
        return 'Aerobic exercises for cardiovascular health';
      case WorkoutType.hiit:
        return 'High-intensity interval training';
      case WorkoutType.flexibility:
        return 'Stretching and mobility exercises';
      case WorkoutType.balance:
        return 'Balance and stability exercises';
      case WorkoutType.sports:
        return 'Sports-specific training';
      case WorkoutType.rest:
        return 'Rest and recovery';
      case WorkoutType.other:
        return 'Other types of physical activity';
    }
  }

  double _getCaloriesPerMinute(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return 8.0;
      case WorkoutType.cardio:
        return 10.0;
      case WorkoutType.hiit:
        return 12.0;
      case WorkoutType.flexibility:
        return 3.0;
      case WorkoutType.balance:
        return 4.0;
      case WorkoutType.sports:
        return 9.0;
      case WorkoutType.rest:
        return 1.0; // Minimal calorie burn for rest
      case WorkoutType.other:
        return 6.0;
    }
  }
}
