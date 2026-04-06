import 'package:flutter/material.dart';

import '../widgets/legal_document_screen.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Help Center',
      subtitle:
          'Use this Help Center to understand how bloop works, how to fix common recording issues, and how to manage saved recordings inside the app.',
      effectiveDateLabel: 'Updated: March 17, 2026',
      icon: Icons.help_outline_rounded,
      heroColor: Color(0xFF1D63E8),
      highlights: <String>[
        'Screen, camera, and microphone recording support',
        'Browser permissions and capture-source troubleshooting',
        'Saved recordings, downloads, playback, and deletion',
        'Account sign-in, sign-out, and password reset guidance',
      ],
      sections: <LegalDocumentSection>[
        LegalDocumentSection(
          heading: 'Getting started',
          body:
              'Sign in to bloop, choose a recording mode, and click the main record button to start a session. The browser may ask for screen, tab, camera, or microphone permissions depending on the mode you select.',
        ),
        LegalDocumentSection(
          heading: 'Recording modes',
          body:
              'bloop supports common browser capture flows such as current tab recording and full-screen recording. Choose the mode that matches what you want to capture, then confirm the source in the browser share dialog before the recording begins.',
        ),
        LegalDocumentSection(
          heading: 'Camera and microphone permissions',
          body:
              'If the app cannot access your camera or microphone, review the browser permission prompt and your site settings. A denied permission at browser level will prevent the app from showing the presenter bubble or capturing audio.',
        ),
        LegalDocumentSection(
          heading: 'Why a recording may fail',
          body:
              'Recordings may fail if screen sharing is cancelled, the selected source cannot be captured, the browser blocks popups or permissions, or the device does not provide an available camera or microphone. Refreshing the page and re-allowing permissions usually resolves the issue.',
        ),
        LegalDocumentSection(
          heading: 'Saved recordings',
          body:
              'On web, saved recordings are currently restored from browser storage. You can play them from the saved recordings list, download them to your device, or remove them from the list if they are no longer needed.',
        ),
        LegalDocumentSection(
          heading: 'Downloads and sharing',
          body:
              'After a recording is saved, you can export it through the available actions in the app. Download saves the recording locally, while sharing depends on browser support for native file sharing features.',
        ),
        LegalDocumentSection(
          heading: 'Account help',
          body:
              'If you cannot sign in, verify that your email and password are correct, or use the forgot-password flow to request a reset email. You can also sign out at any time from the account popup menu.',
        ),
        LegalDocumentSection(
          heading: 'Best practices',
          body:
              'For the most reliable capture experience, keep the app open in a supported browser, confirm the correct capture source, and use a stable internet connection when account or cloud-backed profile features are involved.',
        ),
      ],
    );
  }
}
