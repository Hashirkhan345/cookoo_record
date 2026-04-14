package com.cookoo.cookoorecord

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "bloop/video_transfer"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "exportRecordingToDownloads" -> exportRecordingToDownloads(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun exportRecordingToDownloads(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        val fileName = call.argument<String>("fileName")
        val mimeType = call.argument<String>("mimeType") ?: "video/mp4"

        if (path.isNullOrBlank() || fileName.isNullOrBlank()) {
            result.error("invalid_args", "Recording path or file name is missing.", null)
            return
        }

        val sourceFile = File(path)
        if (!sourceFile.exists()) {
            result.error("missing_file", "Recording file does not exist.", null)
            return
        }

        try {
            val savedLabel = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                exportWithMediaStore(sourceFile, fileName, mimeType)
            } else {
                exportToLegacyDownloads(sourceFile, fileName)
            }
            result.success(savedLabel)
        } catch (error: Exception) {
            result.error("export_failed", error.message, null)
        }
    }

    private fun exportWithMediaStore(
        sourceFile: File,
        fileName: String,
        mimeType: String
    ): String {
        val resolver = applicationContext.contentResolver
        val relativePath = Environment.DIRECTORY_DOWNLOADS + "/bloop"
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, mimeType)
            put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }

        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Unable to create a Downloads entry.")

        resolver.openOutputStream(uri)?.use { outputStream ->
            FileInputStream(sourceFile).use { inputStream ->
                inputStream.copyTo(outputStream)
            }
        } ?: throw IllegalStateException("Unable to open Downloads output stream.")

        val finalizeValues = ContentValues().apply {
            put(MediaStore.Downloads.IS_PENDING, 0)
        }
        resolver.update(uri, finalizeValues, null, null)

        return "Recording exported to Downloads/bloop/$fileName."
    }

    private fun exportToLegacyDownloads(sourceFile: File, fileName: String): String {
        val downloadsDirectory =
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val targetDirectory = File(downloadsDirectory, "bloop")
        if (!targetDirectory.exists()) {
            targetDirectory.mkdirs()
        }

        val targetFile = File(targetDirectory, fileName)
        FileInputStream(sourceFile).use { inputStream ->
            FileOutputStream(targetFile).use { outputStream ->
                inputStream.copyTo(outputStream)
            }
        }

        return "Recording exported to ${targetFile.absolutePath}."
    }
}
