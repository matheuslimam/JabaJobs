import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/cluster_app_state.dart';
import 'admin_page.dart';
import 'dashboard_page.dart';
import 'jobs_page.dart';
import 'logs_page.dart';
import 'mobile_logs_page.dart';
import 'settings_page.dart';
import 'submit_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});

  final ClusterAppState state;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  String? _lastShownMonitorAlertId;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_showMonitorAlertIfNeeded);
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_showMonitorAlertIfNeeded);
      widget.state.addListener(_showMonitorAlertIfNeeded);
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_showMonitorAlertIfNeeded);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final destinations = compact
                ? _mobileDestinations()
                : _desktopDestinations();

            if (_selectedIndex >= destinations.length) {
              _selectedIndex = 0;
            }

            if (compact) {
              return _MobileShell(
                state: widget.state,
                destinations: destinations,
                selectedIndex: _selectedIndex,
                onSelected: (index) => setState(() => _selectedIndex = index),
              );
            }

            return _DesktopShell(
              state: widget.state,
              destinations: destinations,
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
            );
          },
        );
      },
    );
  }

  List<_Destination> _desktopDestinations() {
    return [
      _Destination(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        page: DashboardPage(state: widget.state),
      ),
      _Destination(
        label: 'Jobs',
        icon: Icons.view_list_outlined,
        page: JobsPage(state: widget.state),
      ),
      _Destination(
        label: 'Logs',
        icon: Icons.terminal_outlined,
        page: LogsPage(state: widget.state),
      ),
      _Destination(
        label: 'Submit',
        icon: Icons.play_circle_outline,
        page: SubmitPage(state: widget.state),
      ),
      if (widget.state.isAdmin)
        _Destination(
          label: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          page: AdminPage(state: widget.state),
        ),
      _Destination(
        label: 'Config',
        icon: Icons.settings_outlined,
        page: SettingsPage(state: widget.state),
      ),
    ];
  }

  List<_Destination> _mobileDestinations() {
    return [
      _Destination(
        label: 'Monitor',
        icon: Icons.terminal_outlined,
        page: MobileLogsPage(state: widget.state),
      ),
      _Destination(
        label: 'Config',
        icon: Icons.settings_outlined,
        page: SettingsPage(state: widget.state),
      ),
    ];
  }

  void _showMonitorAlertIfNeeded() {
    final alert = widget.state.jobMonitorAlert;
    if (alert == null || alert.id == _lastShownMonitorAlertId) {
      return;
    }
    _lastShownMonitorAlertId = alert.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.vibrate();
      final color = alert.isError
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.secondary;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF151B23),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          closeIconColor: Colors.white70,
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                alert.isError
                    ? Icons.error_outline
                    : Icons.notifications_active_outlined,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${alert.title}\n${alert.message}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final Widget page;
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.state,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final ClusterAppState state;
  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            state: state,
            destinations: destinations,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(state: state),
                Expanded(
                  child: _PageArea(
                    state: state,
                    page: destinations[selectedIndex].page,
                    padding: const EdgeInsets.all(24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.state,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final ClusterAppState state;
  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _MobileTopBar(state: state),
          Expanded(
            child: _PageArea(
              state: state,
              page: destinations[selectedIndex].page,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _PageArea extends StatelessWidget {
  const _PageArea({
    required this.state,
    required this.page,
    required this.padding,
  });

  final ClusterAppState state;
  final Widget page;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(padding: padding, child: page),
        ),
        if (state.isBusy)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.state,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final ClusterAppState state;
  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 240,
      color: const Color(0xFF0A0F16),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: Image.asset('jenasolo.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Text(
                'JABA JOBS',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  state.isAdmin
                      ? Icons.verified_user_outlined
                      : Icons.person_outline,
                  color: state.isAdmin
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.isAdmin ? 'Administrador' : 'Usuario comum',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < destinations.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _NavButton(
                label: destinations[i].label,
                icon: destinations[i].icon,
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: state.disconnect,
            icon: const Icon(Icons.logout),
            label: const Text('Desconectar'),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? theme.colorScheme.primary : Colors.white60,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state});

  final ClusterAppState state;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1117),
        border: Border(bottom: BorderSide(color: Color(0xFF303844))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              session == null
                  ? 'Nao conectado'
                  : '${session.remoteUser}@${session.hostname}',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.circle, color: Colors.greenAccent, size: 10),
              const SizedBox(width: 8),
              Text(session?.host ?? '-'),
              const SizedBox(width: 20),
              const Text('Auto'),
              Switch(value: state.autoRefresh, onChanged: state.setAutoRefresh),
              IconButton(
                tooltip: 'Atualizar dashboard',
                onPressed: () =>
                    state.refreshDashboard(includeAdmin: state.isAdmin),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({required this.state});

  final ClusterAppState state;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    return SafeArea(
      bottom: false,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF0D1117),
          border: Border(bottom: BorderSide(color: Color(0xFF303844))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Image.asset('jenasolo.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                session == null
                    ? 'JABA JOBS'
                    : '${session.remoteUser}@${session.hostname}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: () =>
                  state.refreshDashboard(includeAdmin: state.isAdmin),
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Desconectar',
              onPressed: state.disconnect,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
      ),
    );
  }
}
