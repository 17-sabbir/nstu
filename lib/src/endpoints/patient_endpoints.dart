import 'package:serverpod/serverpod.dart';
import 'package:backend_server/src/generated/protocol.dart';

class PatientEndpoint extends Endpoint {
  // Fetch patient profile
  Future<PatientProfileDto?> getPatientProfile(
      Session session, int userId) async {
    try {
      final result = await session.db.unsafeQuery(
        '''
  SELECT 
    u.name,
    u.email,
    u.phone,
    u.profile_picture_url,
    p.blood_group,
    p.allergies
  FROM users u
  LEFT JOIN patient_profiles p ON p.user_id = u.user_id
  WHERE u.user_id = @userId
    AND u.role IN ('STUDENT','TEACHER','STAFF','OUTSIDE')
  ''',
        parameters: QueryParameters.named({'userId': userId}),
      );

      if (result.isEmpty) return null;

      final row = result.first.toColumnMap();

      return PatientProfileDto(
        name: _safeString(row['name']),
        email: _safeString(row['email']),
        phone: _safeString(row['phone']),
        bloodGroup: _safeString(row['blood_group']),
        allergies: _safeString(row['allergies']),
        profilePictureUrl: _safeString(row['profile_picture_url']), // base64
      );
    } catch (e, stack) {
      session.log('Error getting patient profile: $e\n$stack',
          level: LogLevel.error);
      return null;
    }
  }

  /// List lab tests from the `tests` table. Returns a list of maps with keys:
  /// test_name, description, student_fee, teacher_fee, outside_fee, available
  Future<List<LabTests>> listTests(Session session) async {
    try {
      final result = await session.db.unsafeQuery(
        '''
        SELECT test_name, description, student_fee, teacher_fee, outside_fee, available
        FROM lab_tests
        ORDER BY test_name
        ''',
      );

      session.log('listTests: DB returned ${result.length} rows',
          level: LogLevel.info);

      // Map each row to a simple Map<String, dynamic>

      return result.map((r) {
        final row = r.toColumnMap();
        return LabTests(
          id: null, // backend will replace this
          testName: _safeString(row['test_name']),
          description: _safeString(row['description']),
          studentFee: _toDouble(row['student_fee']),
          teacherFee: _toDouble(row['teacher_fee']),
          outsideFee: _toDouble(row['outside_fee']),
          available: _toBool(row['available']),
        );
      }).toList();
    } catch (e, stack) {
      session.log('Error listing tests: $e\n$stack', level: LogLevel.error);
      return [];
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    if (v is List<int>) return double.tryParse(String.fromCharCodes(v)) ?? 0.0;
    return 0.0;
  }

  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = _safeString(v).toLowerCase();
    return s == 't' || s == 'true' || s == '1';
  }

  /// Return the role of a user (stored as text in users.role) by email/userId.
  /// Returns uppercase role string or empty string if not found.
  Future<String> getUserRole(Session session, int userId) async {
    try {
      final result = await session.db.unsafeQuery(
        '''
        SELECT role::text as role FROM users WHERE user_id= @userId LIMIT 1
        ''',
        parameters: QueryParameters.named({'userId': userId}),
      );

      if (result.isEmpty) return '';
      final row = result.first.toColumnMap();
      final roleVal = _safeString(row['role']).toUpperCase();
      return roleVal;
    } catch (e, stack) {
      session.log('Error fetching user role for $userId: $e\n$stack',
          level: LogLevel.error);
      return '';
    }
  }

  // Update patient profile
  Future<String> updatePatientProfile(
    Session session,
    int userId,
    String name,
    String phone,
    String allergies,
    String? profilePictureData,
  ) async {
    try {
      await session.db.unsafeExecute('BEGIN');

      String? profilePictureUrl;

      // Handle small images (≤50 KB)
      if (profilePictureData != null && profilePictureData.isNotEmpty) {
        if (profilePictureData.length <= 50 * 1024) {
          profilePictureUrl = profilePictureData; // store base64
        } else {
          throw Exception('Image too large. Max 50 KB allowed.');
        }
      }

      // Update users table
      await session.db.unsafeExecute(
        '''
        UPDATE users 
        SET name = @name, phone = @phone,
            profile_picture_url = COALESCE(@profilePictureUrl, profile_picture_url)
        WHERE user_id = @userId
        ''',
        parameters: QueryParameters.named({
          'userId': userId,
          'name': name,
          'phone': phone,
          'profilePictureUrl': profilePictureUrl,
        }),
      );

      // Update or insert into patient_profiles
      await session.db.unsafeExecute(
        '''
  INSERT INTO patient_profiles (user_id, allergies)
  VALUES (@userId, @allergies)
  ON CONFLICT (user_id)
  DO UPDATE SET allergies = EXCLUDED.allergies
  ''',
        parameters: QueryParameters.named({
          'userId': userId,
          'allergies': allergies,
        }),
      );

      await session.db.unsafeExecute('COMMIT');
      return 'Profile updated successfully';
    } catch (e, stack) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('Update profile failed: $e\n$stack', level: LogLevel.error);
      return 'Failed to update profile: $e';
    }
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List<int>) return String.fromCharCodes(value);
    return value.toString();
  }
}
