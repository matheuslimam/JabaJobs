import 'package:flutter/material.dart';

import '../../models/job_progress.dart';

class JabaProgressCard extends StatefulWidget {
  const JabaProgressCard({super.key, required this.logText});

  final String logText;

  @override
  State<JabaProgressCard> createState() => _JabaProgressCardState();
}

class _JabaProgressCardState extends State<JabaProgressCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = JobProgress.fromLog(widget.logText);
    final theme = Theme.of(context);
    final percent = (progress?.percent ?? 0) / 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101720),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF303844)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lesma do job',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      progress == null
                          ? 'Ainda não encontrei uma linha tqdm no log.'
                          : _progressSubtitle(progress),
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Text(
                progress?.label ?? '--',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const slugSize = 38.0;
              final travel = (constraints.maxWidth - slugSize).clamp(
                0.0,
                double.infinity,
              );
              return SizedBox(
                height: 54,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final bob = progress == null
                        ? 0.0
                        : (_controller.value - 0.5) * 5;
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 24,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 12,
                              value: progress == null ? null : percent,
                              backgroundColor: Colors.white10,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          left: progress == null ? 0 : travel * percent,
                          top: 0 + bob,
                          child: SizedBox(
                            width: slugSize * 1.4,
                            height: slugSize * 1.4,
                            child: Image.asset(
                              'jenasolo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
          if (progress?.rawLine.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            SelectableText(
              progress!.rawLine,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _progressSubtitle(JobProgress progress) {
    final pieces = <String>[
      if (progress.current != null && progress.total != null)
        '${progress.current}/${progress.total}',
      if (progress.elapsed != null) 'decorrido ${progress.elapsed}',
      if (progress.remaining != null) 'restante ${progress.remaining}',
      if (progress.rate != null && progress.rate!.isNotEmpty) progress.rate!,
    ];
    return pieces.isEmpty ? 'Progresso detectado no log.' : pieces.join(' | ');
  }
}
