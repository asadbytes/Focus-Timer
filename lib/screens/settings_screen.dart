import 'package:flutter/material.dart';
import 'package:focus_timer/providers/timer_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _focusDuration;
  late double _breakDuration;

  @override
  void initState() {
    super.initState();
    final timerProvider = context.read<TimerProvider>();
    _focusDuration = timerProvider.focusDuration.toDouble();
    _breakDuration = timerProvider.breakDuration.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            "Timer Durations",
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 20),

          Text("Focus Duration: $_focusDuration minutes"),
          Slider(
            value: _focusDuration.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            label: "$_focusDuration min",
            onChanged: (value) {
              setState(() {
                _focusDuration = value;
              });
            },
          ),

          const SizedBox(height: 20),

          Text("Break Duration: $_breakDuration minutes"),
          Slider(
            value: _breakDuration.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            label: "$_breakDuration min",
            onChanged: (value) {
              setState(() {
                _breakDuration = value;
              });
            },
          ),

          const SizedBox(height: 40),

          FilledButton(
            onPressed: () {
              final timerProvider = context.read<TimerProvider>();
              timerProvider.updateDurations(
                _focusDuration.round(),
                _breakDuration.round(),
              );
              context.pop();
            },
            child: const Text("Save Settings"),
          ),
        ],
      ),
    );
  }
}
