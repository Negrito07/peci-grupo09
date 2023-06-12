import 'package:flutter/material.dart';
import 'package:flutter_map_test/Metric.dart';
import 'Occurrence.dart';
import 'Site.dart';
import 'attribute.dart';
import 'constants.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocore/geocore.dart' as geocore;

Color colorByStatus(String status) {
  print(status);
  if (status == "V") {
    return const Color.fromARGB(255, 0, 0, 255);
  } else if (status == "T") {
    return const Color.fromARGB(255, 0, 0, 255);
  } else if (status == "F") {
    return const Color.fromARGB(255, 0, 0, 255);
  } else {
    return const Color.fromARGB(255, 255, 0, 0);
  }
}

/// Fetch a specific site given its id from the API and store in a Site
/// parameter.
void fetchAndStoreSiteSpecificData(Site site, int site_id) async {
  int id, national_site_code = 0;
  String name, country_iso, parish, status_site = '';
  List<latlong.LatLng> points = [];
  latlong.LatLng? location;
  List<Attribute> attributes;

  try {
    http.Response response = await http.get(Uri.parse('$site_link/$site_id'));
    Map<String, dynamic> data = json.decode(response.body);

    id = data['id'];
    name = data['properties']['name'];
    national_site_code = data['properties']['national_site_code'];
    country_iso = data['properties']['country_iso'];
    parish = data['properties']['parish'];
    status_site = data['properties']['status_site'];
    attributes = data["properties"]["attributes"]
        .map<Attribute>((attribute) => Attribute(
              id: attribute["id"],
              category: attribute["category"],
              value: attribute["value"],
            ))
        .toList();

    List<dynamic> aux = data['properties']['location']['coordinates'];
    location = latlong.LatLng(aux[1], aux[0]);

    aux = data['geometry']['coordinates'][0];
    points = aux.map((e) => latlong.LatLng(e[1], e[0])).toList();

    site = Site(
      id: id,
      points: points,
      name: name,
      national_site_code: national_site_code,
      country_iso: country_iso,
      parish: parish,
      status_site: status_site,
      attributes: attributes,
      borderColor: const Color.fromARGB(255, 4, 173, 252),
      borderStrokeWidth: 2.0,
      isFilled: false,
    );
  } catch (e) {
    throw Exception("Fail to load GEODATA: $e");
  }
}

/// Fetch all occurrences related to a specific site given its id from the
/// API and store in a List<Occurrence> parameter
void fetchAndStoreOccurrenceSpecificData(
    List<Occurrence> occurrencefeatures, int id) async {
  // preservar occurrenceToAdd, se necessario
  Occurrence? temp;
  if (occurrencefeatures.isNotEmpty) {
    temp = occurrencefeatures[occurrencefeatures.length - 1];
    occurrencefeatures.clear();
  }

  List<latlong.LatLng> points = [];
  List<Metric> metrics = [];
  try {
    http.Response response = await http.get(Uri.parse('$occurrences_link/$id'));
    Map<String, dynamic> data = json.decode(
      utf8.decode(response.bodyBytes),
    );
    //print(data);
    data.forEach((key, value) {
      if (key == "features") {
        value.forEach((lista) {
          print('FETCH:\n-----> $lista');

          List<dynamic> aux = lista['geometry']['coordinates'][0];
          List<dynamic> met = lista['properties']['metrics'];
          points = aux.map((e) => latlong.LatLng(e[1], e[0])).toList();
          metrics = met
              .map((e) => Metric(
                  id: e["id"],
                  type_id: e["type"],
                  auto_value: 0,
                  confirmed_value: double.parse(e["confirmed_value"]),
                  unit_measurement: e["unit_measurement"]))
              .toList();
          Occurrence occurrencefeature = Occurrence(
            id: lista["id"],
            designation: lista["properties"]["designation"] ?? "",
            altitude: lista["properties"]["altitude"] ?? 0,
            owner: lista["properties"]["owner"] ?? "",
            acronym: lista["properties"]["acronym"] ?? "",
            toponym: lista["properties"]["toponym"] ?? "",
            status_occurrence: lista["properties"]["status_occurrence"] ?? "",
            added_by_id: lista["properties"]["added_by"] ?? '',
            site_id: lista["properties"]["site"] ?? '',
            algorithm_execution_id:
                lista["properties"]["algorithm_execution"] ?? 0,
            metrics: metrics,
            attributes: lista["properties"]["attributes"]
                .map<Attribute>((attribute) => Attribute(
                      id: attribute["id"],
                      category: attribute["category"],
                      value: attribute["value"],
                    ))
                .toList(),
            points: points,
            borderColor:
                colorByStatus(lista["properties"]["status_occurrence"] ?? ""),
            borderStrokeWidth: 2.0,
            isFilled: false,
          );
          //print(occurrencefeature);
          occurrencefeatures.add(occurrencefeature);
        });
      }
    });
  } catch (e) {
    throw Exception("Fail to load GEODATA: $e");
  } finally {
    if (temp != null) {
      occurrencefeatures.add(temp);
    }
  }
}

