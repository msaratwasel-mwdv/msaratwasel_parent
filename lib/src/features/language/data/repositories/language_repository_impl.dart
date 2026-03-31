import 'package:msaratwasel_user/src/core/storage/storage_service.dart';
import './language_repository.dart';

class LanguageRepositoryImpl implements LanguageRepository {
  final StorageService storageService;

  LanguageRepositoryImpl({required this.storageService});

  @override
  Future<void> setLocale(String code) async {
    await storageService.saveLocale(code);
  }

  @override
  Future<String?> getSavedLocale() async {
    return await storageService.readLocale();
  }
}
