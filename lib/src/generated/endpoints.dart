/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../endpoints/admin_endpoints.dart' as _i2;
import '../endpoints/auth_endpoint.dart' as _i3;
import '../endpoints/lab_endpoints.dart' as _i4;
import '../endpoints/patient_endpoints.dart' as _i5;
import '../greeting_endpoint.dart' as _i6;
import 'package:backend_server/src/generated/patient_return_tests.dart' as _i7;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'adminEndpoints': _i2.AdminEndpoints()
        ..initialize(
          server,
          'adminEndpoints',
          null,
        ),
      'auth': _i3.AuthEndpoint()
        ..initialize(
          server,
          'auth',
          null,
        ),
      'lab': _i4.LabEndpoint()
        ..initialize(
          server,
          'lab',
          null,
        ),
      'patient': _i5.PatientEndpoint()
        ..initialize(
          server,
          'patient',
          null,
        ),
      'greeting': _i6.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };
    connectors['adminEndpoints'] = _i1.EndpointConnector(
      name: 'adminEndpoints',
      endpoint: endpoints['adminEndpoints']!,
      methodConnectors: {
        'listUsersByRole': _i1.MethodConnector(
          name: 'listUsersByRole',
          params: {
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .listUsersByRole(
                    session,
                    params['role'],
                    params['limit'],
                  ),
        ),
        'toggleUserActive': _i1.MethodConnector(
          name: 'toggleUserActive',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .toggleUserActive(
                    session,
                    params['userId'],
                  ),
        ),
        'createUser': _i1.MethodConnector(
          name: 'createUser',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'passwordHash': _i1.ParameterDescription(
              name: 'passwordHash',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .createUser(
                    session,
                    params['userId'],
                    params['name'],
                    params['email'],
                    params['passwordHash'],
                    params['role'],
                    params['phone'],
                  ),
        ),
        'createUserWithPassword': _i1.MethodConnector(
          name: 'createUserWithPassword',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .createUserWithPassword(
                    session,
                    params['userId'],
                    params['name'],
                    params['email'],
                    params['password'],
                    params['role'],
                    params['phone'],
                  ),
        ),
        'listMedicines': _i1.MethodConnector(
          name: 'listMedicines',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .listMedicines(session),
        ),
        'addMedicine': _i1.MethodConnector(
          name: 'addMedicine',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'minimumStock': _i1.ParameterDescription(
              name: 'minimumStock',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .addMedicine(
                    session,
                    params['name'],
                    params['minimumStock'],
                  ),
        ),
        'getRosters': _i1.MethodConnector(
          name: 'getRosters',
          params: {
            'staffId': _i1.ParameterDescription(
              name: 'staffId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'fromDate': _i1.ParameterDescription(
              name: 'fromDate',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
            'toDate': _i1.ParameterDescription(
              name: 'toDate',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .getRosters(
                    session,
                    params['staffId'],
                    params['fromDate'],
                    params['toDate'],
                  ),
        ),
        'saveRoster': _i1.MethodConnector(
          name: 'saveRoster',
          params: {
            'rosterId': _i1.ParameterDescription(
              name: 'rosterId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'staffId': _i1.ParameterDescription(
              name: 'staffId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'shiftType': _i1.ParameterDescription(
              name: 'shiftType',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'shiftDate': _i1.ParameterDescription(
              name: 'shiftDate',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
            'timeRange': _i1.ParameterDescription(
              name: 'timeRange',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'status': _i1.ParameterDescription(
              name: 'status',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'approvedBy': _i1.ParameterDescription(
              name: 'approvedBy',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .saveRoster(
                    session,
                    params['rosterId'],
                    params['staffId'],
                    params['shiftType'],
                    params['shiftDate'],
                    params['timeRange'],
                    params['status'],
                    params['approvedBy'],
                  ),
        ),
        'addAuditLog': _i1.MethodConnector(
          name: 'addAuditLog',
          params: {
            'logId': _i1.ParameterDescription(
              name: 'logId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'action': _i1.ParameterDescription(
              name: 'action',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .addAuditLog(
                    session,
                    params['logId'],
                    params['userId'],
                    params['action'],
                  ),
        ),
        'listStaff': _i1.MethodConnector(
          name: 'listStaff',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminEndpoints'] as _i2.AdminEndpoints).listStaff(
                    session,
                    params['limit'],
                  ),
        ),
        'getAdminProfile': _i1.MethodConnector(
          name: 'getAdminProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .getAdminProfile(
                    session,
                    params['userId'],
                  ),
        ),
        'updateAdminProfile': _i1.MethodConnector(
          name: 'updateAdminProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'profilePictureData': _i1.ParameterDescription(
              name: 'profilePictureData',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .updateAdminProfile(
                    session,
                    params['userId'],
                    params['name'],
                    params['phone'],
                    params['profilePictureData'],
                  ),
        ),
        'changePassword': _i1.MethodConnector(
          name: 'changePassword',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'currentPassword': _i1.ParameterDescription(
              name: 'currentPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .changePassword(
                    session,
                    params['userId'],
                    params['currentPassword'],
                    params['newPassword'],
                  ),
        ),
      },
    );
    connectors['auth'] = _i1.EndpointConnector(
      name: 'auth',
      endpoint: endpoints['auth']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i3.AuthEndpoint).login(
                session,
                params['email'],
                params['password'],
              ),
        ),
        'register': _i1.MethodConnector(
          name: 'register',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i3.AuthEndpoint).register(
                session,
                params['email'],
                params['password'],
                params['name'],
                params['role'],
              ),
        ),
        'resendOtp': _i1.MethodConnector(
          name: 'resendOtp',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i3.AuthEndpoint).resendOtp(
                session,
                params['email'],
                params['password'],
                params['name'],
                params['role'],
              ),
        ),
        'sendWelcomeEmailViaResend': _i1.MethodConnector(
          name: 'sendWelcomeEmailViaResend',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i3.AuthEndpoint)
                  .sendWelcomeEmailViaResend(
                    session,
                    params['email'],
                    params['name'],
                  ),
        ),
        'verifyOtp': _i1.MethodConnector(
          name: 'verifyOtp',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'otp': _i1.ParameterDescription(
              name: 'otp',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'token': _i1.ParameterDescription(
              name: 'token',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'bloodGroup': _i1.ParameterDescription(
              name: 'bloodGroup',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'allergies': _i1.ParameterDescription(
              name: 'allergies',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i3.AuthEndpoint).verifyOtp(
                session,
                params['email'],
                params['otp'],
                params['token'],
                params['password'],
                params['name'],
                params['role'],
                params['phone'],
                params['bloodGroup'],
                params['allergies'],
              ),
        ),
        'requestPasswordReset': _i1.MethodConnector(
          name: 'requestPasswordReset',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i3.AuthEndpoint).requestPasswordReset(
                    session,
                    params['email'],
                  ),
        ),
        'verifyPasswordReset': _i1.MethodConnector(
          name: 'verifyPasswordReset',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'otp': _i1.ParameterDescription(
              name: 'otp',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'token': _i1.ParameterDescription(
              name: 'token',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i3.AuthEndpoint).verifyPasswordReset(
                    session,
                    params['email'],
                    params['otp'],
                    params['token'],
                  ),
        ),
        'resetPassword': _i1.MethodConnector(
          name: 'resetPassword',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'token': _i1.ParameterDescription(
              name: 'token',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i3.AuthEndpoint).resetPassword(
                session,
                params['email'],
                params['token'],
                params['newPassword'],
              ),
        ),
      },
    );
    connectors['lab'] = _i1.EndpointConnector(
      name: 'lab',
      endpoint: endpoints['lab']!,
      methodConnectors: {
        'getAllLabTests': _i1.MethodConnector(
          name: 'getAllLabTests',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lab'] as _i4.LabEndpoint).getAllLabTests(session),
        ),
        'updateLabTest': _i1.MethodConnector(
          name: 'updateLabTest',
          params: {
            'test': _i1.ParameterDescription(
              name: 'test',
              type: _i1.getType<_i7.LabTests>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i4.LabEndpoint).updateLabTest(
                session,
                params['test'],
              ),
        ),
        'createLabTest': _i1.MethodConnector(
          name: 'createLabTest',
          params: {
            'test': _i1.ParameterDescription(
              name: 'test',
              type: _i1.getType<_i7.LabTests>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i4.LabEndpoint).createLabTest(
                session,
                params['test'],
              ),
        ),
        'createTestResult': _i1.MethodConnector(
          name: 'createTestResult',
          params: {
            'testId': _i1.ParameterDescription(
              name: 'testId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'patientName': _i1.ParameterDescription(
              name: 'patientName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'mobileNumber': _i1.ParameterDescription(
              name: 'mobileNumber',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'patientType': _i1.ParameterDescription(
              name: 'patientType',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i4.LabEndpoint).createTestResult(
                session,
                testId: params['testId'],
                patientName: params['patientName'],
                mobileNumber: params['mobileNumber'],
                patientType: params['patientType'],
              ),
        ),
        'attachResultFile': _i1.MethodConnector(
          name: 'attachResultFile',
          params: {
            'resultId': _i1.ParameterDescription(
              name: 'resultId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'attachmentPath': _i1.ParameterDescription(
              name: 'attachmentPath',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i4.LabEndpoint).attachResultFile(
                session,
                resultId: params['resultId'],
                attachmentPath: params['attachmentPath'],
              ),
        ),
        'attachResultFileBytes': _i1.MethodConnector(
          name: 'attachResultFileBytes',
          params: {
            'resultId': _i1.ParameterDescription(
              name: 'resultId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'fileName': _i1.ParameterDescription(
              name: 'fileName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'bytes': _i1.ParameterDescription(
              name: 'bytes',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lab'] as _i4.LabEndpoint).attachResultFileBytes(
                    session,
                    resultId: params['resultId'],
                    fileName: params['fileName'],
                    bytes: params['bytes'],
                  ),
        ),
        'sendDummySms': _i1.MethodConnector(
          name: 'sendDummySms',
          params: {
            'mobileNumber': _i1.ParameterDescription(
              name: 'mobileNumber',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'message': _i1.ParameterDescription(
              name: 'message',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i4.LabEndpoint).sendDummySms(
                session,
                mobileNumber: params['mobileNumber'],
                message: params['message'],
              ),
        ),
        'submitResult': _i1.MethodConnector(
          name: 'submitResult',
          params: {
            'resultId': _i1.ParameterDescription(
              name: 'resultId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i4.LabEndpoint).submitResult(
                session,
                resultId: params['resultId'],
              ),
        ),
        'submitResultWithSms': _i1.MethodConnector(
          name: 'submitResultWithSms',
          params: {
            'resultId': _i1.ParameterDescription(
              name: 'resultId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lab'] as _i4.LabEndpoint).submitResultWithSms(
                    session,
                    resultId: params['resultId'],
                  ),
        ),
        'getAllTestResults': _i1.MethodConnector(
          name: 'getAllTestResults',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i4.LabEndpoint)
                  .getAllTestResults(session),
        ),
        'getAttachmentBytes': _i1.MethodConnector(
          name: 'getAttachmentBytes',
          params: {
            'resultId': _i1.ParameterDescription(
              name: 'resultId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['lab'] as _i4.LabEndpoint).getAttachmentBytes(
                    session,
                    params['resultId'],
                  ),
        ),
        'startFileUpload': _i1.MethodConnector(
          name: 'startFileUpload',
          params: {
            'fileName': _i1.ParameterDescription(
              name: 'fileName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i4.LabEndpoint).startFileUpload(
                session,
                params['fileName'],
              ),
        ),
        'uploadFileChunk': _i1.MethodConnector(
          name: 'uploadFileChunk',
          params: {
            'uploadId': _i1.ParameterDescription(
              name: 'uploadId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'bytes': _i1.ParameterDescription(
              name: 'bytes',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i4.LabEndpoint).uploadFileChunk(
                session,
                params['uploadId'],
                params['bytes'],
              ),
        ),
        'finishFileUpload': _i1.MethodConnector(
          name: 'finishFileUpload',
          params: {
            'uploadId': _i1.ParameterDescription(
              name: 'uploadId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'resultId': _i1.ParameterDescription(
              name: 'resultId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['lab'] as _i4.LabEndpoint).finishFileUpload(
                session,
                params['uploadId'],
                params['resultId'],
              ),
        ),
      },
    );
    connectors['patient'] = _i1.EndpointConnector(
      name: 'patient',
      endpoint: endpoints['patient']!,
      methodConnectors: {
        'getPatientProfile': _i1.MethodConnector(
          name: 'getPatientProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i5.PatientEndpoint)
                  .getPatientProfile(
                    session,
                    params['userId'],
                  ),
        ),
        'listTests': _i1.MethodConnector(
          name: 'listTests',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i5.PatientEndpoint)
                  .listTests(session),
        ),
        'getUserRole': _i1.MethodConnector(
          name: 'getUserRole',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['patient'] as _i5.PatientEndpoint).getUserRole(
                    session,
                    params['userId'],
                  ),
        ),
        'updatePatientProfile': _i1.MethodConnector(
          name: 'updatePatientProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'allergies': _i1.ParameterDescription(
              name: 'allergies',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'profilePictureData': _i1.ParameterDescription(
              name: 'profilePictureData',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i5.PatientEndpoint)
                  .updatePatientProfile(
                    session,
                    params['userId'],
                    params['name'],
                    params['phone'],
                    params['allergies'],
                    params['profilePictureData'],
                  ),
        ),
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['greeting'] as _i6.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
  }
}