void fetchMetricTypes(List<dynamic> metricas) async {
  try {
    http.Response response = await http.get(Uri.parse('$metrics_link'));
    List<dynamic> data = json.decode(
      utf8.decode(response.bodyBytes),
    );
    data.forEach((element) {
      metricas.add(element);
    });
    print(metricas);
  } catch (e) {
    throw Exception("Fail to load GEODATA: $e");
  }
}

/// Fetch all attribute choices from the API and store in a
/// List<Attribute> parameter.
Future<void> fetchAttributes(List<Attribute> attributes) async {
  try {
    http.Response response = await http.get(Uri.parse(attributes_link));
    List<dynamic> data = json.decode(
      utf8.decode(response.bodyBytes),
    );
    print('FETCH: ${data.length} attributes\n----> ${data[0]}');
    data.forEach((element) {
      attributes.add(Attribute(
        id: element["id"],
        category: element["category"],
        value: element["value"],
      ));
    });
    print('STORE: ${attributes.length}\n----> ${attributes[0]}');
  } catch (e) {
    throw Exception("Fail to load GEODATA: $e");
  }
}

/// Send site data to the API to CREATE a new site entry.
void postSiteData(Site polygon) async {
  final encoder = geocore.GeoJSON.feature.encoder();

  geocore.Feature feature = geocore.Feature(
      id: polygon.id,
      geometry: geocore.Polygon.make(
          [polygon.pointToList()], geocore.GeoPoint2.coordinates),
      properties: {
        'name': polygon.name,
        'national_site_code': polygon.national_site_code,
        'country_iso': polygon.country_iso,
        'parish': polygon.parish,
        'status_site': polygon.status_site,
        'attributes': polygon.attributes
            .map<Map<String, dynamic>>((attribute) => attribute.toMap()),
      });
  feature.writeTo(encoder.writer);
  print('POST-request:\n----> ${encoder.toText()}');

  try {
    http.Response response = await http.post(Uri.parse(sites_link),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: encoder.toText());

    print(response.body);
    print(response.statusCode);
  } catch (e) {
    print(e);
  }
}

