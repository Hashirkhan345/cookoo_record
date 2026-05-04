import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../enums/video_recording_mode.dart';
export 'video_browser_recorder_stub.dart' show BrowserVideoRecorder;
import 'video_browser_recorder_stub.dart';

@JS('navigator')
external NavigatorJs? get _navigator;

@JS('MediaRecorder')
external JSFunction? get _mediaRecorderConstructor;

@JS('Blob')
external JSFunction? get _blobConstructor;

extension type NavigatorJs._(JSObject _) implements JSObject {
  external MediaDevicesJs? get mediaDevices;
}

extension type MediaDevicesJs._(JSObject _) implements JSObject {
  external JSPromise<MediaStreamJs> getDisplayMedia(JSAny? constraints);
  external JSPromise<MediaStreamJs> getUserMedia(JSAny? constraints);
}

extension type MediaStreamJs._(JSObject _) implements JSObject {
  external JSArray<MediaStreamTrackJs> getAudioTracks();
  external JSArray<MediaStreamTrackJs> getVideoTracks();
  external JSArray<MediaStreamTrackJs> getTracks();
  external void addTrack(MediaStreamTrackJs track);
}

extension type MediaStreamTrackJs._(JSObject _) implements JSObject {
  external JSObject getSettings();
  external void stop();
}

extension type MediaRecorderJs._(JSObject _) implements JSObject {
  external JSString get state;
  external void start();
  external void pause();
  external void resume();
  external void stop();
}

extension type BlobEventJs._(JSObject _) implements JSObject {
  external BlobJs? get data;
}

extension type BlobJs._(JSObject _) implements JSObject {
  external JSNumber get size;
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

BrowserVideoRecorder createBrowserVideoRecorder() {
  return BrowserVideoRecorderWeb();
}

class BrowserVideoRecorderWeb implements BrowserVideoRecorder {
  MediaRecorderJs? _mediaRecorder;
  MediaStreamJs? _recordingStream;
  MediaStreamJs? _microphoneStream;
  final List<BlobJs> _chunks = <BlobJs>[];
  final List<_JsEventListenerBinding> _eventListeners =
      <_JsEventListenerBinding>[];
  Completer<XFile>? _stopCompleter;
  void Function()? _externalStopListener;
  bool _stopRequestedByApp = false;
  bool _stopTriggeredExternally = false;
  String _mimeType = 'video/webm';

  @override
  bool get isSupported {
    final MediaDevicesJs? mediaDevices = _mediaDevicesObject();
    return mediaDevices != null && mediaDevices.has('getDisplayMedia');
  }

  @override
  void setExternalStopListener(void Function()? listener) {
    _externalStopListener = listener;
  }

  @override
  Future<void> prepareRecording({
    required VideoRecordingMode mode,
    bool includeMicrophone = true,
  }) async {
    if (!mode.capturesDisplay) {
      throw StateError('Camera-only mode must use the camera recorder.');
    }
    if (!isSupported) {
      throw StateError('Screen recording is not supported in this browser.');
    }

    _clearEventListeners();
    _disposeStreams();
    _stopCompleter = null;
    _stopRequestedByApp = false;
    _stopTriggeredExternally = false;
    _chunks.clear();
    final MediaStreamJs recordingStream = await _requestDisplayStream(mode);
    final MediaStreamJs? microphoneStream = includeMicrophone
        ? await _requestMicrophoneStream()
        : null;

    _recordingStream = recordingStream;
    _microphoneStream = microphoneStream;

    if (microphoneStream != null) {
      final JSArray<MediaStreamTrackJs> audioTracks = microphoneStream
          .getAudioTracks();
      for (int index = 0; index < audioTracks.length; index++) {
        recordingStream.addTrack(audioTracks[index]);
      }
    }

    _mimeType = _resolveMimeType();
  }

  @override
  Future<void> startPreparedRecording() async {
    final MediaStreamJs recordingStream =
        _recordingStream ??
        (throw StateError('No browser display capture is prepared.'));
    _stopCompleter = Completer<XFile>();
    _stopRequestedByApp = false;
    _stopTriggeredExternally = false;
    _chunks.clear();

    try {
      final MediaRecorderJs recorder = _createMediaRecorder(
        recordingStream,
        mimeType: _mimeType,
      );
      _mediaRecorder = recorder;
      _attachRecorderListeners(recorder, recordingStream);
      recorder.start();
    } catch (_) {
      _cleanupRecorderState();
      rethrow;
    }
  }

  @override
  Future<void> cancelPreparedRecording() async {
    _stopCompleter = null;
    _stopRequestedByApp = false;
    _stopTriggeredExternally = false;
    _cleanupRecorderState();
  }

