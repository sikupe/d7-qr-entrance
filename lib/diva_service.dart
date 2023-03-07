import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DivaService {
  static const String usernameKey = 'USERNAME';
  static const String passwordKey = 'PASSWORD';
  static const String tokenKey = 'TOKEN';
  static const String codeKey = 'CODE';
  static const String lastRefreshKey = 'LAST_REFRESH';
  static const String d7AirlanName = '"d7-airlan"';

  final storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true));

  setNewCredentials(String username, String password) async {
    final token = await login(username, password);

    await storage.write(key: usernameKey, value: username);
    await storage.write(key: passwordKey, value: password);
    await storage.write(key: tokenKey, value: token);
  }

  Future<String> login(String username, String password) async {
    final response = await http.post(
        Uri.parse('https://start.d7.whka.de/api/public/sso/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'username': username, 'password': password}));

    if (response.statusCode != 200) {
      throw DivaException('Login not successful');
    }

    final result = jsonDecode(response.body);

    final token = result['token'];
    return token;
  }

  Future<bool> hasValidCode() async {
    final lastRefreshString = await storage.read(key: lastRefreshKey);
    if (lastRefreshString == null) {
      return false;
    }

    final lastRefresh = DateTime.parse(lastRefreshString);
    final currentDate = DateTime.now();
    final today5am =
    DateTime(currentDate.year, currentDate.month, currentDate.day, 5);

    return lastRefresh.isAfter(today5am);
  }

  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: tokenKey);

    if (token != null) {
      final jwt = JWT.decode(token);
      final exp = jwt.payload['exp'];
      if (DateTime
          .now()
          .millisecondsSinceEpoch < exp) {
        return true;
      }
    }

    return false;
  }

  Future<bool> hasCredentials() async {
    final username = await storage.read(key: usernameKey);
    final password = await storage.read(key: passwordKey);

    return username != null && password != null;
  }

  logout() async {
    await storage.delete(key: tokenKey);
  }

  logoutAndDeleteCredentials() async {
    await logout();

    await storage.delete(key: usernameKey);
    await storage.delete(key: passwordKey);
  }

  clearCode() async {
    await storage.delete(key: lastRefreshKey);
    await storage.delete(key: codeKey);
  }

  Future<String> retrieveEntranceCode() async {
    if (!(await isLoggedIn())) {
      if (await hasCredentials()) {
        await loginBasedOnSavedCredentials();
      } else {
        throw DivaException('User not logged in!');
      }
    }

    final token = await storage.read(key: tokenKey);

    final response = await http.post(
        Uri.parse('https://diva.d7.whka.de/api/private/resident/get-door-code'),
        headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode != 200) {
      throw DivaException('Could not retrieve entrance code');
    }

    final result = jsonDecode(response.body);

    final code = result['code'];

    await storage.write(key: codeKey, value: code);
    await storage.write(
        key: lastRefreshKey, value: DateTime.now().toIso8601String());

    return code;
  }

  Future<String> retrieveOrGetEntranceCode() async {
    if (await hasValidCode()) {
      return (await storage.read(key: codeKey))!;
    }

    return await retrieveEntranceCode();
  }

  loginBasedOnSavedCredentials() async {
    final username = await storage.read(key: usernameKey);
    final password = await storage.read(key: passwordKey);

    if (username == null || password == null) {
      throw DivaException('User not logged in!');
    }

    await login(username, password);
  }

  get username async {
    final username = await storage.read(key: usernameKey);

    return username;
  }

  get password async {
    final password = await storage.read(key: passwordKey);

    return password;
  }
}

class DivaException implements Exception {
  final String message;

  DivaException(this.message);

  @override
  String toString() {
    return message;
  }
}
