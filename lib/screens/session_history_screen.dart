import 'package:flutter/material.dart';
import 'package:focus_timer/models/session.dart';
import 'package:focus_timer/providers/stats_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Session History"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "delete_old",
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20),
                    SizedBox(width: 8),
                    Text("Delete Old Sessions"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "delete_all",
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      "Delete All Sessions",
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<StatsProvider>(
        builder: (context, statsProvider, child) {
          final sessions = statsProvider.allSessions;

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No sessions yet",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Complete focus sessions to see history",
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildSessionCard(context, session, statsProvider);
            },
          );
        },
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final statsProvider = context.read<StatsProvider>();

    if (action == "delete_old") {
      _showDeleteOldDialog(context, statsProvider);
    } else if (action == "delete_all") {
      _showDeleteAllDialog(context, statsProvider);
    }
  }

  void _showDeleteOldDialog(BuildContext context, StatsProvider statsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Old Sessions"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choose how old sessions to delete:"),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Older than 7 days"),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteOld(context, statsProvider, 7);
              },
            ),
            ListTile(
              title: const Text("Older than 30 days"),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteOld(context, statsProvider, 30);
              },
            ),
            ListTile(
              title: const Text("Older than 90 days"),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteOld(context, statsProvider, 90);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context, StatsProvider statsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete All Sessions"),
        content: const Text(
          "This will permanently delete All session history. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await statsProvider.deleteAllSessions();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All sessions deleted"),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text(
              "Delete All",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    Session session,
    StatsProvider statsProvider,
  ) {
    final dateFormat = DateFormat("MMM dd, yyyy");
    final timeFormat = DateFormat("hh:mm a");

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Session"),
            content: const Text(
              "Are you sure you want to delete this session?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        statsProvider.deleteSession(session);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session deleted"),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: session.wasFocusSession
                ? Colors.deepPurple
                : Colors.green,
            child: Icon(
              session.wasFocusSession ? Icons.work : Icons.coffee,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            session.wasFocusSession ? "Focus Session" : "Break Session",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text("${session.durationMinutes} minutes"),
              const SizedBox(height: 2),
              Text(
                "${dateFormat.format(session.compeletedAt)} at ${timeFormat.format(session.compeletedAt)}",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () =>
                _showDeleteConfirmation(context, session, statsProvider),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Session session,
    StatsProvider statsProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Session"),
        content: const Text("Are you sure you want to delete this session?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              statsProvider.deleteSession(session);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Session deleted"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteOld(
    BuildContext context,
    StatsProvider statsProvider,
    int days,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete all sessions older than $days days?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await statsProvider.deleteOldSessions(days);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Deleted sessions odler than $days days"),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
