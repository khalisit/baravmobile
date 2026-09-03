import 'package:flutter/material.dart';

import '../routing/transitions.dart';
import '../services/device_integrity_service.dart';
import '../../features/security/compromised_device_screen.dart';

/// پشکنینی پاراستنی ئامێر پێش کردنەوەی کویزی زیندوو.
Future<bool> guardLiveQuizAccess(BuildContext context) async {
  final safe = await DeviceIntegrityService.instance.ensureSafe();
  if (safe) return true;
  if (!context.mounted) return false;

  Navigator.of(context).pushAndRemoveUntil(
    fadeRoute(const CompromisedDeviceScreen()),
    (_) => false,
  );
  return false;
}
