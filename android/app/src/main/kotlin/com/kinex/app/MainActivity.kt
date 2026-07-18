package com.kinex.app

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val phoneChannel = "kinex/phone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Emergency SOS auto-call: hands-free ACTION_CALL when Unity (The Dasher)
        // detects a fall and Flutter has an emergency contact configured.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, phoneChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "call") {
                    val number = call.argument<String>("number")
                    try {
                        startActivity(
                            Intent(Intent.ACTION_CALL, Uri.parse("tel:" + number))
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CALL_FAILED", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
