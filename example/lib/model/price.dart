import 'dart:convert';

class Price {
  final String symbol;
  final String price;
  bool selected;

  Price({required this.symbol, required this.price, this.selected = false});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(symbol: json['symbol'], price: json['price']);
  }

  Map<String, dynamic> toJson() {
    return {'symbol': symbol, 'price': price, 'selected': selected};
  }

  // 创建一个带有不同selected值的新Price对象
  Price copyWith({bool? selected}) {
    return Price(
      symbol: symbol,
      price: price,
      selected: selected ?? this.selected,
    );
  }

  // 将List<Price>转换为JSON字符串
  static String encodeList(List<Price> prices) {
    return jsonEncode(prices.map((price) => price.toJson()).toList());
  }

  // 从JSON字符串解析List<Price>
  static List<Price> decodeList(String jsonString) {
    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Price.fromJson(json)).toList();
  }
}
