package com.maojiu.floating_window_android_example

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.maojiu.floating_window_android_example/navigation"
    private var methodChannel: MethodChannel? = null
    private var pendingParams: Map<String, Any?>? = null
    private val TAG = "MainActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "[onCreate] 检查Intent参数")
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "[onNewIntent] 收到新的Intent")
        setIntent(intent)
        handleIntent(intent)
        sendPendingNavigationEvent()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "[configureFlutterEngine] 初始化FlutterEngine并设置MethodChannel")
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            Log.d(TAG, "[Flutter -> Native] 收到方法调用: ${call.method}")
            result.notImplemented()
        }

        // Flutter引擎准备好，尝试发送待处理的导航参数
        sendPendingNavigationEvent()
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "[onResume] 尝试发送导航事件")

        // 延迟两次发送，确保Flutter UI加载完成
        Handler(Looper.getMainLooper()).postDelayed({
            sendPendingNavigationEvent()
            if (pendingParams != null) {
                Handler(Looper.getMainLooper()).postDelayed({
                    sendPendingNavigationEvent()
                }, 1500)
            }
        }, 2000)
    }

    private fun handleIntent(intent: Intent?) {
        val extras = intent?.extras
        if (extras != null) {
            val params = mutableMapOf<String, Any?>()
            Log.d(TAG, "[handleIntent] 提取参数: ${extras.keySet().joinToString()}")

            for (key in extras.keySet()) {
                val value = extras.get(key)
                Log.d(TAG, "[handleIntent] $key: $value")
                params[key] = value
            }

            if (params.isNotEmpty()) {
                pendingParams = params
                Log.d(TAG, "[handleIntent] 有效参数已保存: $pendingParams")

                // 可选：清理Intent参数，避免重复触发
                intent.replaceExtras(Bundle())
            }
        } else {
            Log.d(TAG, "[handleIntent] 未发现任何Intent参数")
            pendingParams = null
        }
    }

    private fun sendPendingNavigationEvent() {
        val params = pendingParams
        Log.d(TAG, "[sendPendingNavigationEvent] 发送导航事件: $params, methodChannel: $methodChannel")
        if (params != null && methodChannel != null) {
            Log.d(TAG, "[sendPendingNavigationEvent] 发送导航事件: $params")

            methodChannel?.invokeMethod("navigateToPage", params, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    Log.d(TAG, "[sendPendingNavigationEvent] 导航事件发送成功")
                    pendingParams = null
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    Log.e(TAG, "[sendPendingNavigationEvent] 发送失败: $errorCode - $errorMessage")
                }

                override fun notImplemented() {
                    Log.e(TAG, "[sendPendingNavigationEvent] 方法未实现")
                }
            })
        } else {
            Log.d(TAG, "[sendPendingNavigationEvent] 无待处理参数或通道未初始化")
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        Log.d(TAG, "[cleanUpFlutterEngine] 清理MethodChannel")
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }
}