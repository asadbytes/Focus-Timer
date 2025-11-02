import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final int focusDuration;
  final int breakDuration;
  const SettingsScreen({
    super.key,
    required this.focusDuration,
    required this.breakDuration,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _focusDuration;
  late int _breakDuration;

  @override
  void initState() {
    super.initState();
    _focusDuration = widget.focusDuration;
    _breakDuration = widget.breakDuration;
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
                _focusDuration = value.toInt();
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
                _breakDuration = value.toInt();
              });
            },
          ),

          const SizedBox(height: 40),

          FilledButton(
            onPressed: () {
              Navigator.pop(context, {
                "focus": _focusDuration,
                "break": _breakDuration,
              });
            },
            child: const Text("Save Settings"),
          ),
        ],
      ),
    );
  }
}
