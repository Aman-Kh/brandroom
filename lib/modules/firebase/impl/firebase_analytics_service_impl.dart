import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

import '../firebase_analytics_service.dart';

class FirebaseAnalyticsServiceImpl extends FirebaseAnalyticsService {
  late FirebaseAnalytics analytics;

  @override
  void init() {
    // analytics = FirebaseAnalytics.instance;
  }

  @override
  List<NavigatorObserver> getMNavigatorObservers() {
    return const <NavigatorObserver>[];
  }
}
