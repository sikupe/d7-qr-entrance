package de.sikupe.qr_entrance

import android.content.Context
import android.net.wifi.WifiEnterpriseConfig
import android.net.wifi.WifiEnterpriseConfig.Phase2
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSuggestion
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.io.ByteArrayInputStream
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate


class MainActivity : FlutterActivity(), MethodCallHandler {
    private val CHANNEL = "de.sikupe.d7/native";

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            if (call.method == "getBrightness") {
                val brightness = getBrightness();
                result.success(brightness);
            } else if (call.method == "setBrightness") {
                val brightness = call.argument<Double>("brightness")!!
                setBrightness(brightness)
                result.success(null)
            } else if (call.method == "configureWifi") {
                val certificate = call.argument<ByteArray>("certificate")!!
                val username = call.argument<String>("username")!!
                val password = call.argument<String>("password")!!
                configureWifi(certificate, username, password)
                result.success(null)
            } else {
                result.notImplemented();
            }
        } catch (e: Throwable) {
            result.error("native-call-failed", e.message, e)
        }
    }

    private fun parseCertificate(certificate: ByteArray): X509Certificate {
        val fact: CertificateFactory = CertificateFactory.getInstance("X.509")
        return fact.generateCertificate(ByteArrayInputStream(certificate)) as X509Certificate
    }

    private fun configureWifi(certificateBytes: ByteArray, username: String, password: String) {
        val certificate = parseCertificate(certificateBytes)

        val enterpriseConfig = WifiEnterpriseConfig()
        enterpriseConfig.anonymousIdentity = "anonymous@d7.whka.de"
        enterpriseConfig.identity = "${username}@d7.whka.de"
        enterpriseConfig.domainSuffixMatch = "auth.d7.whka.de"
        enterpriseConfig.password = password
        enterpriseConfig.eapMethod = WifiEnterpriseConfig.Eap.TTLS
        enterpriseConfig.phase2Method = Phase2.PAP
        enterpriseConfig.caCertificate = certificate

        val wifiSuggestion = WifiNetworkSuggestion.Builder()
                .setSsid("d7-airlan")
                .setWpa2EnterpriseConfig(enterpriseConfig)
                .build()

        val manager = getSystemService(Context.WIFI_SERVICE) as WifiManager
        val result = manager.addNetworkSuggestions(listOf(wifiSuggestion))

        if (result != 0) {
            when (result) {
                WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_INTERNAL -> {
                    throw RuntimeException("Internal Error")
                }
                WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_APP_DISALLOWED -> {
                    throw RuntimeException("App disallowed")
                }
                WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_ADD_DUPLICATE -> {
                    throw RuntimeException("Duplicate network")
                }
                WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_ADD_EXCEEDS_MAX_PER_APP -> {
                    throw RuntimeException("Wifi add exceeds max per app")
                }
                WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_REMOVE_INVALID -> {
                    throw RuntimeException("Remove invalid")
                }
                WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_ADD_NOT_ALLOWED -> {
                    throw RuntimeException("Add not allowed");
                }
                WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_ADD_INVALID -> {
                    throw RuntimeException("Add invalid");
                }
                WifiManager.STATUS_NETWORK_SUGGESTIONS_ERROR_RESTRICTED_BY_ADMIN -> {
                    throw RuntimeException("Restriced by admin");
                }
            }
        }
    }

    private fun setBrightness(brightness: Double) {
        val layoutParams: WindowManager.LayoutParams = window.attributes
        layoutParams.screenBrightness = brightness.toFloat()
        window.attributes = layoutParams
    }

    private fun getBrightness(): Double {
        var result: Float = window.attributes.screenBrightness
        if (result < 0) { // the application is using the system brightness
            try {
                result = Settings.System.getInt(context.contentResolver, Settings.System.SCREEN_BRIGHTNESS) / 255f
            } catch (e: Settings.SettingNotFoundException) {
                result = 1.0f
                e.printStackTrace()
            }
        }
        return result.toDouble()
    }
}
