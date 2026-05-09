class MachineResource {
  const MachineResource({
    required this.name,
    required this.role,
    required this.expectedRam,
    required this.expectedDisk,
    required this.expectedVram,
    required this.observedRam,
    required this.observedDisk,
    required this.observedVram,
    required this.source,
  });

  final String name;
  final String role;
  final String expectedRam;
  final String expectedDisk;
  final String expectedVram;
  final String observedRam;
  final String observedDisk;
  final String observedVram;
  final String source;
}
