class AppException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'AppException(code: $code, message: $message, status: $statusCode)';

  factory AppException.network([String? message]) => AppException(
        message: message ?? 'Koneksi internet bermasalah. Silakan periksa jaringan Anda.',
        code: 'NETWORK_ERROR',
      );

  factory AppException.unauthorized([String? message]) => AppException(
        message: message ?? 'Sesi Anda telah berakhir. Silakan masuk kembali.',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );

  factory AppException.insufficientBalance([String? message]) => AppException(
        message: message ?? 'Saldo dompet tidak mencukupi untuk transaksi ini.',
        code: 'INSUFFICIENT_BALANCE',
        statusCode: 422,
      );

  factory AppException.pinLocked([String? message]) => AppException(
        message: message ?? 'PIN terkunci karena salah 5 kali. Coba lagi dalam 15 menit.',
        code: 'PIN_LOCKED',
        statusCode: 429,
      );

  factory AppException.fromResponse(Map<String, dynamic> json, int? statusCode) {
    final message = json['message'] as String? ?? 'Terjadi kesalahan sistem';
    final errorCode = json['error_code'] as String?;
    return AppException(
      message: message,
      code: errorCode,
      statusCode: statusCode,
      details: json['errors'],
    );
  }
}

