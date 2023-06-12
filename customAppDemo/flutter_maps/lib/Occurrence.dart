import 'package:flutter_map/flutter_map.dart';
import 'package:maps_toolkit/maps_toolkit.dart';
import 'Metric.dart';
import 'attribute.dart';

class Occurrence extends Polygon {
  int? id;
  int altitude, algorithm_execution_id, added_by_id, site_id;
  String designation, acronym, toponym, owner, status_occurrence;
  List<Metric> metrics;
  List<Attribute> attributes;

  Occurrence(
      {this.id,
      this.designation = '',
      this.altitude = 0,
      this.owner = '',
      this.acronym = '',
      this.toponym = '',
      this.status_occurrence = '',
      this.added_by_id = 0,
      this.site_id = 0,
      this.algorithm_execution_id = 0,
      this.metrics = const [],
      required this.attributes,
      required super.points,
      super.borderColor,
      super.color,
      super.borderStrokeWidth,
      super.isFilled});

  List<List<num>> pointToList() {
    points.add(points[0]);
    return points.map((latLng) => [latLng.longitude, latLng.latitude]).toList();
  }

  void setStatus(String status) {
    status_occurrence = status;
  }

  @override
  String toString() {
    return """id: $id
designation: $designation,
site: $site_id,
altitude: $altitude,
owner: $owner,
acronym: $acronym, 
toponym: $toponym,
Added_by: $added_by_id,
status: $status_occurrence,
algorithm_execution_id: $algorithm_execution_id""";
  }
}
