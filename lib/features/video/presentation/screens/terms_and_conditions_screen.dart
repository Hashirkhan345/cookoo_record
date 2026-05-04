import 'package:flutter/material.dart';

import '../widgets/legal_document_screen.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Terms & Conditions',
      subtitle:
          'These Terms & Conditions govern your use of Aks, including account access, recording behavior, storage, and exported content.',
      effectiveDateLabel: 'Effective date: March 17, 2026',
      icon: Icons.gavel_outlined,
      heroColor: Color(0xFF1D2339),
      highlights: <String>[
        'User accounts, sign-in methods, and profile access',
        'Screen recording, camera capture, and microphone usage',
        'Saved recordings, downloads, exports, and shared content',
        'Consent, acceptable use, and service availability rules',
      ],
      sections: <LegalDocumentSection>[
        LegalDocumentSection(
          heading: 'Acceptance of terms',
          body:
              'By creating an account, signing in, or using Aks, you agree to these Terms & Conditions. If you do not accept them, you should not use the application.',
        ),
        LegalDocumentSection(
          heading: 'Account responsibility',
          body:
              'You are responsible for maintaining the confidentiality of your login credentials and for the activity performed through your account. You must provide accurate account details and keep them up to date.',
        ),
        LegalDocumentSection(
          heading: 'Recording responsibility and consent',
          body:
              'You may only record screens, audio, video, meetings, or participants when you have the legal right and all required permissions or consent to do so. You are solely responsible for compliance with local laws and internal company rules.',
        ),
        LegalDocumentSection(
          heading: 'Content ownership',
          body:
              'You retain responsibility for the recordings and materials you create through Aks. The app does not claim ownership of your content, but you grant the service the limited rights needed to process recordings and save them for app functionality.',
        ),
        LegalDocumentSection(
          heading: 'Acceptable use',
          body:
              'You must not use the app for unlawful surveillance, unauthorized recording, credential theft, malware delivery, or any activity that harms other users, systems, or networks.',
        ),
        LegalDocumentSection(
          heading: 'Storage and availability',
          body:
              'Features may change over time, and availability is not guaranteed at all times. Local browser storage, network conditions, browser permissions, or third-party service outages may affect recording reliability and access to saved content.',
        ),
        LegalDocumentSection(
          heading: 'Termination',
          body:
              'We may suspend or terminate access to Aks if misuse, abuse, security concerns, or policy violations are detected. You may stop using the service at any time by signing out and discontinuing access.',
        ),
        LegalDocumentSection(
          heading: 'Limitation of liability',
          body:
              'Aks is provided on an as-available basis. To the maximum extent permitted by law, the service is not liable for lost recordings, indirect damages, interrupted business operations, or consequences resulting from misuse or unsupported environments.',
        ),
      ],
    );
  }
}
