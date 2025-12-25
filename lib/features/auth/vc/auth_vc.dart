// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../model/auth_repository.dart';
// import '../model/auth_state.dart';
// import '../model/user.dart';

// // Demo repository (fake) để chạy UI trước
// class FakeAuthRepository implements AuthRepository {
//   @override
//   Future<User> login({required String email, required String password}) async {
//     await Future.delayed(const Duration(milliseconds: 800));

//     if (email.isEmpty || password.isEmpty) {
//       throw Exception("Email/mật khẩu không được để trống");
//     }
//     if (password.length < 6) {
//       throw Exception("Mật khẩu tối thiểu 6 ký tự");
//     }
//     return User(id: "u_001", name: "Pet Lover", email: email);
//   }

//   @override
//   Future<void> logout() async {
//     await Future.delayed(const Duration(milliseconds: 300));
//   }
// }

// final authRepositoryProvider = Provider<AuthRepository>((ref) {
//   return FakeAuthRepository();
// });

// class AuthVC extends Notifier<AuthState> {
//   @override
//   AuthState build() => const AuthState();

//   Future<void> login(String email, String password) async {
//     state = state.copyWith(isLoading: true, error: null);
//     try {
//       final repo = ref.read(authRepositoryProvider);
//       final user = await repo.login(email: email, password: password);
//       state = state.copyWith(isLoading: false, user: user);
//     } catch (e) {
//       state = state.copyWith(isLoading: false, error: e.toString());
//     }
//   }

//   Future<void> logout() async {
//     state = state.copyWith(isLoading: true, error: null);
//     final repo = ref.read(authRepositoryProvider);
//     await repo.logout();
//     state = const AuthState(isLoading: false, user: null);
//   }

//   void clearError() {
//     state = state.copyWith(error: null);
//   }
// }

// final authVCProvider = NotifierProvider<AuthVC, AuthState>(AuthVC.new);
