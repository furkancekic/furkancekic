# Modern Finance

A cutting-edge, cross-platform finance and stock market application built with Flutter and Firebase. This application features a sleek, futuristic design and supports seamless user experiences across mobile and web platforms.

## Features

- **User Authentication**: Secure login with email/password and social logins (Google, Apple), plus guest access
- **Stock Screener**: Filter stocks based on various criteria (sector, market cap, P/E ratio, etc.)
- **Advanced Charting**: Interactive line and candle charts with technical indicators
- **Backtesting Engine**: Create and test trading strategies with up to 20 technical indicators
- **Stock Reels**: Scroll through stock information in a social media style interface
- **Clean Architecture**: Modular and maintainable codebase following best practices

## Screenshots

*Coming soon*

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code with Flutter plugins
- Git

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/your-username/modern-finance.git
   cd modern-finance
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Run the app
   ```bash
   flutter run
   ```

## Project Structure

The application follows the Clean Architecture pattern, separating the codebase into three main layers:

- **Presentation Layer**: UI components and state management
- **Domain Layer**: Business logic and use cases
- **Data Layer**: Data sources and repositories

```
lib/
├── data/                 # Data layer
│   ├── models/           # Data models
│   ├── repositories/     # Repository implementations
│   └── sources/          # Data sources (API, local storage)
├── domain/               # Domain layer
│   ├── entities/         # Business entities
│   ├── repositories/     # Repository interfaces
│   └── usecases/         # Business logic
├── presentation/         # Presentation layer
│   ├── screens/          # UI screens
│   ├── widgets/          # Reusable UI components
│   └── providers/        # State management
├── theme/                # App theme and styling
└── main.dart             # Entry point
```

## Firebase Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and iOS apps to your Firebase project
3. Download the configuration files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS)
4. Place these files in the respective directories:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
5. Enable Authentication methods (Email/Password, Google, Apple) in Firebase Console
6. Create a Firestore database and set up required collections

## Dependencies

The application uses the following key dependencies:

- **State Management**: Provider
- **UI Components**: Syncfusion Flutter Charts
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Networking**: Dio, HTTP
- **Storage**: Flutter Secure Storage, Shared Preferences
- **Charts**: FL Chart, Syncfusion Flutter Charts

For a complete list of dependencies, refer to the `pubspec.yaml` file.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [Syncfusion Flutter Charts](https://www.syncfusion.com/flutter-widgets/flutter-charts)
- [FL Chart](https://pub.dev/packages/fl_chart)