import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:http/http.dart' as http;
import 'package:backend_server/src/generated/protocol.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';

class AuthEndpoint extends Endpoint {
  // MailerSend API Key
  // static const String mailerSendApiKey = 'mlsn.dfbbd66f89f6a991df8b178c726485f7ea91c8288771134c50fa38438f507584';

  // Resend API Key for email verification
  static const String resendApiKey = 're_5aReX4YE_8hRtqrnkLDV6nm3D7yD1NRnq';

  // JWT secret (should be set in environment in production)
  final String _jwtSecret = const String.fromEnvironment(
    'JWT_SECRET',
    defaultValue: 'replace_with_secure_secret',
  );

  // UUID generator for jti
  final Uuid _uuid = Uuid();

  static final Map<String, List<DateTime>> _rateLimit = {};
  static const int maxAttempts = 5;
  static const Duration window = Duration(minutes: 5);

  bool _isRateLimited(String key) {
    final now = DateTime.now();
    _rateLimit.putIfAbsent(key, () => []);

    // Remove expired attempts
    _rateLimit[key]!.removeWhere((t) => now.difference(t) > window);

    if (_rateLimit[key]!.length >= maxAttempts) {
      return true;
    }

    _rateLimit[key]!.add(now);
    return false;
  }

  //login
  Future<LoginResponse> login(
      Session session, String email, String password) async {
    final rateKey = 'login_$email';

    if (_isRateLimited(rateKey)) {
      return LoginResponse(
        success: false,
        error: 'Too many login attempts. Please try again later.',
      );
    }

    try {
      final result = await session.db.unsafeQuery(
        '''
      SELECT u.user_id, u.name, u.email, u.password_hash, u.role::text AS role, u.is_active,
             u.phone, p.blood_group, p.allergies, u.profile_picture_url
      FROM users u
      LEFT JOIN patient_profiles p ON p.user_id = u.user_id
      WHERE u.email = @e
      ''',
        parameters: QueryParameters.named({'e': email}),
      );

      if (result.isEmpty) {
        return LoginResponse(success: false, error: 'User not found');
      }

      final row = result.first.toColumnMap();

      // --- Helper to decode database values safely ---
      String decodeDbValue(dynamic value) {
        if (value == null) return '';
        if (value is List<int>) return utf8.decode(value);
        return value.toString();
      }

      final storedHash = decodeDbValue(row['password_hash']);
      final hashed = sha256.convert(utf8.encode(password)).toString();

      if (storedHash != hashed) {
        return LoginResponse(success: false, error: 'Invalid password');
      }

      if (row['is_active'] == false) {
        return LoginResponse(
            success: false, error: 'Account deactivated from Admin panel');
      }

      final decodedRole = decodeDbValue(row['role']).toUpperCase();
      final userId = decodeDbValue(row['user_id']);
      final phone = decodeDbValue(row['phone']);
      final bloodGroup = decodeDbValue(row['blood_group']);
      final allergies = decodeDbValue(row['allergies']);
      final profilePictureUrl = decodeDbValue(row['profile_picture_url']);

      return LoginResponse(
        success: true,
        role: decodedRole,
        userId: userId, // <--- pass email
        userName: decodeDbValue(row['name']),
        phone: phone,
        bloodGroup: bloodGroup,
        allergies: allergies,
        profilePictureUrl: profilePictureUrl,
      );
    } catch (e, stack) {
      session.log('Login failed: $e\n$stack', level: LogLevel.error);
      return LoginResponse(success: false, error: 'Internal server error');
    }
  }

  //REGISTER (Generate OTP)
  Future<String> register(Session session, String email, String password,
      String name, String role) async {
    final existing = await session.db.unsafeQuery(
      'SELECT 1 FROM users WHERE email = @email',
      parameters: QueryParameters.named({'email': email}),
    );

    if (existing.isNotEmpty) return 'Email already registered';

    return _sendOtp(session, email, password, name, role);
  }

  // RESEND OTP
  Future<String> resendOtp(Session session, String email, String password,
      String name, String role) async {
    return _sendOtp(session, email, password, name, role);
  }

  //COMMON OTP SENDING LOGIC
  Future<String> _sendOtp(Session session, String email, String password,
      String name, String role) async {
    // Generate OTP and JWT token (expires in 2 minutes)
    final otp = (Random().nextInt(900000) + 100000).toString();
    final jti = _uuid.v4();

    // Build JWT with claims: email, otp, jti
    final jwt = JWT(
      {
        'email': email,
        'otp': otp,
        'jti': jti,
      },
      issuer: 'dishari',
      subject: email,
    );

    final token =
        jwt.sign(SecretKey(_jwtSecret), expiresIn: Duration(minutes: 2));

    final success = await _sendOtpWithResend(session, email, otp);

    if (success) {
      session.log('OTP $otp sent successfully via Resend to $email');
      // Return the token to the client; client must send it back when verifying
      return token;
    } else {
      return 'Failed to send OTP. Please try again later.';
    }
  }

