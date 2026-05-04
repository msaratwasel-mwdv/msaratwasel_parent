import '../entities/auth_user.dart';
import '../../data/repositories/auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this._repo);

  final AuthRepository _repo;

  Future<AuthUser> call({
    required String civilId,
    required String password,
  }) {
    return _repo.login(civilId: civilId, password: password);
  }
}
