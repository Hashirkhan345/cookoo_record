import 'dart:html' as html;

bool get isRecordingFlowFullscreenSupported =>
    html.document.documentElement != null;

Future<bool> toggleRecordingFlowFullscreen() async {
  final dynamic fullscreenElement = html.document.fullscreenElement;
  if (fullscreenElement != null) {
    html.document.exitFullscreen();
    return false;
  }

  final html.Element? rootElement = html.document.documentElement;
  if (rootElement == null) {
    return false;
  }

  await rootElement.requestFullscreen();
  return true;
}
