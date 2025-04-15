// New StatefulWidget for the list item with shake animation
import 'package:flutter/material.dart';

import '../model/price.dart';

class PriceListItem extends StatefulWidget {
  final Price item;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool?> onToggleSelection;

  const PriceListItem({
    required Key key, // GlobalKey will be passed here
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onToggleSelection,
  }) : super(key: key);

  @override
  PriceListItemState createState() => PriceListItemState();
}

class PriceListItemState extends State<PriceListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<Offset> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400), // Slightly faster shake
      vsync: this,
    );
    // Simple left-right shake
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

  // Method to trigger the shake animation
  void shake() {
    _shakeController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // Determine color based on price (assuming '-' indicates negative)
    final bool isNegative = widget.item.price.contains('-');
    final Color priceColor = isNegative ? Colors.red : Colors.green;
    // Placeholder for percentage change - replace with actual data if available
    final String percentageChange = isNegative ? '-1.5%' : '+2.5%';

    return SlideTransition(
      // Wrap the Card for shake effect
      position: _shakeAnimation,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      // Ensure symbol has at least one character
                      widget.item.symbol.isNotEmpty
                          ? widget.item.symbol.substring(0, 1)
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.symbol,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '行情实时更新', // Placeholder description
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      num.parse(widget.item.price).toStringAsFixed(4),
                      style: TextStyle(
                        color: priceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: priceColor.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        percentageChange, // Placeholder percentage
                        style: TextStyle(
                          color: priceColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Use the Checkbox provided by the stateful widget
                Checkbox(
                  value: widget.isSelected,
                  activeColor: const Color(0xFF1E88E5),
                  onChanged: widget.onToggleSelection,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
