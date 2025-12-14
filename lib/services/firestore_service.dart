import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:focus_timer/models/session.dart';
import 'package:focus_timer/models/sync_operation.dart';
import 'package:focus_timer/models/task.dart';
import 'package:hive_flutter/adapters.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Box<SyncOperation>? _syncQueue;
  bool _isSyncing = false;

  String? get _userId => _auth.currentUser?.uid;
  int get pendingOperationsCount => _syncQueue?.length ?? 0;
  bool get isSyncing => _isSyncing;

  Future<void> init() async {
    _syncQueue = await Hive.openBox<SyncOperation>('syncQueue');
    print(
      '🔐 Auth Status: ${_userId != null ? "Authenticated ($_userId)" : "NOT AUTHENTICATED"}',
    );
    print('📦 Pending operations on init: ${_syncQueue!.length}');
    _setupConnectivityListener();
    _processSyncQueue();
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        print('🌐 Internet connected - processing sync queue');
        _processSyncQueue();
      }
    });
  }

  Future<void> _queueOperation(String type, Map<String, dynamic> data) async {
    if (_syncQueue == null) {
      print('⚠️ Sync queue not initialized yet');
      return;
    }

    final operation = SyncOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operationType: type,
      data: data,
      createdAt: DateTime.now(),
    );
    await _syncQueue!.add(operation);
    print('📥 Queued: $type (${_syncQueue!.length} pending)');
    print('   └─ Data: ${data.keys.join(", ")}');
    notifyListeners();
    _processSyncQueue();
  }

  Future<void> _processSyncQueue() async {
    if (_isSyncing) {
      print('⏸️ Already syncing, skipping...');
      return;
    }

    if (_syncQueue == null) {
      print('❌ Sync queue not initialized');
      return;
    }

    if (_syncQueue!.isEmpty) {
      print('✅ Queue is empty, nothing to sync');
      return;
    }

    if (_userId == null) {
      print('❌ No authenticated user! Cannot sync.');
      return;
    }

    // ✅ Check internet connectivity before starting
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('📡 No internet connection - sync skipped');
      return; // Don't set _isSyncing if offline
    }

    _isSyncing = true;
    notifyListeners();

    print('🔄 Starting sync... (${_syncQueue!.length} operations)');
    print('🔐 User ID: $_userId');

    try {
      // ✅ Add overall timeout for entire sync process (30 seconds)
      await _performSync().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ Sync timeout after 30 seconds');
          throw TimeoutException('Sync took too long');
        },
      );
    } catch (e) {
      print('❌ Sync process error: $e');
    } finally {
      // ✅ ALWAYS reset syncing flag, even on error
      _isSyncing = false;
      notifyListeners();
      print('🏁 Sync process ended. Pending: ${_syncQueue!.length}');
    }
  }

  // ✅ Separated actual sync logic for timeout handling
  Future<void> _performSync() async {
    final operations = _syncQueue!.values.toList();
    int successCount = 0;
    int failCount = 0;

    for (final op in operations) {
      try {
        print('  ⏳ Processing: ${op.operationType} (retry: ${op.retryCount})');

        // ✅ Add per-operation timeout (10 seconds)
        await _executeOperation(op).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Operation timeout');
          },
        );

        await op.delete();
        successCount++;
        print('  ✅ Success: ${op.operationType}');
        notifyListeners();
      } catch (e) {
        failCount++;
        print('  ❌ Failed: ${op.operationType}');
        print('     Error: $e');

        op.retryCount++;
        await op.save();

        if (op.retryCount >= 5) {
          print('  ⚠️ Giving up after 5 retries: ${op.operationType}');
          await op.delete();
          notifyListeners();
        }
      }
    }

    print('📊 Sync complete: $successCount succeeded, $failCount failed');
    if (_syncQueue!.isNotEmpty) {
      print('⏳ ${_syncQueue!.length} operations still pending');
    } else {
      print('✨ All operations synced!');
    }
  }

  Future<void> _executeOperation(SyncOperation op) async {
    print('    🔍 Executing: ${op.operationType}');
    print(
      '    📍 Path: users/$_userId/${op.operationType.contains("session") ? "sessions" : "tasks"}',
    );

    switch (op.operationType) {
      case 'upload_session':
        final docRef = _firestore
            .collection('users/$_userId/sessions')
            .doc(op.data['id']);
        print('    📝 Writing to: ${docRef.path}');
        await docRef.set(op.data);
        print('    ✅ Write successful');
        break;

      case 'delete_session':
        await _firestore
            .collection('users/$_userId/sessions')
            .doc(op.data['id'])
            .delete();
        break;

      case 'delete_bulk_sessions':
        final batch = _firestore.batch();
        for (final id in op.data['ids']) {
          batch.delete(
            _firestore.collection('users/$_userId/sessions').doc(id),
          );
        }
        await batch.commit();
        break;

      case 'upload_task':
        final docRef = _firestore
            .collection('users/$_userId/tasks')
            .doc(op.data['id']);
        print('    📝 Writing to: ${docRef.path}');
        await docRef.set(op.data);
        print('    ✅ Write successful');
        break;

      case 'delete_task':
        await _firestore
            .collection('users/$_userId/tasks')
            .doc(op.data['id'])
            .delete();
        break;

      case 'update_task':
        await _firestore
            .collection('users/$_userId/tasks')
            .doc(op.data['id'])
            .update(op.data);
        break;

      default:
        throw Exception('Unknown operation type: ${op.operationType}');
    }
  }

  // ==================== PUBLIC API ====================

  Future<void> uploadSession(Session session) async {
    print('📤 Queueing session upload: ${session.id}');
    await _queueOperation('upload_session', {
      'id': session.id,
      'completedAt': session.compeletedAt.toIso8601String(),
      'durationMinutes': session.durationMinutes,
      'wasFocusSession': session.wasFocusSession,
    });
  }

  Future<void> deleteSession(String sessionId) async {
    await _queueOperation('delete_session', {'id': sessionId});
  }

  Future<void> deleteBulkSessions(List<String> sessionIds) async {
    await _queueOperation('delete_bulk_sessions', {'ids': sessionIds});
  }

  Future<void> uploadTask(Task task) async {
    print('📤 Queueing task upload: ${task.id}');
    await _queueOperation('upload_task', {
      'id': task.id,
      'title': task.title,
      'isCompleted': task.isCompleted,
      'createdAt': task.createdAt.toIso8601String(),
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _queueOperation('delete_task', {'id': taskId});
  }

  Future<void> updateTask(Task task) async {
    await _queueOperation('update_task', {
      'id': task.id,
      'title': task.title,
      'isCompleted': task.isCompleted,
    });
  }

  // ==================== PULL FROM CLOUD ====================

  Future<List<Session>> fetchAllSessions() async {
    if (_userId == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users/$_userId/sessions')
          .get()
          .timeout(const Duration(seconds: 10));
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Session(
          id: doc.id,
          compeletedAt: DateTime.parse(data['completedAt']),
          durationMinutes: data['durationMinutes'],
          wasFocusSession: data['wasFocusSession'],
        );
      }).toList();
    } catch (e) {
      print('❌ Error fetching sessions: $e');
      return [];
    }
  }

  Future<List<Task>> fetchAllTasks() async {
    if (_userId == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users/$_userId/tasks')
          .get()
          .timeout(const Duration(seconds: 10));
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Task(
          id: doc.id,
          title: data['title'],
          isCompleted: data['isCompleted'],
          createdAt: DateTime.parse(data['createdAt']),
        );
      }).toList();
    } catch (e) {
      print('❌ Error fetching tasks: $e');
      return [];
    }
  }

  Future<void> forceSyncNow() async {
    print('🔄 Force sync triggered by user');
    print('📊 Current state:');
    print('   └─ Auth: ${_userId != null ? "✅" : "❌"}');
    print('   └─ Queue size: ${_syncQueue?.length ?? 0}');
    print('   └─ Already syncing: ${_isSyncing ? "Yes" : "No"}');

    await _processSyncQueue();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}
