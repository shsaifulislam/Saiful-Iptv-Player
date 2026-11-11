import 'package:flutter/foundation.dart';

/// Supported Cast Protocol types
enum CastProtocol {
  chromecast,
  dlna,
  airplay,
}

/// Remote Cast Device target
class CastDevice {
  final String id;
  final String name;
  final CastProtocol protocol;
  final String ipAddress;

  const CastDevice({
    required this.id,
    required this.name,
    required this.protocol,
    required this.ipAddress,
  });
}

/// Central Service for Casting, Parental Controls, App Lock, and Cloud Sync
class AdvancedFeaturesService extends ChangeNotifier {
  static final AdvancedFeaturesService instance = AdvancedFeaturesService._internal();

  AdvancedFeaturesService._internal();

  // Casting state
  CastDevice? _connectedCastDevice;
  bool _isCasting = false;

  // Parental Control state
  bool _isParentalControlEnabled = false;
  String _parentalPin = '0000';
  String _maxAllowedAgeRating = 'PG-13'; // G, PG, PG-13, R, NC-17

  // App Lock state
  bool _isAppLockEnabled = false;
  String _appLockPin = '1234';
  bool _isAppUnlocked = false;

  // In-App Notifications
  final List<String> _notifications = [];

  // Getters
  CastDevice? get connectedCastDevice => _connectedCastDevice;
  bool get isCasting => _isCasting;
  bool get isParentalControlEnabled => _isParentalControlEnabled;
  String get maxAllowedAgeRating => _maxAllowedAgeRating;
  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isAppUnlocked => _isAppUnlocked;
  List<String> get notifications => List.unmodifiable(_notifications);

  static const List<String> ageHierarchy = ['G', 'PG', 'PG-13', 'R', 'NC-17'];

  /// Connect to Cast device (Chromecast / DLNA)
  void connectCastDevice(CastDevice device) {
    _connectedCastDevice = device;
    _isCasting = true;
    _addNotification('Casting started on ${device.name} (${device.protocol.name.toUpperCase()})');
    notifyListeners();
  }

  /// Disconnect Cast device
  void disconnectCast() {
    if (_connectedCastDevice != null) {
      _addNotification('Disconnected from ${_connectedCastDevice!.name}');
    }
    _connectedCastDevice = null;
    _isCasting = false;
    notifyListeners();
  }

  /// Verify Parental PIN
  bool verifyParentalPin(String inputPin) {
    return _parentalPin == inputPin;
  }

  /// Configure Parental Controls
  void setParentalControl({required bool enabled, String? newPin, String? maxRating}) {
    _isParentalControlEnabled = enabled;
    if (newPin != null && newPin.length == 4) _parentalPin = newPin;
    if (maxRating != null) _maxAllowedAgeRating = maxRating;
    _addNotification('Parental control settings updated: $maxAllowedAgeRating');
    notifyListeners();
  }

  /// Check whether content is allowed under parental control
  bool isContentAllowed(String contentRating) {
    if (!_isParentalControlEnabled) return true;
    final maxIdx = ageHierarchy.indexOf(_maxAllowedAgeRating);
    final targetIdx = ageHierarchy.indexOf(contentRating);
    if (maxIdx == -1 || targetIdx == -1) return true;
    return targetIdx <= maxIdx;
  }

  /// Verify App Lock PIN
  bool unlockApp(String pin) {
    if (pin == _appLockPin) {
      _isAppUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Lock app
  void lockApp() {
    _isAppUnlocked = false;
    notifyListeners();
  }

  /// Toggle App Lock
  void setAppLock({required bool enabled, String? newPin}) {
    _isAppLockEnabled = enabled;
    if (newPin != null && newPin.length == 4) _appLockPin = newPin;
    notifyListeners();
  }

  /// Safe Conflict Resolution algorithm for Cloud Sync:
  /// Compares local vs remote records by timestamp; latest timestamp wins.
  static Map<String, dynamic> resolveRecordConflict(
    Map<String, dynamic> localRecord,
    Map<String, dynamic> remoteRecord,
  ) {
    final localTime = DateTime.tryParse(localRecord['updated_at']?.toString() ?? '') ?? DateTime(1970);
    final remoteTime = DateTime.tryParse(remoteRecord['updated_at']?.toString() ?? '') ?? DateTime(1970);

    if (remoteTime.isAfter(localTime)) {
      return Map<String, dynamic>.from(remoteRecord);
    } else {
      return Map<String, dynamic>.from(localRecord);
    }
  }

  void _addNotification(String msg) {
    _notifications.insert(0, '[${DateTime.now().toLocal().toString().substring(11, 19)}] $msg');
    if (_notifications.length > 50) {
      _notifications.removeLast();
    }
  }
}

