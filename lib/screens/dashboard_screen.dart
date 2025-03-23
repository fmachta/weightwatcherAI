// screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/workout_provider.dart';
import '../models/body_measurement.dart';
import '../models/workout.dart';
import '../models/daily_nutrition.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer3<UserProvider, NutritionProvider, WorkoutProvider>(
      builder: (context, userProvider, nutritionProvider, workoutProvider, child) {
        final userProfile = userProvider.userProfile;
        final bodyMeasurements = userProvider.bodyMeasurements;
        final recentWorkouts = workoutProvider.workouts;
        final dailyNutrition = nutritionProvider.dailyNutrition;

        if (userProfile == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Text(
                  'Hello, ${userProfile.name}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Here\'s your fitness summary',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Current Weight',
                        value: '${userProfile.currentWeight.toStringAsFixed(1)} kg',
                        icon: Icons.monitor_weight,
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Target Weight',
                        value: '${userProfile.targetWeight.toStringAsFixed(1)} kg',
                        icon: Icons.flag,
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Body Fat',
                        value: '${userProfile.bodyFat.toStringAsFixed(1)}%',
                        icon: Icons.water_drop,
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Muscle Mass',
                        value: '${userProfile.muscleMass.toStringAsFixed(1)}%',
                        icon: Icons.fitness_center,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Weight progress chart
                if (bodyMeasurements.isNotEmpty)
                  _WeightProgressChart(measurements: bodyMeasurements),

                const SizedBox(height: 24),

                // Today's summary
                Text(
                  'Today\'s Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Calorie summary
                if (dailyNutrition != null)
                  _CalorieSummaryCard(dailyNutrition: dailyNutrition),

                const SizedBox(height: 16),

                // Recent workouts
                Text(
                  'Recent Workouts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (recentWorkouts.isEmpty)
                  const Center(
                    child: Text('No recent workouts'),
                  )
                else
                  _RecentWorkoutsCard(workouts: recentWorkouts.take(3).toList()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightProgressChart extends StatelessWidget {
  final List<BodyMeasurement> measurements;

  const _WeightProgressChart({
    required this.measurements,
  });

  @override
  Widget build(BuildContext context) {
    // Sort measurements by date
    final sortedMeasurements = List<BodyMeasurement>.from(measurements)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Only display last 7 measurements
    final displayedMeasurements = sortedMeasurements.length > 7
        ? sortedMeasurements.sublist(sortedMeasurements.length - 7)
        : sortedMeasurements;

    // Calculate min and max weight for y-axis
    final weights = displayedMeasurements.map((m) => m.weight).toList();
    final minWeight = weights.reduce((curr, next) => curr < next ? curr : next);
    final maxWeight = weights.reduce((curr, next) => curr > next ? curr : next);

    // Add padding to min and max
    final yMin = (minWeight - 2).clamp(0, double.infinity);
    final yMax = maxWeight + 2;

    return Card(
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
              'Weight Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < displayedMeasurements.length) {
                            final date = displayedMeasurements[value.toInt()].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MM/dd').format(date),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  minX: 0,
                  maxX: displayedMeasurements.length - 1.toDouble(),
                  minY: yMin,
                  maxY: yMax,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        displayedMeasurements.length,
                            (index) => FlSpot(
                          index.toDouble(),
                          displayedMeasurements[index].weight,
                        ),
                      ),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 4,
                              color: Theme.of(context).colorScheme.primary,
                              strokeWidth: 1,
                              strokeColor: Theme.of(context).colorScheme.surface,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalorieSummaryCard extends StatelessWidget {
  final DailyNutrition dailyNutrition;

  const _CalorieSummaryCard({
    required this.dailyNutrition,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Calories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${dailyNutrition.totalCalories.toInt()} / ${dailyNutrition.calorieGoal.toInt()} kcal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: dailyNutrition.calorieProgress.clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NutrientIndicator(
                  label: 'Protein',
                  value: '${dailyNutrition.totalProtein.toInt()}g',
                  progress: dailyNutrition.proteinProgress.clamp(0.0, 1.0),
                  color: Colors.red.shade400,
                ),
                _NutrientIndicator(
                  label: 'Carbs',
                  value: '${dailyNutrition.totalCarbs.toInt()}g',
                  progress: dailyNutrition.carbsProgress.clamp(0.0, 1.0),
                  color: Colors.green.shade400,
                ),
                _NutrientIndicator(
                  label: 'Fat',
                  value: '${dailyNutrition.totalFat.toInt()}g',
                  progress: dailyNutrition.fatProgress.clamp(0.0, 1.0),
                  color: Colors.blue.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrientIndicator extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _NutrientIndicator({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
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
        const SizedBox(height: 4),
        SizedBox(
          width: 50,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _RecentWorkoutsCard extends StatelessWidget {
  final List<Workout> workouts;

  const _RecentWorkoutsCard({
    required this.workouts,
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
          children: workouts.map((workout) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      workout.type == WorkoutType.strength
                          ? Icons.fitness_center
                          : workout.type == WorkoutType.cardio
                          ? Icons.directions_run
                          : Icons.sports_gymnastics,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, yyyy').format(workout.dateTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${workout.duration.inMinutes} min',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${workout.caloriesBurned} kcal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}