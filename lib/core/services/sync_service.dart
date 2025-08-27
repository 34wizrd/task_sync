import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';

import 'db_service.dart';
import 'timestamp_service.dart';

/// A service dedicated to orchestrating the synchronization of local data
/// with the remote Firebase Firestore database.
class SyncService {
  final DbService _dbService = DbService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TimestampService _timestampService = TimestampService();

  /// A utility to get the current user at the time of sync.
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  /// The main entry point for the synchronization process.
  /// It checks for network connectivity before proceeding.
  Future<void> sync() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      print("No internet connection. Skipping sync.");
      return;
    }

    print("Sync process started...");
    await _pullRemoteChanges();
    await _pushLocalChanges();
    print("Sync process finished.");
  }

  /// Pushes local changes (creates, updates, deletes) from the 'outbox' table
  /// to the remote Firestore database.
  Future<void> _pushLocalChanges() async {
    if (_currentUser == null) {
      print("No user logged in, skipping push to cloud.");
      return;
    }
    final String userId = _currentUser!.uid;

    final db = await _dbService.database;
    final List<Map<String, dynamic>> outboxItems =
    await db.query('outbox', orderBy: 'createdAt ASC');

    if (outboxItems.isEmpty) {
      print("No local changes to push.");
      return;
    }

    print("Pushing ${outboxItems.length} local changes to the server.");
    for (var item in outboxItems) {
      final data = jsonDecode(item['data'] as String);
      final tableName = item['tableName'] as String;
      final operation = item['operation'] as String;
      final docId = data['id'];

      try {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection(tableName)
            .doc(docId);

        if (operation == 'DELETE') {
          await docRef.delete();
        } else {
          await docRef.set(data);
        }

        await db.delete('outbox', where: 'id = ?', whereArgs: [item['id']]);
      } catch (e) {
        print("Failed to sync item ${item['id']}: $e");
        break;
      }
    }
  }

  /// Pulls remote changes from Firestore to the local SQLite database using an
  /// efficient delta-syncing strategy.
  Future<void> _pullRemoteChanges() async {
    if (_currentUser == null) {
      print("No user logged in, skipping pull from cloud.");
      return;
    }
    final String userId = _currentUser!.uid;
    print("Pulling remote changes from Firestore for user $userId.");
    final db = await _dbService.database;

    final int lastSync = await _timestampService.getLastSyncTimestamp();
    print("Last sync timestamp: $lastSync. Fetching changes since then.");

    try {
      // CORRECTED: The type from sqflite's db.batch() is 'Batch'.
      final Batch batch = db.batch();

      final foodItemsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('food_items')
          .where('updatedAt', isGreaterThan: lastSync)
          .get();

      print("Found ${foodItemsSnapshot.docs.length} updated food items.");
      for (var doc in foodItemsSnapshot.docs) {
        batch.insert('food_items', doc.data(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final mealEntriesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meal_entries')
          .where('updatedAt', isGreaterThan: lastSync)
          .get();

      print("Found ${mealEntriesSnapshot.docs.length} updated meal entries.");
      for (var doc in mealEntriesSnapshot.docs) {
        batch.insert('meal_entries', doc.data(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);

      await _timestampService.updateLastSyncTimestamp();

    } catch (e) {
      print("Failed to pull remote changes: $e");
    }
  }
}