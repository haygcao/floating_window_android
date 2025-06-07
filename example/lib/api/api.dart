import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../model/github_event.dart';

Dio dio = Dio();

/// GitHub API client for fetching public events
class GitHubApi {
  static const String baseUrl = 'https://api.github.com';

  /// Fetch public events from GitHub
  static Future<List<GitHubEvent>> fetchPublicEvents({
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/events',
        queryParameters: {'page': page, 'per_page': perPage},
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'FloatingWindowApp/1.0',
          },
        ),
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('Failed to fetch GitHub events: ${response.statusCode}');
        }
        return [];
      }

      final List<dynamic> jsonData = response.data;
      return jsonData.map((json) => GitHubEvent.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching GitHub events: $e');
      }
      return [];
    }
  }

  /// Fetch events for a specific user
  static Future<List<GitHubEvent>> fetchUserEvents(
    String username, {
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/users/$username/events',
        queryParameters: {'page': page, 'per_page': perPage},
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'FloatingWindowApp/1.0',
          },
        ),
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print(
            'Failed to fetch user events for $username: ${response.statusCode}',
          );
        }
        return [];
      }

      final List<dynamic> jsonData = response.data;
      return jsonData.map((json) => GitHubEvent.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user events for $username: $e');
      }
      return [];
    }
  }

  /// Fetch events for a specific repository
  static Future<List<GitHubEvent>> fetchRepoEvents(
    String owner,
    String repo, {
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/repos/$owner/$repo/events',
        queryParameters: {'page': page, 'per_page': perPage},
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'FloatingWindowApp/1.0',
          },
        ),
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print(
            'Failed to fetch repo events for $owner/$repo: ${response.statusCode}',
          );
        }
        return [];
      }

      final List<dynamic> jsonData = response.data;
      return jsonData.map((json) => GitHubEvent.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching repo events for $owner/$repo: $e');
      }
      return [];
    }
  }

  /// Fetch trending repositories (using search API as approximation)
  static Future<List<Map<String, dynamic>>> fetchTrendingRepos({
    String language = '',
    String since = 'daily',
  }) async {
    try {
      final DateTime now = DateTime.now();
      final DateTime sinceDate =
          since == 'weekly'
              ? now.subtract(const Duration(days: 7))
              : now.subtract(const Duration(days: 1));

      final String dateQuery =
          'created:>${sinceDate.toIso8601String().split('T')[0]}';
      final String langQuery = language.isNotEmpty ? 'language:$language' : '';
      final String query = '$dateQuery $langQuery'.trim();

      final response = await dio.get(
        '$baseUrl/search/repositories',
        queryParameters: {
          'q': query,
          'sort': 'stars',
          'order': 'desc',
          'per_page': 20,
        },
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'FloatingWindowApp/1.0',
          },
        ),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final Map<String, dynamic> data = response.data;
      final List<dynamic> items = data['items'] ?? [];
      return items.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching trending repos: $e');
      }
      return [];
    }
  }
}