  @override
  Future<void> startRecording({
    required VideoRecordingMode mode,
    bool includeMicrophone = true,
  }) async {
    await prepareRecording(mode: mode, includeMicrophone: includeMicrophone);
    await startPreparedRecording();
  }

  @override
  Future<void> pauseRecording() async {
    final MediaRecorderJs recorder = _requireRecorder();
    if (_recorderState(recorder) == 'recording') {
      recorder.pause();
    }
  }

  @override
  Future<void> resumeRecording() async {
    final MediaRecorderJs recorder = _requireRecorder();
    if (_recorderState(recorder) == 'paused') {
      recorder.resume();
    }
  }

  @override
  Future<XFile> stopRecording() async {
    final Completer<XFile> completer =
        _stopCompleter ?? (throw StateError('No browser recording is active.'));
    final MediaRecorderJs? recorder = _mediaRecorder;

    _stopRequestedByApp = true;

    if (recorder != null && _recorderState(recorder) != 'inactive') {
      recorder.stop();
    }

    return completer.future;
  }

  Future<MediaStreamJs> _requestDisplayStream(VideoRecordingMode mode) async {
    final MediaDevicesJs? mediaDevices = _mediaDevicesObject();
    if (mediaDevices == null || !mediaDevices.has('getDisplayMedia')) {
      throw StateError('Screen capture is not supported in this browser.');
    }
    final List<Map<String, dynamic>> attempts = _buildDisplayConstraintAttempts(
      mode,
    );
    Object? lastError;
    StackTrace? lastStackTrace;

    for (int index = 0; index < attempts.length; index++) {
      final Map<String, dynamic> constraints = attempts[index];
      try {
        debugPrint(
          '[screen-capture] getDisplayMedia mode=${mode.name} '
          'attempt=${index + 1}/${attempts.length} '
          'constraints=$constraints',
        );
        final MediaStreamJs displayStream = await mediaDevices
            .getDisplayMedia(_jsObject(constraints))
            .toDart;
        _ensureExpectedSurface(displayStream, mode);
        return displayStream;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        debugPrint(
          '[screen-capture] getDisplayMedia failed for ${mode.name}: $error',
        );
        debugPrintStack(
          label: '[screen-capture] stack for ${mode.name}',
          stackTrace: stackTrace,
        );
        if (!_shouldRetryDisplayRequest(error) ||
            index == attempts.length - 1) {
          rethrow;
        }
      }
    }

    Error.throwWithStackTrace(
      lastError ?? StateError('Display capture failed.'),
      lastStackTrace ?? StackTrace.current,
    );
  }

