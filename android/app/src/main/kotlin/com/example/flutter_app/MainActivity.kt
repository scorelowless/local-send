package com.example.flutter_app

import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.net.wifi.WifiManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val HOTSPOT_CHANNEL = "com.example.flutter_app/hotspot"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HOTSPOT_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "isHotspotEnabled") {
                    try {
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager?
                        var isApEnabled = false
                        if (wifiManager != null) {
                            try {
                                val method = wifiManager.javaClass.getDeclaredMethod("isWifiApEnabled")
                                method.isAccessible = true
                                val invoked = method.invoke(wifiManager) as? Boolean
                                isApEnabled = invoked ?: false
                            } catch (e: Exception) {
                                // Reflection failed or method not available - assume disabled
                                isApEnabled = false
                            }
                        }
                        result.success(isApEnabled)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
