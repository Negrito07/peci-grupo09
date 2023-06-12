import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:maps_toolkit/maps_toolkit.dart';
import 'package:latlong2/latlong.dart' as latlong;

class Metric {
  int? id;
  double confirmed_value, auto_value;
  String unit_measurement;
  String? type_id;

  Metric({
    this.id,
    this.type_id,
    this.auto_value = 0,
    this.confirmed_value = 0,
    this.unit_measurement = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type_id,
      'auto_value': auto_value,
      'confirmed_value': confirmed_value,
      'unit_measurement': unit_measurement,
    };
  }

  Map<String, dynamic> toMapnoId() {
    return {
      'type': type_id,
      'auto_value': auto_value,
      'confirmed_value': confirmed_value,
      'unit_measurement': unit_measurement,
    };
  }

  @override
  String toString() {
    return '\n Métrica:\n auto_value: $auto_value\n confirmed_value: $confirmed_value\n type_id: $type_id\n unit_measurement: $unit_measurement';
  }
}
