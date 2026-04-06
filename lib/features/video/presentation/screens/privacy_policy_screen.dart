import 'package:flutter/material.dart';

import '../widgets/legal_document_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Privacy Policy',
      subtitle:
          'This Privacy Policy explains how bloop handles account details, browser permissions, and recordings created through the app.',
      effectiveDateLabel: 'Effective date: March 17, 2026',
      icon: Icons.privacy_tip_outlined,
      heroColor: Color(0xFFFC4C1E),
      highlights: <String>[
        'bloop account holders and signed-in workspace users',
        'Screen, camera, microphone, and browser recording flows',
        'Locally saved recordings, exports, and sharing actions',
        'Password reset, account security, and profile details',
      ],
      sections: <LegalDocumentSection>[
        LegalDocumentSection(
          heading: 'Information we collect',
          body:
              'bloop may collect your name, email address, and account status through Firebase Authentication. When you record a video, the app may also process screen, camera, microphone, and recording metadata such as file name, duration, and created date.',
        ),
        LegalDocumentSection(
          heading: 'How recordings are stored',
          body:
              'In the current web flow, saved recordings remain in your local browser storage, including IndexedDB, until you delete them or export them. We may also store account profile details in Firebase services so your account can be identified in the app.',
        ),
        LegalDocumentSection(
          heading: 'How we use your data',
          body:
              'We use your account information to authenticate you, display your profile inside the app, protect access to your workspace, and support features such as password reset and saved recording management. We also use technical information from the browser and recording session to keep the product stable and improve the overall recording experience.',
        ),
        LegalDocumentSection(
          heading: 'Sharing and exports',
          body:
              'Your recordings are not automatically shared with other users. A recording is only exported, downloaded, or shared when you explicitly choose one of those actions inside the app.',
        ),
        LegalDocumentSection(
          heading: 'Permissions and device access',
          body:
              'bloop requests access to screen capture, camera, and microphone only when required for a recording flow. Browser-level permission controls remain available to you at all times.',
        ),
        LegalDocumentSection(
          heading: 'Retention and deletion',
          body:
              'You can remove locally saved recordings from the app interface. Account data kept in Firebase may remain until the account is deleted or administrative cleanup is performed as part of service maintenance.',
        ),
        LegalDocumentSection(
          heading: 'Security',
          body:
              'We use platform services such as Firebase Authentication and Firestore to help secure account access and profile data. Even so, no storage or transmission method can be guaranteed to be completely secure.',
        ),
        LegalDocumentSection(
          heading: 'Your choices',
          body:
              'You can sign out, reset your password, delete local recordings, and control browser permissions for camera, microphone, and screen sharing. If you do not agree with this policy, you should stop using the service.',
        ),
      ],
    );
  }
}
