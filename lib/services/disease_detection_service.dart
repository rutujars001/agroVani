import 'dart:convert';
import 'dart:io';
// import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class DiseaseDetectionService {
  static const String _modelPath =
      'assets/ml/AgroVani_Disease_Model.tflite';

  static const String _classNamesPath =
      'assets/ml/class_names.json';

  static const String _knowledgePath =
      'assets/ml/disease_knowledge.json';

  static const int imageSize = 224;
  static const int numClasses = 45;

  Interpreter? _interpreter;
  List<String> _classNames = [];
  Map<String, dynamic> _knowledge = {};

  /// Loads the TFLite model and JSON files.
  Future<void> load() async {
    _interpreter ??= await Interpreter.fromAsset(_modelPath);

    if (_classNames.isEmpty) {
      final classJson =
          await rootBundle.loadString(_classNamesPath);

      final decoded = jsonDecode(classJson);

      if (decoded is List) {
        _classNames = List<String>.from(decoded);
      } else if (decoded is Map) {
        _classNames = List<String>.from(
          decoded.values.map((e) => e.toString()),
        );
      }
    }

    if (_knowledge.isEmpty) {
      final knowledgeJson =
          await rootBundle.loadString(_knowledgePath);

      final decoded = jsonDecode(knowledgeJson);

      if (decoded is Map<String, dynamic>) {
        _knowledge = decoded;
      }
    }

    print('Disease model loaded successfully');
    print('Classes loaded: ${_classNames.length}');
  }

  /// Runs disease detection on the supplied image.
  Future<Map<String, dynamic>> detectDisease(File imageFile) async {
    await load();

    if (_interpreter == null) {
      throw Exception('Disease model could not be loaded.');
    }

    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Could not read image.');

    final resized = img.copyResize(image, width: imageSize, height: imageSize);

    // Flat Float32List — tflite_flutter needs [1, 224, 224, 3] as flat buffer
    // MobileNetV2 normalization: pixel / 127.5 - 1.0  => range [-1, 1]
    final inputBuffer = List.generate(
      imageSize * imageSize * 3,
      (i) {
        final pixel = i ~/ 3;
        final channel = i % 3;
        final x = pixel % imageSize;
        final y = pixel ~/ imageSize;
        final p = resized.getPixel(x, y);
        final val = channel == 0 ? p.r : channel == 1 ? p.g : p.b;
        return (val.toDouble() / 127.5) - 1.0;
      },
    );

    // Reshape to [1, 224, 224, 3]
    final input = [List.generate(
      imageSize,
      (y) => List.generate(
        imageSize,
        (x) {
          final base = (y * imageSize + x) * 3;
          return [inputBuffer[base], inputBuffer[base+1], inputBuffer[base+2]];
        },
      ),
    )];

    final output = [List.filled(numClasses, 0.0)];

    _interpreter!.run(input, output);

    final probs = List<double>.from(output[0].map((e) => (e as num).toDouble()));

    // Apply softmax if output doesn't sum to ~1 (logits case)
    final sum = probs.reduce((a, b) => a + b);
    final probabilities = sum > 1.5
        ? _softmax(probs)   // logits — apply softmax
        : probs;            // already softmax

    int bestIndex = 0;
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > probabilities[bestIndex]) bestIndex = i;
    }

    final confidence = probabilities[bestIndex];
    final className = _classNames[bestIndex];

    print('AgroVani Model -> $className (${ (confidence*100).toStringAsFixed(1)}%)');

    return {
      'className': className,
      'confidence': confidence,
      'confidencePercent': (confidence * 100).round(),
      'knowledge': _getDiseaseKnowledge(className),
    };
  }

  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce((a, b) => a > b ? a : b);
    final exps = logits.map((x) => (x - maxVal).abs() < 500 ? _exp(x - maxVal) : 0.0).toList();
    final sumExp = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExp).toList();
  }

  double _exp(double x) {
    // Safe exp
    if (x < -88) return 0.0;
    return x == 0 ? 1.0 : (x > 0 ? 1.0 / _exp(-x) : _expNeg(x));
  }

  double _expNeg(double x) {
    // Taylor series for small negative x
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      result += term;
      if (term.abs() < 1e-10) break;
    }
    return result < 0 ? 0.0 : result;
  }

  /// Finds disease information using:
  /// Crop___DiseaseClass
  ///
  /// Example:
  /// Tomato___early_blight
  /// becomes:
  /// knowledge["Tomato"]["early_blight"]
  Map<String, dynamic> _getDiseaseKnowledge(
    String className,
  ) {
    final parts = className.split('___');

    if (parts.length != 2) {
      return {};
    }

    final crop = parts[0];
    final disease = parts[1];

    final cropData = _knowledge[crop];

    if (cropData is! Map) {
      return {};
    }

    final diseaseData = cropData[disease];

    if (diseaseData is Map) {
      return Map<String, dynamic>.from(diseaseData);
    }

    return {};
  }

  Future<void> testModel() async {
  await load();

  print('===== AGROVANI MODEL TEST =====');
  print('Model loaded: ${_interpreter != null}');
  print('Classes: ${_classNames.length}');
  print('===============================');
}

  /// Releases the TFLite interpreter.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}