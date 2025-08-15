import 'dart:convert';
import 'dart:ui';

/// Model representing a single drawing stroke
class DoodleStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final StrokeCap strokeCap;
  final String? toolType; // pen, eraser, highlighter, etc.
  final DateTime createdAt;

  const DoodleStroke({
    required this.points,
    required this.color,
    required this.width,
    this.strokeCap = StrokeCap.round,
    this.toolType = 'pen',
    required this.createdAt,
  });

  /// Create a copy of the stroke with updated fields
  DoodleStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? width,
    StrokeCap? strokeCap,
    String? toolType,
    DateTime? createdAt,
  }) {
    return DoodleStroke(
      points: points ?? List.from(this.points),
      color: color ?? this.color,
      width: width ?? this.width,
      strokeCap: strokeCap ?? this.strokeCap,
      toolType: toolType ?? this.toolType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert stroke to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
      'width': width,
      'strokeCap': strokeCap.index,
      'toolType': toolType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create stroke from JSON
  factory DoodleStroke.fromJson(Map<String, dynamic> json) {
    final pointsJson = json['points'] as List<dynamic>;
    final points = pointsJson
        .map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
        .toList();

    return DoodleStroke(
      points: points,
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
      strokeCap: StrokeCap.values[json['strokeCap'] as int? ?? 0],
      toolType: json['toolType'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoodleStroke &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          width == other.width &&
          strokeCap == other.strokeCap &&
          toolType == other.toolType &&
          points.length == other.points.length;

  @override
  int get hashCode => Object.hash(color, width, strokeCap, toolType, points.length);
}

/// Model representing a drawing layer (premium feature)
class DoodleLayer {
  final String id;
  final String name;
  final List<DoodleStroke> strokes;
  final bool isVisible;
  final double opacity;
  final BlendMode blendMode;

  const DoodleLayer({
    required this.id,
    required this.name,
    required this.strokes,
    this.isVisible = true,
    this.opacity = 1.0,
    this.blendMode = BlendMode.srcOver,
  });

  /// Create a copy of the layer with updated fields
  DoodleLayer copyWith({
    String? id,
    String? name,
    List<DoodleStroke>? strokes,
    bool? isVisible,
    double? opacity,
    BlendMode? blendMode,
  }) {
    return DoodleLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      strokes: strokes ?? List.from(this.strokes),
      isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
    );
  }

  /// Convert layer to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'strokes': strokes.map((stroke) => stroke.toJson()).toList(),
      'isVisible': isVisible,
      'opacity': opacity,
      'blendMode': blendMode.index,
    };
  }

  /// Create layer from JSON
  factory DoodleLayer.fromJson(Map<String, dynamic> json) {
    final strokesJson = json['strokes'] as List<dynamic>;
    final strokes = strokesJson
        .map((strokeJson) => DoodleStroke.fromJson(strokeJson as Map<String, dynamic>))
        .toList();

    return DoodleLayer(
      id: json['id'] as String,
      name: json['name'] as String,
      strokes: strokes,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      blendMode: BlendMode.values[json['blendMode'] as int? ?? 0],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoodleLayer &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Complete doodle data model containing all drawing information
class DoodleData {
  final List<DoodleLayer> layers;
  final Size canvasSize;
  final Color backgroundColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const DoodleData({
    required this.layers,
    required this.canvasSize,
    this.backgroundColor = const Color(0xFFFFFFFF),
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Create a copy of the doodle data with updated fields
  DoodleData copyWith({
    List<DoodleLayer>? layers,
    Size? canvasSize,
    Color? backgroundColor,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return DoodleData(
      layers: layers ?? List.from(this.layers),
      canvasSize: canvasSize ?? this.canvasSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert doodle data to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'layers': layers.map((layer) => layer.toJson()).toList(),
      'canvasSize': {
        'width': canvasSize.width,
        'height': canvasSize.height,
      },
      'backgroundColor': backgroundColor.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create doodle data from JSON
  factory DoodleData.fromJson(Map<String, dynamic> json) {
    final layersJson = json['layers'] as List<dynamic>;
    final layers = layersJson
        .map((layerJson) => DoodleLayer.fromJson(layerJson as Map<String, dynamic>))
        .toList();

    final canvasSizeJson = json['canvasSize'] as Map<String, dynamic>;
    final canvasSize = Size(
      (canvasSizeJson['width'] as num).toDouble(),
      (canvasSizeJson['height'] as num).toDouble(),
    );

    return DoodleData(
      layers: layers,
      canvasSize: canvasSize,
      backgroundColor: Color(json['backgroundColor'] as int? ?? 0xFFFFFFFF),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert doodle data to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create doodle data from JSON string
  factory DoodleData.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return DoodleData.fromJson(json);
  }

  /// Get all strokes from all layers as a flat list
  List<DoodleStroke> get allStrokes {
    return layers
        .where((layer) => layer.isVisible)
        .expand((layer) => layer.strokes)
        .toList();
  }

  /// Get total number of strokes
  int get strokeCount {
    return layers.fold(0, (total, layer) => total + layer.strokes.length);
  }

  /// Check if doodle is empty
  bool get isEmpty {
    return layers.every((layer) => layer.strokes.isEmpty);
  }

  /// Get the primary/default layer
  DoodleLayer get primaryLayer {
    if (layers.isEmpty) {
      return const DoodleLayer(
        id: 'default',
        name: 'Layer 1',
        strokes: [],
      );
    }
    return layers.first;
  }

  /// Create a new doodle with default settings
  factory DoodleData.createNew({
    Size? canvasSize,
    Color? backgroundColor,
  }) {
    final now = DateTime.now();
    return DoodleData(
      layers: [
        const DoodleLayer(
          id: 'default',
          name: 'Layer 1',
          strokes: [],
        ),
      ],
      canvasSize: canvasSize ?? const Size(800, 600),
      backgroundColor: backgroundColor ?? const Color(0xFFFFFFFF),
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoodleData &&
          runtimeType == other.runtimeType &&
          canvasSize == other.canvasSize &&
          backgroundColor == other.backgroundColor &&
          layers.length == other.layers.length;

  @override
  int get hashCode => Object.hash(canvasSize, backgroundColor, layers.length);

  @override
  String toString() {
    return 'DoodleData{layers: ${layers.length}, canvasSize: $canvasSize, '
           'strokes: $strokeCount, created: $createdAt}';
  }
}