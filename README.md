# Weight Watcher AI

A comprehensive Flutter fitness application that helps users track calories, workouts, and provides AI-powered fitness guidance.

## Features

- **Dashboard**: Get an overview of your fitness progress, recent meals, and upcoming workouts.
- **Calorie Tracker**: Log meals with detailed nutritional information and track your daily calorie intake.
- **Workout Tracker**: Record and monitor your workouts, exercises, and track calories burned.
- **AI Trainer**: Receive AI-generated workout and meal plans tailored to your fitness goals.
- **Profile Management**: Manage your personal profile, body measurements, and fitness goals.

## Screenshots

![Calorie Tracker Screen](screenshots/calorie_tracker.png)

## Getting Started

### Prerequisites

- Flutter (latest stable version)
- Dart SDK
- An OpenAI API key (for AI features)

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/weightwatcherAI.git
cd weightwatcherAI
```

2. Install dependencies
```bash
flutter pub get
```

3. Create a `.env` file in the root directory and add your Gemini API key:
```
OPENAI_API_KEY=your-api-key-here
```

4. Run the application
```bash
flutter run
```

## Technologies Used

- **Flutter**: UI framework
- **Provider**: State management
- **OpenAI API**: For AI-generated fitness plans and insights
- **Shared Preferences**: Local data storage
- **Material 3**: Modern UI design
- **Charts**: Visualize fitness progress

## Architecture

The app follows a clean architecture approach with:

- **Models**: Data structures for user, meals, workouts, etc.
- **Providers**: State management and business logic
- **Repositories**: Data access layer
- **Services**: External API interactions
- **Screens**: UI components

## Future Enhancements

- Social sharing functionality
- Integration with fitness wearables
- More advanced AI features
- Barcode scanner for food items
- Cloud sync across devices

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- OpenAI for the powerful API
