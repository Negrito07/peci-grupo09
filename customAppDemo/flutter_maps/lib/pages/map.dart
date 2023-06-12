import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_test/Occurrence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_test/attribute.dart';
import 'package:flutter_map_test/form.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_map_line_editor/dragmarker.dart';
import 'package:flutter_map_line_editor/polyeditor.dart';
import 'package:maps_toolkit/maps_toolkit.dart';
import 'package:flutter_map_test/Site.dart';
import 'package:location/location.dart';
import 'package:flutter_map_test/DataOperations.dart' as operation;
import 'SitesList.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  final Site site;
  final List<Attribute> attributechoices;

  const MapPage({
    super.key,
    required this.site,
    required this.attributechoices,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // bottom app bar
  // opcoes de menu
  late List<Widget> _invisibleMenuOptions;
  late List<Widget> _visibleMenuOptions;
  late List<dynamic> metricas = [];
  late LocationData _currentPosition;
  /// Save MENU state
  bool _menuIsVisible = false;

  /// Show MENU options
  void _showMenu() {
    setState(() {
      if (!_menuIsVisible) {
        // esconder icone de menu
        var temp = _visibleMenuOptions;
        // mostrar opcoes
        _visibleMenuOptions = _invisibleMenuOptions;
        // guardar icone de menu
        _invisibleMenuOptions = temp;
        // lembrar estado
        _menuIsVisible = true;
      }
    });
  }

  /// Hide MENU options
  void _hideMenu() {
    setState(() {
      if (_menuIsVisible) {
        // pegar icone de menu
        var temp = _invisibleMenuOptions;
        //esconder opcoes
        _invisibleMenuOptions = _visibleMenuOptions;
        // mostrar icone de menu
        _visibleMenuOptions = temp;
        // lembrar estado
        _menuIsVisible = false;
      }
    });
  }

  void showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("Não"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Sim"),
      onPressed: () {
        Navigator.pushNamed(context, '/');
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Aviso!"),
      content: const Text("Tem a certeza que quer sair?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void _pauseEditing() {
    setState(() {
      if (_isEditing && !_editingPaused) {
        _isEditing = false;
        _editingPaused = true;
      }
    });
  }

  void _resumeEditing() {
    setState(() {
      if (!_isEditing && _editingPaused) {
        _isEditing = true;
        _editingPaused = false;
      }
    });
  }

  void _pauseSelecting() {
    setState(() {
      if (_isSelecting) {
        _isSelecting = false;
      }
    });
  }

  void _resumeSelecting() {
    setState(() {
      if (!_isSelecting) {
        _isSelecting = true;
      }
    });
  }

  /// Save state of edition mode
  bool _isEditing = false;
  bool _isSelecting = false;
  String selected = '';

  /// Remeber if a editing operation was interrupted
  bool _editingPaused = false;

  /// Polygon to be added for the user interaction
  late Site siteToAdd;
  late Occurrence occurrenceToAdd;

  Map<String, dynamic> data = {};

  /// List to store the API polygons
  List<Site> sitefeatures = [];
  List<Occurrence> occurrencefeatures = [];

  /// Variable to edit the polygon added by the user
  late PolyEditor siteEditor;
  late PolyEditor occurrenceEditor;

  /// Controller of the map, used in Flutter Maps
  late MapController mapController;

  /// List of map layers
  List<Widget> layers = [];

  /// List of Tile layers to toggle
  List<TileLayer> tiles = [
    TileLayer(
      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    ),
    TileLayer(
      urlTemplate:
          "https://api.mapbox.com/v4/mapbox.satellite/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibmVncmlnYWJyaWVsIiwiYSI6ImNsZ2k0MnQyODBnYnMzanBndnRwOXNjODgifQ.ku8BfZvUIwf0foWsv8rdUw",
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    ),
  ];

  /// Current Tile layer index
  int tile = 0;

  /// Toggles Tile layer index
  void _toggleTile() {
    setState(() {
      if (tile == 0) {
        tile = 1;
      } else if (tile == 1) {
        tile = 0;
      }
    });
  }

  /// Function to add the point that the user input in the map
  void _addPointToPolygon() {
    setState(() {
      if (selected == "site") {
        siteEditor.add(siteToAdd.points, mapController.center);
      } else if (selected == "occurrence") {
        occurrenceEditor.add(occurrenceToAdd.points, mapController.center);
      }
    });
  }

  /// Function to remove the point that the user remove in the map
  void _removePointFromPolygon() {
    setState(() {
      if (selected == "site") {
        if (siteToAdd.points.isNotEmpty) {
          siteEditor.remove(siteToAdd.points.length - 1);
        }
      } else if (selected == "occurrence") {
        if (occurrenceToAdd.points.isNotEmpty) {
          occurrenceEditor.remove(occurrenceToAdd.points.length - 1);
        }
      }
    });
  }

  /// Function to confirm the creation of the polygon
  void _confirmPolygonCreation() {
    setState(() {
      if (selected == "site") {
        // verificar se poligono a adicionar tem pontos suficientes para ser um poligono
        if (siteToAdd.points.length > 2) {
          // adicionar ponto de fechamento do polígono criado
          siteToAdd.points.add(siteToAdd.points[0]);
          // novo poligono a criar
          siteToAdd = Site(
            borderColor: const Color.fromARGB(255, 4, 173, 252),
            borderStrokeWidth: 2.0,
            isFilled: false,
            points: [],
            attributes: [],
          );

          siteEditor = PolyEditor(
            points: siteToAdd.points,
            pointIcon: const Icon(Icons.crop_square, size: 23),
            intermediateIcon:
                const Icon(Icons.lens, size: 15, color: Colors.grey),
            addClosePathMarker: true,
          );
          // adicionar referencia do novo poligono a ser criado ao mapa
          sitefeatures.add(siteToAdd);
        }
      } else if (selected == "occurrence") {
        if (occurrenceToAdd.points.length > 2) {
          // adicionar ponto de fechamento do polígono criado
          occurrenceToAdd.points.add(occurrenceToAdd.points[0]);

          // novo poligono a criar
          occurrenceToAdd = Occurrence(
            borderColor: const Color.fromARGB(255, 252, 4, 4),
            borderStrokeWidth: 2.0,
            isFilled: false,
            site_id: widget.site.id!,
            points: [],
            attributes: [],
          );

          occurrenceEditor = PolyEditor(
            points: occurrenceToAdd.points,
            pointIcon: const Icon(Icons.crop_square, size: 23),
            intermediateIcon:
                const Icon(Icons.lens, size: 15, color: Colors.grey),
            addClosePathMarker: true,
          );
          // adicionar referencia do novo poligono a ser criado ao mapa
          occurrencefeatures.add(occurrenceToAdd);
        }
      }
      _isEditing = false;
    });
  }

  /// Function to cancel the polygon creation
  void _cancelPolygonCreation() {
    setState(() {
      if (selected == "site") {
        if (siteToAdd.points.isNotEmpty) {
          siteToAdd.points.clear();
        }
      } else if (selected == "occurrence") {
        if (occurrenceToAdd.points.isNotEmpty) {
          occurrenceToAdd.points.clear();
        }
      }
      _isEditing = false;
    });
  }

  /// Function to verify if the user clicked in the polygon.
  /// If he did, return the polygon clicked
  Map<dynamic, bool> _checkInPolygon(LatLng position) {
    Map<dynamic, bool> m = {null: false};

    occurrencefeatures.forEach((polygon) {
      if (PolygonUtil.containsLocation(
          position, _convertLatlngPolygon(polygon), true)) {
        m = {polygon: true};
      }
    });
    if (m.values.first == true) {
      return m;
    }
    sitefeatures.forEach((polygon) {
      if (PolygonUtil.containsLocation(
          position, _convertLatlngPolygon(polygon), true)) {
        m = {polygon: true};
      }
    });
    return m;
  }

  List<LatLng> _convertLatlngPolygon(Polygon polygon) {
    List<LatLng> converted_points = [];
    List<latlong.LatLng> points = polygon.points;

    points.forEach((point) {
      final p = LatLng(point.latitude, point.longitude);
      converted_points.add(p);
    });
    return converted_points;
  }

  LatLng _convertLatlngPoint(latlong.LatLng point) {
    final p = LatLng(point.latitude, point.longitude);
    return p;
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  /// Function to pop up the form when the user confirmed the creation of the polygon
  void _showSiteModel(Site polygon) {
    final _formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height / 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Add Site"),
              actions: [
                IconButton(
                  tooltip: 'Cancel Creation',
                  icon: const Icon(Icons.close),
                  onPressed: () => {
                    _cancelPolygonCreation(),
                    Navigator.pop(context),
                  },
                ),
              ],
            ),
            body: Center(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ListView(
                    scrollDirection: Axis.vertical,
                    children: [
                      TextFormField(
                        readOnly: true,
                        initialValue: "",
                        decoration: const InputDecoration(
                          labelText: 'Id',
                        ),
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Name',
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          polygon.name = value!;
                        },
                      ),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'National Site Code',
                        ),
                        onSaved: (value) {
                          polygon.national_site_code = int.parse(value!);
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Country ISO',
                        ),
                        onSaved: (value) {
                          polygon.country_iso = value!;
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Parish',
                        ),
                        onSaved: (value) {
                          polygon.parish = value!;
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Added By',
                        ),
                        onSaved: (value) {
                          polygon.added_by = value!;
                        },
                      ),
                      DropdownButtonFormField(
                        value: polygon.status_site,
                        onChanged: (value) {
                          setState(() {
                            polygon.status_site = value!;
                          });
                        },
                        items: const [
                          DropdownMenuItem(
                            value: "",
                            child: Text(""),
                          ),
                          DropdownMenuItem(
                            value: 'N',
                            child: Text("Not Verified"),
                          ),
                          DropdownMenuItem(
                            value: 'V',
                            child: Text("Verified"),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Status',
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a status';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          polygon.status_site = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: () => {
                                if (_formKey.currentState!.validate())
                                  {
                                    polygon.id = 0,
                                    _formKey.currentState!.save(),
                                    operation.postSiteData(polygon),
                                    _confirmPolygonCreation(),
                                    Navigator.pop(context),
                                  }
                              },
                          child: const Text("Add"))
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showOccurrenceModel(Occurrence polygon) {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return OccurrenceCreationForm(
            polygon: polygon,
            onSaved: () {
              _confirmPolygonCreation();
              operation.postOccurrenceData(polygon, widget.site.id!);
            },
            onCancel: () {
              _cancelPolygonCreation();
            },
            metricas: metricas,
          );
        });
  }
  FollowOnLocationUpdate loc = FollowOnLocationUpdate.never;
  Icon icon =  Icon(Icons.gps_not_fixed);

  @override
  void initState() {
    super.initState();

    //operation.fetchAndStoreData(sitefeatures, occurrencefeatures);
    // inicializar mapController aqui, garante que ele seja criado antes do mapa
    mapController = MapController();
    //WidgetsBinding.instance.addPostFrameCallback((_) {});

    siteToAdd = Site(
      borderColor: const Color.fromARGB(255, 4, 173, 252),
      borderStrokeWidth: 2.0,
      isFilled: false,
      points: [],
      attributes: [],
    );

    occurrenceToAdd = Occurrence(
      borderColor: const Color.fromARGB(255, 252, 4, 4),
      borderStrokeWidth: 2.0,
      isFilled: false,
      site_id: widget.site.id!,
      points: [],
      attributes: [],
    );

    siteEditor = PolyEditor(
      points: siteToAdd.points,
      pointIcon: const Icon(Icons.crop_square, size: 23),
      intermediateIcon: const Icon(Icons.lens, size: 15, color: Colors.grey),
      addClosePathMarker: true,
    );

    occurrenceEditor = PolyEditor(
      points: occurrenceToAdd.points,
      pointIcon: const Icon(Icons.crop_square, size: 23),
      intermediateIcon: const Icon(Icons.lens, size: 15, color: Colors.grey),
      addClosePathMarker: true,
    );

    sitefeatures.add(siteToAdd);
    occurrencefeatures.add(occurrenceToAdd);

    _invisibleMenuOptions = [
      IconButton(
        tooltip: 'Logout',
        icon: const Icon(Icons.logout),
        onPressed: () => showAlertDialog(context),
      ),
      IconButton(
        tooltip: 'Refresh',
        icon: const Icon(Icons.refresh),
        onPressed: () => {
          operation.fetchAndStoreSiteSpecificData(widget.site, widget.site.id!),
          operation.fetchAndStoreOccurrenceSpecificData(
              occurrencefeatures, widget.site.id!),
        },
      ),
      IconButton(
        tooltip: 'Search',
        icon: const Icon(Icons.search),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SitesList()),
          );
        },
      ),
      IconButton(
        tooltip: 'Toggle Map Layer',
        icon: const Icon(Icons.layers),
        onPressed: _toggleTile,
      ),
    ];

    // bottom app bar
    _visibleMenuOptions = [
      IconButton(
        tooltip: 'Open navigation menu',
        icon: const Icon(Icons.menu),
        onPressed: () => {
          if (_isSelecting)
            {
              _pauseSelecting(),
            },
          if (_isEditing)
            {
              _pauseEditing(),
            },
          _showMenu(),
        },
      ),
      IconButton(
        tooltip: 'Follow current location',
        icon: icon,
        onPressed: () => {
          setState(() {
            if (loc == FollowOnLocationUpdate.never){
              icon = Icon(Icons.gps_fixed);
              loc = FollowOnLocationUpdate.always;
              print(icon);
            }else{
              icon = Icon(Icons.gps_not_fixed);
              loc = FollowOnLocationUpdate.never;
              print(icon);
            }
          })
        },
      ),
    ];

    sitefeatures.add(widget.site);
    operation.fetchAndStoreOccurrenceSpecificData(
        occurrencefeatures, widget.site.id!);
    operation.fetchMetricTypes(metricas);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              rotationThreshold: 2000,
              minZoom: 2,
              zoom: 11,
              maxZoom: 18,
              center: LatLngBounds.fromPoints(widget.site.points).center,
              maxBounds: LatLngBounds(
                latlong.LatLng(-90, -180.0),
                latlong.LatLng(90.0, 180.0),
              ),
              onTap: (_, latlong.LatLng location) {
                if (!_isEditing) {
                  Map<dynamic, bool> m =
                      _checkInPolygon(_convertLatlngPoint(location));
                  if (m.values.first == true) {
                    if ((m.keys.first.runtimeType == Site)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => FormularioSite(
                                  polygon: m.keys.first,
                                  attributechoices: widget.attributechoices,
                                )),
                      );
                    } else if ((m.keys.first.runtimeType == Occurrence)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => FormularioOccurrence(
                                  polygon: m.keys.first,
                                  metricas: metricas,
                                  attributechoices: widget.attributechoices,
                                  occurrences:occurrencefeatures
                                )),
                      );
                    }
                  }
                }
              },
            ),
            mapController: mapController,
            children: [
              tiles[tile], // switchable background tile map
              PolygonLayer(polygons: sitefeatures),
              PolygonLayer(polygons: occurrencefeatures),
              DragMarkers(markers: siteEditor.edit()),
              DragMarkers(markers: occurrenceEditor.edit()),
              
              CurrentLocationLayer(
                followOnLocationUpdate: loc,
                turnOnHeadingUpdate: TurnOnHeadingUpdate.never,
                style: LocationMarkerStyle(
                  marker: const DefaultLocationMarker(
                    child: Icon(
                      Icons.navigation,
                      color: Colors.white,
                    ),
                  ),
                  markerSize: const Size(40, 40),
                  markerDirection: MarkerDirection.heading,
              )),
              
            ],
          ),
          const Positioned.fill(
              child: Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.adjust,
                    size: 50,
                    color: Colors.black,
                  ))),
          (_isSelecting
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      FloatingActionButton.extended(

                        onPressed: () => {
                          setState(() {
                            selected = "site";
                            _isEditing = true;
                            _isSelecting = false;
                            _addPointToPolygon();
                          })
                        },
                        tooltip: 'Create New Site',
                        label: const SizedBox(
                          width: 80,
                          child: Center(
                            child: Text("Site"),
                          ),
                        ),
                        backgroundColor: const Color.fromARGB(255, 4, 173, 252),
                      ),
                    ]),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton.extended(
                          onPressed: () => {
                            setState(() {
                              selected = "occurrence";
                              _isEditing = true;
                              _isSelecting = false;
                              _addPointToPolygon();
                            })
                          },
                          tooltip: 'Create New Occurrence',
                          label: const Text("Occurence"),
                          backgroundColor: const Color.fromARGB(255, 252, 4, 4),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 90,
                    ),
                  ],
                )
              : const SizedBox(height: 0)),
          (_isEditing &
                  (siteToAdd.points.isNotEmpty ||
                      occurrenceEditor.points.isNotEmpty)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          onPressed: _removePointFromPolygon,
                          tooltip: 'Remove Last Point',
                          mini: true,
                          child: const Icon(Icons.remove),
                        ),
                        const SizedBox(
                          width: 70,
                        ),
                        FloatingActionButton(
                          onPressed: _addPointToPolygon,
                          tooltip: 'Add Point',
                          mini: true,
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 50,
                    ),
                  ],
                )
              : const SizedBox(height: 0)),
          (_isEditing &
                  (siteToAdd.points.isNotEmpty ||
                      occurrenceEditor.points.isNotEmpty)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          backgroundColor: Colors.red,
                          onPressed: _cancelPolygonCreation,
                          tooltip: 'Delete polygon',
                          mini: true,
                          child: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 85,
                    ),
                  ],
                )
              : const SizedBox(height: 0)),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: Colors.blue,
        child: IconTheme(
          data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
          child: Row(
            mainAxisAlignment: _menuIsVisible
                ? MainAxisAlignment.start
                : MainAxisAlignment.spaceBetween,
            children: _visibleMenuOptions,
          ),
        ),
      ),
      floatingActionButtonLocation: (_menuIsVisible
          ? FloatingActionButtonLocation.endDocked
          : FloatingActionButtonLocation.centerDocked),
      floatingActionButton: (_menuIsVisible
          ? FloatingActionButton(
              onPressed: () => {
                _hideMenu(),
                if (_editingPaused)
                  {
                    _resumeEditing(),
                  }
              },
              tooltip: 'Hide options',
              child: const Icon(Icons.reply),
            )
          : (_isSelecting
              ? FloatingActionButton(
                  onPressed: () => {
                    setState(() {
                      _isSelecting = false;
                    })
                  },
                  tooltip: 'Cancel Selection',
                  child: const Icon(Icons.close),
                )
              : (siteToAdd.points.isEmpty & occurrenceToAdd.points.isEmpty
                  ? FloatingActionButton(
                      onPressed: () => {
                        setState(() {
                          _isSelecting = true;
                        })
                      },
                      tooltip: 'Add Point',
                      child: const Icon(Icons.add),
                    )
                  : FloatingActionButton(
                      backgroundColor: Colors.green,
                      onPressed: () => {
                        if (siteToAdd.points.length > 2)
                          {
                            _showSiteModel(siteToAdd),
                          }
                        else if (occurrenceToAdd.points.length > 2)
                          {
                            _showOccurrenceModel(occurrenceToAdd),
                          }
                      },
                      tooltip: 'Add Polygon',
                      child: const Icon(Icons.check),
                    )))),
    );
  }
}
