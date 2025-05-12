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
- A Google Gemini API key (for AI features). You can obtain one from [Google AI Studio](https://aistudio.google.com/app/apikey).

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

3. Create a `.env` file in the root directory (you can copy `.env_template`) and add your Google Gemini API key:
```
# .env
GEMINI_API_KEY=your-google-api-key-here
```

4. Run the application
```bash
flutter run
```

## Technologies Used

- **Flutter**: UI framework
- **Provider**: State management
- **Google Gemini API**: For AI-generated fitness plans and insights (via `google_generative_ai` package)
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

## Build and Deployment Instructions

### Building for Production

1. Ensure you have the correct Flutter channel and dependencies:
   ```bash
   flutter channel stable
   flutter upgrade
   flutter pub get
   ```

2. Run Flutter diagnostics to verify everything is set up correctly:
   ```bash
   flutter doctor
   ```

3. Build the application for your target platform:

   **Android**
   ```bash
   flutter build apk --release
   # For app bundle (recommended for Play Store)
   flutter build appbundle --release
   ```

   **iOS**
   ```bash
   flutter build ios --release
   # Then archive using Xcode
   ```

   **Web**
   ```bash
   flutter build web --release
   ```

### Deployment

#### Android Deployment
1. Sign your app with a keystore (required for Play Store submission)
   ```bash
   # Create a keystore if you don't have one
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Configure signing in `android/app/build.gradle` and `android/key.properties`

3. Submit to Google Play Store through the [Google Play Console](https://play.google.com/console/)

#### iOS Deployment
1. Open the Runner.xcworkspace in Xcode:
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. Configure app signing, capabilities, and app identifier in Xcode

3. Archive the application in Xcode and submit to App Store Connect

#### Web Deployment
1. Deploy the contents of the `build/web` directory to your hosting provider:
   ```bash
   # For Firebase Hosting example
   firebase deploy --only hosting
   ```

## Release Notes

### Version 1.0.0 (May 2025)
- Initial release of Weight Watcher AI
- Dashboard with fitness overview and statistics
- Calorie tracking with food database
- Workout tracking with custom exercise library
- AI-powered fitness recommendations using Google Gemini API
- Profile management with goal setting

### Version 0.9.0 (April 2025) - Beta
- Beta testing release
- Core functionality implementation
- Performance optimizations
- UI/UX refinements based on initial feedback

### Version 0.5.0 (March 2025) - Alpha
- Alpha testing version
- Basic UI implementation
- Initial integration with Google Gemini API
- Fundamental calorie and workout tracking features

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
- Google AI for the powerful Gemini API
