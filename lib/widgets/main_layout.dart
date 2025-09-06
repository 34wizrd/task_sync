import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/network/connectivity_notifier.dart';
import '../core/network/sync_notifier.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;

  const MainLayout({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Column(
        children: [
          // This consistent sync bar appears on every screen using this layout.
          const _SyncBar(),
          // The screen's content fills the remaining space.
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// A private widget for displaying the sync status bar.
class _SyncBar extends StatelessWidget {
  const _SyncBar();

  @override
  Widget build(BuildContext context) {
    final isConnected = context.watch<ConnectivityNotifier>().isOnline;
    final isSyncing = context.watch<SyncNotifier>().isSyncing;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isConnected ? 24 : 0,
      width: double.infinity,
      color: isSyncing ? Colors.blueAccent : Colors.green,
      child: isConnected
          ? Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(isSyncing ? Icons.sync : Icons.cloud_done, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(isSyncing ? "Syncing..." : "Online", style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      )
          : null,
    );
  }
}