import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

class FileService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadUserDocument({
    required String uid,
    required File file,
    required String documentType,
  }) async {
    final extension = path.extension(file.path);
    final fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final ref = _storage.ref().child('users/$uid/documents/$fileName');
    
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> uploadProfileImage({
    required String uid,
    required File file,
  }) async {
    final extension = path.extension(file.path);
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}$extension';
    final ref = _storage.ref().child('users/$uid/profile/$fileName');
    
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}

final fileServiceProvider = Provider<FileService>((ref) => FileService());
