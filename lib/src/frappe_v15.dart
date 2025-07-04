import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:frappe_dart/frappe_dart.dart';
import 'package:frappe_dart/src/frappe_api.dart';
import 'package:frappe_dart/src/models/error_response.dart';
import 'package:frappe_dart/src/models/report_view_request.dart';
import 'package:frappe_dart/src/models/report_view_response.dart';
import 'package:frappe_dart/src/models/savedocs_response/savedocs_response.dart';
import 'package:frappe_dart/src/models/send_email_response.dart';

/// A class that implements the Frappe API for version 15.
class FrappeV15 implements FrappeApi {
  /// Creates a new instance of [FrappeV15].
  FrappeV15({required String baseUrl, Dio? dio, String? cookie})
    : _baseUrl = baseUrl,
      _cookie = cookie,
      _dio = dio ?? Dio();

  String _baseUrl;
  String? _cookie;
  final Dio _dio;

  /// The base URL of the Frappe instance.
  String get baseUrl => _baseUrl;

  /// The cookie used for authentication.
  String? get cookie => _cookie;

  set baseUrl(String newBaseUrl) {
    _baseUrl = newBaseUrl;
  }

  set cookie(String? newCookie) {
    _cookie = newCookie;
  }

  ///getter of dio
  Dio get dio => _dio;

