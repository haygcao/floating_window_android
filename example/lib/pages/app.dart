import 'package:floating_window_android/constants.dart';
import 'package:floating_window_android/floating_window_android.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../model/price.dart';
import '../widgets/price_list_item.dart';
import 'permission.dart';

import 'detail.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static const String channelName = Constants.navigationEventChannel;
  late MethodChannel _channel;

  List<Price> _prices = [];

  static const String _selectedItemsKey = "selected_symbols";
  static const String _selectedPricesDataKey = "selected_prices_data";

  List<GlobalKey<PriceListItemState>> _itemKeys = [];

  bool _permissionDialogShown = false; // 添加变量跟踪弹窗状态

  @override
  void initState() {
    super.initState();

    // 初始化方法通道
    _channel = const MethodChannel(channelName);
    _channel.setMethodCallHandler(_handleMethodCall);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkPermission();
      await _fetchData();
    });
  }

  Future<void> _checkPermission() async {
    // 如果弹窗已经显示过，不再重复显示
    if (_permissionDialogShown) return;

    // 检查权限
    bool permission = await FloatingWindowAndroid.isPermissionGranted();

    if (!permission && _navigatorKey.currentContext != null) {
      // 如果没有权限，显示弹窗
      _permissionDialogShown = true; // 标记弹窗已显示
      showDialog(
        context: _navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) => const PermissionDialog(),
      ).then((_) {
        // 弹窗关闭后，隔一段时间再允许显示
        Future.delayed(const Duration(seconds: 5), () {
          _permissionDialogShown = false;
        });
      });
    }
  }

  // 处理从原生平台传递的方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint('收到方法调用: ${call.method}，参数: ${call.arguments}');

    if (call.method == Constants.navigateToPage) {
      final String? name = call.arguments['name'] as String?;

      debugPrint('准备导航到Detail页面，参数 name: $name');

      if (name != null) {
        if (!mounted) {
          debugPrint('组件已卸载，取消导航');
          return;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          debugPrint('执行导航操作');
          try {
            _navigateToDetail(name);
          } catch (e) {
            debugPrint('导航时发生错误: $e');
          }
        });
      } else {
        debugPrint('导航参数不完整，取消导航');
      }
    }
    return null;
  }

  void _navigateToDetail(String symbol) {
    final NavigatorState? navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    var item = _prices.firstWhere((element) => element.symbol == symbol);

    navigator.popUntil((route) => route.isFirst);

    navigator.push(
      MaterialPageRoute(
        builder: (context) => Detail(name: item.symbol, value: item.price),
      ),
    );

    debugPrint('已导航到详情页，symbol = $symbol');
  }

  Future<void> _showOverlay() async {
    bool permission = await FloatingWindowAndroid.isPermissionGranted();
    if (!permission) {
      debugPrint("无法显示悬浮窗，权限被拒绝。");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("请前往设置开启悬浮窗权限")));
      bool requested = await FloatingWindowAndroid.requestPermission();
      if (!requested) {
        debugPrint("请求权限失败或用户未授予权限。");
        return;
      }
      permission = await FloatingWindowAndroid.isPermissionGranted();
      if (!permission) return;
    }

    // 先保存选中的项目到SharedPreferences
    await _saveSelectedItems();

    // 保存完整的价格数据给悬浮窗使用
    await _saveSelectedPriceData();

    // Check if overlay is already showing
    bool isShowing = await FloatingWindowAndroid.isShowing();
    if (isShowing) {
      debugPrint("悬浮窗已在显示中。");
      return;
    }

    final selectedItems = _prices.where((item) => item.selected).toList();
    if (selectedItems.isEmpty) {
      debugPrint("没有选中的项目，不显示悬浮窗。");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("请选择至少一个项目以显示悬浮窗")));
      return;
    }

    // ignore: use_build_context_synchronously
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final width = (115 * devicePixelRatio).toInt();
    final height = (70 * selectedItems.length * devicePixelRatio).toInt() + 150;

    bool? res = await FloatingWindowAndroid.showOverlay(
      height: height,
      width: width,
      alignment: OverlayAlignment.center,
      flag: OverlayFlag.defaultFlag,
      enableDrag: true,
      positionGravity: PositionGravity.none,
      overlayTitle: "情报监控",
      overlayContent: "您的情报监控已开启",
      notificationVisibility: NotificationVisibility.visibilityPublic,
    );
    debugPrint("show overlay ${res.toString()}");
  }

  // 保存完整的价格数据，供悬浮窗使用
  Future<void> _saveSelectedPriceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedItems = _prices.where((item) => item.selected).toList();
      final selectedItemsJson = Price.encodeList(selectedItems);

      // 保存完整的价格数据
      await prefs.setString(_selectedPricesDataKey, selectedItemsJson);
      debugPrint('已保存${selectedItems.length}个选中项的完整数据');
    } catch (e) {
      debugPrint('保存价格数据时出错: $e');
    }
  }

  Future<void> _fetchData() async {
    final pricesResult = await Api.fetchData();
    debugPrint('获取数据完成，数据长度: ${Price.encodeList(pricesResult)}');

    List<Price> filterResult =
        pricesResult
            .where(
              (item) =>
                  num.parse(num.parse(item.price).toStringAsFixed(4)) != 0,
            )
            .map(
              (item) => Price(
                symbol: item.symbol,
                price: num.parse(item.price).toStringAsFixed(4),
              ),
            )
            .toList();

    await _loadSelectedItems(filterResult);

    setState(() {
      _prices = filterResult;
      _itemKeys = List.generate(
        _prices.length,
        (_) => GlobalKey<PriceListItemState>(),
      );
    });
  }

  Future<void> _loadSelectedItems(List<Price> prices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedSymbols = prefs.getStringList(_selectedItemsKey) ?? [];

      for (var i = 0; i < prices.length; i++) {
        if (selectedSymbols.contains(prices[i].symbol)) {
          prices[i].selected = true;
        } else {
          prices[i].selected = false;
        }
      }
    } catch (e) {
      debugPrint('加载选择状态时出错: $e');
    }
  }

  Future<void> _saveSelectedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedSymbols =
          _prices
              .where((price) => price.selected)
              .map((price) => price.symbol)
              .toList();

      await prefs.setStringList(_selectedItemsKey, selectedSymbols);
      debugPrint('已保存${selectedSymbols.length}个选中的符号');
    } catch (e) {
      debugPrint('保存选择状态时出错: $e');
    }
  }

  void _toggleItemSelection(int index) {
    final isCurrentlySelected = _prices[index].selected;
    final selectedCount = _prices.where((price) => price.selected).length;

    if (!isCurrentlySelected && selectedCount >= 5) {
      _itemKeys[index].currentState?.shake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("最多只能选择5个项目"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _prices[index].selected = !isCurrentlySelected;
    });
    _saveSelectedItems();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E88E5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('情报监控'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: _showOverlay,
            ),
          ],
        ),
        body:
            _prices.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _prices.length,
                  itemBuilder: (context, index) {
                    final item = _prices[index];
                    return PriceListItem(
                      key: _itemKeys[index],
                      item: item,
                      isSelected: item.selected,
                      onTap: () {
                        _navigateToDetail(item.symbol);
                      },
                      onToggleSelection: (value) {
                        _toggleItemSelection(index);
                      },
                    );
                  },
                ),
      ),
    );
  }
}
