enum TaskId {
  getPicnicRug,
  bozoFollowYou,
  pickupRedDress,
  collectApple,
  collectCarrot,
  collectHorseradish,
  collectEgg,
  collectMilk,
  getWafflesFromFridge,
  cookBreakfast,
  makeCake,
  putRagAtBeach,
}

class Task {
  Task({
    required this.id,
    required this.title,
    this.completed = false,
  });

  final TaskId id;
  final String title;

  bool completed;
}