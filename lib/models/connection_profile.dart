class ConnectionProfile {
  const ConnectionProfile({
    required this.host,
    required this.username,
    required this.password,
    this.port = 22,
    this.rememberHostAndUser = false,
  });

  final String host;
  final String username;
  final String password;
  final int port;
  final bool rememberHostAndUser;

  bool get isValid =>
      host.trim().isNotEmpty &&
      username.trim().isNotEmpty &&
      password.isNotEmpty &&
      port > 0 &&
      port <= 65535;
}
