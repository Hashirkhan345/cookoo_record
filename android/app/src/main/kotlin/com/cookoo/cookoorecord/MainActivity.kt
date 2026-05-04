package com.cookoo.cookoorecord

import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.DisplayMetrics
import android.view.Surface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    companion object {
        private const val screenCaptureRequestCode = 4817
        private const val maxCaptureShortSide = 720
        private const val maxCaptureLongSide = 1280
    }

    private val videoTransferChannelName = "Aks/video_transfer"
    private val nativeDisplayRecorderChannelName = "Aks/native_display_recorder"

    private var pendingDisplayCaptureResult: MethodChannel.Result? = null
    private var preparedDisplayCaptureResultCode: Int? = null
    private var preparedDisplayCaptureData: Intent? = null

    private var mediaProjectionManager: MediaProjectionManager? = null
    private var mediaProjection: MediaProjection? = null
    private var mediaProjectionCallback: MediaProjection.Callback? = null
    private var mediaRecorder: MediaRecorder? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var activeDisplayCaptureFile: File? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            videoTransferChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "exportRecordingToDownloads" -> exportRecordingToDownloads(call, result)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            nativeDisplayRecorderChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "prepareDisplayCapture" -> prepareDisplayCapture(result)
                "startPreparedDisplayCapture" -> startPreparedDisplayCapture(result)
                "cancelPreparedDisplayCapture" -> cancelPreparedDisplayCapture(result)
                "pauseDisplayCapture" -> pauseDisplayCapture(result)
                "resumeDisplayCapture" -> resumeDisplayCapture(result)
                "stopDisplayCapture" -> stopDisplayCapture(result)
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

    private fun prepareDisplayCapture(result: MethodChannel.Result) {
        if (pendingDisplayCaptureResult != null) {
            result.error(
                "screen_capture_busy",
                "A screen recording permission request is already in progress.",
                null
            )
            return
        }

        if (isDisplayCaptureActive()) {
            result.success(true)
            return
        }

        val projectionManager =
            getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
        if (projectionManager == null) {
            result.error(
                "display_capture_not_supported",
                "Screen recording is not supported on this device.",
                null
            )
            return
        }

        mediaProjectionManager = projectionManager
        pendingDisplayCaptureResult = result
        @Suppress("DEPRECATION")
        startActivityForResult(
            projectionManager.createScreenCaptureIntent(),
            screenCaptureRequestCode
        )
    }

    private fun startPreparedDisplayCapture(result: MethodChannel.Result) {
        if (isDisplayCaptureActive()) {
            result.success(true)
            return
        }

        val projectionManager = mediaProjectionManager
            ?: getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
        val captureResultCode = preparedDisplayCaptureResultCode
        val captureData = preparedDisplayCaptureData
        if (projectionManager == null || captureResultCode == null || captureData == null) {
            DisplayCaptureForegroundService.stop(this)
            result.error(
                "display_capture_not_prepared",
                "Screen recording permission must be granted before recording starts.",
                null
            )
            return
        }

        DisplayCaptureForegroundService.start(
            this,
            onReady = {
                beginPreparedDisplayCapture(
                    projectionManager = projectionManager,
                    captureResultCode = captureResultCode,
                    captureData = Intent(captureData),
                    result = result
                )
            },
            onFailure = { error ->
                clearPreparedDisplayCapture()
                result.error(
                    "display_capture_service_failed",
                    error.message ?: "Unable to start the screen recording service.",
                    null
                )
            }
        )
    }

    private fun beginPreparedDisplayCapture(
        projectionManager: MediaProjectionManager,
        captureResultCode: Int,
        captureData: Intent,
        result: MethodChannel.Result
    ) {
        try {
            val recordingFile = createScreenRecordingFile()
            val (displayWidth, displayHeight, densityDpi) = currentDisplayMetrics()
            val (width, height) = compatibleCaptureSize(
                width = displayWidth,
                height = displayHeight
            )
            val rotation = currentDisplayRotation()
            val projection = projectionManager.getMediaProjection(captureResultCode, captureData)
                ?: throw IllegalStateException("Unable to initialize screen capture.")

            val callback = object : MediaProjection.Callback() {
                override fun onStop() {
                    releaseDisplayCapture(stopRecorder = false, deleteFile = false)
                }
            }

            projection.registerCallback(callback, null)
            mediaProjection = projection
            mediaProjectionCallback = callback

            val recorder = createScreenMediaRecorder(
                outputFile = recordingFile,
                width = width,
                height = height,
                rotation = rotation
            )
            val virtualDisplay = projection.createVirtualDisplay(
                "Aks-screen-recording",
                width,
                height,
                densityDpi,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                recorder.surface,
                null,
                null
            )
            recorder.start()

            mediaRecorder = recorder
            this.virtualDisplay = virtualDisplay
            activeDisplayCaptureFile = recordingFile

            preparedDisplayCaptureResultCode = null
            preparedDisplayCaptureData = null

            result.success(true)
        } catch (error: Exception) {
            releaseDisplayCapture(stopRecorder = false, deleteFile = true)
            result.error(
                "display_capture_start_failed",
                error.message ?: "Unable to start screen recording.",
                null
            )
        }
    }

    private fun cancelPreparedDisplayCapture(result: MethodChannel.Result) {
        clearPreparedDisplayCapture()
        if (isDisplayCaptureActive()) {
            releaseDisplayCapture(stopRecorder = false, deleteFile = true)
        } else {
            DisplayCaptureForegroundService.stop(this)
        }
        result.success(true)
    }

    private fun pauseDisplayCapture(result: MethodChannel.Result) {
        val recorder = mediaRecorder
        if (recorder == null) {
            result.error(
                "display_capture_not_active",
                "No active screen recording is available to pause.",
                null
            )
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            result.error(
                "pause_not_supported",
                "Pause and resume are not supported for screen recording on this Android version.",
                null
            )
            return
        }

        try {
            recorder.pause()
            result.success(true)
        } catch (error: Exception) {
            result.error(
                "display_capture_pause_failed",
                error.message ?: "Unable to pause screen recording.",
                null
            )
        }
    }

    private fun resumeDisplayCapture(result: MethodChannel.Result) {
        val recorder = mediaRecorder
        if (recorder == null) {
            result.error(
                "display_capture_not_active",
                "No active screen recording is available to resume.",
                null
            )
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            result.error(
                "resume_not_supported",
                "Pause and resume are not supported for screen recording on this Android version.",
                null
            )
            return
        }

        try {
            recorder.resume()
            result.success(true)
        } catch (error: Exception) {
            result.error(
                "display_capture_resume_failed",
                error.message ?: "Unable to resume screen recording.",
                null
            )
        }
    }

    private fun stopDisplayCapture(result: MethodChannel.Result) {
        val recorder = mediaRecorder
        val outputFile = activeDisplayCaptureFile
        if (recorder == null || outputFile == null) {
            result.error(
                "display_capture_not_active",
                "No active screen recording is available to stop.",
                null
            )
            return
        }

        try {
            recorder.stop()
            result.success(outputFile.absolutePath)
        } catch (error: Exception) {
            if (outputFile.exists()) {
                outputFile.delete()
            }
            result.error(
                "display_capture_stop_failed",
                error.message ?: "Unable to finish screen recording.",
                null
            )
        } finally {
            releaseDisplayCapture(stopRecorder = false, deleteFile = false)
            clearPreparedDisplayCapture()
        }
    }

    private fun exportWithMediaStore(
        sourceFile: File,
        fileName: String,
        mimeType: String
    ): String {
        val resolver = applicationContext.contentResolver
        val relativePath = Environment.DIRECTORY_DOWNLOADS + "/Aks"
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

        return "Recording exported to Downloads/Aks/$fileName."
    }

    private fun exportToLegacyDownloads(sourceFile: File, fileName: String): String {
        val downloadsDirectory =
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val targetDirectory = File(downloadsDirectory, "Aks")
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

    private fun clearPreparedDisplayCapture() {
        preparedDisplayCaptureResultCode = null
        preparedDisplayCaptureData = null
    }

    private fun isDisplayCaptureActive(): Boolean {
        return mediaRecorder != null
    }

    private fun createScreenRecordingFile(): File {
        val recordingsDirectory = File(cacheDir, "native_display_recordings")
        if (!recordingsDirectory.exists()) {
            recordingsDirectory.mkdirs()
        }

        return File(
            recordingsDirectory,
            "recording_${System.currentTimeMillis()}.mp4"
        )
    }

    private fun createScreenMediaRecorder(
        outputFile: File,
        width: Int,
        height: Int,
        rotation: Int
    ): MediaRecorder {
        val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(this)
        } else {
            MediaRecorder()
        }

        recorder.setAudioSource(MediaRecorder.AudioSource.MIC)
        recorder.setVideoSource(MediaRecorder.VideoSource.SURFACE)
        recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        recorder.setOutputFile(outputFile.absolutePath)
        recorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
        recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        recorder.setVideoEncodingBitRate(4_000_000)
        recorder.setVideoFrameRate(24)
        recorder.setVideoSize(width, height)
        recorder.setAudioEncodingBitRate(128_000)
        recorder.setAudioSamplingRate(44_100)
        recorder.setOrientationHint(orientationHintFor(rotation))
        recorder.prepare()
        return recorder
    }

    @Suppress("DEPRECATION")
    private fun currentDisplayMetrics(): Triple<Int, Int, Int> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val bounds = windowManager.currentWindowMetrics.bounds
            Triple(
                makeEven(bounds.width()),
                makeEven(bounds.height()),
                resources.displayMetrics.densityDpi
            )
        } else {
            val metrics = DisplayMetrics()
            windowManager.defaultDisplay.getRealMetrics(metrics)
            Triple(
                makeEven(metrics.widthPixels),
                makeEven(metrics.heightPixels),
                metrics.densityDpi
            )
        }
    }

    @Suppress("DEPRECATION")
    private fun currentDisplayRotation(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display?.rotation ?: Surface.ROTATION_0
        } else {
            windowManager.defaultDisplay.rotation
        }
    }

    private fun orientationHintFor(rotation: Int): Int {
        return when (rotation) {
            Surface.ROTATION_0 -> 90
            Surface.ROTATION_90 -> 0
            Surface.ROTATION_180 -> 270
            Surface.ROTATION_270 -> 180
            else -> 0
        }
    }

    private fun makeEven(value: Int): Int {
        return if (value % 2 == 0) value else value - 1
    }

    private fun compatibleCaptureSize(width: Int, height: Int): Pair<Int, Int> {
        val shortSide = minOf(width, height)
        val longSide = maxOf(width, height)
        val shortScale = maxCaptureShortSide.toDouble() / shortSide.toDouble()
        val longScale = maxCaptureLongSide.toDouble() / longSide.toDouble()
        val scale = minOf(1.0, shortScale, longScale)

        val scaledWidth = makeEven((width * scale).toInt())
        val scaledHeight = makeEven((height * scale).toInt())

        return Pair(
            scaledWidth.coerceAtLeast(2),
            scaledHeight.coerceAtLeast(2)
        )
    }

    private fun releaseDisplayCapture(stopRecorder: Boolean, deleteFile: Boolean) {
        val recorder = mediaRecorder
        mediaRecorder = null

        if (stopRecorder) {
            try {
                recorder?.stop()
            } catch (_: Exception) {
                // Ignore stop failures during cleanup.
            }
        }

        try {
            recorder?.reset()
        } catch (_: Exception) {
            // Ignore reset failures during cleanup.
        }
        try {
            recorder?.release()
        } catch (_: Exception) {
            // Ignore release failures during cleanup.
        }

        try {
            virtualDisplay?.release()
        } catch (_: Exception) {
            // Ignore display release failures during cleanup.
        }
        virtualDisplay = null

        mediaProjectionCallback?.let { callback ->
            try {
                mediaProjection?.unregisterCallback(callback)
            } catch (_: Exception) {
                // Ignore callback unregistration failures during cleanup.
            }
        }
        mediaProjectionCallback = null

        try {
            mediaProjection?.stop()
        } catch (_: Exception) {
            // Ignore projection stop failures during cleanup.
        }
        mediaProjection = null

        val outputFile = activeDisplayCaptureFile
        activeDisplayCaptureFile = null
        if (deleteFile && outputFile != null && outputFile.exists()) {
            outputFile.delete()
        }

        DisplayCaptureForegroundService.stop(this)
    }

    override fun onDestroy() {
        pendingDisplayCaptureResult?.error(
            "screen_capture_cancelled",
            "The screen recording request was interrupted.",
            null
        )
        pendingDisplayCaptureResult = null
        clearPreparedDisplayCapture()
        releaseDisplayCapture(stopRecorder = false, deleteFile = false)
        super.onDestroy()
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != screenCaptureRequestCode) {
            return
        }

        val pendingResult = pendingDisplayCaptureResult ?: return
        pendingDisplayCaptureResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            clearPreparedDisplayCapture()
            DisplayCaptureForegroundService.stop(this)
            pendingResult.error(
                "screen_capture_cancelled",
                "Screen recording permission was denied.",
                null
            )
            return
        }

        preparedDisplayCaptureResultCode = resultCode
        preparedDisplayCaptureData = Intent(data)
        pendingResult.success(true)
    }
}
