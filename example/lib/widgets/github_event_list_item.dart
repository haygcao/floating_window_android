// New StatefulWidget for the list item with shake animation
import 'package:flutter/material.dart';

import '../model/github_event.dart';

/// Widget to display a GitHub event in a list
class GitHubEventListItem extends StatefulWidget {
  final GitHubEvent event;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onToggleSelection;

  const GitHubEventListItem({
    super.key,
    required this.event,
    this.isSelected = false,
    this.onTap,
    this.onToggleSelection,
  });

  @override
  GitHubEventListItemState createState() => GitHubEventListItemState();
}

class GitHubEventListItemState extends State<GitHubEventListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<Offset> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: const Offset(0.03, 0.0)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.03, 0.0),
          end: const Offset(-0.03, 0.0),
        ),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(-0.03, 0.0), end: Offset.zero),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  /// Trigger shake animation
  void shake() {
    _shakeController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _shakeAnimation,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        elevation: widget.isSelected ? 4.0 : 1.0,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User avatar
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      widget.event.actorAvatarUrl.isNotEmpty
                          ? NetworkImage(widget.event.actorAvatarUrl)
                          : null,
                  backgroundColor: Colors.grey[300],
                  child:
                      widget.event.actorAvatarUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                ),
                const SizedBox(width: 12),

                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Actor and action
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: widget.event.actorLogin,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: ' ${widget.event.description}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Repository name
                      Row(
                        children: [
                          const Icon(
                            Icons.folder_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.event.repoName,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Event type and time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getEventTypeColor(
                                widget.event.type,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getEventTypeColor(
                                  widget.event.type,
                                ).withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _getEventTypeDisplayName(widget.event.type),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getEventTypeColor(widget.event.type),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            widget.event.timeAgo,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Selection checkbox
                if (widget.onToggleSelection != null)
                  Checkbox(
                    value: widget.isSelected,
                    onChanged: (_) => widget.onToggleSelection?.call(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get color based on event type
  Color _getEventTypeColor(String eventType) {
    switch (eventType) {
      case 'PushEvent':
        return Colors.green;
      case 'CreateEvent':
        return Colors.blue;
      case 'DeleteEvent':
        return Colors.red;
      case 'ForkEvent':
        return Colors.orange;
      case 'WatchEvent':
        return Colors.yellow[700]!;
      case 'IssuesEvent':
        return Colors.purple;
      case 'PullRequestEvent':
        return Colors.teal;
      case 'ReleaseEvent':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  /// Get display name for event type
  String _getEventTypeDisplayName(String eventType) {
    switch (eventType) {
      case 'PushEvent':
        return 'Push';
      case 'CreateEvent':
        return 'Create';
      case 'DeleteEvent':
        return 'Delete';
      case 'ForkEvent':
        return 'Fork';
      case 'WatchEvent':
        return 'Star';
      case 'IssuesEvent':
        return 'Issue';
      case 'PullRequestEvent':
        return 'PR';
      case 'ReleaseEvent':
        return 'Release';
      default:
        return eventType.replaceAll('Event', '');
    }
  }
}

/// Compact version of GitHub event item for floating window
class CompactGitHubEventItem extends StatelessWidget {
  final GitHubEvent event;
  final VoidCallback? onTap;

  const CompactGitHubEventItem({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Event type indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getEventTypeColor(event.type),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),

            // Event content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${event.actorLogin} ${event.description}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.repoName,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        event.timeAgo,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get color based on event type
  Color _getEventTypeColor(String eventType) {
    switch (eventType) {
      case 'PushEvent':
        return Colors.green;
      case 'CreateEvent':
        return Colors.blue;
      case 'DeleteEvent':
        return Colors.red;
      case 'ForkEvent':
        return Colors.orange;
      case 'WatchEvent':
        return Colors.yellow[700]!;
      case 'IssuesEvent':
        return Colors.purple;
      case 'PullRequestEvent':
        return Colors.teal;
      case 'ReleaseEvent':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