  Future<MediaStreamJs?> _requestMicrophoneStream() async {
    final MediaDevicesJs? mediaDevices = _mediaDevicesObject();
    if (mediaDevices == null || !mediaDevices.has('getUserMedia')) {
      return null;
    }
    try {
      return await mediaDevices
          .getUserMedia(
            _jsObject(<String, Object?>{'audio': true, 'video': false}),
          )
          .toDart;
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _buildDisplayConstraintAttempts(
    VideoRecordingMode mode,
  ) {
    switch (mode) {
      case VideoRecordingMode.fullScreen:
        return <Map<String, dynamic>>[
          <String, dynamic>{
            'video': <String, dynamic>{
              'displaySurface': 'monitor',
              'frameRate': <String, dynamic>{'ideal': 30, 'max': 30},
              'logicalSurface': true,
            },
            'audio': false,
            'monitorTypeSurfaces': 'include',
            'surfaceSwitching': 'include',
            'selfBrowserSurface': 'exclude',
          },
          <String, dynamic>{
            'video': <String, dynamic>{'displaySurface': 'monitor'},
            'audio': false,
          },
        ];
      case VideoRecordingMode.window:
        return <Map<String, dynamic>>[
          <String, dynamic>{
            'video': <String, dynamic>{'displaySurface': 'window'},
            'audio': false,
          },
        ];
      case VideoRecordingMode.currentTab:
        return <Map<String, dynamic>>[
          <String, dynamic>{
            'video': <String, dynamic>{'displaySurface': 'browser'},
            'audio': false,
            'preferCurrentTab': true,
            'selfBrowserSurface': 'include',
          },
          <String, dynamic>{
            'video': <String, dynamic>{'displaySurface': 'browser'},
            'audio': false,
          },
        ];
      case VideoRecordingMode.cameraOnly:
        throw StateError('Camera-only mode does not request a display stream.');
    }
  }

  bool _shouldRetryDisplayRequest(Object error) {
    final String message = error.toString();
    return message.contains('TypeError') ||
        message.contains('OverconstrainedError');
  }

  MediaDevicesJs? _mediaDevicesObject() {
    return _navigator?.mediaDevices;
  }

  MediaRecorderJs _createMediaRecorder(
    MediaStreamJs recordingStream, {
    required String mimeType,
  }) {
    final JSFunction? constructor = _mediaRecorderConstructor;
    if (constructor == null) {
      throw StateError('Screen recording is not supported in this browser.');
    }

    if (mimeType.isEmpty) {
      return constructor.callAsConstructorVarArgs<MediaRecorderJs>(<JSAny?>[
        recordingStream,
      ]);
    }

    return constructor.callAsConstructorVarArgs<MediaRecorderJs>(<JSAny?>[
      recordingStream,
      _jsObject(<String, Object?>{'mimeType': mimeType}),
    ]);
  }

  void _attachRecorderListeners(
    MediaRecorderJs recorder,
    MediaStreamJs recordingStream,
  ) {
    _listen(recorder, 'dataavailable', (JSAny? event) {
      final BlobJs? blob = (event as BlobEventJs?)?.data;
      if (blob == null || blob.size.toDartInt == 0) {
        return;
      }
      _chunks.add(blob);
    });

    _listen(recorder, 'stop', (JSAny? _) async {
      final Completer<XFile>? completer = _stopCompleter;
      final bool notifyExternalStop =
          _stopTriggeredExternally && !_stopRequestedByApp;
      _stopTriggeredExternally = false;
      _stopRequestedByApp = false;
      if (completer == null || completer.isCompleted) {
        _cleanupRecorderState();
        if (notifyExternalStop) {
          scheduleMicrotask(_notifyExternalStopListener);
        }
        return;
      }

      try {
        completer.complete(await _buildRecordedFile());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        _cleanupRecorderState();
        if (notifyExternalStop) {
          scheduleMicrotask(_notifyExternalStopListener);
        }
      }
    });

    _listen(recorder, 'error', (JSAny? _) {
      final Completer<XFile>? completer = _stopCompleter;
      _stopTriggeredExternally = false;
      _stopRequestedByApp = false;
      if (completer != null && !completer.isCompleted) {
        completer.completeError(
          StateError('The browser could not record this screen capture.'),
        );
      }
      _cleanupRecorderState();
    });

    final JSArray<MediaStreamTrackJs> videoTracks = recordingStream
        .getVideoTracks();
    for (int index = 0; index < videoTracks.length; index++) {
      _listen(videoTracks[index], 'ended', (JSAny? _) {
        final MediaRecorderJs? activeRecorder = _mediaRecorder;
        if (activeRecorder == null ||
            _recorderState(activeRecorder) == 'inactive') {
          return;
        }
        _stopTriggeredExternally = true;
        activeRecorder.stop();
      }, once: true);
    }
  }

  void _listen(
    JSObject target,
    String type,
    void Function(JSAny? event) onEvent, {
    bool once = false,
  }) {
    final JSFunction listener = ((JSAny? event) {
      onEvent(event);
    }).toJS;
    final List<JSAny?> arguments = <JSAny?>[type.toJS, listener];
    if (once) {
      arguments.add(_jsObject(<String, Object?>{'once': true}));
    }
    target.callMethodVarArgs<JSAny?>('addEventListener'.toJS, arguments);
    _eventListeners.add(_JsEventListenerBinding(target, type, listener));
  }

  void _clearEventListeners() {
    for (final _JsEventListenerBinding binding in _eventListeners) {
      binding.target.callMethodVarArgs<JSAny?>(
        'removeEventListener'.toJS,
        <JSAny?>[binding.type.toJS, binding.listener],
      );
    }
    _eventListeners.clear();
  }

  void _cleanupRecorderState() {
    _clearEventListeners();
    _mediaRecorder = null;
    _disposeStreams();
  }

  void _ensureExpectedSurface(
    MediaStreamJs displayStream,
    VideoRecordingMode mode,
  ) {
    if (mode != VideoRecordingMode.currentTab) {
      return;
    }

    final String? displaySurface = _selectedDisplaySurface(displayStream);
    debugPrint(
      '[screen-capture] resolved displaySurface=${displaySurface ?? 'unknown'} '
      'for mode=${mode.name}',
    );
    if (displaySurface == null || displaySurface == 'browser') {
      return;
    }

    _stopStream(displayStream);
    throw StateError('Please choose a browser tab for Current Tab recording.');
  }

  String _resolveMimeType() {
    const List<String> preferredTypes = <String>[
      'video/webm;codecs=vp9,opus',
      'video/webm;codecs=vp8,opus',
      'video/webm',
    ];

    for (final String mimeType in preferredTypes) {
      final JSFunction? constructor = _mediaRecorderConstructor;
      if (constructor != null &&
          constructor
              .callMethod<JSBoolean>('isTypeSupported'.toJS, mimeType.toJS)
              .toDart) {
        return mimeType;
      }
    }

    return 'video/webm';
  }

  Future<XFile> _buildRecordedFile() async {
    if (_chunks.isEmpty) {
      throw StateError('The browser did not return any recorded video data.');
    }

    final BlobJs blob = _createBlob(_chunks, _mimeType);
    final Uint8List bytes = await _blobToBytes(blob);
    final DateTime now = DateTime.now();
    return XFile.fromData(
      bytes,
      mimeType: _mimeType,
      name: 'recording_${now.millisecondsSinceEpoch}.webm',
      length: bytes.length,
      lastModified: now,
    );
  }

  BlobJs _createBlob(List<BlobJs> chunks, String mimeType) {
    final JSFunction? constructor = _blobConstructor;
    if (constructor == null) {
      throw StateError('Unable to assemble the recorded browser video.');
    }
    return constructor.callAsConstructorVarArgs<BlobJs>(<JSAny?>[
      chunks.toJS,
      _jsObject(<String, Object?>{'type': mimeType}),
    ]);
  }

  Future<Uint8List> _blobToBytes(BlobJs blob) async {
    final JSArrayBuffer arrayBuffer = await blob.arrayBuffer().toDart;
    final ByteBuffer buffer = arrayBuffer.toDart;
    return Uint8List.view(buffer);
  }

  MediaRecorderJs _requireRecorder() {
    final MediaRecorderJs? recorder = _mediaRecorder;
    if (recorder == null) {
      throw StateError('No browser recording is active.');
    }
    return recorder;
  }

  String _recorderState(MediaRecorderJs recorder) {
    return recorder.state.toDart;
  }

  String? _selectedDisplaySurface(MediaStreamJs displayStream) {
    final JSArray<MediaStreamTrackJs> videoTracks = displayStream
        .getVideoTracks();
    if (videoTracks.length == 0) {
      return null;
    }

    final JSAny? displaySurface = videoTracks[0]
        .getSettings()['displaySurface'];
    if (displaySurface == null) {
      return null;
    }

    return (displaySurface as JSString).toDart;
  }

  JSObject _jsObject(Map<String, Object?> values) {
    final JSObject object = JSObject();
    for (final MapEntry<String, Object?> entry in values.entries) {
      object[entry.key] = _jsValue(entry.value);
    }
    return object;
  }

  JSAny? _jsValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value.toJS;
    }
    if (value is String) {
      return value.toJS;
    }
    if (value is int) {
      return value.toJS;
    }
    if (value is double) {
      return value.toJS;
    }
    if (value is num) {
      return value.toDouble().toJS;
    }
    if (value is Map<String, Object?>) {
      return _jsObject(value);
    }
    if (value is Map<String, dynamic>) {
      return _jsObject(value.cast<String, Object?>());
    }
    if (value is List<Object?>) {
      final JSArray<JSAny?> array = JSArray<JSAny?>();
      for (final Object? item in value) {
        array.add(_jsValue(item));
      }
      return array;
    }
    if (value is List<dynamic>) {
      final JSArray<JSAny?> array = JSArray<JSAny?>();
      for (final Object? item in value.cast<Object?>()) {
        array.add(_jsValue(item));
      }
      return array;
    }
    throw ArgumentError.value(
      value,
      'value',
      'Unsupported JavaScript interop value.',
    );
  }

