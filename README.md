# Budget Tracker

A personal finance application built with Flutter and Dart. Budget Tracker helps users record transactions, manage monthly budgets, organize spending categories, and understand their financial activity through dashboards and reports.

## Features

- Dashboard with income, expenses, net balance, and budget summaries
- Add and edit financial transactions
- Manage expense and income categories
- Create and manage monthly budgets
- View financial reports and spending insights
- Local data storage using Drift and SQLite
- Bottom navigation for Dashboard, Transactions, Reports, and Settings
- Receipt and image input support
- Smart recording functionality using text recognition
- Local notifications support
- Responsive Material Design interface
- Android application support

## Screens

The application is organized around four main sections:

- **Dashboard** – View current financial summaries and recent activity
- **Transactions** – Add, edit, and review income and expenses
- **Reports** – Analyze spending and budget performance
- **Settings** – Configure application preferences

## Technology Stack

- **Flutter** – Cross-platform application framework
- **Dart** – Programming language
- **Riverpod** – State management and dependency injection
- **GoRouter** – Application navigation
- **Drift** – Local database and type-safe SQL access
- **fl_chart** – Charts and financial data visualization
- **Google ML Kit** – Text recognition for smart receipt recording
- **Image Picker** – Selecting receipt images
- **Flutter Local Notifications** – Local notification support

## Project Structure

```text
lib/
├── app.dart                         # Root application widget
├── main.dart                        # Application entry point
├── core/
│   ├── constants/                   # Shared application constants
│   ├── theme/                       # Colors, themes, and styling
│   └── utils/                       # Shared utility functions
├── database/
│   ├── app_database.dart             # Drift database definition
│   ├── database_provider.dart        # Database Riverpod providers
│   ├── converters/                   # Database type converters
│   ├── daos/                         # Data access objects
│   └── tables/                       # Database table definitions
├── features/
│   ├── budget/                       # Budget management
│   ├── categories/                   # Category management
│   ├── dashboard/                    # Financial dashboard
│   ├── reports/                      # Reports and analytics
│   ├── settings/                     # Application settings
│   ├── smart_recording/              # Receipt and text recognition
│   └── transactions/                 # Income and expense transactions
└── routing/
    ├── app_router.dart               # GoRouter configuration
    ├── app_routes.dart               # Application route definitions
    └── scaffold_with_nested_navigation.dart
```

## Requirements

Before running the project, install:

- Flutter SDK
- Dart SDK included with Flutter
- Android Studio or another supported Android development environment
- An Android emulator or physical Android device

The project currently uses Dart SDK version `3.10.4` or compatible.

## Getting Started

Clone the repository:

```bash
git clone https://github.com/Shevanka/budget-tracker.git
cd budget-tracker
```

Switch to the development branch if necessary:

```bash
git checkout dev
```

Install dependencies:

```bash
flutter pub get
```

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Run the application:

```bash
flutter run
```

## Code Generation

The project uses Drift and build tools for generated database code. If database models or Drift files are changed, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

For continuous code generation during development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Testing

Tests are located in the `test/` directory. The test suite includes coverage for:

- Application startup
- Dashboard rendering
- Navigation tabs
- Database behavior
- Core functionality
- Feature-specific behavior

Run all tests with:

```bash
flutter test
```

## Database

Budget Tracker stores application data locally using Drift. The database includes tables for:

- Categories
- Transactions
- Budgets
- Budget categories
- Notification logs

The database also supports an in-memory configuration for testing.

## Development Notes

This project is being developed as a personal finance management application. Product functionality and user workflows may continue to evolve as new features are added.

Before submitting changes, run:

```bash
flutter analyze
flutter test
```

## Roadmap

Planned improvements may include:

- More detailed financial analytics
- Improved receipt text recognition
- Recurring transactions
- Export and backup functionality
- Additional currency and locale support
- Improved notification scheduling
- Cloud synchronization
- Expanded test coverage
- Production Android release configuration

## Contributing

Contributions, suggestions, and improvements are welcome.

1. Fork the repository
2. Create a feature branch

```bash
git checkout -b feature/your-feature
```

3. Make your changes
4. Run the analyzer and tests
5. Commit your changes

```bash
git commit -m "Add your feature"
```

6. Push the branch and open a pull request

## License

This project does not currently specify a license. Add a license file if you want to define how others may use, modify, and distribute the project.
