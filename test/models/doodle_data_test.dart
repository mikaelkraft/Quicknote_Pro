import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:quicknote_pro/models/doodle_data.dart';

void main() {
  group('DoodleStroke', () {
    test('should create DoodleStroke with required fields', () {
      final now = DateTime.now();
      final points = [const Offset(0, 0), const Offset(10, 10)];
      
      final stroke = DoodleStroke(
        points: points,
        color: Colors.black,
        width: 2.0,
        createdAt: now,
      );

      expect(stroke.points, equals(points));
      expect(stroke.color, equals(Colors.black));
      expect(stroke.width, equals(2.0));
      expect(stroke.strokeCap, equals(StrokeCap.round));
      expect(stroke.toolType, equals('pen'));
      expect(stroke.createdAt, equals(now));
    });

    test('should convert DoodleStroke to and from JSON', () {
      final now = DateTime.now();
      final points = [const Offset(5, 10), const Offset(15, 20)];
      
      final originalStroke = DoodleStroke(
        points: points,
        color: Colors.red,
        width: 3.0,
        strokeCap: StrokeCap.square,
        toolType: 'highlighter',
        createdAt: now,
      );

      final json = originalStroke.toJson();
      final restoredStroke = DoodleStroke.fromJson(json);

      expect(restoredStroke.points.length, equals(originalStroke.points.length));
      expect(restoredStroke.points[0].dx, equals(originalStroke.points[0].dx));
      expect(restoredStroke.points[0].dy, equals(originalStroke.points[0].dy));
      expect(restoredStroke.color, equals(originalStroke.color));
      expect(restoredStroke.width, equals(originalStroke.width));
      expect(restoredStroke.strokeCap, equals(originalStroke.strokeCap));
      expect(restoredStroke.toolType, equals(originalStroke.toolType));
      expect(restoredStroke.createdAt, equals(originalStroke.createdAt));
    });

    test('should create copy with updated fields', () {
      final stroke = DoodleStroke(
        points: [const Offset(0, 0)],
        color: Colors.black,
        width: 2.0,
        createdAt: DateTime.now(),
      );

      final newPoints = [const Offset(10, 10), const Offset(20, 20)];
      final copiedStroke = stroke.copyWith(
        points: newPoints,
        color: Colors.blue,
        width: 4.0,
      );

      expect(copiedStroke.points, equals(newPoints));
      expect(copiedStroke.color, equals(Colors.blue));
      expect(copiedStroke.width, equals(4.0));
      expect(copiedStroke.createdAt, equals(stroke.createdAt)); // unchanged
    });
  });

  group('DoodleLayer', () {
    test('should create DoodleLayer with strokes', () {
      final stroke1 = DoodleStroke(
        points: [const Offset(0, 0)],
        color: Colors.black,
        width: 2.0,
        createdAt: DateTime.now(),
      );
      
      final stroke2 = DoodleStroke(
        points: [const Offset(10, 10)],
        color: Colors.red,
        width: 3.0,
        createdAt: DateTime.now(),
      );

      final layer = DoodleLayer(
        id: 'layer1',
        name: 'Main Layer',
        strokes: [stroke1, stroke2],
      );

      expect(layer.id, equals('layer1'));
      expect(layer.name, equals('Main Layer'));
      expect(layer.strokes.length, equals(2));
      expect(layer.isVisible, equals(true));
      expect(layer.opacity, equals(1.0));
    });

    test('should convert DoodleLayer to and from JSON', () {
      final stroke = DoodleStroke(
        points: [const Offset(5, 5)],
        color: Colors.green,
        width: 1.5,
        createdAt: DateTime.now(),
      );

      final originalLayer = DoodleLayer(
        id: 'test-layer',
        name: 'Test Layer',
        strokes: [stroke],
        isVisible: false,
        opacity: 0.7,
      );

      final json = originalLayer.toJson();
      final restoredLayer = DoodleLayer.fromJson(json);

      expect(restoredLayer.id, equals(originalLayer.id));
      expect(restoredLayer.name, equals(originalLayer.name));
      expect(restoredLayer.strokes.length, equals(originalLayer.strokes.length));
      expect(restoredLayer.isVisible, equals(originalLayer.isVisible));
      expect(restoredLayer.opacity, equals(originalLayer.opacity));
    });
  });

  group('DoodleData', () {
    test('should create new DoodleData with default settings', () {
      final doodle = DoodleData.createNew();

      expect(doodle.layers.length, equals(1));
      expect(doodle.layers.first.name, equals('Layer 1'));
      expect(doodle.canvasSize, equals(const Size(800, 600)));
      expect(doodle.backgroundColor, equals(const Color(0xFFFFFFFF)));
      expect(doodle.isEmpty, equals(true));
    });

    test('should create DoodleData with custom canvas size', () {
      const customSize = Size(1200, 800);
      final doodle = DoodleData.createNew(canvasSize: customSize);

      expect(doodle.canvasSize, equals(customSize));
    });

    test('should convert DoodleData to and from JSON', () {
      final now = DateTime.now();
      final stroke = DoodleStroke(
        points: [const Offset(10, 20)],
        color: Colors.purple,
        width: 2.5,
        createdAt: now,
      );

      final layer = DoodleLayer(
        id: 'main',
        name: 'Main Layer',
        strokes: [stroke],
      );

      final originalDoodle = DoodleData(
        layers: [layer],
        canvasSize: const Size(1000, 800),
        backgroundColor: Colors.yellow,
        createdAt: now,
        updatedAt: now,
      );

      final jsonString = originalDoodle.toJsonString();
      final restoredDoodle = DoodleData.fromJsonString(jsonString);

      expect(restoredDoodle.layers.length, equals(originalDoodle.layers.length));
      expect(restoredDoodle.canvasSize, equals(originalDoodle.canvasSize));
      expect(restoredDoodle.backgroundColor, equals(originalDoodle.backgroundColor));
      expect(restoredDoodle.createdAt, equals(originalDoodle.createdAt));
      expect(restoredDoodle.updatedAt, equals(originalDoodle.updatedAt));
    });

    test('should get all strokes from visible layers', () {
      final stroke1 = DoodleStroke(
        points: [const Offset(0, 0)],
        color: Colors.black,
        width: 2.0,
        createdAt: DateTime.now(),
      );
      
      final stroke2 = DoodleStroke(
        points: [const Offset(10, 10)],
        color: Colors.red,
        width: 3.0,
        createdAt: DateTime.now(),
      );

      final visibleLayer = DoodleLayer(
        id: 'visible',
        name: 'Visible Layer',
        strokes: [stroke1],
        isVisible: true,
      );

      final hiddenLayer = DoodleLayer(
        id: 'hidden',
        name: 'Hidden Layer',
        strokes: [stroke2],
        isVisible: false,
      );

      final doodle = DoodleData(
        layers: [visibleLayer, hiddenLayer],
        canvasSize: const Size(800, 600),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final allStrokes = doodle.allStrokes;
      expect(allStrokes.length, equals(1)); // Only visible layer strokes
      expect(allStrokes.first, equals(stroke1));
    });

    test('should correctly identify empty doodle', () {
      final emptyDoodle = DoodleData.createNew();
      expect(emptyDoodle.isEmpty, equals(true));

      final stroke = DoodleStroke(
        points: [const Offset(0, 0)],
        color: Colors.black,
        width: 2.0,
        createdAt: DateTime.now(),
      );

      final layerWithStroke = emptyDoodle.primaryLayer.copyWith(
        strokes: [stroke],
      );

      final nonEmptyDoodle = emptyDoodle.copyWith(
        layers: [layerWithStroke],
      );

      expect(nonEmptyDoodle.isEmpty, equals(false));
    });

    test('should get correct stroke count', () {
      final stroke1 = DoodleStroke(
        points: [const Offset(0, 0)],
        color: Colors.black,
        width: 2.0,
        createdAt: DateTime.now(),
      );
      
      final stroke2 = DoodleStroke(
        points: [const Offset(10, 10)],
        color: Colors.red,
        width: 3.0,
        createdAt: DateTime.now(),
      );

      final layer = DoodleLayer(
        id: 'main',
        name: 'Main Layer',
        strokes: [stroke1, stroke2],
      );

      final doodle = DoodleData(
        layers: [layer],
        canvasSize: const Size(800, 600),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(doodle.strokeCount, equals(2));
    });
  });
}