  @override
  Future<LoginResponse> login(LoginRequest loginRequest) async {
    final url = '$_baseUrl/api/method/login';
    try {
      // Sending the POST request
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: loginRequest.toMap(),
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      // Checking the response status
      if (response.statusCode == HttpStatus.ok) {
        final responseBody = response.data!;

        final Map<String, dynamic> headers = response.headers.map;
        if (headers['set-cookie'] != null &&
            headers['set-cookie']![3] != null) {
          responseBody['user_id'] = headers['set-cookie']![3]
              .split(';')[0]
              .split('=')[1];
          responseBody['cookie'] = headers['set-cookie']![0];
        }

        // Returning the parsed response
        return LoginResponse.fromJson(responseBody);
      } else {
        throw Exception(
          '''Failed to login. Response Status: ${response.statusCode}, Body: ${response.data}''',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('An unknown error occurred during login: $e');
    }
  }

  @override
  Future<LogoutResponse> logout() async {
    final url = '$_baseUrl/api/method/logout';
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(headers: {if (cookie != null) 'Cookie': cookie}),
      );

      if (response.statusCode == HttpStatus.ok) {
        return LogoutResponse.fromMap(response.data!);
      } else {
        throw Exception('Failed to logout. Status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('An unknown error occurred during logout: $e');
    }
  }

  // Helper method to extract user ID from cookies
  String? _extractUserIdFromCookies(String cookies) {
    final cookieParts = cookies.split(';');
    for (final part in cookieParts) {
      if (part.trim().startsWith('SameSite=Lax,user_id=')) {
        return Uri.decodeComponent(
          part.trim().substring('SameSite=Lax,user_id='.length),
        );
      }
    }
    return null;
  }

  @override
  Future<DeskSidebarItemsResponse> getDeskSideBarItems() async {
    final url =
        '$_baseUrl/api/method/frappe.desk.desktop.get_workspace_sidebar_items';
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
      );

      if (response.statusCode == HttpStatus.ok) {
        return DeskSidebarItemsResponse.fromMap(response.data!);
      } else {
        throw Exception(
          '''Failed to get desk sidebar items. Response Status: ${response.statusCode}''',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception(
        '''An unknown error occurred while retrieving desk sidebar items: $e''',
      );
    }
  }

  @override
  Future<DesktopPageResponse> getDesktopPage(
    DesktopPageRequest deskPageRequest,
  ) async {
    final url = '$_baseUrl/api/method/frappe.desk.desktop.get_desktop_page';
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
        data: {'page': deskPageRequest.toJson()},
      );

      if (response.statusCode == HttpStatus.ok) {
        print(json.encode(response.data));
        return DesktopPageResponse.fromMap(response.data!);
      } else {
        throw Exception(
          'Failed to get desk page. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception(
        '''An unknown error occurred while retrieving desk page: $e''',
      );
    }
  }

  @override
  Future<NumberCardResponse> getNumberCard(String name) async {
    final url =
        '$_baseUrl/api/method/frappe.desk.doctype.number_card.number_card.get_result';
    try {
      final numberCardDoc = await getdoc('Number Card', name);

      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
        data: {
          'doc': numberCardDoc.docs?[0].toJson(),
          'filters': numberCardDoc.docs?[0].dynamicFiltersJson ?? '',
        },
      );

      if (response.statusCode == HttpStatus.ok) {
        return NumberCardResponse.fromMap(response.data!);
      } else {
        throw Exception(
          '''Failed to get desk number card. Response Status: ${response.statusCode}''',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception(
        '''An unknown error occurred while retrieving number card: $e''',
      );
    }
  }

  @override
  Future<NumberCardPercentageDifferenceResponse>
  getNumberCardPercentageDifference(String name, String result) async {
    final url =
        '$_baseUrl/api/method/frappe.desk.doctype.number_card.number_card.get_percentage_difference';
    try {
      final numberCardDoc = await getdoc('Number Card', name);

      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
        data: {
          'doc': numberCardDoc.docs?[0].toJson(),
          'filters': numberCardDoc.docs?[0].dynamicFiltersJson ?? '',
          'result': result,
        },
      );

      if (response.statusCode == HttpStatus.ok) {
        return NumberCardPercentageDifferenceResponse.fromMap(response.data!);
      } else {
        throw Exception(
          '''Failed to get desk number card. Response Status: ${response.statusCode}''',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception(
        '''An unknown error occurred while retrieving number card: $e''',
      );
    }
  }

  @override
  Future<GetDoctypeResponse> getDoctype(String doctype) async {
    final url =
        '$_baseUrl/api/method/frappe.desk.form.load.getdoctype?doctype=$doctype&with_parent=1';
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
        data: {'doctype': doctype},
      );

      if (response.statusCode == HttpStatus.ok) {
        return GetDoctypeResponse.fromMap(response.data!);
      } else {
        throw Exception(
          'Failed to get doc. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('''An unknown error occurred while retrieving doc: $e''');
    }
  }

  @override
  Future<Map<String, dynamic>> getList({
    required String doctype,
    List<String>? fields,
    int? limitStart,
    int? limitPageLength,
    String? orderBy,
    String? parent,
    Map<String, dynamic>? filters,
    String? groupBy,
    bool? debug,
    bool? asDict,
    Map<String, dynamic>? orFilters,
  }) async {
    final url = '$_baseUrl/api/method/frappe.client.get_list';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
        data: {
          'doctype': doctype,
          if (fields != null) 'fields': jsonEncode(fields),
          if (filters != null) 'filters': jsonEncode(filters),
          if (groupBy != null) 'group_by': groupBy,
          if (orderBy != null) 'order_by': orderBy,
          if (limitStart != null) 'limit_start': limitStart.toString(),
          if (limitPageLength != null)
            'limit_page_length': limitPageLength.toString(),
          if (parent != null) 'parent': parent,
          if (debug != null) 'debug': debug.toString(),
          if (asDict != null) 'as_dict': asDict.toString(),
          if (orFilters != null) 'or_filters': jsonEncode(orFilters),
        },
      );

      if (response.statusCode == HttpStatus.ok) {
        return response.data ?? {};
      } else {
        throw Exception(
          'Failed to get doc. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('''An unknown error occurred while retrieving doc: $e''');
    }
  }

  @override
  Future<GetDocResponse> getdoc(String doctype, String name) async {
    final url = '$_baseUrl/api/method/frappe.desk.form.load.getdoc';
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
        data: {'doctype': doctype, 'name': name},
      );

      if (response.statusCode == HttpStatus.ok) {
        return GetDocResponse.fromMap(response.data!);
      } else {
        throw Exception(
          'Failed to get doc. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('''An unknown error occurred while retrieving doc: $e''');
    }
  }

  @override
  Future<GetCountResponse> getCount(GetCountRequest getCountRequest) async {
    final url =
        '$_baseUrl/api/method/frappe.client.get_count?doctype=${getCountRequest.doctype}';
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
        data: getCountRequest.toMap(),
      );

      if (response.statusCode == HttpStatus.ok) {
        return GetCountResponse.fromMap(response.data!);
      } else {
        throw Exception(
          'Failed to get doc. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('''An unknown error occurred while retrieving doc: $e''');
    }
  }

  @override
  Future<SavedocsReponse<T>> savedocs<T>({
    required T document,
    required String action,
    required String Function() toJson,
    required T Function(Map<String, dynamic>) fromMap,
  }) async {
    final url = '$_baseUrl/api/method/frappe.desk.form.save.savedocs';

    try {
      final response = await dio.post<Map<String, dynamic>>(
        url,
        data: {'doc': toJson(), 'action': action},
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
      );

      if (response.statusCode == HttpStatus.ok) {
        return SavedocsReponse.fromMap<T>(response.data!, fromMap);
      } else {
        throw Exception('Failed to save doc. Status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('An unknown error occurred while saving doc: $e');
    }
  }

  @override
  Future<SearchLinkResponse> searchLink(
    SearchLinkRequest searchLinkRequest,
  ) async {
    final url = '$_baseUrl/api/method/frappe.desk.search.search_link';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(headers: {if (cookie != null) 'Cookie': cookie}),
        data: searchLinkRequest.toMap(),
      );

      if (response.statusCode == HttpStatus.ok) {
        return SearchLinkResponse.fromMap(response.data!);
      } else {
        throw Exception(
          'Failed to search link. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('''An unknown error occurred while searching link: $e''');
    }
  }

  @override
  Future<Map<String, dynamic>> validateLink(
    ValidateLinkRequest validateLinkRequest,
  ) async {
    final url = '$_baseUrl/api/method/frappe.client.validate_link';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
        data: validateLinkRequest.toMap(),
      );

      if (response.statusCode == HttpStatus.ok) {
        return response.data!;
      } else {
        throw Exception(
          'Failed to search link. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception(
        '''An unknown error occurred while searching for link: $e''',
      );
    }
  }

  @override
  Future<SystemSettingsResponse> getSystemSettings() async {
    final url =
        '$_baseUrl/api/method/frappe.core.doctype.system_settings.system_settings.load';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(headers: {if (cookie != null) 'Cookie': cookie}),
      );

      if (response.statusCode == HttpStatus.ok) {
        return SystemSettingsResponse.fromMap(response.data!);
      } else {
        throw Exception(
          '''Failed to get system settings. Response Status: ${response.statusCode}''',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception(
        '''An unknown error occurred while retrieving system settings: $e''',
      );
    }
  }

  @override
  Future<GetVersionsResponse> getVersions() async {
    final url = '$_baseUrl/api/method/frappe.utils.change_log.get_versions';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(headers: {if (cookie != null) 'Cookie': cookie}),
      );

      if (response.statusCode == HttpStatus.ok) {
        return GetVersionsResponse.fromMap(response.data!);
      } else {
        throw Exception(
          'Failed to get versions. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception(
        '''An unknown error occurred while retrieving versions: $e''',
      );
    }
  }

  @override
  Future<LoggedUserResponse> getLoggerUser() async {
    final url = '$_baseUrl/api/method/frappe.auth.get_logged_user';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(headers: {if (cookie != null) 'Cookie': cookie}),
      );

      if (response.statusCode == HttpStatus.ok) {
        return LoggedUserResponse.fromMap(response.data!);
      } else {
        throw Exception(
          'Failed to get logged user. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception(
        '''An unknown error occurred while retrieving logged user: $e''',
      );
    }
  }

  @override
  Future<AppsResponse> getApps() async {
    final url = '$_baseUrl/api/method/frappe.apps.get_apps';
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(headers: {if (cookie != null) 'Cookie': cookie}),
      );

      if (response.statusCode == HttpStatus.ok) {
        return AppsResponse.fromMap(response.data!);
      } else {
        throw Exception(
          'Failed to get apps. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception(
        '''An unknown error occurred while retrieving apps: $e''',
      );
    }
  }

  @override
  Future<UserInfoResponse> getUserInfo() async {
    final url = '$_baseUrl/api/method/frappe.realtime.get_user_info';
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(headers: {if (cookie != null) 'Cookie': cookie}),
      );

      if (response.statusCode == HttpStatus.ok) {
        return UserInfoResponse.fromMap(response.data!);
      } else {
        throw Exception(
          'Failed to get apps. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception(
        '''An unknown error occurred while retrieving apps: $e''',
      );
    }
  }

  @override
  Future<PingResponse> ping() async {
    final url = '$_baseUrl/api/method/ping';
    try {
      final response = await _dio.post<Map<String, dynamic>>(url);

      if (response.statusCode == HttpStatus.ok) {
        return PingResponse.fromMap(response.data!);
      } else {
        throw Exception(
          'Failed to ping. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('''An unknown error occurred while pinging: $e''');
    }
  }

  @override
  Future<Map<String, dynamic>> save(Map<String, dynamic> doc) async {
    final url = '$_baseUrl/api/method/frappe.client.save';
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
        data: {'doc': json.encode(doc)},
      );

      if (response.statusCode == HttpStatus.ok) {
        return response.data ?? {};
      } else {
        throw Exception(
          'Failed to save doc. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('''An unknown error occurred while saving doc: $e''');
    }
  }

  @override
  Future<Map<String, dynamic>> deleteDoc(
    DeleteDocRequest deleteDocRequest,
  ) async {
    final url = '$_baseUrl/api/method/frappe.client.delete';
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
        data: deleteDocRequest.toMap(),
      );

      if (response.statusCode == HttpStatus.ok) {
        return response.data ?? {};
      } else {
        throw Exception(
          'Failed to delete doc. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('''An unknown error occurred while deleting doc: $e''');
    }
  }

  @override
  Future<Map<String, dynamic>> getValue({
    required String doctype,
    required String fieldname,
  }) async {
    final url =
        '$_baseUrl/api/method/frappe.client.get_value?doctype=$doctype&fieldname=$fieldname';

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(headers: {if (cookie != null) 'Cookie': cookie}),
      );

      if (response.statusCode == HttpStatus.ok) {
        return response.data ?? {};
      } else {
        throw Exception(
          'Failed to get value. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('''An unknown error occurred while getting value: $e''');
    }
  }

  @override
  Future<Map<String, dynamic>> get(GetRequest getRequest) async {
    final url = '$_baseUrl/api/method/frappe.client.get';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            if (cookie != null) 'Cookie': cookie,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: getRequest.toMap(),
      );

      if (response.statusCode == HttpStatus.ok) {
        return response.data ?? {};
      } else {
        throw Exception(
          'Failed to get value. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('''An unknown error occurred while getting value: $e''');
    }
  }

  @override
  Future<Map<String, dynamic>> call({
    required String method,
    required String type,
    Map<String, dynamic>? args,
    String? url,
  }) async {
    final apiUrl = url ?? '$_baseUrl/api/method/$method';
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        apiUrl,
        options: Options(
          method: type,
          headers: {if (cookie != null) 'Cookie': cookie},
        ),
        data: args,
      );

      if (response.statusCode == HttpStatus.ok) {
        return response.data ?? {};
      } else {
        throw Exception(
          'Failed to call. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('''An unknown error occurred while calling: $e''');
    }
  }

  @override
  Future<Map<String, dynamic>> getDashboardChart(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/api/method/frappe.desk.doctype.dashboard_chart.dashboard_chart.get',
        data: payload,
        options: Options(headers: {if (cookie != null) 'Cookie': cookie}),
      );

      if (response.statusCode == HttpStatus.ok) {
        return response.data!;
      } else {
        throw Exception(
          'Failed to get dashboard chart. Response Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception(
        '''An unknown error occurred while retrieving dashboard chart: $e''',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getReportRun(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '$baseUrl/api/method/frappe.desk.query_report.run',
        data: payload,
        options: Options(headers: {if (cookie != null) 'Cookie': cookie}),
      );

      if (response.statusCode == HttpStatus.ok) {
        return response.data!;
      } else {
        throw Exception('Failed to get report run');
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('''An unknown error occurred while calling: $e''');
    }
  }

  @override
  Future<SendEmailResponse> sendEmail({
    required String recipients,
    required String subject,
    required String content,
    required String doctype,
    required String name,
    required String sendEmail,
    required String printFormat,
    required String senderFullName,
    required String lang,
  }) async {
    final url =
        '$baseUrl/api/method/frappe.core.doctype.communication.email.make';

    try {
      final response = await dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
        data: {
          'recipients': recipients,
          'subject': subject,
          'content': content,
          'doctype': doctype,
          'name': name,
          'send_email': sendEmail,
          'print_format': printFormat,
          'sender_full_name': senderFullName,
          '_lang': lang,
        },
      );

      if (response.statusCode == HttpStatus.ok) {
        return SendEmailResponse.fromMap(response.data!);
      } else {
        final res = ErrorResponse.fromMap(response.data!);
        throw Exception(
          'Failed to send email. HTTP Status: ${response.statusCode}, data: ${res.exception}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e, stack) {
      throw Exception('An error occurred while sending email: $e');
    }
  }

  Future<ReportViewResponse> getReportView(
    ReportViewRequest reportViewRequest,
  ) async {
    final url = '$baseUrl/api/method/frappe.desk.reportview.get_list';

    try {
      final response = await dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
        data: jsonEncode(reportViewRequest.toMap()),
      );

      if (response.statusCode == 200) {
        // Decode the response body into a Map and explicitly cast it
        return ReportViewResponse.fromJson(response.data!);
      } else {
        throw Exception(
          'Failed to get list. HTTP Status: ${response.statusCode}, Response: ${response.data!}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e, stack) {
      throw Exception('An error occurred while fetching the list: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> mapDocs({
    required List<String> sourceName,
    required Map<String, dynamic> targetDoc,
    required String method,
  }) async {
    try {
      final payload =
          'method=$method'
          '&source_names=${Uri.encodeComponent(jsonEncode(sourceName))}'
          '&target_doc=${Uri.encodeComponent(json.encode(targetDoc))}';

      final response = await dio.post<Map<String, dynamic>>(
        '$baseUrl/api/method/frappe.model.mapper.map_docs',
        data: payload,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {if (cookie != null) 'Cookie': cookie},
        ),
      );

      if (response.statusCode == HttpStatus.ok) {
        return response.data!;
      } else {
        print('Server error: ${response.statusCode}');
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> switchTheme({required String theme}) async {
    final url =
        '$baseUrl/api/method/frappe.core.doctype.user.user.switch_theme';

    try {
      final payload = {'theme': theme};
      final response = await dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
        data: payload,
      );

      if (response.statusCode == HttpStatus.ok) {
        return response.data!;
      } else {
        throw Exception(
          'Failed to switch theme. HTTP Status: ${response.statusCode}, data: ${response.data!}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('An error occurred while switching theme: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> searchWidget({
    required String doctype,
    required String txt,
    required String query,
    required Map<String, dynamic> filters,
    List<String>? filterFields,
    String? searchField,
    String start = '0',
    String pageLength = '10',
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '$baseUrl/api/method/frappe.desk.search.search_widget',
        queryParameters: {
          'doctype': doctype,
          'txt': txt,
          'filters': jsonEncode(filters),
          if (filterFields != null) 'filter_fields': jsonEncode(filterFields),
          'page_length': '25',
          'as_dict': '1',
          if (query.isNotEmpty) 'query': query,
          if (searchField != null) 'search_field': searchField,
          if (start != '0') 'start': start,
          if (pageLength != '10') 'page_length': pageLength,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
      );

      if (response.statusCode == HttpStatus.ok) {
        return response.data!;
      } else {
        throw Exception('''An unknown error occurred while calling''');
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('''An unknown error occurred while calling: $e''');
    }
  }

  @override
  Future<Map<String, dynamic>> runDocMethod({
    required Map<String, dynamic> data,
    required String method,
  }) async {
    final url = '$baseUrl/api/method/run_doc_method';

    try {
      final response = await dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            if (cookie != null) 'Cookie': cookie,
          },
        ),
        data: {'docs': json.encode(data), 'method': method},
      );

      if (response.statusCode == HttpStatus.ok) {
        return response.data!;
      } else {
        throw Exception(
          'Failed to run doc method. HTTP Status: ${response.statusCode}, data: ${response.data!}',
        );
      }
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('An error occurred while running doc method: $e');
    }
  }
}
