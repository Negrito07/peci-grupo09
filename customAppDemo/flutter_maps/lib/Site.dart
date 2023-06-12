import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:maps_toolkit/maps_toolkit.dart';
import 'package:latlong2/latlong.dart' as latlong;

import 'attribute.dart';

class Site extends Polygon {
  int? id, national_site_code, created_by_execution_id;
  String? name, country_iso, parish, status_site, added_by;
  latlong.LatLng? location;
  List<Attribute> attributes;

  Site({
    this.id = 0,
    this.name = '',
    this.national_site_code = 0,
    this.country_iso = '',
    this.parish = '',
    this.status_site = '',
    this.added_by = '',
    this.created_by_execution_id = 0,
    this.location,
    required super.points,
    required this.attributes,
    super.borderColor,
    super.color,
    super.borderStrokeWidth,
    super.isFilled,
  });

  List<List<num>> pointToList() {
    return points.map((latLng) => [latLng.longitude, latLng.latitude]).toList();
  }

  @override
  String toString() {
    return """id: $id,
name: $name,
national_site_code: $national_site_code,
country_iso: $country_iso,
parish: $parish, 
status_site: $status_site,
added_by: $added_by,
creation_by_execution: $created_by_execution_id """;
  }
}
