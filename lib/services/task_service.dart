import 'package:flutter/foundation.dart';

import '../data/task.dart';

class TaskService extends ChangeNotifier {
  TaskService._();

  static final TaskService instance = TaskService._();

  final List<Task> tasks = [
    Task(
      id: TaskId.getPicnicRug,
      title: 'Get the picnic rug',
    ),
    Task(
      id: TaskId.bozoFollowYou,
      title: 'Have Bozo the Cat follow you',
    ),
    Task(
      id: TaskId.pickupRedDress,
      title: 'Pick up the red dress',
    ),
    Task(
      id: TaskId.collectApple,
      title: 'Collect apples from the trees',
    ),
    Task(
      id: TaskId.collectCarrot,
      title: 'Collect carrots from the field',
    ),
    Task(
      id: TaskId.collectHorseradish,
      title: 'Collect horseradish from the field',
    ),
    Task(
      id: TaskId.collectEgg,
      title: 'Collect eggs from the coop',
    ),
    Task(
      id: TaskId.collectMilk,
      title: 'Collect milk from the cow',
    ),
    Task(
      id: TaskId.getWafflesFromFridge,
      title: 'Get waffles from the fridge',
    ),
    Task(
      id: TaskId.cookBreakfast,
      title: 'Cook breakfast',
    ),
    Task(
      id: TaskId.makeCake,
      title: 'Make a cake in the kitchen counter',
    ),
    Task(
      id: TaskId.putRagAtBeach,
      title: 'Put the rug at the beach',
    ),
  ];

  bool isCompleted(TaskId id) {
    return tasks
        .firstWhere((task) => task.id == id)
        .completed;
  }

  void complete(TaskId id) {
    final task = tasks.firstWhere(
      (task) => task.id == id,
    );

    if (task.completed) {
      return;
    }

    task.completed = true;
    notifyListeners();
  }

  void uncomplete(TaskId id) {
    final task = tasks.firstWhere(
      (task) => task.id == id,
    );

    if (!task.completed) {
      return;
    }

    task.completed = false;
    notifyListeners();
  }

  int get completedCount {
    return tasks
        .where((task) => task.completed)
        .length;
  }

  int get totalCount => tasks.length;

  bool get allCompleted {
    return tasks.isNotEmpty &&
        tasks.every((task) => task.completed);
  }
}