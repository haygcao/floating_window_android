import 'package:floating_window_android/floating_window_android.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../model/github_event.dart';
import '../api/api.dart';
import '../widgets/github_event_list_item.dart';

/// Overlay window displaying selected GitHub events
class OverlayWindow extends StatefulWidget {
  const OverlayWindow({super.key});

  @override
  State<OverlayWindow> createState() => _OverlayWindowState();
}

class _OverlayWindowState extends State<OverlayWindow> {
  List<GitHubEvent> _events = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  List<String> _selectedEventIds = [];
  int _failureCount = 0;

  // Use same key names as main app
  static const String _selectedItemsKey = "selected_events";
  static const String _selectedEventsDataKey = "selected_events_data";

  // GitHub theme colors
  static const Color kGitHubColor = Color(0xFF24292e);
  static const Color kGreenColor = Color(0xFF28a745);

  @override
  void initState() {
    super.initState();
    debugPrint('Overlay window initializing...');
    _loadSelectedEvents();

    // Set timer to refresh data every 5 minutes to reduce API calls
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      // Adjust refresh frequency based on failure count
      if (_failureCount > 3) {
        debugPrint('Skipping refresh due to multiple failures');
        _failureCount--; // Gradually reduce failure count
        return;
      }

      _refreshData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Refresh GitHub events data
  Future<void> _refreshData() async {
    if (_selectedEventIds.isEmpty) {
      debugPrint('No selected events, cannot refresh data');
      return;
    }

    // Skip if already loading
    if (_isLoading) {
      debugPrint('Already loading, skipping refresh');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    debugPrint('Overlay window starting data refresh...');

    try {
      // Fetch latest public events
      final latestEvents = await GitHubApi.fetchPublicEvents(perPage: 50);

      // Filter to only include selected events that are still in the latest feed
      final updatedEvents = <GitHubEvent>[];
      int foundCount = 0;

      for (final selectedId in _selectedEventIds) {
        final foundEvent = latestEvents.firstWhere(
          (event) => event.id == selectedId,
          orElse:
              () => _events.firstWhere(
                (event) => event.id == selectedId,
                orElse:
                    () => GitHubEvent(
                      id: selectedId,
                      type: 'Unknown',
                      actorLogin: 'Unknown',
                      actorAvatarUrl: '',
                      repoName: 'Event not found',
                      repoUrl: '',
                      createdAt: DateTime.now(),
                    ),
              ),
        );

        if (foundEvent.id == selectedId) {
          updatedEvents.add(foundEvent.copyWith(selected: true));
          if (latestEvents.any((e) => e.id == selectedId)) {
            foundCount++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _events = updatedEvents;
          _isLoading = false;
        });

        if (foundCount < _selectedEventIds.length) {
          _failureCount++;
          debugPrint(
            'Data refresh completed, found: $foundCount/${_selectedEventIds.length}, failure count: $_failureCount',
          );
        } else {
          _failureCount = 0; // Reset failure count
          debugPrint(
            'Data refresh completed successfully, events: ${_events.length}',
          );
        }
      }
    } catch (e) {
      debugPrint('Error refreshing GitHub events: $e');
      _failureCount++;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Load selected events from SharedPreferences
  Future<void> _loadSelectedEvents() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('Loading data from SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();

      // Try to get complete data from 'selected_events_data'
      final selectedEventsJson = prefs.getString(_selectedEventsDataKey);

      // Get selected event IDs list
      _selectedEventIds = prefs.getStringList(_selectedItemsKey) ?? [];

      debugPrint('Retrieved selected event IDs: $_selectedEventIds');

      if (selectedEventsJson != null) {
        debugPrint('Loading event data from cache...');
        final loadedEvents = GitHubEvent.decodeList(selectedEventsJson);
        setState(() {
          _events = loadedEvents;
          _isLoading = false;
        });

        debugPrint('Loaded ${loadedEvents.length} events from cache');

        // Refresh data after 10 seconds to prioritize cached data for better UX
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted) {
            debugPrint('Starting delayed data refresh...');
            _refreshData();
          }
        });
      } else if (_selectedEventIds.isNotEmpty) {
        debugPrint(
          'No cached event data but have selected IDs, fetching latest data',
        );
        _fetchLatestData();
      } else {
        debugPrint('No selected events, cannot load data');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading event data: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Fetch latest GitHub events data
  Future<void> _fetchLatestData() async {
    if (_selectedEventIds.isEmpty) {
      debugPrint('No selected events, cannot fetch latest data');
      setState(() {
        _isLoading = false;
        _events = []; // Ensure list is empty to show "No data"
      });
      return;
    }

    debugPrint('Fetching latest GitHub events data...');
    final List<GitHubEvent> updatedEvents = [];
    bool hasError = false;

    try {
      // Fetch latest public events
      final latestEvents = await GitHubApi.fetchPublicEvents(perPage: 100);

      for (final eventId in _selectedEventIds) {
        final foundEvent = latestEvents.firstWhere(
          (event) => event.id == eventId,
          orElse:
              () => GitHubEvent(
                id: eventId,
                type: 'NotFound',
                actorLogin: 'Unknown',
                actorAvatarUrl: '',
                repoName: 'Event not found in recent feed',
                repoUrl: '',
                createdAt: DateTime.now(),
              ),
        );

        updatedEvents.add(foundEvent.copyWith(selected: true));

        if (foundEvent.type == 'NotFound') {
          hasError = true;
        }
      }
    } catch (e) {
      debugPrint('Error fetching latest events: $e');
      // Add error placeholder data
      for (final eventId in _selectedEventIds) {
        updatedEvents.add(
          GitHubEvent(
            id: eventId,
            type: 'Error',
            actorLogin: 'Error',
            actorAvatarUrl: '',
            repoName: 'Failed to fetch',
            repoUrl: '',
            createdAt: DateTime.now(),
          ),
        );
      }
      hasError = true;
    }

    if (mounted) {
      setState(() {
        _events = updatedEvents;
        _isLoading = false;
      });
      debugPrint('Loaded ${updatedEvents.length} latest event data');

      if (hasError && updatedEvents.isNotEmpty) {
        // If there are errors but some data was retrieved, retry after 30 seconds
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) {
            _refreshData();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: kGitHubColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Stack(
          children: [
            // Close button (top right)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    await FloatingWindowAndroid.closeOverlayFromOverlay();
                  },
                ),
              ),
            ),

            // Refresh button (top left)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              kGreenColor,
                            ),
                          ),
                        )
                        : IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 16,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _refreshData();
                          },
                        ),
              ),
            ),

            // GitHub Events list
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 32, 8, 8),
              child:
                  _events.isEmpty
                      ? _isLoading
                          ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  kGreenColor,
                                ),
                              ),
                            ),
                          )
                          : const Center(
                            child: Text(
                              "No events selected",
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          return CompactGitHubEventItem(
                            event: _events[index],
                            onTap: () => _handleEventTap(_events[index]),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle tapping on an event in the overlay
  Future<void> _handleEventTap(GitHubEvent event) async {
    bool isError = event.type == 'Error' || event.type == 'NotFound';

    if (isError) {
      debugPrint('Tapped error item, attempting to refresh data');
      _refreshData();
      return;
    }

    debugPrint('Tapped overlay event: ${event.id}, actor: ${event.actorLogin}');

    try {
      // Check if main app is already running in foreground
      final isMainAppRunning = await FloatingWindowAndroid.isMainAppRunning();

      if (isMainAppRunning) {
        debugPrint('Main app is already running in foreground, not navigating');
        return;
      }

      final result = await FloatingWindowAndroid.openMainApp({
        'name': event.id,
      });

      debugPrint('Open main app result: $result');
    } catch (e) {
      debugPrint('Error opening main app: $e');
    }
  }
}
