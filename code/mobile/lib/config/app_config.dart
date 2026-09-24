import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static const _envUrl = String.fromEnvironment('API_BASE_URL');
  static const _envWorkerUrl = String.fromEnvironment('WORKER_BASE_URL');
  static const _envChatUrl = String.fromEnvironment('CHAT_BASE_URL');
  static const _mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
  );
  static const _defaultMapboxStyleUriLight =
      'mapbox://styles/devmigueldiniz/cmosyokj6001f01s41yiccnxd';
  static const _defaultMapboxStyleUriDark =
      'mapbox://styles/devmigueldiniz/cmosxavkh001a01s55hujggx9';

  static String get apiBaseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:3001';
  }

  static String get workerBaseUrl {
    if (_envWorkerUrl.isNotEmpty) return _envWorkerUrl;
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:3002';
  }

  static String get chatBaseUrl {
    if (_envChatUrl.isNotEmpty) return _envChatUrl;
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:3003';
  }

  static String get mapboxAccessToken {
    if (_mapboxAccessToken.isNotEmpty) return _mapboxAccessToken;
    return dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  }

  static bool get hasMapboxAccessToken => mapboxAccessToken.isNotEmpty;

  static String get mapboxStyleUriLight =>
      dotenv.env['MAPBOX_STYLE_URI_LIGHT'] ?? _defaultMapboxStyleUriLight;

  static String get mapboxStyleUriDark =>
      dotenv.env['MAPBOX_STYLE_URI_DARK'] ?? _defaultMapboxStyleUriDark;

  static String mapboxStyleUriForBrightness(bool isDark) {
    return isDark ? mapboxStyleUriDark : mapboxStyleUriLight;
  }
}
