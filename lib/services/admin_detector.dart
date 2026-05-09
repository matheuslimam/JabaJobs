class AdminDetector {
  const AdminDetector();

  bool isAdmin(List<String> groups) {
    final normalized = groups.map((group) => group.toLowerCase()).toSet();
    return normalized.contains('clusteradmins') || normalized.contains('sudo');
  }
}
