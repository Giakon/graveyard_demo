import 'package:flutter/material.dart';
import '../inventory.dart';

class Hotbar extends StatefulWidget {
  const Hotbar({required this.inventory, super.key});
  final Inventory inventory;

  @override
  State<Hotbar> createState() => _HotbarState();
}

class _HotbarState extends State<Hotbar> {
  @override
  void initState() {
    super.initState();
    widget.inventory.addListener(_onInventoryChanged);
  }

  @override
  void dispose() {
    widget.inventory.removeListener(_onInventoryChanged);
    super.dispose();
  }

  void _onInventoryChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 620.0;
        final slotSize = ((availableWidth - 8) / 8 - 4)
            .clamp(16.0, 36.0)
            .toDouble();

        final firstRow = widget.inventory.slots.take(8);
        final secondRow = widget.inventory.slots.skip(8);

        Widget buildRow(Iterable<InventorySlot?> slots) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: slots
                .map((slot) => _HotbarSlot(slot: slot, size: slotSize))
                .toList(),
          );
        }

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white24,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildRow(firstRow),
                  buildRow(secondRow),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
class _HotbarSlot extends StatelessWidget {
  const _HotbarSlot({required this.slot, required this.size});

  final InventorySlot? slot;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: slot != null
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white24,
          width: 0.5,
        ),
      ),
      child: slot == null
          ? null
          : Stack(
              children: [
              Center(
  child: slot!.item.icon is IconData
      ? Icon(
          slot!.item.icon as IconData,
              size: size * 0.58,
          color: slot!.item.id == 'picnic_rug'
              ? Colors.amber
              : Colors.white,
        )
      : Text(
          slot!.item.icon as String,
          style: const TextStyle(fontSize: 20),
        ),
),
                if (slot!.count > 1)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Text(
                      '${slot!.count}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.25,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}