import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../model/price.dart';

Dio dio = Dio();

class Api {
  static Future<Price> fetchPrice(String symbol) async {
    final response = await dio.get(
      'https://api.binance.com/api/v3/ticker/price?symbol=$symbol',
    );

    if (response.statusCode != 200) {
      return Price(symbol: '', price: '');
    }

    final jsonData = response.data;
    if (jsonData is Map) {
      return Price.fromJson(jsonData as Map<String, dynamic>);
    } else {
      return Price(symbol: '', price: '');
    }
  }

  static Future<List<Price>> fetchData() async {
    final response = await dio.get(
      'https://api.binance.com/api/v3/ticker/price',
    );

    if (response.statusCode != 200) {
      return [];
    }

    final jsonData = response.data;
    if (jsonData is List) {
      return jsonData.map((e) => Price.fromJson(e)).toList().cast<Price>();
    } else {
      if (kDebugMode) {
        print(
          "Unexpected data format received from API: ${jsonData.runtimeType}",
        );
      }
      return [];
    }
  }
}
