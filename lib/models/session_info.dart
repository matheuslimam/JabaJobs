class SessionInfo {
  const SessionInfo({
    required this.host,
    required this.username,
    required this.remoteUser,
    required this.hostname,
    required this.groups,
    required this.isAdmin,
  });

  final String host;
  final String username;
  final String remoteUser;
  final String hostname;
  final List<String> groups;
  final bool isAdmin;

  bool get hasSudoGroup => groups.contains('sudo');
}
