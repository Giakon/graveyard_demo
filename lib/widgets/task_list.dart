import 'package:flutter/material.dart';

import '../data/task.dart';
import '../services/task_service.dart';

class TaskList extends StatelessWidget {
  const TaskList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TaskService.instance,
      builder: (context, _) {
        final taskService = TaskService.instance;

        return Container(
          width: 280,
          constraints: const BoxConstraints(
            maxHeight: 500,
          ),
          padding: const EdgeInsets.fromLTRB(
            16,
            14,
            16,
            14,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            border: Border.all(
              color: Colors.white.withOpacity(0.7),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'TASKS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${taskService.completedCount}/${taskService.totalCount}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const Divider(
                color: Colors.white24,
                height: 1,
              ),

              const SizedBox(height: 8),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final task in taskService.tasks)
                        _TaskRow(task: task),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
  });

  final Task task;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: task.completed
          ? Colors.white38
          : Colors.white,
      fontSize: 14,
      decoration: task.completed
          ? TextDecoration.lineThrough
          : TextDecoration.none,
      decorationColor: Colors.white38,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              task.completed ? '✓' : '□',
              style: TextStyle(
                color: task.completed
                    ? Colors.white70
                    : Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              task.title,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}