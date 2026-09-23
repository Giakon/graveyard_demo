import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.label,
    required this.icon, // emoji for now, we can replace with sprites later
  });

  final String id;
  final String label;
  final dynamic  icon;
}

const items = {
  'apple':       InventoryItem(id: 'apple',       label: 'Apple',       icon: '🍎'),
  'egg':         InventoryItem(id: 'egg',         label: 'Egg',         icon: '🥚'),
  'horseradish': InventoryItem(id: 'horseradish', label: 'Horseradish', icon: '🍠'),
  'carrot':      InventoryItem(id: 'carrot',      label: 'Carrot',      icon: '🥕'),
  'cooked':      InventoryItem(id: 'cooked',      label: 'Cooked Meal', icon: '🍳'),
  'cake':      InventoryItem(id: 'cake',      label: 'Cake', icon: '🍰'),
    'milk':        InventoryItem(id: 'milk',        label: 'Milk',        icon: '🥛'),
    'picnic_rug': InventoryItem(
  id: 'picnic_rug',
  label: 'Picnic Rug',
  icon: Icons.texture,
),
  'waffles':        InventoryItem(id: 'waffles',        label: 'Waffles',        icon: '🧇'),
  'red_dress': InventoryItem(id: 'red_dress', label: 'Red Dress', icon: '👗'),
'present':   InventoryItem(id: 'present',   label: 'Present',   icon: '🎁'),

};

class InventorySlot {
  InventorySlot({required this.item, this.count = 1});
  final InventoryItem item;
  int count;
}

class Inventory extends ChangeNotifier {
  final List<InventorySlot?> slots = List.filled(15, null);

  void add(String itemId) {
    final item = items[itemId];
    if (item == null) return;

    // find existing slot with same item
    for (final slot in slots) {
      if (slot?.item.id == itemId) {
        slot!.count++;
        notifyListeners();
        return;
      }
    }

    // find empty slot
    for (var i = 0; i < slots.length; i++) {
      if (slots[i] == null) {
        slots[i] = InventorySlot(item: item);
        notifyListeners();
        return;
      }
    }

    // inventory full — ignore for now
  }

  int count(String itemId) {
    for (final slot in slots) {
      if (slot?.item.id == itemId) return slot!.count;
    }
    return 0;
  }
bool has(String itemId, {int amount = 1}) {
  return count(itemId) >= amount;
}

bool remove(String itemId, {int amount = 1}) {
  for (var i = 0; i < slots.length; i++) {
    final slot = slots[i];

    if (slot?.item.id != itemId) {
      continue;
    }

    if (slot!.count < amount) {
      return false;
    }

    slot.count -= amount;

    if (slot.count <= 0) {
      slots[i] = null;
    }

    notifyListeners();
    return true;
  }

  return false;
}
}