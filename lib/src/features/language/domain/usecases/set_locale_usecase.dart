import '../../data/repositories/language_repository.dart';

class SetLocaleUseCase {
  SetLocaleUseCase(this._repo);

  final LanguageRepository _repo;

  Future<void> call(String code) => _repo.setLocale(code);
}
