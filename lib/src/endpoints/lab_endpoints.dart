import 'package:serverpod/serverpod.dart';
import 'package:backend_server/src/generated/protocol.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

class LabEndpoint extends Endpoint {
  /// Fetch all lab tests using your raw SQL schema
  Future<List<LabTests>> getAllLabTests(Session session) async {
    try {
      final result = await session.db.unsafeQuery(
        '''SELECT test_id, test_name, description, student_fee, teacher_fee, outside_fee, available 
           FROM lab_tests 
           ORDER BY test_name ASC''',
      );

      return result.map((r) {
        final row = r.toColumnMap();

        return LabTests(
          id: row['test_id'] as int?, // Ekhon eti constructor-e kaj korbe
          testName: _safeString(row['test_name']),
          description: _safeString(row['description']),
          studentFee: _toDouble(row['student_fee']),
          teacherFee: _toDouble(row['teacher_fee']),
          outsideFee: _toDouble(row['outside_fee']),
          available: row['available'] as bool? ?? true,
        );
      }).toList();
    } catch (e, stackTrace) {
      session.log('Error fetching lab tests: $e',
          level: LogLevel.error, stackTrace: stackTrace);
      return [];
    }
  }

  /// Update an existing lab test (Admin style using QueryParameters)
  Future<bool> updateLabTest(Session session, LabTests test) async {
    if (test.id == null) return false;
    try {
      // AdminEndpoints-er moto unsafeExecute ebong QueryParameters use kora hoyeche
      await session.db.unsafeExecute(
        '''UPDATE lab_tests 
           SET test_name = @testName, 
               description = @description, 
               student_fee = @studentFee, 
               teacher_fee = @teacherFee, 
               outside_fee = @outsideFee, 
               available = @available
           WHERE test_id = @id''',
        parameters: QueryParameters.named({
          'id': test.id,
          'testName': test.testName,
          'description': test.description,
          'studentFee': test.studentFee,
          'teacherFee': test.teacherFee,
          'outsideFee': test.outsideFee,
          'available': test.available,
        }),
      );
      return true;
    } catch (e, stackTrace) {
      session.log('Error updating lab test: $e',
          level: LogLevel.error, stackTrace: stackTrace);
      return false;
    }
  }

  /// Create a new lab test record
  Future<bool> createLabTest(Session session, LabTests test) async {
    try {
      await session.db.unsafeExecute(
        '''INSERT INTO lab_tests (test_name, description, student_fee, teacher_fee, outside_fee, available)
           VALUES (@testName, @description, @studentFee, @teacherFee, @outsideFee, @available)''',
        parameters: QueryParameters.named({
          'testName': test.testName,
          'description': test.description,
          'studentFee': test.studentFee,
          'teacherFee': test.teacherFee,
          'outsideFee': test.outsideFee,
          'available': test.available,
        }),
      );
      return true;
    } catch (e, stackTrace) {
      session.log('Error creating lab test: $e',
          level: LogLevel.error, stackTrace: stackTrace);
      return false;
    }
  }

//result upload er jonnne user er test create
  Future<bool> createTestResult(
    Session session, {
    required int testId,
    required String patientName,
    required String mobileNumber,
    String patientType = 'STUDENT',
  }) async {
    try {
      await session.db.unsafeExecute(
        '''
      INSERT INTO test_results 
      (test_id, patient_name, mobile_number, patient_type)
      VALUES (@testId, @patientName, @mobile, @patientType)
      ''',
        parameters: QueryParameters.named({
          'testId': testId,
          'patientName': patientName,
          'mobile': mobileNumber,
          'patientType': patientType,
        }),
      );
      return true;
    } catch (e, st) {
      session.log('Create test result failed: $e',
          level: LogLevel.error, stackTrace: st);
      return false;
    }
  }

//File upload after create test for users
  Future<bool> attachResultFile(
    Session session, {
    required int resultId,
    required String attachmentPath,
  }) async {
    try {
      await session.db.unsafeExecute(
        '''
      UPDATE test_results
      SET is_uploaded = TRUE,
          attachment_path = @path
      WHERE result_id = @id
      ''',
        parameters: QueryParameters.named({
          'id': resultId,
          'path': attachmentPath,
        }),
      );
      return true;
    } catch (e, st) {
      session.log('Attach file failed: $e',
          level: LogLevel.error, stackTrace: st);
      return false;
    }
  }

