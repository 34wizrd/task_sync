import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/connectivity_notifier.dart';
import '../../core/network/sync_notifier.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String? title; // ADDED: To be used in the AppBar
  final Widget? fab;   // ADDED: For the FloatingActionButton

  const MainLayout({
    super.key,
    required this.child,
    this.title,
    this.fab,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap the content in a Scaffold to provide standard app structure.
    return Scaffold(
      appBar: title != null
          ? AppBar(
        title: Text(title!),
        elevation: 1,
      )
          : null,
      floatingActionButton: fab,
      body: Column(
        children: [
          // The connectivity/sync status bar remains at the top.
          const _SyncBar(),
          // The page body is expanded to fill the remaining space.
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// A private widget for the sync bar to keep the build method clean.
class _SyncBar extends StatelessWidget {
  const _SyncBar();

  @override
  Widget build(BuildContext context) {
    // Consume state from providers to drive the UI.
    final isConnected = context.watch<ConnectivityNotifier>().isOnline;
    final syncNotifier = context.watch<SyncNotifier>();
    final isSyncing = syncNotifier.isSyncing;
    final pending = syncNotifier.pending;

    return Container(
      width: double.infinity,
      color: isSyncing
          ? Colors.blue // syncing
          : isConnected
          ? Colors.green // online
          : Colors.grey, // offline
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Display pending changes if there are any and we are not syncing.
          if (pending > 0 && !isSyncing) ...[
            Text(
              '$pending pending',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 8),
          ],
          Icon(
            isSyncing
                ? Icons.sync
                : isConnected
                ? Icons.wifi
                : Icons.wifi_off,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            isSyncing
                ? "Syncing..."
                : isConnected
                ? "Online"
                : "Offline",
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}