  void _disposeStreams() {
    final MediaStreamJs? recordingStream = _recordingStream;
    if (recordingStream != null) {
      final JSArray<MediaStreamTrackJs> recordingTracks = recordingStream
          .getTracks();
      for (int index = 0; index < recordingTracks.length; index++) {
        recordingTracks[index].stop();
      }
    }
    final MediaStreamJs? microphoneStream = _microphoneStream;
    if (microphoneStream != null) {
      final JSArray<MediaStreamTrackJs> microphoneTracks = microphoneStream
          .getTracks();
      for (int index = 0; index < microphoneTracks.length; index++) {
        microphoneTracks[index].stop();
      }
    }
    _recordingStream = null;
    _microphoneStream = null;
    _chunks.clear();
  }

  void _stopStream(MediaStreamJs displayStream) {
    final JSArray<MediaStreamTrackJs> tracks = displayStream.getTracks();
    for (int index = 0; index < tracks.length; index++) {
      tracks[index].stop();
    }
  }

  void _notifyExternalStopListener() {
    final void Function()? listener = _externalStopListener;
    if (listener != null) {
      listener();
    }
  }
}

class _JsEventListenerBinding {
  const _JsEventListenerBinding(this.target, this.type, this.listener);

  final JSObject target;
  final String type;
  final JSFunction listener;
}
