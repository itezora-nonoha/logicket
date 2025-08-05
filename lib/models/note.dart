class Note {
  final String id;
  final String content;
  final double order;
  final List<String> linkedNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Note({
    required this.id,
    required this.content,
    required this.order,
    this.linkedNotes = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Note copyWith({
    String? id,
    String? content,
    double? order,
    List<String>? linkedNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Note(
      id: id ?? this.id,
      content: content ?? this.content,
      order: order ?? this.order,
      linkedNotes: linkedNotes ?? this.linkedNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'order': order,
      'linkedNotes': linkedNotes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isDeleted': isDeleted,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      order: (map['order'] ?? 0.0).toDouble(),
      linkedNotes: List<String>.from(map['linkedNotes'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      isDeleted: map['isDeleted'] ?? false,
    );
  }
}
