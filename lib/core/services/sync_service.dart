import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';

import 'db_service.dart';
import 'timestamp_service.dart';

/// A configuration class that defines how a specific collection should be synced.
class SyncCollectionConfig {
  /// The name of the collection in both Firestore and the local SQLite database.
  final String name;

  /// A function that transforms a data map from Firestore into a format
  /// suitable for the local SQLite database.
  final Map<String, dynamic> Function(Map<String, dynamic> remoteData) remoteToLocalMapper;

  SyncCollectionConfig({
    required this.name,
    // By default, assume the data structures match and no transformation is needed.
    this.remoteToLocalMapper = _passthroughMapper,
  });

  /// A default mapper that simply returns the data as-is.
  static Map<String, dynamic> _passthroughMapper(Map<String, dynamic> data) => data;
}

class SyncService {
  final DbService _dbService = DbService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TimestampService _timestampService = TimestampService.instance;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // --- DYNAMIC SYNC CONFIGURATION ---
  // This list now drives the entire pull process. To sync a new collection,
  // simply add a new configuration object here.
  final List<SyncCollectionConfig> _collectionsToSync = [
    // For 'food_items', the Firestore and SQLite schemas match perfectly.
    // We can use the default passthrough mapper.
    SyncCollectionConfig(name: 'food_items'),

    // For 'meal_entries', we need to map the remote 'date' field
    // to the local 'createdAt' column.
    SyncCollectionConfig(
      name: 'meal_entries',
      remoteToLocalMapper: (remoteData) {
        // This function translates the Firestore data into the local schema.
        return {
          'id': remoteData['id'],
          'foodId': remoteData['foodId'],
          'foodName': remoteData['foodName'],
          'calories': remoteData['calories'],
          'updatedAt': remoteData['updatedAt'],
          // The critical mapping: Firestore 'date' -> SQLite 'createdAt'
          'createdAt': remoteData['date'] ?? remoteData['createdAt'] ?? 0,
        };
      },
    ),
    // To sync a new 'workouts' table in the future, you would just add:
    // SyncCollectionConfig(name: 'workouts', remoteToLocalMapper: _workoutMapper),
  ];
  // --- END CONFIGURATION ---

  Future<void> sync() async {
    print("Sync process started...");
    // These can be run in parallel for efficiency
    await Future.wait([
      _pullRemoteChanges(),
      _pushLocalChanges(),
    ]);
    print("Sync process finished.");
  }

  /// Pushes local changes from the 'outbox' to Firestore.
  /// This method is already dynamic as it reads the table name from the outbox item.
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
        final docRef = _firestore.collection('users').doc(userId).collection(tableName).doc(docId);
        if (operation == 'DELETE') {
          await docRef.delete();
        } else {
          await docRef.set(data, SetOptions(merge: true));
        }
        await db.delete('outbox', where: 'id = ?', whereArgs: [item['id']]);
      } catch (e) {
        print("Failed to sync item ${item['id']}: $e");
        continue;
      }
    }
  }

  /// Pulls remote changes from Firestore and saves them to the local database.
  /// UPDATED: This method is now fully dynamic and driven by the _collectionsToSync config.
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
      final Batch batch = db.batch();

      // Iterate over the configuration objects, not a hardcoded list of strings.
      for (final config in _collectionsToSync) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection(config.name)
            .where('updatedAt', isGreaterThan: lastSync)
            .get();

        print("Found ${snapshot.docs.length} updated documents in '${config.name}'.");
        for (var doc in snapshot.docs) {
          // Use the specific mapper for this collection to transform the data.
          final localData = config.remoteToLocalMapper(doc.data());

          // Insert the correctly formatted data into the local database.
          batch.insert(config.name, localData, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      await batch.commit(noResult: true);
      await _timestampService.updateLastSyncTimestamp();
    } catch (e) {
      print("Failed to pull remote changes: $e");
    }
  }
}