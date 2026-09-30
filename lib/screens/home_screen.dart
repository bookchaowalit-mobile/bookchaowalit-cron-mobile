import 'package:flutter/material.dart';

import '../logic/cron_expression.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.clock});

  /// Injectable clock so tests get deterministic "next run" output.
  final DateTime Function()? clock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _examples = [
    '*/15 * * * *',
    '0 9 * * MON-FRI',
    '30 2 1 * *',
    '0 0 * * 0',
    '@hourly',
  ];

  final _controller = TextEditingController(text: '0 9 * * MON-FRI');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = (widget.clock ?? DateTime.now)();
    CronExpression? expression;
    String? error;
    try {
      expression = CronExpression.parse(_controller.text);
    } on CronFormatException catch (e) {
      error = e.message;
    }
    final textTheme = Theme.of(context).textTheme;
    final runs = expression?.nextRuns(now) ?? const <DateTime>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Cron')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('cron-input'),
            controller: _controller,
            autocorrect: false,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: 'Cron expression',
              helperText: 'minute hour day-of-month month day-of-week',
              errorText: error,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final example in _examples)
                ActionChip(
                  label: Text(example),
                  onPressed: () => setState(() => _controller.text = example),
                ),
            ],
          ),
          if (expression != null) ...[
            const SizedBox(height: 24),
            Text('Meaning', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              expression.describe(),
              key: const Key('cron-description'),
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text('Next runs', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            if (runs.isEmpty)
              const Text('This schedule never fires in the next ten years.')
            else
              for (final run in runs)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.event),
                  title: Text(_format(run)),
                ),
          ],
        ],
      ),
    );
  }

  static String _format(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    final day = dayLabels[t.weekday % 7];
    return '$day ${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}';
  }
}
