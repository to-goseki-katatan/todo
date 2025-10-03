class Task {
  String id;
  String title;
  bool completed;
  int position;

  Task({
    required this.id,
    required this.title,
    this.completed = false,
    required this.position,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'].toString(),
      title: map['title'],
      completed: map['completed'] == 1,
      position: map['position'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completed': completed ? 1 : 0,
      'position': position,
    };
  }
}
