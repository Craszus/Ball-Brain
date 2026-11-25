// Vi bruker FCM-token (getToken), slik serveren sender med feltet `token` – samme som i Logica.
// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud.dart';

/// Brukes til å vise varsler som kommer mens appen er åpen.
final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

const pushEnabledKey = 'settings.push';

/// Push-varsler (Firebase Cloud Messaging), samme oppsett som i Logica. Virker først når
/// android/app/google-services.json finnes (se docs/PUSH.md); uten den gjør alt her ingenting.
class Push {
  static bool _ready = false;
  static StreamSubscription<String>? _refresh;
  static StreamSubscription<RemoteMessage>? _foreground;

  static Future<bool> isEnabled() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(pushEnabledKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> _init() async {
    if (_ready) return true;
    try {
      if (!Platform.isAndroid) return false;
      await Firebase.initializeApp();
      _ready = true;
    } catch (_) {}
    return _ready;
  }

  static Future<void> _register(String token) async {
    try {
      await Cloud.ensureSignedIn();
      await Cloud.client?.rpc('register_push_token', params: {'p_token': token});
    } catch (_) {}
  }

  /// Ber om varseltillatelse og lagrer enhetens varsel-id på serveren, hvis varsler er på.
  static Future<void> start() async {
    if (!await isEnabled() || !await _init()) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token != null) await _register(token);
      _refresh ??= messaging.onTokenRefresh.listen(_register);
      _foreground ??= FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n == null) return;
        appMessengerKey.currentState
            ?.showSnackBar(SnackBar(content: Text('${n.title ?? ''}\n${n.body ?? ''}')));
      });
    } catch (_) {}
  }

  /// Sletter varsel-id-en på serveren (når varsler slås av eller data slettes).
  static Future<void> stop() async {
    try {
      await Cloud.client?.rpc('unregister_push_token');
    } catch (_) {}
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  static Future<void> setEnabled(bool on) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(pushEnabledKey, on);
    } catch (_) {}
    if (on) {
      await start();
    } else {
      await stop();
    }
  }
}
