# Cash Management App 💰

A beautiful Flutter money management application with custom dotted design patterns for iOS and Android.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

## ✨ Features

- 📊 **Financial Tracking**: Track expenses, income, and loans seamlessly
- 💳 **Multi-Account Support**: Manage cash, bank accounts, and credit cards
- 📈 **Interactive Charts**: Visualize your finances with pie and line charts
- 🎯 **Budget Management**: Set budgets with custom **dotted progress bars**
- 🔄 **Recurring Transactions**: Automate regular payments
- 🎨 **Beautiful UI**: Modern design with purple/blue gradients and dotted patterns
- 🌙 **Dark Mode**: Eye-friendly dark theme by default
- 💾 **Local Storage**: All data stored securely on your device with SQLite

## 🎨 Design Highlights

- **Custom Dotted Progress Bars**: Unique square-dot progress indicators matching your reference design
- **Halftone Patterns**: Diamond-shaped dot patterns for backgrounds
- **Smooth Animations**: Fluid transitions and animated charts
- **Color-Coded**: Green for income, red for expenses, purple gradients for premium feel

## 📱 Screenshots

The app includes:
- **Dashboard**: Total balance, monthly stats, recent transactions
- **Transactions**: Filterable list grouped by date
- **Add Transaction**: Easy form with category selection
- **Charts**: Pie chart for category breakdown, line chart for trends
- **Budgets**: Track spending with custom dotted progress bars
- **Accounts**: Manage multiple payment accounts

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- iOS Simulator / Android Emulator or physical device

### Installation

1. **Install Flutter SDK**
   
   Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
   
   For Windows:
   - Download Flutter SDK
   - Extract to desired location (e.g., `C:\src\flutter`)
   - Add to PATH: `C:\src\flutter\bin`
   - Run `flutter doctor` to verify installation

2. **Clone/Navigate to the project**
   ```bash
   cd "c:\Users\OUSS\Desktop\Cash Management"
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   # For Android
   flutter run
   
   # For iOS
   flutter run -d ios
   
   # For a specific device
   flutter devices
   flutter run -d <device-id>
   ```

## 📦 Dependencies

- `sqflite` - Local database
- `fl_chart` - Beautiful charts
- `provider` - State management
- `google_fonts` - Typography
- `intl` - Date and number formatting
- `uuid` - Unique ID generation

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point
├── theme/
│   └── app_theme.dart          # Color scheme and themes
├── models/
│   ├── transaction.dart        # Transaction model
│   ├── category.dart           # Category model
│   ├── budget.dart             # Budget model
│   ├── account.dart            # Account model
│   └── loan.dart               # Loan model
├── services/
│   └── database_service.dart   # SQLite database service
├── screens/
│   ├── home_screen.dart        # Dashboard
│   ├── transactions_screen.dart # Transaction list
│   ├── add_transaction_screen.dart # Add transaction form
│   ├── charts_screen.dart      # Analytics & charts
│   ├── budgets_screen.dart     # Budget management
│   └── accounts_screen.dart    # Account management
└── widgets/
    ├── dotted_pattern_painter.dart  # Halftone background pattern
    ├── dotted_progress_bar.dart     # Custom dotted progress bars
    ├── dotted_loading.dart          # Loading indicators
    ├── transaction_card.dart        # Transaction list item
    ├── stat_card.dart               # Dashboard stat cards
    └── category_icon.dart           # Category icons
```

## 🎯 Usage

1. **Add an Account**: Tap Accounts → + → Enter details
2. **Create a Budget**: Tap Budgets → + → Select category and amount
3. **Add Transaction**: Tap the + button → Fill form → Save
4. **View Charts**: Navigate to Charts tab for visual analytics
5. **Track Progress**: See dotted progress bars in Budgets screen

## 🔮 Future Enhancements

- Export/Import data
- Cloud backup
- Expense reminders
- Bill payment tracking
- Financial insights with AI
- Multi-currency support
- Loan payment schedules

## 📄 License

This project is open source and available for personal use.

## 🤝 Contributing

Feel free tocontribute to this project by submitting issues or pull requests.

---

Built with ❤️ using Flutter and custom dotted design patterns
