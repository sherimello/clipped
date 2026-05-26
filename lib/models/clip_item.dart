
enum ClipType { text, image, url }

class ClipItem {
  final String id;
  final ClipType type;
  final String? textContent;
  final String? imagePath;
  String? ocrText;
  final DateTime timestamp;
  bool isPinned;
  List<String> tags;
  final int? imageWidth;
  final int? imageHeight;

  ClipItem({
    required this.id,
    required this.type,
    required this.timestamp,
    this.textContent,
    this.imagePath,
    this.ocrText,
    this.isPinned = false,
    List<String>? tags,
    this.imageWidth,
    this.imageHeight,
  }) : tags = tags ?? [];

  factory ClipItem.text({
    required String id,
    required String content,
    required DateTime timestamp,
  }) =>
      ClipItem(
        id: id,
        type: ClipType.text,
        textContent: content,
        timestamp: timestamp,
      );

  factory ClipItem.url({
    required String id,
    required String url,
    required DateTime timestamp,
  }) =>
      ClipItem(
        id: id,
        type: ClipType.url,
        textContent: url,
        timestamp: timestamp,
      );

  factory ClipItem.image({
    required String id,
    required String imagePath,
    required DateTime timestamp,
    int? width,
    int? height,
  }) =>
      ClipItem(
        id: id,
        type: ClipType.image,
        imagePath: imagePath,
        timestamp: timestamp,
        imageWidth: width,
        imageHeight: height,
      );

  bool get isText => type == ClipType.text;
  bool get isImage => type == ClipType.image;
  bool get isUrl => type == ClipType.url;

  String get displayText {
    if (type == ClipType.image) return ocrText ?? 'Image';
    return textContent ?? '';
  }

  String get preview {
    final text = displayText;
    return text.length > 120 ? '${text.substring(0, 120)}...' : text;
  }

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (textContent?.toLowerCase().contains(q) == true) return true;
    if (ocrText?.toLowerCase().contains(q) == true) return true;
    if (tags.any((t) => t.toLowerCase().contains(q))) return true;
    return false;
  }

  ClipItem copyWith({
    bool? isPinned,
    List<String>? tags,
    String? ocrText,
  }) =>
      ClipItem(
        id: id,
        type: type,
        timestamp: timestamp,
        textContent: textContent,
        imagePath: imagePath,
        ocrText: ocrText ?? this.ocrText,
        isPinned: isPinned ?? this.isPinned,
        tags: tags ?? List.from(this.tags),
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'textContent': textContent,
        'imagePath': imagePath,
        'ocrText': ocrText,
        'timestamp': timestamp.toIso8601String(),
        'isPinned': isPinned,
        'tags': tags,
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
      };

  factory ClipItem.fromJson(Map<String, dynamic> json) => ClipItem(
        id: json['id'] as String,
        type: ClipType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ClipType.text,
        ),
        textContent: json['textContent'] as String?,
        imagePath: json['imagePath'] as String?,
        ocrText: json['ocrText'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isPinned: json['isPinned'] as bool? ?? false,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        imageWidth: json['imageWidth'] as int?,
        imageHeight: json['imageHeight'] as int?,
      );

  @override
  bool operator ==(Object other) => other is ClipItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
