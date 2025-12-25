class RegisterPayload {
  final String name;
  final String username;
  final String email;
  final String password;

  const RegisterPayload({
    required this.name,
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'username': username,
    'email': email,
    'password': password,
  };
}

class LoginPayload {
  final String email;
  final String password;

  const LoginPayload({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class VerifyOtpPayload {
  final String email;
  final String code;

  const VerifyOtpPayload({required this.email, required this.code});

  Map<String, dynamic> toJson() => {'email': email, 'code': code};
}
