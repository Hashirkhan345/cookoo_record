import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/admin_config_model.dart';
import '../data/repository/admin_config_repository.dart';

final adminConfigRepositoryProvider = Provider<AdminConfigRepository>(
  (Ref ref) => FirebaseAdminConfigRepository(),
);

final adminConfigProvider = FutureProvider<AdminConfigModel>((Ref ref) {
  return ref.read(adminConfigRepositoryProvider).fetchConfig();
});
