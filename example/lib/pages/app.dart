import 'package:floating_window_android/constants.dart';
import 'package:floating_window_android/floating_window_android.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../model/github_event.dart';
import '../widgets/github_event_list_item.dart';
import 'permission.dart';
import 'detail.dart';

/// Main application widget showing GitHub events
class App extends StatefulWidget {
  const App({super.key});

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> with SingleTickerProviderStateMixin {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static const String channelName = Constants.navigationEventChannel;
  late MethodChannel _channel;
  late TabController _tabController;

  List<GitHubEvent> _events = [];
  List<Map<String, dynamic>> _trendingRepos = [];
  bool _isLoading = false;
  String _currentTab = 'public'; // 'public', 'user', 'trending'

  static const String _selectedItemsKey = "selected_events";
  static const String _selectedEventsDataKey = "selected_events_data";
  static const String _userInputKey = "github_username";

  List<GlobalKey<GitHubEventListItemState>> _itemKeys = [];
  bool _permissionDialogShown = false;

  final TextEditingController _usernameController = TextEditingController();
  String _currentUsername = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize method channel
    _channel = const MethodChannel(channelName);
    _channel.setMethodCallHandler(_handleMethodCall);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkPermission();
      await _loadSavedUsername();
      await _fetchData();

      // Preload Flutter engine for faster overlay startup
      await FloatingWindowAndroid.preloadFlutterEngine();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    // Clean up preloaded Flutter engine
    FloatingWindowAndroid.cleanupPreloadedEngine();
    super.dispose();
  }

