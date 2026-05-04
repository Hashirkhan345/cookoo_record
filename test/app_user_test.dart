import 'package:flutter_test/flutter_test.dart';

import 'package:bloop/features/auth/data/models/app_user.dart';

void main() {
  test('toJson includes stored recorded videos count', () {
    const AppUser user = AppUser(
      uid: 'user-1',
      email: 'user@example.com',
      name: 'User Example',
      emailVerified: true,
      recordedVideosCount: 8,
    );

    final Map<String, Object?> json = user.toJson();

    expect(json['recordedVideosCount'], 8);
  });
}
