import 'package:floating_window_android/floating_window_android.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../model/price.dart';
import '../api/api.dart';

class OverlayWindow extends StatefulWidget {
  const OverlayWindow({super.key});

  @override
  State<OverlayWindow> createState() => _OverlayWindowState();
}

class _OverlayWindowState extends State<OverlayWindow> {
  List<Price> _prices = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  List<String> _selectedSymbols = [];
  int _failureCount = 0; // 添加失败计数

  // 使用与主应用相同的键名
  static const String _selectedItemsKey = "selected_symbols";
  static const String _selectedPricesDataKey = "selected_prices_data";

  // 绿色文本颜色
  static const Color kGreenColor = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    debugPrint('悬浮窗初始化...');
    _loadSelectedPrices();

    // 设置定时器，每60秒刷新一次数据，减少请求频率
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      // 根据失败次数调整刷新频率
      if (_failureCount > 3) {
        debugPrint('由于多次请求失败，本次刷新跳过');
        _failureCount--; // 逐渐减少失败计数
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

  // 刷新数据
  Future<void> _refreshData() async {
    if (_selectedSymbols.isEmpty) {
      debugPrint('没有选中的符号，无法刷新数据');
      return;
    }

    // 如果已经在加载中，跳过本次刷新
    if (_isLoading) {
      debugPrint('已经在加载中，跳过本次刷新');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    debugPrint('悬浮窗开始刷新数据...');
    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < _prices.length; i++) {
      try {
        final updatedPrice = await Api.fetchPrice(_prices[i].symbol);
        debugPrint('获取${_prices[i].symbol}价格结果: ${updatedPrice.price}');
        if (updatedPrice.price.isNotEmpty &&
            updatedPrice.price != _prices[i].price) {
          _prices[i] = Price(
            symbol: _prices[i].symbol,
            price: num.parse(updatedPrice.price).toStringAsFixed(4),
            selected: true,
          );
          successCount++;
        } else if (updatedPrice.price.isNotEmpty) {
          // 数据获取成功但价格未变
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        debugPrint('获取${_prices[i].symbol}价格时出错: $e');
        failCount++;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (failCount > 0) {
        _failureCount++;
        debugPrint(
          '数据刷新完成，成功:$successCount，失败:$failCount，累计失败次数:$_failureCount',
        );
      } else {
        _failureCount = 0; // 重置失败计数
        debugPrint('数据刷新完成，全部成功，数据项数: ${_prices.length}');
      }
    }
  }

  Future<void> _loadSelectedPrices() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('开始从SharedPreferences加载数据...');
      final prefs = await SharedPreferences.getInstance();

      // 先尝试从 'selected_prices_data' 获取完整数据
      final selectedPricesJson = prefs.getString(_selectedPricesDataKey);

      // 获取选中的符号列表
      _selectedSymbols = prefs.getStringList(_selectedItemsKey) ?? [];

      debugPrint('获取到的选中符号列表: $_selectedSymbols');

      if (selectedPricesJson != null) {
        debugPrint('从缓存加载价格数据...');
        final loadedPrices = Price.decodeList(selectedPricesJson);
        setState(() {
          _prices = loadedPrices;
          _isLoading = false;
        });

        debugPrint('从缓存加载了 ${loadedPrices.length} 个价格项');

        // 5秒后再刷新数据，优先显示缓存数据提升用户体验
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            debugPrint('延迟5秒后开始刷新数据...');
            _refreshData();
          }
        });
      } else if (_selectedSymbols.isNotEmpty) {
        debugPrint('没有缓存的价格数据，但有选中的符号，直接获取最新数据');
        // 如果没有缓存的价格数据但有选中的符号，则直接获取最新数据
        _fetchLatestData();
      } else {
        debugPrint('没有选中的符号，无法加载数据');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('加载价格数据时出错: $e');
      setState(() => _isLoading = false);
    }
  }

  // 获取最新的价格数据
  Future<void> _fetchLatestData() async {
    if (_selectedSymbols.isEmpty) {
      debugPrint('没有选中的符号，无法获取最新数据');
      setState(() {
        _isLoading = false;
        _prices = []; // 确保列表为空，显示"暂无数据"
      });
      return;
    }

    debugPrint('开始获取最新价格数据...');
    final List<Price> updatedPrices = [];
    bool hasError = false;

    for (final symbol in _selectedSymbols) {
      try {
        debugPrint('获取$symbol的最新价格...');
        final price = await Api.fetchPrice(symbol);
        debugPrint('获取到$symbol的价格: ${price.price}');
        if (price.symbol.isNotEmpty && price.price.isNotEmpty) {
          updatedPrices.add(
            Price(
              symbol: symbol, // 使用原符号，避免API返回的符号不一致
              price: num.parse(price.price).toStringAsFixed(4),
              selected: true,
            ),
          );
        } else {
          // 如果API返回空数据，添加一个占位数据
          updatedPrices.add(
            Price(symbol: symbol, price: '0.0000', selected: true),
          );
          hasError = true;
        }
      } catch (e) {
        debugPrint('获取$symbol价格时出错: $e');
        // 添加错误占位数据
        updatedPrices.add(Price(symbol: symbol, price: '获取失败', selected: true));
        hasError = true;
      }
    }

    if (mounted) {
      setState(() {
        _prices = updatedPrices;
        _isLoading = false;
      });
      debugPrint('已加载 ${updatedPrices.length} 个最新价格数据');

      if (hasError && updatedPrices.isNotEmpty) {
        // 如果有错误但获取到了部分数据，1秒后重试
        Future.delayed(const Duration(seconds: 1), () {
          _refreshData();
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
          color: Colors.black.withValues(alpha: .75),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // 关闭按钮（右上角）
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

            // 刷新按钮（左上角）
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

            // 价格列表
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child:
                  _prices.isEmpty
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
                              "暂无数据",
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                      : Column(
                        mainAxisSize: MainAxisSize.min,
                        children:
                            _prices
                                .map((item) => _buildPriceItem(item))
                                .toList(),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建价格项，简化为只显示 symbol 和 price
  Widget _buildPriceItem(Price item) {
    bool isError = item.price == '获取失败';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: () async {
          if (isError) {
            debugPrint('点击了错误项，尝试刷新数据');
            _refreshData();
            return;
          }

          debugPrint('点击悬浮窗项目: ${item.symbol}, 价格: ${item.price}');

          try {
            // 先检查主应用是否已经在前台运行
            final isMainAppRunning =
                await FloatingWindowAndroid.isMainAppRunning();

            if (isMainAppRunning) {
              debugPrint('主应用已经在前台运行，不再导航');
              // 可以显示一个提示，例如使用Toast或者Flushbar
              return;
            }

            final result = await FloatingWindowAndroid.openMainApp({
              'name': item.symbol,
            });

            debugPrint('打开主应用结果: $result');
          } catch (e) {
            debugPrint('打开主应用时出错: $e');
          }
        },
        child: Column(
          children: [
            // 货币符号名称
            Text(
              item.symbol,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),

            // 价格
            Text(
              item.price,
              style: TextStyle(
                fontSize: 18,
                color: isError ? Colors.red : kGreenColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
