import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/typography.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/charts_screen.dart';
import 'screens/budgets_screen.dart';
import 'screens/accounts_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (works on Web, Android, iOS, Desktop)
  await DatabaseService.initialize();
  final databaseService = DatabaseService();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const CashManagementApp(),
    ),
  );
}

class CashManagementApp extends StatelessWidget {
  const CashManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Cash Management Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  // We remove 'const' so the widgets can be rebuilt when we need to refresh data
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initScreens();
  }

  void _initScreens() {
    _screens = [
      const HomeScreen(),
      const TransactionsScreen(),
      const BudgetsScreen(),
      const SavingsScreen(),
      const AccountsScreen(),
    ];
  }

  void _refreshCurrentScreen() {
    setState(() {
      _initScreens(); // Creates new instances, forcing them to run initState & loadData
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBarItem(
              icon: Icons.home_filled,
              label: 'Home',
              isSelected: _currentIndex == 0,
              onTap: () => _onTabTapped(0),
            ),
            _NavBarItem(
              icon: Icons.history_rounded,
              label: 'History',
              isSelected: _currentIndex == 1,
              onTap: () => _onTabTapped(1),
            ),
            _NavBarItem(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Budgets',
              isSelected: _currentIndex == 2,
              onTap: () => _onTabTapped(2),
            ),
            _NavBarItem(
              icon: Icons.flag_rounded,
              label: 'Savings',
              isSelected: _currentIndex == 3,
              onTap: () => _onTabTapped(3),
            ),
            _NavBarItem(
              icon: Icons.credit_card_rounded,
              label: 'Cards',
              isSelected: _currentIndex == 4,
              onTap: () => _onTabTapped(4),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
          if (result == true) {
            _refreshCurrentScreen();
          }
        },
        backgroundColor: AppTheme.primaryPurple,
        elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryPurple
                  : Colors.grey.withOpacity(0.5),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppTheme.primaryPurple
                    : Colors.grey.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
