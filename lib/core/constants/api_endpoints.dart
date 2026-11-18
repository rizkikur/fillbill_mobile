class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String requestOtp = '/auth/otp';
  static const String register = '/auth/register';
  static const String verifyRegister = '/auth/verify-register';
  static const String loginOtp = '/auth/login';
  static const String profileMe = '/auth/me';
  static const String updateProfile = '/auth/profile';
  static const String registerFcm = '/auth/fcm-token';
  static const String logout = '/auth/logout';

  // Security
  static const String setupPin = '/security/pin';
  static const String pinChallenge = '/security/pin/challenge';
  static const String pinVerify = '/security/pin/verify';
  static const String changePin = '/security/pin';

  // Home Dashboard
  static const String home = '/home';

  // Products
  static const String categories = '/products/categories';
  static const String operatorPrefix = '/products/operator-prefix';
  static const String products = '/products';

  // Postpaid Inquiry
  static const String inquiry = '/inquiry';

  // Transactions
  static const String transactions = '/transactions';
  static String transactionDetail(int id) => '/transactions/$id';

  // Wallet
  static const String wallet = '/wallet';
  static const String walletChannels = '/wallet/channels';
  static const String walletMutations = '/wallet/mutations';
  static const String walletTopup = '/wallet/topup';
}