  /// Accepts raw file bytes from client, saves them to server disk (uploads/),
  /// and updates test_results. Returns the saved relative path on success.
  Future<String?> attachResultFileBytes(
    Session session, {
    required int resultId,
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      // sanitize filename
      final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final dir = Directory('uploads');
      if (!await dir.exists()) await dir.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedName = '${timestamp}_$safeName';
      final savedFile = File('${dir.path}/$savedName');

      await savedFile.writeAsBytes(bytes);

      final relativePath = '${dir.path}/$savedName';

      await session.db.unsafeExecute(
        '''
      UPDATE test_results
      SET is_uploaded = TRUE,
          attachment_path = @path
      WHERE result_id = @id
      ''',
        parameters: QueryParameters.named({
          'id': resultId,
          'path': relativePath,
        }),
      );

      return relativePath;
    } catch (e, st) {
      session.log('Attach file (bytes) failed: $e',
          level: LogLevel.error, stackTrace: st);
      return null;
    }
  }

  /// Dummy SMS sender: logs message to server logs (no real SMS)
  Future<bool> sendDummySms(Session session,
      {required String mobileNumber, required String message}) async {
    // simulate sending delay
    await Future.delayed(const Duration(milliseconds: 500));

    print('We sent a SMS TO: $mobileNumber');
    print('Message: $message');
    return true;
  }
//submit result

  Future<bool> submitResult(
    Session session, {
    required int resultId,
  }) async {
    try {
      await session.db.unsafeExecute(
        '''
      UPDATE test_results
      SET submitted_at = NOW()
      WHERE result_id = @id
      ''',
        parameters: QueryParameters.named({
          'id': resultId,
        }),
      );
      return true;
    } catch (e, st) {
      session.log('Submit result failed: $e',
          level: LogLevel.error, stackTrace: st);
      return false;
    }
  }

  /// Submit or resubmit result + dummy SMS notification
  Future<bool> submitResultWithSms(Session session,
      {required int resultId}) async {
    try {
      // Update submitted_at anyway (submit or resubmit)
      await session.db.unsafeExecute(
        '''
      UPDATE test_results
      SET submitted_at = NOW()
      WHERE result_id = @id
      ''',
        parameters: QueryParameters.named({'id': resultId}),
      );

      // Fetch result to get mobile number and patient name
      final rows = await session.db.unsafeQuery(
        'SELECT patient_name, mobile_number FROM test_results WHERE result_id = @id',
        parameters: QueryParameters.named({'id': resultId}),
      );

      if (rows.isEmpty) return false;

      final m = rows.first.toColumnMap();
      final name = m['patient_name']?.toString() ?? 'Patient';
      final mobile = m['mobile_number']?.toString() ?? '';

      // Send SMS message (same for submit/resubmit)
      final message = 'প্রিয় $name, আপনার lab result submit হয়েছে।';
      await sendDummySms(session, mobileNumber: mobile, message: message);

      return true;
    } catch (e, st) {
      session.log('submitResultWithSms failed: $e',
          level: LogLevel.error, stackTrace: st);
      return false;
    }
  }

//Fetch all results (list screen)
  Future<List<TestResult>> getAllTestResults(Session session) async {
    try {
      final rows = await session.db.unsafeQuery(
        '''
      SELECT * FROM test_results
      ORDER BY created_at DESC
      ''',
      );

      return rows.map((r) {
        final m = r.toColumnMap();
        return TestResult(
          resultId: m['result_id'] as int,
          testId: m['test_id'] as int,
          patientName: _safeString(m['patient_name']),
          mobileNumber: _safeString(m['mobile_number']),
          patientType: _safeString(m['patient_type']),
          isUploaded: (m['is_uploaded'] as bool?) ?? false,
          attachmentPath: m['attachment_path'] as String?,
          submittedAt: m['submitted_at'] as DateTime?,
          createdAt: m['created_at'] as DateTime?,
        );
      }).toList();
    } catch (e, st) {
      session.log('Fetch results failed: $e',
          level: LogLevel.error, stackTrace: st);
      return [];
    }
  }

