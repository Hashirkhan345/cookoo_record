import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/admin_config_model.dart';

abstract class AdminConfigRepository {
  Future<AdminConfigModel> fetchConfig();

  Future<void> saveConfig(AdminConfigModel config);
}

class FirebaseAdminConfigRepository implements AdminConfigRepository {
  FirebaseAdminConfigRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _configDocument =>
      _firestore.collection('adminConfig').doc('config');

  @override
  Future<AdminConfigModel> fetchConfig() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _configDocument.get();
      final Map<String, dynamic>? data = snapshot.data();
      if (data == null) {
        return AdminConfigModel.defaults;
      }

      return AdminConfigModel.fromJson(data);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('[adminConfig] fetch failed: ${error.code} ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      return AdminConfigModel.defaults;
    }
  }

  @override
  Future<void> saveConfig(AdminConfigModel config) {
    return _configDocument.set(config.toJson(), SetOptions(merge: true));
  }
}
