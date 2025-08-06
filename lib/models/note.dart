class Note {
  final String id;
  final String? title; // タイトル（任意）
  final String content;
  final double order;
  final List<String> linkedNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Note({
    required this.id,
    this.title,
    required this.content,
    required this.order,
    this.linkedNotes = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    double? order,
    List<String>? linkedNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
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
      'title': title,
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
      title: map['title'],
      content: map['content'] ?? '',
      order: (map['order'] ?? 0.0).toDouble(),
      linkedNotes: List<String>.from(map['linkedNotes'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  // 表示用のタイトルを取得（タイトルがない場合は本文の最初の行から生成）
  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) {
      return title!;
    }
    
    // 本文の最初の行からタイトルを生成
    final firstLine = content.split('\n').first.trim();
    if (firstLine.startsWith('#')) {
      // マークダウンのヘッダーがある場合は#を除去
      return firstLine.replaceAll(RegExp(r'^#+\s*'), '');
    } else {
      // 最初の50文字まで（改行は含まない）
      return firstLine.length > 50 ? '${firstLine.substring(0, 50)}...' : firstLine;
    }
  }
}
