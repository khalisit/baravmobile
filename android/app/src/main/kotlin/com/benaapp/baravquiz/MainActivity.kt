package com.benaapp.baravquiz

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "barav_quiz/haptics",
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "prepare" -> result.success(null)
        "quizStart" -> {
          vibrate(longArrayOf(0, 90, 70, 140, 60, 100))
          result.success(null)
        }
        "nextQuestion" -> {
          vibrate(longArrayOf(0, 55, 45, 55))
          result.success(null)
        }
        else -> result.notImplemented()
      }
    }

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "barav_quiz/screen_security",
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "enable" -> {
          runOnUiThread {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
          }
          result.success(null)
        }
        "disable" -> {
          runOnUiThread {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
          }
          result.success(null)
        }
        "isRecording" -> result.success(false)
        else -> result.notImplemented()
      }
    }

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "barav_quiz/device_integrity",
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "check" -> {
          val rooted = isDeviceRooted()
          val emulator = isEmulator()
          result.success(
            mapOf(
              "compromised" to (rooted || emulator),
              "rooted" to rooted,
              "emulator" to emulator,
              "realDevice" to !emulator,
            ),
          )
        }
        else -> result.notImplemented()
      }
    }
  }

  private fun isDeviceRooted(): Boolean {
    val tags = Build.TAGS
    if (tags != null && tags.contains("test-keys")) return true

    val paths = arrayOf(
      "/system/app/Superuser.apk",
      "/system/app/SuperSU.apk",
      "/system/xbin/su",
      "/system/bin/su",
      "/sbin/su",
      "/su/bin/su",
      "/data/local/xbin/su",
      "/data/local/bin/su",
      "/data/local/su",
      "/system/sd/xbin/su",
      "/system/bin/failsafe/su",
      "/system/etc/init.d/99SuperSUDaemon",
      "/dev/com.koushikdutta.superuser.daemon/",
      "/system/xbin/daemonsu",
      "/system/etc/.has_su_daemon",
      "/system/etc/.installed_su_daemon",
      "/system/xbin/busybox",
      "/system/bin/.ext/.su",
      "/system/usr/we-need-root/su-backup",
      "/system/xbin/mu",
      "/magisk",
      "/sbin/.magisk",
      "/data/adb/magisk",
      "/data/adb/modules",
    )
    if (paths.any { File(it).exists() }) return true

    return try {
      Runtime.getRuntime().exec(arrayOf("which", "su")).inputStream.bufferedReader().use {
        it.readLine() != null
      }
    } catch (_: Exception) {
      false
    }
  }

  private fun isEmulator(): Boolean {
    return (Build.FINGERPRINT.startsWith("generic")
      || Build.FINGERPRINT.startsWith("unknown")
      || Build.FINGERPRINT.contains("emulator")
      || Build.FINGERPRINT.contains("vbox")
      || Build.MODEL.contains("google_sdk", ignoreCase = true)
      || Build.MODEL.contains("Emulator", ignoreCase = true)
      || Build.MODEL.contains("Android SDK built for x86", ignoreCase = true)
      || Build.MANUFACTURER.contains("Genymotion", ignoreCase = true)
      || Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")
      || Build.PRODUCT.contains("sdk", ignoreCase = true)
      || Build.PRODUCT.contains("emulator", ignoreCase = true)
      || Build.PRODUCT.contains("simulator", ignoreCase = true)
      || Build.HARDWARE.contains("goldfish", ignoreCase = true)
      || Build.HARDWARE.contains("ranchu", ignoreCase = true)
      || Build.HARDWARE.contains("vbox86", ignoreCase = true)
      || Build.BOARD.contains("nox", ignoreCase = true)
      || Build.BOOTLOADER.contains("nox", ignoreCase = true))
  }

  private fun vibrate(pattern: LongArray) {
    val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
      manager?.defaultVibrator
    } else {
      @Suppress("DEPRECATION")
      getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
    }

    if (vibrator == null || !vibrator.hasVibrator()) return

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
    } else {
      @Suppress("DEPRECATION")
      vibrator.vibrate(pattern, -1)
    }
  }
}
