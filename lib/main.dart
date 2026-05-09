import 'package:flutter/material.dart';

import 'repositories/cluster_repository.dart';
import 'services/cluster_parser.dart';
import 'services/preferences_service.dart';
import 'services/ssh_service.dart';
import 'state/cluster_app_state.dart';
import 'ui/pages/app_shell.dart';
import 'ui/pages/login_page.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await PreferencesService.create();
  final ssh = SshService();
  final parser = ClusterParser();
  final repository = ClusterRepository(
    ssh: ssh,
    parser: parser,
    preferences: preferences,
  );

  runApp(JabaJobsApp(state: ClusterAppState(repository)));
}

class JabaJobsApp extends StatelessWidget {
  const JabaJobsApp({super.key, required this.state});

  final ClusterAppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return MaterialApp(
          title: 'JABA JOBS',
          debugShowCheckedModeBanner: false,
          theme: buildClusterGlassTheme(),
          home: state.isConnected
              ? AppShell(state: state)
              : LoginPage(state: state),
        );
      },
    );
  }
}
