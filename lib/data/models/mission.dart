class Mission {
  final String id;
  final String title;
  final bool completed;

  const Mission({
    required this.id,
    required this.title,
    this.completed = false,
  });

  Mission copyWith({bool? completed}) =>
      Mission(id: id, title: title, completed: completed ?? this.completed);

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'completed': completed,
      };

  factory Mission.fromMap(Map<dynamic, dynamic> map) => Mission(
        id: map['id'] as String,
        title: map['title'] as String,
        completed: map['completed'] as bool? ?? false,
      );
}
