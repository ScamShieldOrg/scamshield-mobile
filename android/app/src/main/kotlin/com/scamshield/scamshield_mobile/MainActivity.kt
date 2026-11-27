package com.scamshield.scamshield_mobile

import android.app.Activity
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.OpenableColumns
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private var pickerResult: MethodChannel.Result? = null
    private val pickerRequest = 4101

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "scamshield/evidence_ocr")
            .setMethodCallHandler { call, result ->
                if (call.method != "scan") {
                    result.notImplemented()
                } else {
                    val bytes = call.arguments as? ByteArray
                    if (bytes == null) result.error("ocr", "Missing image", null)
                    else scanEvidence(bytes, result)
                }
            }
        val guestSession = getSharedPreferences("guest_session", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "scamshield/guest_session")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "read" -> result.success(guestSession.getString("token", null))
                    "write" -> {
                        guestSession.edit().putString("token", call.arguments as String).apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "scamshield/privacy_reference")
            .setMethodCallHandler { call, result ->
                if (call.method != "open") {
                    result.notImplemented()
                } else {
                    try {
                        startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://csrc.nist.gov/pubs/sp/800/122/final")))
                        result.success(true)
                    } catch (_: android.content.ActivityNotFoundException) {
                        result.success(false)
                    }
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "scamshield/report_evidence")
            .setMethodCallHandler { call, result ->
                when {
                    call.method != "pick" -> result.notImplemented()
                    pickerResult != null -> result.error("busy", "Đang chọn tệp.", null)
                    else -> {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/png", "image/jpeg", "application/pdf"))
                        }
                        try {
                            pickerResult = result
                            startActivityForResult(intent, pickerRequest)
                        } catch (error: Exception) {
                            pickerResult = null
                            result.error("picker", "Không mở được trình chọn tệp.", null)
                        }
                    }
                }
            }
    }

    private fun scanEvidence(bytes: ByteArray, result: MethodChannel.Result) {
        Thread {
            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            if (bitmap == null) {
                runOnUiThread { result.error("ocr", "Invalid image", null) }
                return@Thread
            }
            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            recognizer.process(InputImage.fromBitmap(bitmap, 0))
                .addOnSuccessListener { recognized ->
                    result.success(recognized.textBlocks.flatMap { block ->
                        block.lines.map { line ->
                            line.elements.mapNotNull { word ->
                                word.boundingBox?.let { box ->
                                    listOf(word.text, box.left.toDouble() / bitmap.width,
                                        box.top.toDouble() / bitmap.height, box.right.toDouble() / bitmap.width,
                                        box.bottom.toDouble() / bitmap.height)
                                }
                            }
                        }
                    })
                }
                .addOnFailureListener { result.error("ocr", "Text recognition failed", null) }
                .addOnCompleteListener {
                    recognizer.close()
                    bitmap.recycle()
                }
        }.start()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickerRequest) return
        val result = pickerResult ?: return
        pickerResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        Thread {
            try {
                val name = contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                    ?.use { if (it.moveToFirst()) it.getString(0) else null }
                    ?: throw IllegalArgumentException()
                val bytes = contentResolver.openInputStream(uri)?.use { input ->
                    val output = ByteArrayOutputStream()
                    val chunk = ByteArray(8192)
                    while (true) {
                        val size = input.read(chunk)
                        if (size < 0) break
                        if (output.size() + size > 5 * 1024 * 1024) {
                            throw IllegalArgumentException()
                        }
                        output.write(chunk, 0, size)
                    }
                    output.toByteArray()
                } ?: throw IllegalArgumentException()
                runOnUiThread { result.success(mapOf("name" to name, "bytes" to bytes)) }
            } catch (error: Exception) {
                runOnUiThread { result.error("file", "Không đọc được tệp hoặc tệp vượt quá 5 MB.", null) }
            }
        }.start()
    }
}
