import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Splash & Onboarding (Milestone 2)
import '../features/splash/presentation/splash_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';

// Top-Up Screen (Milestone 3 Stub / Contract)
import '../features/wallet/presentation/topup_screen.dart';

// Auth Routes
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/phone_input_screen.dart';
import '../features/auth/presentation/pin_setup_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/notifications_screen.dart';
import '../features/home/presentation/promo_detail_screen.dart';
import '../features/products/presentation/bill_transaction_screen.dart';
import '../features/products/presentation/emoney_transaction_screen.dart';
import '../features/products/presentation/game_voucher_screen.dart';
import '../features/products/presentation/pln_transaction_screen.dart';
import '../features/products/presentation/prepaid_transaction_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/transactions/domain/transaction_entity.dart';
import '../features/transactions/presentation/receipt_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/wallet/presentation/wallet_screen.dart';
import 'main_nav_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // Splash Route (Cold Start Dispatcher)
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Web Root Alias (Direct root hit redirects to splash)
    GoRoute(
      path: '/',
      redirect: (context, state) => '/splash',
    ),

    // First-Time User Onboarding Route
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Top-Up Route (Milestone 3 Dedicated Route)
    GoRoute(
      path: '/topup',
      name: 'topup',
      builder: (context, state) => const TopupScreen(),
    ),

    // Auth Routes
    GoRoute(
      path: '/auth/phone',
      builder: (context, state) => const PhoneInputScreen(),
    ),
    GoRoute(
      path: '/auth/otp',
      builder: (context, state) => const OtpScreen(),
    ),
    GoRoute(
      path: '/auth/pin-setup',
      builder: (context, state) => const PinSetupScreen(),
    ),

    // Notifications & Inbox Route
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),

    // Promo Detail Route
    GoRoute(
      path: '/promo-detail',
      builder: (context, state) {
        final promo = state.extra as Map<String, dynamic>? ?? {};
        return PromoDetailScreen(promo: promo);
      },
    ),

    // Prepaid Transaction Route (Pulsa & Paket Data)
    GoRoute(
      path: '/transaction/prepaid',
      builder: (context, state) {
        final category = state.uri.queryParameters['category'] ?? 'pulsa';
        return PrepaidTransactionScreen(initialCategory: category);
      },
    ),

    // PLN Transaction Route (Token Prabayar & Tagihan Pascabayar)
    GoRoute(
      path: '/transaction/pln',
      builder: (context, state) {
        final initialType = state.uri.queryParameters['type'] ?? 'token';
        return PlnTransactionScreen(initialType: initialType);
      },
    ),

    // E-Money / Dompet Digital (DANA, OVO, GoPay, ShopeePay, LinkAja)
    GoRoute(
      path: '/transaction/emoney',
      builder: (context, state) => const EmoneyTransactionScreen(),
    ),

    // Tagihan Bulanan (PDAM Air Bersih & BPJS Kesehatan)
    GoRoute(
      path: '/transaction/bill',
      builder: (context, state) {
        final service = state.uri.queryParameters['service'] ?? 'pdam';
        return BillTransactionScreen(service: service);
      },
    ),

    // Voucher Game Online (MLBB, Free Fire, PUBG, Genshin Impact)
    GoRoute(
      path: '/transaction/game',
      builder: (context, state) => const GameVoucherScreen(),
    ),

    // Receipt Route
    GoRoute(
      path: '/receipt',
      builder: (context, state) {
        if (state.extra is ReceiptArgs) {
          final args = state.extra as ReceiptArgs;
          return ReceiptScreen(
            transaction: args.transaction,
            pinToExecute: args.pinToExecute,
            inquiryId: args.inquiryId,
          );
        } else if (state.extra is TransactionEntity) {
          return ReceiptScreen(transaction: state.extra as TransactionEntity);
        }

        return const Scaffold(
          body: Center(child: Text('Data transaksi tidak ditemukan')),
        );
      },
    ),

    // Main App Shell (Navigasi 4 Branch dengan Tombol Tengah Action Modal)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavShell(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Beranda
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Branch 1: Riwayat Transaksi
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionsScreen(),
            ),
          ],
        ),
        // Branch 2: Dompet & Mutasi Rekening
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/wallet',
              builder: (context, state) => const WalletScreen(),
            ),
          ],
        ),
        // Branch 3: Akun & Profil
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
