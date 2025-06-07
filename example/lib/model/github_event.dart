import 'dart:convert';

/// GitHub Event model representing various GitHub events
class GitHubEvent {
  final String id;
  final String type;
  final String actorLogin;
  final String actorAvatarUrl;
  final String repoName;
  final String repoUrl;
  final DateTime createdAt;
  final Map<String, dynamic>? payload;
  bool selected;

  GitHubEvent({
    required this.id,
    required this.type,
    required this.actorLogin,
    required this.actorAvatarUrl,
    required this.repoName,
    required this.repoUrl,
    required this.createdAt,
    this.payload,
    this.selected = false,
  });

  /// Create GitHubEvent from JSON response
  factory GitHubEvent.fromJson(Map<String, dynamic> json) {
    return GitHubEvent(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      actorLogin: json['actor']?['login'] ?? '',
      actorAvatarUrl: json['actor']?['avatar_url'] ?? '',
      repoName: json['repo']?['name'] ?? '',
      repoUrl: json['repo']?['url'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      payload: json['payload'],
    );
  }

  /// Convert GitHubEvent to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'actor_login': actorLogin,
      'actor_avatar_url': actorAvatarUrl,
      'repo_name': repoName,
      'repo_url': repoUrl,
      'created_at': createdAt.toIso8601String(),
      'payload': payload,
      'selected': selected,
    };
  }

  /// Create a copy with different selected value
  GitHubEvent copyWith({bool? selected}) {
    return GitHubEvent(
      id: id,
      type: type,
      actorLogin: actorLogin,
      actorAvatarUrl: actorAvatarUrl,
      repoName: repoName,
      repoUrl: repoUrl,
      createdAt: createdAt,
      payload: payload,
      selected: selected ?? this.selected,
    );
  }

  // ignore: unintended_html_in_doc_comment
  /// Convert List<GitHubEvent> to JSON string
  static String encodeList(List<GitHubEvent> events) {
    return jsonEncode(events.map((event) => event.toJson()).toList());
  }

  // ignore: unintended_html_in_doc_comment
  /// Parse List<GitHubEvent> from JSON string
  static List<GitHubEvent> decodeList(String jsonString) {
    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => GitHubEvent.fromJson(json)).toList();
  }

  /// Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  /// Get event description based on type
  String get description {
    switch (type) {
      case 'PushEvent':
        final commits = payload?['commits']?.length ?? 0;
        return 'pushed $commits commit${commits != 1 ? 's' : ''}';
      case 'CreateEvent':
        final refType = payload?['ref_type'] ?? 'repository';
        return 'created $refType';
      case 'DeleteEvent':
        final refType = payload?['ref_type'] ?? 'branch';
        return 'deleted $refType';
      case 'ForkEvent':
        return 'forked repository';
      case 'WatchEvent':
        return 'starred repository';
      case 'IssuesEvent':
        final action = payload?['action'] ?? 'updated';
        return '$action issue';
      case 'PullRequestEvent':
        final action = payload?['action'] ?? 'updated';
        return '$action pull request';
      default:
        return type.toLowerCase().replaceAll('event', '');
    }
  }
}