  Future<void> _loadSavedUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString(_userInputKey) ?? '';
      setState(() {
        _currentUsername = savedUsername;
        _usernameController.text = savedUsername;
      });
    } catch (e) {
      debugPrint('Error loading saved username: $e');
    }
  }

  Future<void> _saveUsername(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userInputKey, username);
      setState(() {
        _currentUsername = username;
      });
    } catch (e) {
      debugPrint('Error saving username: $e');
    }
  }

  Future<void> _checkPermission() async {
    // If dialog already shown, don't show again
    if (_permissionDialogShown) return;

    // Check permission
    bool permission = await FloatingWindowAndroid.isPermissionGranted();

    if (!permission && _navigatorKey.currentContext != null) {
      // If no permission, show dialog
      _permissionDialogShown = true;
      showDialog(
        context: _navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) => const PermissionDialog(),
      ).then((_) {
        // Allow showing dialog again after some time
        Future.delayed(const Duration(seconds: 5), () {
          _permissionDialogShown = false;
        });
      });
    }
  }

  // Handle method calls from native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint(
      'Received method call: ${call.method}, arguments: ${call.arguments}',
    );

    if (call.method == Constants.navigateToPage) {
      final String? eventId = call.arguments['name'] as String?;

      debugPrint('Preparing to navigate to Detail page, event ID: $eventId');

      if (eventId != null) {
        if (!mounted) {
          debugPrint('Widget unmounted, canceling navigation');
          return;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          debugPrint('Executing navigation');
          try {
            _navigateToDetail(eventId);
          } catch (e) {
            debugPrint('Navigation error: $e');
          }
        });
      } else {
        debugPrint('Navigation parameters incomplete, canceling navigation');
      }
    }
    return null;
  }

  void _navigateToDetail(String eventId) {
    final NavigatorState? navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    final event = _events.firstWhere(
      (element) => element.id == eventId,
      orElse:
          () =>
              _events.isNotEmpty
                  ? _events.first
                  : GitHubEvent(
                    id: eventId,
                    type: 'Unknown',
                    actorLogin: 'Unknown',
                    actorAvatarUrl: '',
                    repoName: 'Unknown',
                    repoUrl: '',
                    createdAt: DateTime.now(),
                  ),
    );

    navigator.popUntil((route) => route.isFirst);

    navigator.push(
      MaterialPageRoute(
        builder:
            (context) =>
                Detail(name: event.actorLogin, value: event.description),
      ),
    );

    debugPrint('Navigated to detail page, event ID = $eventId');
  }

  Future<void> _showOverlay() async {
    bool permission = await FloatingWindowAndroid.isPermissionGranted();
    if (!permission) {
      debugPrint("Cannot show floating window, permission denied.");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enable floating window permission in settings"),
        ),
      );
      bool requested = await FloatingWindowAndroid.requestPermission();
      if (!requested) {
        debugPrint("Permission request failed or user denied permission.");
        return;
      }
      permission = await FloatingWindowAndroid.isPermissionGranted();
      if (!permission) return;
    }

    // Save selected items to SharedPreferences first
    await _saveSelectedItems();

    // Save complete event data for floating window use
    await _saveSelectedEventData();

    // Check if overlay is already showing
    bool isShowing = await FloatingWindowAndroid.isShowing();
    if (isShowing) {
      debugPrint("Floating window is already showing.");
      return;
    }

    final selectedItems = _events.where((item) => item.selected).toList();
    if (selectedItems.isEmpty) {
      debugPrint("No selected items, not showing floating window.");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select at least one event to display floating window",
          ),
        ),
      );
      return;
    }

    // ignore: use_build_context_synchronously
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final width = (200 * devicePixelRatio).toInt();
    final height = (50 * selectedItems.length * devicePixelRatio).toInt() + 100;

    bool? res = await FloatingWindowAndroid.showOverlay(
      height: height,
      width: width,
      alignment: OverlayAlignment.center,
      flag: OverlayFlag.defaultFlag,
      enableDrag: true,
      positionGravity: PositionGravity.none,
      overlayTitle: "GitHub Events Monitor",
      overlayContent: "Your GitHub events monitor is active",
      notificationVisibility: NotificationVisibility.visibilityPublic,
    );
    debugPrint("show overlay ${res.toString()}");
  }

  // Save complete event data for floating window use
  Future<void> _saveSelectedEventData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedItems = _events.where((item) => item.selected).toList();
      final selectedItemsJson = GitHubEvent.encodeList(selectedItems);

      // Save complete event data
      await prefs.setString(_selectedEventsDataKey, selectedItemsJson);
      debugPrint(
        'Saved complete data for ${selectedItems.length} selected events',
      );
    } catch (e) {
      debugPrint('Error saving event data: $e');
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<GitHubEvent> eventsResult = [];

      switch (_currentTab) {
        case 'public':
          eventsResult = await GitHubApi.fetchPublicEvents();
          break;
        case 'user':
          if (_currentUsername.isNotEmpty) {
            eventsResult = await GitHubApi.fetchUserEvents(_currentUsername);
          }
          break;
        case 'trending':
          final trendingResult = await GitHubApi.fetchTrendingRepos();
          setState(() {
            _trendingRepos = trendingResult;
          });
          break;
      }

      if (_currentTab != 'trending') {
        debugPrint('Data fetch complete, event count: ${eventsResult.length}');

        await _loadSelectedItems(eventsResult);

        setState(() {
          _events = eventsResult;
          _itemKeys = List.generate(
            _events.length,
            (_) => GlobalKey<GitHubEventListItemState>(),
          );
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSelectedItems(List<GitHubEvent> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedEventIds = prefs.getStringList(_selectedItemsKey) ?? [];

      for (var i = 0; i < events.length; i++) {
        if (selectedEventIds.contains(events[i].id)) {
          events[i].selected = true;
        } else {
          events[i].selected = false;
        }
      }
    } catch (e) {
      debugPrint('Error loading selection state: $e');
    }
  }

  Future<void> _saveSelectedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedEventIds =
          _events
              .where((event) => event.selected)
              .map((event) => event.id)
              .toList();

      await prefs.setStringList(_selectedItemsKey, selectedEventIds);
      debugPrint('Saved ${selectedEventIds.length} selected event IDs');
    } catch (e) {
      debugPrint('Error saving selection state: $e');
    }
  }

  void _toggleItemSelection(int index) {
    final isCurrentlySelected = _events[index].selected;
    final selectedCount = _events.where((event) => event.selected).length;

    if (!isCurrentlySelected && selectedCount >= 5) {
      _itemKeys[index].currentState?.shake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Maximum 5 events can be selected"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _events[index].selected = !isCurrentlySelected;
    });
    _saveSelectedItems();
  }

  void _showUserInputDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter GitHub Username'),
            content: TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                hintText: 'e.g. octocat',
                labelText: 'Username',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final username = _usernameController.text.trim();
                  if (username.isNotEmpty) {
                    _saveUsername(username);
                    _fetchData();
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildTrendingReposList() {
    if (_trendingRepos.isEmpty) {
      return const Center(child: Text('No trending repositories found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _trendingRepos.length,
      itemBuilder: (context, index) {
        final repo = _trendingRepos[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: const Icon(Icons.star, color: Colors.orange),
            title: Text(
              repo['full_name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (repo['description'] != null)
                  Text(
                    repo['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${repo['stargazers_count'] ?? 0}'),
                    const SizedBox(width: 16),
                    const Icon(Icons.code, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(repo['language'] ?? 'Unknown'),
                  ],
                ),
              ],
            ),
            onTap: () {
              // Navigate to repository detail or open URL
              debugPrint('Tapped on repo: ${repo['full_name']}');
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        primaryColor: const Color(0xFF24292e),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF24292e),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF24292e),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('GitHub Events Monitor'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
          actions: [
            if (_currentTab == 'user')
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: _showUserInputDialog,
              ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: _showOverlay,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            onTap: (index) {
              setState(() {
                _currentTab = ['public', 'user', 'trending'][index];
              });
              _fetchData();
            },
            tabs: const [
              Tab(text: 'Public', icon: Icon(Icons.public)),
              Tab(text: 'User', icon: Icon(Icons.person)),
              Tab(text: 'Trending', icon: Icon(Icons.trending_up)),
            ],
          ),
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentTab == 'trending'
                ? _buildTrendingReposList()
                : _events.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentTab == 'user' && _currentUsername.isEmpty
                            ? 'Please enter a GitHub username'
                            : 'No events found',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      if (_currentTab == 'user' && _currentUsername.isEmpty)
                        const SizedBox(height: 16),
                      if (_currentTab == 'user' && _currentUsername.isEmpty)
                        ElevatedButton(
                          onPressed: _showUserInputDialog,
                          child: const Text('Enter Username'),
                        ),
                    ],
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return GitHubEventListItem(
                      key: _itemKeys[index],
                      event: event,
                      isSelected: event.selected,
                      onTap: () {
                        _navigateToDetail(event.id);
                      },
                      onToggleSelection: () {
                        _toggleItemSelection(index);
                      },
                    );
                  },
                ),
      ),
    );
  }
}
