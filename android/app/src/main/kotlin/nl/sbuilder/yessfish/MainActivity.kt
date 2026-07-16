package nl.sbuilder.yessfish

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private val CH = "nl.sbuilder.yessfish/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CH)
    }

    // Widget-klik terwijl de app al draait (warm): home_widget pikt onNewIntent niet
    // betrouwbaar op, dus sturen we de yessfishwidget://-URI zelf door naar Flutter.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val data = intent.data?.toString()
        if (data != null && data.startsWith("yessfishwidget://")) {
            channel?.invokeMethod("route", data)
        }
    }
}
