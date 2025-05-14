// README.md - Updated with fund screener documentation
# Modern Finance - Financial Analysis and Investment Fund Screener

## Project Overview

Modern Finance is a cutting-edge Flutter-based financial application that combines stock market analysis with comprehensive investment fund screening capabilities. The app provides users with advanced tools to analyze, compare, and track both stocks and investment funds.

## New Features - Fund Screener

### 🏦 Comprehensive Fund Analysis
- **Fund Discovery**: Browse and search through investment funds with advanced filtering
- **Risk Analysis**: Detailed risk metrics including Sharpe ratio, Beta, Alpha, and volatility
- **Performance Tracking**: Historical performance charts with multiple timeframes
- **Monte Carlo Simulation**: Advanced risk modeling and scenario analysis
- **Portfolio Distribution**: Visual breakdown of fund asset allocation

### 📱 Enhanced User Experience
- **Modern Material 3 Design**: Updated with dynamic color themes and improved accessibility
- **Smart Filtering**: Multi-criteria filtering with real-time search
- **Responsive Cards**: Optimized fund cards with key metrics at a glance
- **Smooth Animations**: Fluid transitions and loading states with shimmer effects
- **Dark/Light Theme**: Seamless theme switching with custom gradient backgrounds

### 🔧 Technical Improvements
- **Modular Architecture**: Clean separation of concerns with dedicated fund services
- **Error Handling**: Robust error management with user-friendly fallbacks
- **API Integration**: RESTful API integration with MongoDB backend support
- **Performance Optimization**: Debounced search, infinite scrolling, and efficient state management
- **Accessibility**: High contrast support and screen reader compatibility

## Features

### Existing Features
- **Real-Time Stock Data**: Access up-to-the-minute stock prices and market information
- **Historical Data**: View historical price charts to identify trends and patterns
- **Technical Indicators**: Utilize various technical indicators (MA, MACD, RSI, Bollinger Bands)
- **Backtesting**: Simulate trades with historical data to test strategies
- **Customizable Charts**: Configure charts with multiple indicators and timeframes
- **Stock Reels**: Quick stock insights in a swipe-through format
- **Portfolio Tracking**: Monitor your investment portfolio with detailed analytics

### New Fund Features
- **Fund Screener**: Advanced filtering by category, risk level, returns, and TEFAS status
- **Fund Comparison**: Side-by-side comparison of multiple funds
- **Risk Metrics**: Comprehensive risk analysis with industry-standard measures
- **Distribution Analysis**: Detailed breakdown of fund asset allocation
- **Monte Carlo Simulation**: Probabilistic return scenarios and risk modeling
- **Performance Charts**: Interactive charts with touch tooltips and zoom functionality

## Tech Stack

- **Flutter**: Cross-platform mobile development
- **Dart**: Programming language
- **Provider**: State management
- **FL Chart**: Interactive charting library
- **HTTP**: API communication
- **SharedPreferences**: Local data persistence
- **Material 3**: Modern design system with dynamic theming

## API Integration

The app integrates with a comprehensive fund API providing:
- Fund list and search functionality
- Historical performance data
- Risk metrics calculation
- Monte Carlo simulation results
- Category and filter options

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Android/iOS emulator or physical device

### Installation

1. **Clone the repository:**
```bash
git clone [repository-url]
cd modern_finance
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Set up API configuration:**
```dart
// lib/src/config.dart
class Config {
  static const String baseUrl = 'your-api-endpoint';
}
```

4. **Run the application:**
```bash
flutter run
```

## Project Structure

```
lib/
├── models/              # Data models for funds and stocks
│   ├── fund.dart       # Fund-related models
│   └── ...
├── services/           # API services and business logic
│   ├── fund_api_service.dart
│   └── ...
├── screens/            # UI screens
│   ├── fund_list_screen.dart
│   ├── fund_detail_screen.dart
│   └── ...
├── widgets/            # Reusable UI components
│   ├── fund_card.dart
│   ├── fund_filter_sheet.dart
│   └── ...
├── theme/              # Theme and styling
│   ├── app_theme.dart
│   └── theme_provider.dart
└── utils/              # Utility functions
    └── logger.dart
```

## Fund Screener Usage

1. **Access Fund Screener**: Navigate to the "Funds" tab in the bottom navigation
2. **Browse Funds**: Scroll through the list of available investment funds
3. **Search and Filter**: Use the search bar and filter options to find specific funds
4. **View Details**: Tap on any fund card to see detailed information
5. **Analyze Performance**: Switch between tabs to view performance, risk, and distribution data
6. **Compare Funds**: Use filter options to compare multiple funds side by side

## Customization

### Adding New Themes
The app supports multiple color palettes. To add a new theme:

1. Update `ColorPalette` enum in `theme_provider.dart`
2. Add new colors in `AppTheme._themeColors` map
3. The theme system automatically generates light/dark variations

### Extending Fund Features
To add new fund analysis features:

1. Create new models in `models/fund.dart`
2. Extend `FundApiService` with new endpoints
3. Add corresponding UI components in the widgets directory

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Add tests if applicable
5. Commit your changes (`git commit -m 'Add new feature'`)
6. Push to the branch (`git push origin feature/your-feature`)
7. Open a Pull Request

## License

This project is licensed under the [MIT License](LICENSE.md).

## Acknowledgments

- Flutter team for the excellent framework
- FL Chart contributors for the charting library
- Community contributors for feedback and suggestions

---

**Note**: This app is for educational and demonstration purposes. Always consult with qualified financial advisors before making investment decisions.