  // Fetch raw attachment bytes for a given result id (for preview)
  Future<List<int>?> getAttachmentBytes(Session session, int resultId) async {
    try {
      final rows = await session.db.unsafeQuery(
        '''SELECT attachment_path FROM test_results WHERE result_id = @id''',
        parameters: QueryParameters.named({'id': resultId}),
      );

      if (rows.isEmpty) return null;
      final path = rows.first.toColumnMap()['attachment_path'] as String?;
      if (path == null) return null;

      final file = File(path);
      if (!await file.exists()) return null;

      return await file.readAsBytes();
    } catch (e, st) {
      session.log('getAttachmentBytes failed: $e',
          level: LogLevel.error, stackTrace: st);
      return null;
    }
  }

  /// Start a chunked upload. Returns an uploadId string.
  Future<String> startFileUpload(Session session, String fileName) async {
    try {
      final uploadId =
          '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
      final dir = Directory('uploads');
      if (!await dir.exists()) await dir.create(recursive: true);

      // create empty temp part file and metadata
      final partFile = File(
          'uploads/tmp_\$uploadId.part'.replaceAll('\$uploadId', uploadId));
      await partFile.writeAsBytes([], flush: true);

      final metaFile = File(
          'uploads/tmp_\$uploadId.meta'.replaceAll('\$uploadId', uploadId));
      await metaFile.writeAsString(fileName, flush: true);

      return uploadId;
    } catch (e, st) {
      session.log('startFileUpload failed: $e',
          level: LogLevel.error, stackTrace: st);
      return '';
    }
  }

  /// Upload a chunk for a given uploadId. Appends bytes to the temp part file.
  Future<bool> uploadFileChunk(
      Session session, String uploadId, List<int> bytes) async {
    try {
      final partPath = 'uploads/tmp_\$uploadId.part'.replaceAll('\\', '/');
      final partFile = File(partPath);
      if (!await partFile.exists()) await partFile.create(recursive: true);
      await partFile.writeAsBytes(bytes, mode: FileMode.append, flush: true);
      return true;
    } catch (e, st) {
      session.log('uploadFileChunk failed: $e',
          level: LogLevel.error, stackTrace: st);
      return false;
    }
  }

  /// Finish chunked upload: move temp file to final path and update DB for resultId.
  Future<String?> finishFileUpload(
      Session session, String uploadId, int resultId) async {
    try {
      final metaPath = 'uploads/tmp_\$uploadId.meta'.replaceAll('\\', '/');
      final partPath = 'uploads/tmp_\$uploadId.part'.replaceAll('\\', '/');
      final metaFile = File(metaPath);
      final partFile = File(partPath);
      if (!await partFile.exists() || !await metaFile.exists()) return null;

      final originalName = await metaFile.readAsString();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Construct saved file path using sanitized name (inline to avoid unused-variable warnings)
      final savedFile = File(
          'uploads/${timestamp}_${originalName.replaceAll(RegExp(r"[^A-Za-z0-9._-]"), "_")}'
              .replaceAll('\\', '/'));

      await partFile.rename(savedFile.path);
      // remove meta file (best-effort)
      try {
        await metaFile.delete();
      } catch (_) {
        // ignore
      }

      final relativePath = savedFile.path;

      await session.db.unsafeExecute(
        '''
      UPDATE test_results
      SET is_uploaded = TRUE,
          attachment_path = @path
      WHERE result_id = @id
      ''',
        parameters:
            QueryParameters.named({'id': resultId, 'path': relativePath}),
      );

      return relativePath;
    } catch (e, st) {
      session.log('finishFileUpload failed: $e',
          level: LogLevel.error, stackTrace: st);
      return null;
    }
  }

  // --- Type Safety Helpers ---

  String _safeString(dynamic value) {
    if (value == null) return '';

    try {
      // ✅ handles UndecodedBytes WITHOUT referencing the type
      if (value is dynamic &&
          value.runtimeType.toString() == 'UndecodedBytes') {
        final bytes = (value as dynamic).bytes as List<int>;
        return utf8.decode(bytes);
      }

      if (value is Uint8List) {
        return utf8.decode(value);
      }

      if (value is Iterable<int>) {
        return utf8.decode(value.toList());
      }
    } catch (_) {
      // ignore decode errors
    }
    return value.toString();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    // PostgreSQL NUMERIC often comes back as a String or double via the driver
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
