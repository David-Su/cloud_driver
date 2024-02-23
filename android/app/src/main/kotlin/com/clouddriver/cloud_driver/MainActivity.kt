package com.clouddriver.cloud_driver

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import android.content.Intent
import android.os.Bundle
import android.net.Uri
class MainActivity : FlutterActivity() {

    private val CHANNEL = "channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val flutterEngine = flutterEngine ?: return
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playVideo" -> {
                    val url = call.argument("url") as String?
                    val mimeType = call.argument("mimeType") as String?
                    val intent = Intent(Intent.ACTION_VIEW).setDataAndType(Uri.parse(url), mimeType)
                    startActivity(intent)
                    result.success(Unit)
                }
            }
        }
    }

}
