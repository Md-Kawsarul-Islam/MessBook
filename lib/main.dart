// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/routes.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/providers/member_provider.dart';
import 'package:mess_manager/providers/meal_provider.dart';
import 'package:mess_manager/providers/expense_provider.dart';
import 'package:mess_manager/providers/market_schedule_provider.dart';
import 'package:mess_manager/providers/expense_prediction_provider.dart';
import 'package:mess_manager/providers/theme_provider.dart';
import 'package:mess_manager/providers/notice_provider.dart';
import 'package:mess_manager/providers/meal_feedback_provider.dart';

import 'package:mess_manager/services/auth_service.dart';
import 'package:mess_manager/services/member_service.dart';
import 'package:mess_manager/services/meal_service.dart';
import 'package:mess_manager/services/expense_service.dart';
import 'package:mess_manager/services/market_schedule_service.dart';
import 'package:mess_manager/services/expense_prediction_service.dart';
import 'package:mess_manager/services/notice_service.dart';
import 'package:mess_manager/services/meal_feedback_service.dart';
import 'package:mess_manager/services/expense_request_service.dart';
import 'package:mess_manager/providers/expense_request_provider.dart';
import 'package:mess_manager/services/chat_service.dart';
import 'package:mess_manager/providers/chat_provider.dart';
import 'package:mess_manager/services/monthly_history_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mess_manager/firebase_options.dart';

import 'package:mess_manager/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services (instantiated once)
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<MemberService>(create: (_) => MemberService()),
        Provider<MealService>(create: (_) => MealService()),
        Provider<ExpenseService>(create: (_) => ExpenseService()),
        // ContributionService removed as it is merged into ExpenseService
        Provider<MarketScheduleService>(create: (_) => MarketScheduleService()),
        Provider<ExpensePredictionService>(
          create: (_) => ExpensePredictionService(),
        ),
        Provider<NoticeService>(create: (_) => NoticeService()),
        Provider<MealFeedbackService>(create: (_) => MealFeedbackService()),

        Provider<ExpenseRequestService>(create: (_) => ExpenseRequestService()),
        Provider<ChatService>(create: (_) => ChatService()),
        Provider<MonthlyHistoryService>(create: (_) => MonthlyHistoryService()),

        // Providers (depend on services)
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) => UserProvider(context.read<AuthService>()),
        ),
        ChangeNotifierProvider<NoticeProvider>(
          create:
              (context) => NoticeProvider(
                Provider.of<NoticeService>(context, listen: false),
              ),
        ),
        ChangeNotifierProvider<MealFeedbackProvider>(
          create:
              (context) => MealFeedbackProvider(
                Provider.of<MealFeedbackService>(context, listen: false),
              ),
        ),
        ChangeNotifierProvider<ExpenseRequestProvider>(
          create:
              (context) => ExpenseRequestProvider(
                Provider.of<ExpenseRequestService>(context, listen: false),
              ),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create:
              (context) => ChatProvider(
                Provider.of<ChatService>(context, listen: false),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (context) => MemberProvider(
                context.read<MemberService>(),
                context.read<AuthService>(),
              ),
        ),
        ChangeNotifierProvider(
          create: (context) => MealProvider(context.read<MealService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ExpenseProvider(context.read<ExpenseService>()),
        ),
        ChangeNotifierProvider(
          create:
              (context) =>
                  MarketScheduleProvider(context.read<MarketScheduleService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => NoticeProvider(context.read<NoticeService>()),
        ),
        ChangeNotifierProvider(
          create:
              (context) => ExpensePredictionProvider(
                context.read<ExpensePredictionService>(),
                context.read<MonthlyHistoryService>(),
              ), // Initialize prediction on startup
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MessBook',
            // NEW: Remove the debug banner from the corner of the screen
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              primaryColor: const Color(0xFFFC6600), // Nair Orange
              scaffoldBackgroundColor: const Color(
                0xFFF8F9FA,
              ), // Slightly off-white for depth
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFC6600),
                primary: const Color(0xFFFC6600),
                secondary: const Color(0xFFFF9E40), // Lighter orange
                surface: Colors.white,
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFFFC6600), // Orange text/icons
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  color: Color(0xFFFC6600),
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                iconTheme: IconThemeData(color: Color(0xFFFC6600)),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC6600),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFC6600),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Color(0xFFFC6600),
                foregroundColor: Colors.white,
                elevation: 4,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFFC6600),
                    width: 2,
                  ),
                ),
                labelStyle: const TextStyle(color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              ),
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF333333),
                contentTextStyle: const TextStyle(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textTheme: const TextTheme(
                headlineSmall: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
                titleLarge: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
                titleMedium: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3436),
                ),
                bodyLarge: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFFFC6600),
                ),
                bodyMedium: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFFFC6600),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              primaryColor: const Color(0xFFFC6600),
              scaffoldBackgroundColor: const Color(0xFF121212),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFC6600),
                primary: const Color(0xFFFC6600),
                secondary: const Color(0xFFFF9E40),
                surface: const Color(0xFF1E1E1E),
                onSurface: Colors.white,
                brightness: Brightness.dark,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1E1E1E),
                foregroundColor: Color(0xFFFC6600),
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  color: Color(0xFFFC6600),
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                iconTheme: IconThemeData(color: Color(0xFFFC6600)),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC6600),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFC6600),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Color(0xFFFC6600),
                foregroundColor: Colors.white,
                elevation: 4,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF424242)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF424242)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFFC6600),
                    width: 2,
                  ),
                ),
                labelStyle: const TextStyle(color: Colors.grey),
                hintStyle: const TextStyle(color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
              ),
              cardTheme: CardThemeData(
                color: const Color(0xFF1E1E1E),
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              ),
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF2C2C2C),
                contentTextStyle: const TextStyle(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textTheme: const TextTheme(
                headlineSmall: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                titleLarge: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                titleMedium: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                bodyLarge: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFFFC6600),
                ),
                bodyMedium: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFFFC6600),
                ),
              ),
              iconTheme: const IconThemeData(color: Color(0xFFE0E0E0)),
            ),
            onGenerateRoute: AppRoutes.generateRoute,
            initialRoute: AppRoutes.splash,
          );
        },
      ),
    );
  }
}
