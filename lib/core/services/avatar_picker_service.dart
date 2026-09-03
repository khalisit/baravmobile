import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:path_provider/path_provider.dart';

/// Configures platform image pickers once at app start.
///
/// On Android this enables the system Photo Picker (no broad storage
/// permission). Safe to call multiple times.
void configureImagePicker() {
  if (kIsWeb) return;
  if (!Platform.isAndroid) return;

  final implementation = ImagePickerPlatform.instance;
  if (implementation is ImagePickerAndroid) {
    implementation.useAndroidPhotoPicker = true;
  }
}

enum AvatarPickSource { gallery, camera }

/// Result of a profile-photo pick attempt.
sealed class AvatarPickResult {
  const AvatarPickResult();
}

class AvatarPickSuccess extends AvatarPickResult {
  const AvatarPickSuccess(this.path);
  final String path;
}

class AvatarPickCancelled extends AvatarPickResult {
  const AvatarPickCancelled();
}

class AvatarPickFailure extends AvatarPickResult {
  const AvatarPickFailure(this.code, {this.details});
  final String code;
  final String? details;
}

/// Cross-platform profile avatar picker (Android + iOS).
class AvatarPickerService {
  AvatarPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<AvatarPickResult> pickAndPersist({
    required AvatarPickSource source,
    required String userKey,
  }) async {
    // Let modal sheets / transitions finish so the Activity is ready.
    await Future<void>.delayed(const Duration(milliseconds: 280));

    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: source == AvatarPickSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        requestFullMetadata: false,
      );
    } on PlatformException catch (e) {
      final code = e.code;
      if (code == 'camera_access_denied' ||
          code == 'photo_access_denied' ||
          code == 'channel-error') {
        return AvatarPickFailure(code, details: e.message);
      }
      return AvatarPickFailure(code, details: e.message);
    } catch (e) {
      return AvatarPickFailure('unknown', details: e.toString());
    }

    if (file == null) return const AvatarPickCancelled();

    try {
      final saved = await _persist(file.path, userKey);
      return AvatarPickSuccess(saved);
    } catch (e) {
      return AvatarPickFailure('persist_failed', details: e.toString());
    }
  }

  Future<String> _persist(String sourcePath, String userKey) async {
    final dir = await getApplicationDocumentsDirectory();
    final safe = userKey.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final dest = File('${dir.path}/avatar_$safe.jpg');
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }
}
