# myapp - Financial Analysis and Backtesting App

## Project Overview

myapp is a Flutter-based financial application designed to empower users with the tools they need to analyze and backtest stocks. Whether you're a seasoned investor or just starting, myapp provides a comprehensive platform for researching, strategizing, and simulating stock trades. This app allows users to view real-time and historical stock data, explore various technical indicators, and test their trading strategies in a simulated environment before committing real capital.

## Features

-   **Real-Time Stock Data:** Access up-to-the-minute stock prices and market information.
-   **Historical Data:** View historical price charts to identify trends and patterns.
-   **Technical Indicators:** Utilize a wide array of technical indicators, such as Moving Averages, MACD, RSI, and Bollinger Bands, to enhance your analysis.
-   **Backtesting:** Simulate trades with historical data to test and refine your strategies.
-   **Customizable Charts:** Configure charts to display the data and indicators most relevant to your analysis.
-   **User-Friendly Interface:** Enjoy an intuitive design that simplifies complex financial data.
- **Screener**: Find best stocks for you with filters.
- **Stock Reels**: See stocks reels.
- **Login**: Login screen to start and save data.
- **Theme**: Change the theme to light or dark mode.

## Tech Stack

-   **Flutter:** For cross-platform mobile application development.
-   **Dart:** The programming language used in Flutter.
-   **Various Flutter Packages:** For chart implementation, http requests, state management, etc.
- **REST API**: For providing data.

## Getting Started

### Prerequisites

-   Flutter SDK installed on your machine.
-   An IDE like VS Code or Android Studio.
-   Android/iOS emulator or a physical device for testing.

### Installation

1.  **Clone the repository:**
```
bash
    git clone [repository-url]
    
```
2.  **Navigate to the project directory:**
```
bash
    cd myapp
    
```
3.  **Install dependencies:**
```
bash
    flutter pub get
    
```
4.  **Run the application:**
    
```
bash
    flutter run
    
```
## How to Use

1.  **Launching the App:** Open the myapp on your emulator or physical device.
2.  **Exploring Stocks:** Use the search feature to find specific stocks you want to analyze.
3.  **Viewing Charts:** Tap on a stock to view its interactive chart. Customize the chart by selecting different timeframes and indicators.
4.  **Analyzing Indicators:** Add and configure technical indicators to overlay on the chart for a deeper analysis.
5.  **Backtesting:** Go to backtesting screen, choose a stock and date, set your strategy and click backtest button.
6. **Login:** Go to login screen to save your data.
7. **Screener:** Go to screener to filter stocks.
8. **Stock Reels:** Go to stock reels to see reels of stocks.
9. **Theme**: Change your theme in theme settings screen.

## Project Structure
```
myapp/
├── android/                 # Android-specific project files
│   └── ...
├── ios/                     # iOS-specific project files
│   └── ...
├── lib/                     # Dart source code
│   ├── data_sources/        # Data providers, api calls
│   │   └── stock_api.dart       # API calls and data fetching.
│   ├── repositories/        # Data retrieval logic, manages data_sources.
│   │   └── stock_repository.dart  # Interface with data sources.
│   ├── models/              # Data models
│   │   ├── backtest_models.dart # Data for backtesting.
│   │   └── candle_data.dart     # Data for candle.
│   │   └── indicator.dart # Data for indicators.
│   ├── providers/           # State management classes
│   │   └── backtest_provider.dart  # State management for backtest screen.
│   ├── services/            # Business logic layer
│   │   ├── backtest_service.dart  # Backtest logic.
│   │   ├── chart_service.dart   # Chart and indicator logic.
│   │   ├── home_screen_service.dart # Home screen logic
│   │   └── stock_api_service.dart # API requests.
│   ├── screens/             # UI screens
│   │   ├── backtesting_screen.dart # Backtesting page.
│   │   ├── chart_screen.dart    # Chart page.
│   │   ├── home_screen.dart     # Home page.
│   │   ├── login_screen.dart  # Login page.
│   │   ├── screener_screen.dart # Screener page.
│   │   ├── stock_reels_screen.dart # Reels page.
│   │   └── theme_settings_screen.dart # Theme settings.
│   ├── theme/               # Theme files
│   │   ├── app_theme.dart   # Theme settings.
│   │   └── theme_provider.dart # Provider for theme.
│   ├── widgets/             # Reusable UI components
│   │   ├── app_drawer.dart  # Drawer for app.
│   │   ├── common_widgets.dart # Common UI elements.
│   │   ├── intraday_chart.dart # Intraday chart.
│   │   └── mini_chart.dart # Mini charts.
│   ├── utils/               # Utility functions
│   │   └── logger.dart          # Logger for project.
│   ├── main.dart            # Entry point of the app
├── test/                    # Test files
│   └── widget_test.dart
├── web/                     # Web-specific project files
│   └── ...
├── assets/                  # Static assets (images, fonts, etc.)
│   └── fonts/
│       └── ...
├── pubspec.yaml             # Project dependencies and configurations
└── pubspec.lock             # Auto-generated dependencies file
```
### File Descriptions:

-   **`lib/main.dart`**: The main entry point of the Flutter application.
-   **`lib/models/`**: Contains Dart classes that define the data structures used in the app, such as `backtest_models.dart` for backtest results and `candle_data.dart` for stock prices data. `indicator.dart` to define indicators.
-   **`lib/data_sources/`**: Contains classes for fetching data from remote or local sources. `stock_api.dart` will handle API calls.
-   **`lib/repositories/`**: Contains classes that implement the business logic for data access. `stock_repository.dart` will use the data sources to get the data.
-   **`lib/services/`**: Contains classes that provide services to the UI layer, like `backtest_service.dart` for backtesting logic, `chart_service.dart` for chart logic, `stock_api_service.dart` for API requests, `home_screen_service.dart` for home screen logic.
-   **`lib/providers/`**: Contains state management classes that provide data to the UI layer like `backtest_provider.dart` for backtesting.
-   **`lib/screens/`**: Contains Dart files for each screen of the application like `backtesting_screen.dart`, `chart_screen.dart`, `home_screen.dart`, `login_screen.dart` , `screener_screen.dart`, `stock_reels_screen.dart` and `theme_settings_screen.dart`.
-   **`lib/widgets/`**: Contains reusable UI widgets like `app_drawer.dart`, `common_widgets.dart`, `intraday_chart.dart` and `mini_chart.dart`.
- **`lib/utils/`**: Contains utility files like `logger.dart`.
-   **`lib/theme/`**: Contains theme files.
-   **`assets/`**: Contains all the assets of the project.
-   **`test/`**: Contains `widget_test.dart` for widget tests.
- **`web/`**: Contains the web files for the project.
-   **`android/`**: Contains all the configuration files related to Android.
-   **`pubspec.yaml`**: The project configuration file.
-   **`pubspec.lock`**: The auto-generated dependencies file.

## How to Contribute

Contributions to myapp are welcome! Here's how you can contribute:

1.  **Fork the repository.**
2.  **Create a new branch** (`git checkout -b feature/YourContribution`).
3.  **Make your changes.**
4.  **Commit your changes** (`git commit -m 'Add some feature'`).
5.  **Push to the branch** (`git push origin feature/YourContribution`).
6.  **Open a pull request.**

## License

This project is licensed under the [License Name] - see the [LICENSE.md](LICENSE.md) file for details.