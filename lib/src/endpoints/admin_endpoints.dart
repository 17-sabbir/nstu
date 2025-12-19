import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'dart:async'; // added for fire-and-forget scheduling

import 'auth_endpoint.dart';
import '../generated/protocol.dart';

/// AdminEndpoints: server-side methods used by the admin UI to manage users,
/// inventory, rosters, audit logs and notifications.
class AdminEndpoints extends Endpoint {
  /// Helper: map a DB row to a serializable map for the client.
  Map<String, dynamic> _rowToUserMap(Map<String, dynamic> row) {
    String decode(dynamic v) {
      if (v == null) return '';
      if (v is List<int>) return String.fromCharCodes(v);
      return v.toString();
    }

    return {
      'userId': decode(row['user_id']),
      'name': decode(row['name']),
      'email': decode(row['email']),
      'role': decode(row['role']).toUpperCase(),
      'phone': decode(row['phone']),
      // Normalize profile picture column (nullable)
      'profilePictureUrl': decode(row['profile_picture_url']),
      'active': row['is_active'] == true,
    };
  }

  /// List users filtered by role. Use role = 'ALL' to fetch all users.
  Future<List<UserListItem>> listUsersByRole(
      Session session, String role, int limit) async {
    try {
      final isAll = role.trim().toUpperCase() == 'ALL' || role.trim().isEmpty;
      final sql = isAll
          ? '''SELECT user_id, name, email, role::text, phone, profile_picture_url, is_active FROM users ORDER BY name LIMIT @lim'''
          : '''SELECT user_id, name, email, role::text, phone, profile_picture_url, is_active FROM users WHERE (lower(role::text) LIKE @role || '%' OR @role LIKE lower(role::text) || '%') ORDER BY name LIMIT @lim''';

      final params = isAll
          ? QueryParameters.named({'lim': limit})
          : QueryParameters.named({'role': role.toLowerCase(), 'lim': limit});

      final result = await session.db.unsafeQuery(sql, parameters: params);
      final list = <UserListItem>[];
      for (final r in result) {
        final row = r.toColumnMap();
        final decoded = _rowToUserMap(row);
        list.add(UserListItem(
          userId: decoded['userId'] ?? '',
          name: decoded['name'] ?? '',
          email: decoded['email'] ?? '',
          role: decoded['role'] ?? '',
          phone: decoded['phone'] ?? '',
          profilePictureUrl: decoded['profilePictureUrl'] ?? '',
          active: decoded['active'] == true,
        ));
      }
      return list;
    } catch (e, st) {
      session.log('listUsersByRole failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  /// Toggle user's active flag. Returns true on success.
  Future<bool> toggleUserActive(Session session, String userId) async {
    try {
      await session.db.unsafeExecute(
        'UPDATE users SET is_active = NOT is_active WHERE user_id = @uid',
        parameters: QueryParameters.named({'uid': userId}),
      );
      return true;
    } catch (e, st) {
      session.log('UserActive failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  /// Create a new user record. Expects passwordHash to already be hashed by the caller.
  /// Returns 'OK' on success or an error message string.
  Future<String> createUser(Session session, String userId, String name,
      String email, String passwordHash, String role, String? phone) async {
    try {
      // Pre-check for existing email or phone to return clear messages
      final existing = await session.db.unsafeQuery(
        'SELECT email, phone FROM users WHERE email = @e OR phone = @ph LIMIT 1',
        parameters: QueryParameters.named({'e': email, 'ph': phone}),
      );

      if (existing.isNotEmpty) {
        final row = existing.first.toColumnMap();
        final existingEmail = row['email'];
        final existingPhone = row['phone'];
        if (existingEmail != null &&
            existingEmail.toString().toLowerCase() == email.toLowerCase()) {
          return 'Email already registered';
        }
        if (phone != null &&
            existingPhone != null &&
            existingPhone.toString() == phone) {
          return 'Phone number already registered';
        }
        // Fallback generic duplicate message
        return 'User already exists';
      }

      await session.db.unsafeExecute('BEGIN');

      // Insert user letting DB generate user_id (ignore provided userId)
      final insertResult = await session.db.unsafeQuery(
        '''
        INSERT INTO users (name, email, password_hash, phone, role, is_active)
        VALUES (@name, @email, @pass, @phone, @role::user_role, TRUE)
        RETURNING user_id
        ''',
        parameters: QueryParameters.named({
          'name': name,
          'email': email,
          'pass': passwordHash,
          'phone': phone,
          'role': role,
        }),
      );

      if (insertResult.isEmpty) {
        await session.db.unsafeExecute('ROLLBACK');
        return 'Database error';
      }

      // generated id available in `insertResult.first` if needed

      await session.db.unsafeExecute('COMMIT');
      return 'OK';
    } on DatabaseQueryException catch (e) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('createUser DB error: $e', level: LogLevel.error);
      // Try to surface a helpful message if duplicate key
      final msg = e.message.toLowerCase();
      if (msg.contains('duplicate')) {
        return 'User already exists';
      }
      return 'Database error';
    } catch (e, st) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('createUser failed: $e\n$st', level: LogLevel.error);
      return 'Internal error';
    }
  }

  /// Create user by hashing the provided raw password server-side.
  Future<String> createUserWithPassword(
      Session session,
      String userId,
      String name,
      String email,
      String password,
      String role,
      String? phone) async {
    try {
      final hashed = sha256.convert(utf8.encode(password)).toString();
      final res =
          await createUser(session, userId, name, email, hashed, role, phone);
      if (res == 'OK') {
        // Send welcome email for these roles when created via admin UI.
        try {
          final allowed = <String>{'ADMIN', 'DOCTOR', 'DISPENSER', 'LABSTAFF'};
          final r = role.toUpperCase();
          if (allowed.contains(r)) {
            // Fire-and-forget so user creation is not blocked by email sending.
            Future.microtask(() async {
              try {
                final auth = AuthEndpoint();
                await auth.sendWelcomeEmailViaResend(session, email, name);
              } catch (e, st) {
                session.log('Failed to send welcome email (async): $e\n$st',
                    level: LogLevel.warning);
              }
            });
          }
        } catch (e) {
          session.log('Failed to schedule welcome email: $e',
              level: LogLevel.warning);
        }
      }
      return res;
    } catch (e, st) {
      session.log('createUserWithPassword failed: $e\n$st',
          level: LogLevel.error);
      return 'Internal error';
    }
  }

  // ------------------ Inventory / Medicines ------------------
  /// Ensure medicines and medicine_batches tables exist.
  Future<bool> _initMedicineTables(Session session) async {
    try {
      await session.db.unsafeExecute('''
        CREATE TABLE IF NOT EXISTS medicines (
          medicine_id SERIAL PRIMARY KEY,
          name VARCHAR(100) NOT NULL UNIQUE,
          minimum_stock INTEGER DEFAULT 10
        )
      ''');

      await session.db.unsafeExecute('''
        CREATE TABLE IF NOT EXISTS medicine_batches (
          batch_id TEXT PRIMARY KEY,
          medicine_id INTEGER REFERENCES medicines(medicine_id) ON DELETE CASCADE,
          stock INTEGER DEFAULT 0,
          expiry DATE
        )
      ''');

      return true;
    } catch (e, st) {
      session.log('initMedicineTables failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  /// List all medicines with aggregated stock and earliest expiry.
  Future<List<Map<String, dynamic>>> listMedicines(Session session) async {
    try {
      await _initMedicineTables(session);

      final result = await session.db.unsafeQuery('''
        SELECT m.medicine_id, m.name, m.minimum_stock,
               COALESCE(SUM(b.stock), 0) AS total_stock,
               MIN(b.expiry) AS earliest_expiry
        FROM medicines m
        LEFT JOIN medicine_batches b ON b.medicine_id = m.medicine_id
        GROUP BY m.medicine_id, m.name, m.minimum_stock
        ORDER BY m.name
      ''');

      final list = <Map<String, dynamic>>[];
      for (final r in result) {
        final row = r.toColumnMap();
        list.add({
          'medicineId': row['medicine_id'],
          'name': row['name'],
          'minimumStock': row['minimum_stock'],
          'totalStock': row['total_stock'],
          'earliestExpiry': row['earliest_expiry']?.toString(),
        });
      }
      return list;
    } catch (e, st) {
      session.log('listMedicines failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  /// Add a medicine and return the inserted id or -1 on error.
  Future<int> addMedicine(
      Session session, String name, int minimumStock) async {
    try {
      await _initMedicineTables(session);
      final result = await session.db.unsafeQuery('''
        INSERT INTO medicines (name, minimum_stock)
        VALUES (@name, @min)
        RETURNING medicine_id
      ''',
          parameters:
              QueryParameters.named({'name': name, 'min': minimumStock}));

      if (result.isEmpty) return -1;
      final row = result.first.toColumnMap();
      return row['medicine_id'];
    } catch (e, st) {
      session.log('addMedicine failed: $e\n$st', level: LogLevel.error);
      return -1;
    }
  }

  // ------------------ Rosters ------------------
  Future<bool> _initRostersTable(Session session) async {
    try {
      // Create enum types if missing and the new staff_roster table.
      await session.db.unsafeExecute(r'''
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'roster_user_role') THEN
            CREATE TYPE roster_user_role AS ENUM ('DOCTOR','NURSE','STAFF');
          END IF;
          IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'shift_type') THEN
            CREATE TYPE shift_type AS ENUM ('DAY','NIGHT');
          END IF;
        END
        $$;
      ''');

      await session.db.unsafeExecute(r'''
        CREATE TABLE IF NOT EXISTS staff_roster (
          roster_id BIGSERIAL PRIMARY KEY,
          staff_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
          staff_name VARCHAR(100) NOT NULL,
          staff_role roster_user_role NOT NULL,
          shift_date DATE NOT NULL,
          shift shift_type NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          UNIQUE (staff_id, shift_date)
        )
      ''');

      return true;
    } catch (e, st) {
      session.log('initRostersTable failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  Future<List<Roster>> getRosters(Session session,
      String? staffId, DateTime? fromDate, DateTime? toDate) async {
    try {
      await _initRostersTable(session);

      final DateTime effectiveFrom = fromDate ?? DateTime.now();

      final buffer = StringBuffer(
          'SELECT roster_id, staff_id, staff_name, staff_role::text AS staff_role, shift::text AS shift, shift_date FROM staff_roster');
      final params = <String, dynamic>{};
      final where = <String>[];

      if (staffId != null && staffId.isNotEmpty) {
        where.add('staff_id = @staff::bigint');
        params['staff'] = staffId;
      }

      where.add('shift_date >= @fromd');
      params['fromd'] = DateTime(effectiveFrom.year, effectiveFrom.month, effectiveFrom.day);

      if (toDate != null) {
        where.add('shift_date <= @tod');
        params['tod'] = toDate;
      }

      if (where.isNotEmpty) {
        buffer.write(' WHERE ' + where.join(' AND '));
      }
      buffer.write(' ORDER BY shift_date');

      final result = await session.db.unsafeQuery(buffer.toString(),
          parameters: QueryParameters.named(params));

      return result.map((r) {
        final row = r.toColumnMap();
        return Roster(
          rosterId: row['roster_id'] as int?,
          staffId: row['staff_id'] as int,
          staffName: row['staff_name'] as String,
          staffRole: row['staff_role'] as String,
          shift: row['shift'] as String,
          shiftDate: row['shift_date'] as DateTime,
        );
      }).toList();
    } catch (e, st) {
      session.log('getRosters failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  Future<bool> saveRoster(
      Session session,
      String rosterId,
      String staffId,
      String shiftType,
      DateTime shiftDate,
      String timeRange,
      String status,
      String? approvedBy) async {
    try {
      await _initRostersTable(session);

      // Helper to determine shift enum value
      String determineShift(String st, String tr) {
        final up = st.trim().toUpperCase();
        if (up == 'DAY' || up == 'NIGHT') return up;
        final ltr = tr.toLowerCase();
        if (ltr.contains('night')) return 'NIGHT';
        return 'DAY';
      }

      // Validate staffId presence
      if (staffId.trim().isEmpty) {
        // Do not insert rows without a valid staff id
        session.log('saveRoster rejected: empty staffId', level: LogLevel.info);
        return false;
      }

      // Fetch user's name and role to populate staff_name and staff_role
      final ures = await session.db.unsafeQuery(
        'SELECT name, role::text AS role FROM users WHERE user_id = @uid::bigint LIMIT 1',
        parameters: QueryParameters.named({'uid': staffId}),
      );

      if (ures.isEmpty) {
        // No user found with provided id -> reject
        session.log('saveRoster rejected: user not found for staffId=$staffId', level: LogLevel.info);
        return false;
      }

      final userRow = ures.first.toColumnMap();
      final staffName = userRow['name']?.toString() ?? '';

      String staffRole() {
        final r = (userRow['role'] ?? '').toString().toLowerCase();
        if (r.contains('doctor')) return 'DOCTOR';
        if (r.contains('nurse')) return 'NURSE';
        if (r.contains('dispenser')) return 'NURSE';
        return 'STAFF';
      }

      final shift = determineShift(shiftType, timeRange);
      final srole = staffRole();

      // If rosterId parseable -> UPDATE, else INSERT
      if (rosterId.isNotEmpty) {
        final parsed = int.tryParse(rosterId);
        if (parsed != null && parsed > 0) {
          await session.db.unsafeExecute('''
            UPDATE staff_roster SET
              staff_id = @sid::bigint,
              staff_name = @sname,
              staff_role = @srole::roster_user_role,
              shift = @shift::shift_type,
              shift_date = @sdate,
              updated_at = CURRENT_TIMESTAMP
            WHERE roster_id = @rid::bigint
          ''',
              parameters: QueryParameters.named({
                'sid': staffId,
                'sname': staffName,
                'srole': srole,
                'shift': shift,
                'sdate': shiftDate,
                'rid': rosterId,
              }));
          return true;
        }
      }

      // Insert new roster row. Unique constraint (staff_id, shift_date) will prevent duplicates.
      final insertRes = await session.db.unsafeQuery('''
        INSERT INTO staff_roster (staff_id, staff_name, staff_role, shift, shift_date)
        VALUES (@sid::bigint, @sname, @srole::roster_user_role, @shift::shift_type, @sdate)
        RETURNING roster_id
      ''',
          parameters: QueryParameters.named({
            'sid': staffId,
            'sname': staffName,
            'srole': srole,
            'shift': shift,
            'sdate': shiftDate,
          }));

      return insertRes.isNotEmpty;
    } on DatabaseQueryException catch (e) {
      // DB constraint failure (e.g., unique) -> return false
      session.log('saveRoster DB error: $e', level: LogLevel.error);
      return false;
    } catch (e, st) {
      session.log('saveRoster failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  // ------------------ Audit Log ------------------
  Future<bool> _initAuditLog(Session session) async {
    try {
      await session.db.unsafeExecute('''
        CREATE TABLE IF NOT EXISTS audit_log (
          log_id VARCHAR(50) PRIMARY KEY,
          user_id VARCHAR(50),
          action VARCHAR(200),
          timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      return true;
    } catch (e, st) {
      session.log('initAuditLog failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  Future<bool> addAuditLog(
      Session session, String logId, String userId, String action) async {
    try {
      await _initAuditLog(session);
      await session.db.unsafeExecute('''
        INSERT INTO audit_log (log_id, user_id, action) VALUES (@id, @uid, @act)
      ''',
          parameters: QueryParameters.named(
              {'id': logId, 'uid': userId, 'act': action}));
      return true;
    } catch (e, st) {
      session.log('addAuditLog failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }




  // ------------------ Staff Profiles ------------------
  Future<bool> _initStaffProfiles(Session session) async {
    try {
      await session.db.unsafeExecute('''
        CREATE TABLE IF NOT EXISTS staff_profiles (
          user_id VARCHAR(50) PRIMARY KEY REFERENCES users(user_id),
          specialization VARCHAR(100),
          qualification VARCHAR(100),
          joining_date DATE
        )
      ''');
      return true;
    } catch (e, st) {
      session.log('initStaffProfiles failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  Future<List<Rosterlists>> listStaff(
      Session session, int limit) async {
    try {
      final result = await session.db.unsafeQuery(
        '''
      SELECT u.user_id, u.name, u.role::text AS role
      FROM users u
      WHERE lower(u.role::text) IN ('doctor','dispenser','labstaff','staff')
      ORDER BY u.name
      LIMIT @lim
      ''',
        parameters: QueryParameters.named({'lim': limit}),
      );

      final list = <Rosterlists>[];

      for (final r in result) {
        final row = r.toColumnMap();

        list.add(
          Rosterlists(
            userId: row['user_id'].toString(),
            name: row['name'].toString(),
            role: row['role'].toString(),
          ),
        );
      }

      return list;
    } catch (e, st) {
      session.log('listStaff failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }


  // ------------------ Admin Profile / Password Management ------------------
  /// Get admin profile (name, email, phone, profilePictureUrl) by email (userId)
  Future<Map<String, dynamic>?> getAdminProfile(
      Session session, String userId) async {
    try {
      final result = await session.db.unsafeQuery(
        '''
        SELECT name, email, phone, profile_picture_url
        FROM users
        WHERE email = @e
        ''',
        parameters: QueryParameters.named({'e': userId}),
      );

      if (result.isEmpty) return null;
      final row = result.first.toColumnMap();
      return {
        'name': row['name'] ?? '',
        'email': row['email'] ?? '',
        'phone': row['phone'] ?? '',
        'profilePictureUrl': row['profile_picture_url'] ?? '',
      };
    } catch (e, st) {
      session.log('getAdminProfile failed: $e\n$st', level: LogLevel.error);
      return null;
    }
  }

  /// Update admin profile: name, phone, optional small base64 profilePictureData (<=50KB)
  Future<String> updateAdminProfile(Session session, String userId, String name,
      String phone, String? profilePictureData) async {
    try {
      await session.db.unsafeExecute('BEGIN');

      String? profilePictureUrl;
      if (profilePictureData != null && profilePictureData.isNotEmpty) {
        if (profilePictureData.length <= 50 * 1024) {
          profilePictureUrl = profilePictureData; // store small base64 blob
        } else {
          await session.db.unsafeExecute('ROLLBACK');
          return 'Profile picture too large. Max 50 KB allowed.';
        }
      }

      await session.db.unsafeExecute(
        '''
        UPDATE users
        SET name = @name,
            phone = @phone,
            profile_picture_url = COALESCE(@ppurl, profile_picture_url)
        WHERE email = @e
        ''',
        parameters: QueryParameters.named({
          'e': userId,
          'name': name,
          'phone': phone,
          'ppurl': profilePictureUrl,
        }),
      );

      await session.db.unsafeExecute('COMMIT');
      return 'OK';
    } catch (e, st) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('updateAdminProfile failed: $e\n$st', level: LogLevel.error);
      return 'Failed to update profile';
    }
  }

  /// Change password for given user (identified by email/userId). Verifies current password before updating.
  Future<String> changePassword(Session session, String userId,
      String currentPassword, String newPassword) async {
    try {
      final result = await session.db.unsafeQuery(
        '''SELECT password_hash FROM users WHERE email = @e''',
        parameters: QueryParameters.named({'e': userId}),
      );

      if (result.isEmpty) return 'User not found';

      final row = result.first.toColumnMap();
      String storedHash;
      final ph = row['password_hash'];
      if (ph == null)
        storedHash = '';
      else if (ph is List<int>)
        storedHash = String.fromCharCodes(ph);
      else
        storedHash = ph.toString();

      final currHash = sha256.convert(utf8.encode(currentPassword)).toString();
      if (storedHash != currHash) return 'Incorrect current password';

      final newHash = sha256.convert(utf8.encode(newPassword)).toString();
      await session.db.unsafeExecute(
        'UPDATE users SET password_hash = @p WHERE email = @e',
        parameters: QueryParameters.named({'p': newHash, 'e': userId}),
      );

      return 'OK';
    } catch (e, st) {
      session.log('changePassword failed: $e\n$st', level: LogLevel.error);
      return 'Failed to change password';
    }
  }
}