/// Send occurrence data to the API to CREATE a new occurrence entry.
void postOccurrenceData(Occurrence polygon, int site_id) async {
  final encoder = geocore.GeoJSON.feature.encoder();
  List<dynamic> metrics = [];
  polygon.metrics.forEach((metrica) {
    metrics.add(metrica.toMap());
  });
  geocore.Feature feature = geocore.Feature(
      id: polygon.id,
      geometry: geocore.Polygon.make(
          [polygon.pointToList()], geocore.GeoPoint2.coordinates),
      properties: {
        'designation': polygon.designation,
        'acronym': polygon.acronym,
        'toponym': polygon.toponym,
        'owner': polygon.owner,
        'altitude': polygon.altitude,
        'added_by': polygon.added_by_id,
        'site': polygon.site_id,
        'status_occurrence': polygon.status_occurrence,
        'algorithm_execution':
            null, // Implementar -> polygon.algorithm_execution_id,
        'metrics': metrics,
        'attributes': polygon.attributes
            .map<Map<String, dynamic>>((attribute) => attribute.toMap()),
      });
  feature.writeTo(encoder.writer);
  print('POST-request:\n-----> ${encoder.toText()}');

  try {
    http.Response response =
        await http.post(Uri.parse('$occurrences_link/$site_id'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: encoder.toText());

    // TODO: verificar status da operacao
    print('POST-status: ${response.statusCode}');
    print('POST-response:\n-----> ${response.body}');

    Map<String, dynamic> data = json.decode(
      utf8.decode(response.bodyBytes),
    );

    polygon.id = data["id"];
    polygon.metrics = data["properties"]["metrics"]
        .map<Metric>((e) => Metric(
            id: e["id"],
            type_id: e["type"],
            auto_value: 0,
            confirmed_value: double.parse(e["confirmed_value"]),
            unit_measurement: e["unit_measurement"]))
        .toList();
  } catch (e) {
    print(e);
  }
}

/// Send site data to the API to UPDATE a site entry.
void putSiteData(Site polygon) async {
  final encoder = geocore.GeoJSON.feature.encoder();

  geocore.Feature feature = geocore.Feature(
      id: polygon.id,
      geometry: geocore.Polygon.make(
          [polygon.pointToList()], geocore.GeoPoint2.coordinates),
      properties: {
        'name': polygon.name,
        'national_site_code': polygon.national_site_code,
        'country_iso': polygon.country_iso,
        'parish': polygon.parish,
        'status_site': polygon.status_site
      });
  feature.writeTo(encoder.writer);
  //print(encoder.toText());

  try {
    http.Response response =
        await http.put(Uri.parse('$site_link/${polygon.id}'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: encoder.toText());

    //print(response.body);
    print(response.statusCode);
  } catch (e) {
    print(e);
  }
}

/// Send occurrence data to the API to UPDATE an occurrence entry.
void putOccurrenceData(Occurrence polygon) async {
  List<dynamic> auxmetrics = [];
  List<dynamic> auxattributes = [];
  polygon.metrics.forEach((metrica) {
    auxmetrics.add(metrica.toMap());
  });
  polygon.attributes.forEach((attribute) {
    auxattributes.add(attribute.toMap());
  });
  final encoder = geocore.GeoJSON.feature.encoder();
  geocore.Feature feature = geocore.Feature(
      id: polygon.id,
      geometry: geocore.Polygon.make(
          [polygon.pointToList()], geocore.GeoPoint2.coordinates),
      properties: {
        'designation': polygon.designation,
        'acronym': polygon.acronym,
        'toponym': polygon.toponym,
        'owner': polygon.owner,
        'altitude': polygon.altitude,
        'added_by': polygon.added_by_id,
        'site': polygon.site_id,
        'status_occurrence': polygon.status_occurrence,
        'algorithm_execution': null,
        'metrics': auxmetrics,
        'attributes': auxattributes,
      });
  feature.writeTo(encoder.writer);
  print('PUT-request:\n-----> ${auxmetrics}');

  try {
    http.Response response =
        await http.put(Uri.parse('$occurrence_link/${polygon.id}'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: encoder.toText());

    Map<String, dynamic> data = json.decode(
      utf8.decode(response.bodyBytes),
    );

    print('PUT-status: ${response.statusCode}');
    print('PUT-response: ${response.body}');
  } catch (e) {
    print(e);
  }
}

/// Request the API to DELETE a site entry given its respective id.
void deleteSite(Site polygon) async {
  try {
    http.Response response = await http.delete(
      Uri.parse('$site_link/${polygon.id}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    print('DELETE-status: ${response.statusCode}');
  } catch (e) {
    print(e);
  }
}

/// Request the API to DELETE an occurrence entry given its respective id.
void deleteOccurrence(Occurrence polygon) async {
  try {
    http.Response response = await http.delete(
      Uri.parse('$occurrence_link/${polygon.id}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    print('DELETE-status: ${response.statusCode}');
  } catch (e) {
    print(e);
  }
}

void fetchAndStoreOccurrence(Occurrence polygon) async {
  List<latlong.LatLng> points = [];
  List<Metric> metrics = [];
  try {
    http.Response response =
        await http.get(Uri.parse('$occurrence_link/${polygon.id}'));
    Map<String, dynamic> data = json.decode(
      utf8.decode(response.bodyBytes),
    );
    //print(data);

    

    List<dynamic> aux = data['geometry']['coordinates'][0];
    List<dynamic> met = data['properties']['metrics'];
    points = aux.map((e) => latlong.LatLng(e[1], e[0])).toList();
    metrics = met
        .map((e) => Metric(
            id: e["id"],
            type_id: e["type"],
            auto_value: 0,
            confirmed_value: double.parse(e["confirmed_value"]),
            unit_measurement: e["unit_measurement"]))
        .toList();
    Occurrence occurrencefeature = Occurrence(
      id: data["id"],
      designation: data["properties"]["designation"] ?? "",
      altitude: data["properties"]["altitude"] ?? 0,
      owner: data["properties"]["owner"] ?? "",
      acronym: data["properties"]["acronym"] ?? "",
      toponym: data["properties"]["toponym"] ?? "",
      status_occurrence: data["properties"]["status_occurrence"] ?? "",
      added_by_id: data["properties"]["added_by"] ?? '',
      site_id: data["properties"]["site"] ?? '',
      algorithm_execution_id: data["properties"]["algorithm_execution"] ?? 0,
      metrics: metrics,
      attributes: data["properties"]["attributes"]
          .map<Attribute>((attribute) => Attribute(
                id: attribute["id"],
                category: attribute["category"],
                value: attribute["value"],
              ))
          .toList(),
      points: points,
      borderColor:
          colorByStatus(data["properties"]["status_occurrence"] ?? ""),
      borderStrokeWidth: 2.0,
      isFilled: false,
    );
    //print(occurrencefeature);
    
  } catch (e) {
    throw Exception("Fail to load GEODATA: $e");
  } 
}

Future<void> auxiliar(List<Site> sitefeatures) async {
  int id, national_site_code = 0;
  List<latlong.LatLng> points = [];
  latlong.LatLng? location;
  String name, country_iso, parish, status_site = '';
  List<Attribute> attributes;

  try {
    http.Response response = await http.get(Uri.parse(sites_link));
    Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));

    sitefeatures.clear();
    data.forEach((key, value) {
      if (key == "features") {
        value.forEach((lista) {
          print(lista["id"]);
          if (lista['geometry'] != null) {
            List<dynamic> aux = lista['geometry']['coordinates'][0];
            Site sitefeature = Site(
              id: lista['id'],
              points: aux.map((e) => latlong.LatLng(e[1], e[0])).toList(),
              name: lista['properties']['name'],
              national_site_code: lista['properties']['national_site_code'],
              country_iso: lista['properties']['country_iso'],
              parish: lista['properties']['parish'],
              status_site: lista['properties']['status_site'],
              attributes: lista["properties"]["attributes"]
                  .map<Attribute>((attribute) => Attribute(
                        id: attribute["id"],
                        category: attribute["category"],
                        value: attribute["value"],
                      ))
                  .toList(),
              borderColor: const Color.fromARGB(255, 4, 173, 252),
              borderStrokeWidth: 2.0,
              isFilled: false,
            );
            sitefeatures.add(sitefeature);
          }
        });
      }
    });
  } catch (e) {
    throw Exception("Fail to load GEODATA: $e");
  }
}