  // ---------------- RESEND EMAIL IMPLEMENTATION ----------------
  /// Sends an OTP email using the Resend API. If [isReset] is true,
  /// the email content/subject will be for password reset; otherwise it's for registration.
  Future<bool> _sendOtpWithResend(Session session, String email, String otp,
      {bool isReset = false}) async {
    // Subject and email body content
    final String subject = isReset
        ? 'NSTU Medical Center Password Reset Code'
        : 'NSTU Medical Center Verification Code';

    final String plainTextBody = isReset
        ? 'Your NSTU Medical Center password reset code is: $otp\n'
            'This code will expire in 2 minutes.\n\n'
            'If you did not request this, you can ignore this email.'
        : 'Your NSTU Medical Center registration code is: $otp\n'
            'This code will expire in 2 minutes.\n\n'
            'If you did not request this, you can ignore this email.';

    final String htmlBody = """
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>$subject</title>
  </head>
  <body style="font-family: Arial, sans-serif; line-height:1.6; color:#333;">
    <p>Hello,</p>
    <p>Your one-time code is:</p>
    <h1 style="margin:0; font-size:28px; letter-spacing:1.5px;">$otp</h1>
    <p>This code will expire in <strong>2 minutes</strong>.</p>
    <p>If you did not request ${isReset ? 'a password reset' : 'this verification'}, you can safely ignore this email.</p>
    <br>
    <p>Thank you,<br>NSTU Medical Center</p>
  </body>
</html>
""";

    // Resend API payload
    const String fromEmail = "NSTU Medical Center <onboarding@sabbir.qzz.io>";

    final Map<String, dynamic> emailData = {
      "from": fromEmail,
      "to": [email],
      "subject": subject,
      // Include both plain text and HTML
      "text": plainTextBody,
      "html": htmlBody,
    };

    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $resendApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(emailData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        session.log('Email ($subject) sent successfully to $email via Resend',
            level: LogLevel.info);
        return true;
      } else {
        session.log(
            'Resend API Error (${response.statusCode}): ${response.body}',
            level: LogLevel.warning);
        return false;
      }
    } catch (e) {
      session.log('Resend API connection error: $e', level: LogLevel.warning);
      return false;
    }
  }

  /// Public helper: send a welcome email using Resend API. Returns true on success.
  Future<bool> sendWelcomeEmailViaResend(
      Session session, String email, String name) async {
    final String subject = 'Welcome to NSTU Medical Center';
    final String mailBody =
        'Hi $name,\n\nYour account has been created. You can log in using your email.';

    // Correctly formatted from email
    const String verifiedFromEmail = "Welcome to NSTU Medical Center <onboarding@sabbir.qzz.io>";

    final Map<String, dynamic> emailData = {
      "from": verifiedFromEmail,
      "to": [email],
      "subject": subject,
      "text": mailBody,
    };

    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $resendApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(emailData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        session.log('Welcome email sent via Resend to $email',
            level: LogLevel.info);
        return true;
      } else {
        session.log(
            'Resend API Error (${response.statusCode}): ${response.body}',
            level: LogLevel.warning);
        return false;
      }
    } catch (e) {
      session.log('Resend API connection error (welcome email): $e',
          level: LogLevel.warning);
      return false;
    }
  }

  // VERIFY OTP
  Future<String> verifyOtp(
    Session session,
    String email,
    String otp,
    String token,
    String password,
    String name,
    String role,
    String? phone,
    String? bloodGroup,
    String? allergies,
  ) async {
    final rateKey = 'verifyOtp_$email';
    if (_isRateLimited(rateKey)) {
      return 'Too many OTP attempts. Please wait.';
    }

    // Verify JWT token
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      final payload = jwt.payload;

      // payload should contain email and otp
      if (payload['email'] != email || payload['otp'] != otp) {
        return 'Invalid or expired OTP';
      }
      // token expiry is verified by JWT.verify; if expired or invalid, it throws
    } catch (e) {
      session.log('JWT verification failed: $e', level: LogLevel.warning);
      return 'Invalid or expired OTP';
    }

    // Ensure phone uniqueness if phone provided
    try {
      if (phone != null && phone.trim().isNotEmpty) {
        final existingPhone = await session.db.unsafeQuery(
          'SELECT 1 FROM users WHERE phone = @ph',
          parameters: QueryParameters.named({'ph': phone}),
        );
        if (existingPhone.isNotEmpty) {
          return 'Registration failed: Phone number already registered.';
        }
      }
    } catch (e) {
      session.log('Phone uniqueness check failed: $e', level: LogLevel.warning);
      // Continue - if DB check fails for unexpected reason, let insertion handle unique constraint
    }

    final hashed = sha256.convert(utf8.encode(password)).toString();
    // final String userId = email; // user_id should be auto-generated by DB

    try {
      // Start a transaction
      await session.db.unsafeExecute('BEGIN');

      // 1. Insert into users table and get generated user_id
      final insertResult = await session.db.unsafeQuery(
        '''
      INSERT INTO users (name, email, password_hash, phone, role, is_active)
      VALUES (@n, @e, @p, @ph, @r::user_role, TRUE)
      RETURNING user_id
      ''',
        parameters: QueryParameters.named({
          'n': name,
          'e': email,
          'p': hashed,
          'ph': phone,
          'r': role,
        }),
      );

      if (insertResult.isEmpty) {
        await session.db.unsafeExecute('ROLLBACK');
        return 'Database error during account creation.';
      }

      final insertedRow = insertResult.first.toColumnMap();
      final dynamic generatedId = insertedRow['user_id'];

      // 2. Insert into patient_profiles table ONLY for STUDENT, TEACHER, STAFF
      if (role == 'STUDENT' || role == 'TEACHER' || role == 'STAFF') {
        await session.db.unsafeExecute(
          '''
        INSERT INTO patient_profiles (user_id, blood_group, allergies)
        VALUES (@uid, @bg, @allg)
        ''',
          parameters: QueryParameters.named({
            'uid': generatedId,
            'bg': bloodGroup,
            'allg': allergies,
          }),
        );
      }

      // Commit transaction
      await session.db.unsafeExecute('COMMIT');
    } on DatabaseQueryException catch (e) {
      await session.db.unsafeExecute('ROLLBACK');

      final msg = e.message.toLowerCase();

      if (msg.contains('users_phone_key') || msg.contains('phone')) {
        return 'Phone number already exists';
      }

      if (msg.contains('users_email_key') || msg.contains('email')) {
        return 'Email already exists';
      }

      session.log('Database error during user creation: $e',
          level: LogLevel.error);
      return 'Database error during account creation.';
    } catch (e) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('Unexpected error: $e', level: LogLevel.error);
      return 'An unexpected error occurred during registration.';
    }

    return 'Account created successfully';
  }

  // ---------------- FORGOT PASSWORD / RESET FLOW ----------------
  /// Request a password reset: generate OTP and JWT token (expires in 2 minutes)
  /// Returns the token if email was sent successfully, otherwise an error message.
  Future<String> requestPasswordReset(Session session, String email) async {
    final rateKey = 'reset_$email';
    if (_isRateLimited(rateKey)) {
      return 'Too many reset requests. Please try later.';
    }

    try {
      // Check if user exists in the database; if not, return explicit "User not found" per request
      final exists = await session.db.unsafeQuery(
        'SELECT 1 FROM users WHERE email = @e',
        parameters: QueryParameters.named({'e': email}),
      );

      if (exists.isEmpty) {
        return 'User not found';
      }

      // Generate OTP and token (even if user does not exist, generate & attempt send to keep timing similar)
      final otp = (Random().nextInt(900000) + 100000).toString();
      final jti = _uuid.v4();

      final jwt = JWT(
        {
          'email': email,
          'otp': otp,
          'jti': jti,
        },
        issuer: 'dishari',
        subject: email,
      );

      final token =
          jwt.sign(SecretKey(_jwtSecret), expiresIn: Duration(minutes: 2));

      // Try to send email. If user doesn't exist, _sendOtpWithResend will still be called but not harmful.
      final sent = await _sendOtpWithResend(session, email, otp, isReset: true);

      if (sent) {
        session.log('Password reset OTP $otp sent to $email');
        return token;
      } else {
        return 'Failed to send password reset email. Please try again later.';
      }
    } catch (e, st) {
      session.log('requestPasswordReset failed: $e\n$st',
          level: LogLevel.error);
      return 'Internal server error';
    }
  }

  /// Verify password reset OTP using the client-provided token.
  /// Returns 'OK' on success or an error message on failure.
  Future<String> verifyPasswordReset(
      Session session, String email, String otp, String token) async {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      final payload = jwt.payload;

      if (payload['email'] != email || payload['otp'] != otp) {
        return 'Invalid or expired OTP';
      }

      return 'OK';
    } catch (e) {
      session.log('verifyPasswordReset JWT verification failed: $e',
          level: LogLevel.warning);
      return 'Invalid or expired OTP';
    }
  }

  /// Reset the user's password. Token must be a valid JWT created by requestPasswordReset.
  Future<String> resetPassword(
      Session session, String email, String token, String newPassword) async {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      final payload = jwt.payload;

      if (payload['email'] != email) {
        return 'Invalid token';
      }

      final hashed = sha256.convert(utf8.encode(newPassword)).toString();

      // Update password if user exists
      await session.db.unsafeExecute(
        '''
        UPDATE users SET password_hash = @p WHERE email = @e
        ''',
        parameters: QueryParameters.named({'p': hashed, 'e': email}),
      );

      // unsafeExecute does not return affected rows; do a quick check
      final check = await session.db.unsafeQuery(
        'SELECT 1 FROM users WHERE email = @e',
        parameters: QueryParameters.named({'e': email}),
      );

      if (check.isEmpty) {
        return 'User not found';
      }

      session.log('Password reset successful for $email');
      return 'Password reset successful';
    } catch (e, st) {
      session.log('resetPassword failed: $e\n$st', level: LogLevel.error);
      return 'Internal server error';
    }
  }
}
