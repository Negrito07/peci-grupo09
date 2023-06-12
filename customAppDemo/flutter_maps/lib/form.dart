import 'package:flutter/material.dart';
import 'package:flutter_map_test/attribute.dart';
import 'package:flutter_map_test/Metric.dart';
import 'DataOperations.dart' as operation;
import 'package:flutter_map_test/Site.dart';
import 'package:flutter_map_test/Occurrence.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'package:flutter_map_test/DataOperations.dart' as operation;
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class FormularioSite extends StatefulWidget {
  final Site polygon;
  final List<Attribute> attributechoices;

  const FormularioSite(
      {super.key, required this.polygon, required this.attributechoices});

  @override
  State<FormularioSite> createState() => _FormularioSiteState();
}

class _FormularioSiteState extends State<FormularioSite> {
  final _formKey = GlobalKey<FormState>();

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
        operation.deleteSite(widget.polygon);
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Aviso!"),
      content: const Text("Tem a certeza que deseja excluir este sítio?"),
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

  Future<void> _createPDF(Site polygon) async {
    String fileName = polygon.name!;
    List<pw.Widget> widgets = [];
    int count = 0;
    pw.ListView w = pw.ListView(
      children: [
        pw.Text(polygon.toString(), style: pw.TextStyle(fontSize: 25)),
        for (var metrica in polygon.attributes) ...[
          pw.Text(metrica.toString(), style: pw.TextStyle(fontSize: 25)),
        ]
      ],
      direction: pw.Axis.vertical,
    );
    widgets.add(w);
    final dynamic downloadDirectory = await getExternalStorageDirectory();
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4, build: (pw.Context context) => widgets));

    final String filePath = '${downloadDirectory.path}/$fileName.pdf';
    final File file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    OpenFile.open(filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Site"),
        actions: [
          IconButton(
            tooltip: 'Delete Site',
            icon: const Icon(Icons.delete),
            onPressed: () => showAlertDialog(context),
          ),
          IconButton(
            tooltip: 'Download Site',
            icon: const Icon(Icons.download),
            onPressed: () => _createPDF(widget.polygon),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              initialValue: widget.polygon.name,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              onSaved: (value) {
                widget.polygon.name = value!;
              },
            ),
            TextFormField(
              initialValue: '${widget.polygon.national_site_code}',
              decoration: const InputDecoration(
                labelText: 'National Site Code',
              ),
              onSaved: (value) {
                widget.polygon.national_site_code = int.parse(value!);
              },
            ),
            TextFormField(
              initialValue: widget.polygon.country_iso,
              decoration: const InputDecoration(
                labelText: 'Country Iso',
              ),
              onSaved: (value) {
                widget.polygon.country_iso = value!;
              },
            ),
            TextFormField(
              initialValue: widget.polygon.parish,
              decoration: const InputDecoration(
                labelText: 'Parish',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              onSaved: (value) {
                widget.polygon.parish = value!;
              },
            ),
            TextFormField(
              initialValue: widget.polygon.added_by,
              decoration: const InputDecoration(
                labelText: 'Added By',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              onSaved: (value) {},
            ),
            DropdownButtonFormField(
              value: widget.polygon.status_site,
              onChanged: (value) {
                setState(() {
                  widget.polygon.status_site = value!;
                });
              },
              items: const [
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
                  return 'Please enter your name';
                }
                return null;
              },
              onSaved: (value) {
                widget.polygon.status_site = value!;
              },
            ),
            AttributesFormField(
              choices: widget.attributechoices,
              entries: widget.polygon.attributes,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  operation.putSiteData(widget.polygon);
                  Navigator.pop(context);
                }
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}

class FormularioOccurrence extends StatefulWidget {
  final Occurrence polygon;
  final List<Attribute> attributechoices;
  final List<dynamic> metricas;
  final List<Occurrence> occurrences;

  const FormularioOccurrence({
    super.key,
    required this.polygon,
    required this.metricas,
    required this.attributechoices,
    required this.occurrences,
  });

  @override
  State<FormularioOccurrence> createState() => _FormularioOccurrenceState();
}

class _FormularioOccurrenceState extends State<FormularioOccurrence> {
  final _formKey = GlobalKey<FormState>();

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
        operation.deleteOccurrence(widget.polygon);
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Aviso!"),
      content: const Text("Tem a certeza que deseja excluir essa ocorrência?"),
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

  Future<void> _createPDF(Occurrence polygon) async {
    String fileName = polygon.designation;
    List<pw.Widget> widgets = [];
    int count = 0;
    pw.ListView w = pw.ListView(
      children: [
        pw.Text(polygon.toString(), style: pw.TextStyle(fontSize: 25)),
        for (var metrica in polygon.metrics) ...[
          pw.Text(metrica.toString(), style: pw.TextStyle(fontSize: 25)),
        ],
        for (var attribute in polygon.attributes) ...[
          pw.Text(attribute.toString(), style: pw.TextStyle(fontSize: 25)),
        ]
      ],
      direction: pw.Axis.vertical,
    );
    widgets.add(w);
    final dynamic downloadDirectory = await getExternalStorageDirectory();
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4, build: (pw.Context context) => widgets));

    final String filePath = '${downloadDirectory.path}/$fileName.pdf';
    final File file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    OpenFile.open(filePath);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> mywidgets = [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Occurrence"),
        actions: [
          IconButton(
            tooltip: 'Delete Occurrence',
            icon: const Icon(Icons.delete),
            onPressed: () => showAlertDialog(context),
          ),
          IconButton(
            tooltip: 'Download Occurrence',
            icon: const Icon(Icons.download),
            onPressed: () => _createPDF(widget.polygon),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              readOnly: true,
              initialValue: '${widget.polygon.id}',
              decoration: const InputDecoration(
                labelText: 'ID',
              ),
            ),
            TextFormField(
              initialValue: widget.polygon.designation,
              decoration: const InputDecoration(
                labelText: 'Designation',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a designation';
                }
                return null;
              },
              onChanged: (value) {
                widget.polygon.designation = value;
              },
            ),
            TextFormField(
              initialValue: widget.polygon.owner,
              decoration: const InputDecoration(
                labelText: 'Owner',
              ),
              onSaved: (value) {
                widget.polygon.owner = value!;
              },
            ),
            TextFormField(
              initialValue: widget.polygon.acronym,
              decoration: const InputDecoration(
                labelText: 'Acronym',
              ),
              onChanged: (value) {
                widget.polygon.acronym = value;
              },
            ),
            TextFormField(
              initialValue: widget.polygon.toponym,
              decoration: const InputDecoration(
                labelText: 'Toponym',
              ),
              onChanged: (value) {
                widget.polygon.toponym = value;
              },
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              initialValue: '${widget.polygon.altitude}',
              decoration: const InputDecoration(
                labelText: 'Altitude',
              ),
              onChanged: (value) {
                widget.polygon.altitude = int.parse(value);
              },
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              initialValue: '${widget.polygon.added_by_id}',
              decoration: const InputDecoration(
                labelText: 'Added By',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              onChanged: (value) {
                widget.polygon.added_by_id = int.parse(value);
              },
            ),
            DropdownButtonFormField(
              value: widget.polygon.status_occurrence,
              onChanged: (value) {
                setState(() {
                  widget.polygon.status_occurrence = value!;
                });
              },
              items: const [
                DropdownMenuItem(
                  value: 'N',
                  child: Text("Not Verified"),
                ),
                DropdownMenuItem(
                  value: 'V',
                  child: Text("Verified"),
                ),
                DropdownMenuItem(
                  value: 'F',
                  child: Text("Verified - False Positive"),
                ),
                DropdownMenuItem(
                  value: 'T',
                  child: Text("Verified - True Positive"),
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
                widget.polygon.status_occurrence = value!;
              },
            ),
            TextFormField(
              initialValue: '${widget.polygon.algorithm_execution_id}',
              decoration: const InputDecoration(
                labelText: 'algorithm_execution_id',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              onSaved: (value) {
                widget.polygon.algorithm_execution_id = int.parse(value!);
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Metricas",
                  style: TextStyle(fontSize: 20),
                ),
                ButtonTheme(
                  minWidth: 50,
                  child: MaterialButton(
                    onPressed: () => {
                      setState(() {
                        widget.polygon.metrics.add(Metric());
                      }),
                    },
                    child: const Icon(Icons.add),
                  ),
                )
              ],
            ),
            // Métricas
            ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.polygon.metrics.length,
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Metrica $index",
                          style: const TextStyle(fontSize: 20),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => {
                            setState(() {
                              widget.polygon.metrics.removeAt(index);
                            })
                          },
                        ),
                      ],
                    ),
                    TextFormField(
                      initialValue:
                          '${widget.polygon.metrics[index].auto_value}',
                      decoration: const InputDecoration(
                        labelText: 'Auto_value',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        widget.polygon.metrics[index].auto_value =
                            double.parse(value!);
                      },
                    ),
                    TextFormField(
                      initialValue:
                          '${widget.polygon.metrics[index].confirmed_value}',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Confirmed_value',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        widget.polygon.metrics[index].confirmed_value =
                            double.parse(value!);
                      },
                    ),
                    DropdownButtonFormField(
                      value: widget.polygon.metrics[index].type_id,
                      onChanged: (value) {
                        setState(() {
                          widget.polygon.metrics[index].type_id =
                              value! as String;
                        });
                      },
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(""),
                        ),
                        for (var v in widget.metricas) ...[
                          DropdownMenuItem(
                            value: v["name"],
                            child: Text(v["name"]),
                          ),
                        ]
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Type',
                      ),
                      onSaved: (value) {
                        widget.polygon.metrics[index].type_id =
                            value! as String;
                      },
                    ),
                    TextFormField(
                      initialValue:
                          widget.polygon.metrics[index].unit_measurement,
                      decoration: const InputDecoration(
                        labelText: 'Unit Measurement',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        widget.polygon.metrics[index].unit_measurement = value!;
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            AttributesFormField(
              choices: widget.attributechoices,
              entries: widget.polygon.attributes,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  operation.putOccurrenceData(widget.polygon);
                  
                  Navigator.pop(context);
                }
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}

class OccurrenceCreationForm extends StatefulWidget {
  final Occurrence polygon;
  final VoidCallback onSaved;
  final VoidCallback onCancel;
  final List<dynamic> metricas;
  const OccurrenceCreationForm(
      {super.key,
      required this.polygon,
      required this.onSaved,
      required this.onCancel,
      required this.metricas});

  @override
  State<OccurrenceCreationForm> createState() => _OccurrenceCreationFormState();
}

class _OccurrenceCreationFormState extends State<OccurrenceCreationForm> {
  final _formKey = GlobalKey<FormState>();
  final List<Metric> entries = [];
  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Scaffold(
            appBar: AppBar(
              title: const Text("Add Occurrence"),
              actions: [
                IconButton(
                  tooltip: 'Cancel Creation',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    widget.onCancel();
                    Navigator.pop(context);
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
                    shrinkWrap: true,
                    children: [
                      TextFormField(
                        initialValue: widget.polygon.designation,
                        decoration: const InputDecoration(
                          labelText: 'Designation',
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a designation';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          widget.polygon.designation = value;
                        },
                      ),
                      TextFormField(
                        initialValue: '${widget.polygon.altitude}',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Altitude',
                        ),
                        onChanged: (value) {
                          widget.polygon.altitude = int.parse(value);
                        },
                      ),
                      TextFormField(
                        initialValue: widget.polygon.owner,
                        decoration: const InputDecoration(
                          labelText: 'Owner',
                        ),
                        onChanged: (newValue) {
                          widget.polygon.owner = newValue;
                        },
                      ),
                      TextFormField(
                        initialValue: widget.polygon.acronym,
                        decoration: const InputDecoration(
                          labelText: 'Acronym',
                        ),
                        onChanged: (value) {
                          widget.polygon.acronym = value;
                        },
                      ),
                      TextFormField(
                        initialValue: widget.polygon.toponym,
                        decoration: const InputDecoration(
                          labelText: 'Toponym',
                        ),
                        onChanged: (value) {
                          widget.polygon.toponym = value;
                        },
                      ),
                      TextFormField(
                        initialValue: '${widget.polygon.added_by_id}',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Added By',
                        ),
                        onChanged: (value) {
                          widget.polygon.added_by_id = int.parse(value);
                        },
                      ),
                      DropdownButtonFormField(
                        value: widget.polygon.status_occurrence,
                        onChanged: (value) {
                          print(widget.metricas);
                          setState(() {
                            widget.polygon.status_occurrence = value!;
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
                          DropdownMenuItem(
                            value: 'VF',
                            child: Text("Verified - False Positive"),
                          ),
                          DropdownMenuItem(
                            value: 'VT',
                            child: Text("Verified - True Positive"),
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
                          widget.polygon.status_occurrence = value!;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Metricas",
                            style: TextStyle(fontSize: 20),
                          ),
                          ButtonTheme(
                            minWidth: 50,
                            child: MaterialButton(
                              onPressed: () => {
                                setState(() {
                                  entries.add(Metric());
                                }),
                                print(entries)
                              },
                              child: Icon(Icons.add),
                            ),
                          )
                        ],
                      ),
                      ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: entries.length,
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Metrica $index",
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => {
                                      setState(() {
                                        entries.removeAt(index);
                                      })
                                    },
                                  ),
                                ],
                              ),
                              TextFormField(
                                initialValue: '${entries[index].auto_value}',
                                decoration: const InputDecoration(
                                  labelText: 'Auto_value',
                                ),
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  entries[index].auto_value =
                                      double.parse(value!);
                                },
                              ),
                              TextFormField(
                                initialValue:
                                    '${entries[index].confirmed_value}',
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Confirmed_value',
                                ),
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  entries[index].confirmed_value =
                                      double.parse(value!);
                                },
                              ),
                              DropdownButtonFormField(
                                value: entries[index].type_id,
                                onChanged: (value) {
                                  setState(() {
                                    entries[index].type_id = value! as String;
                                  });
                                },
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text(""),
                                  ),
                                  for (var v in widget.metricas) ...[
                                    DropdownMenuItem(
                                      value: v["name"],
                                      child: Text(v["name"]),
                                    ),
                                  ]
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Type',
                                ),
                                onSaved: (value) {
                                  entries[index].type_id = value! as String;
                                },
                              ),
                              TextFormField(
                                initialValue:
                                    '${entries[index].unit_measurement}',
                                decoration: const InputDecoration(
                                  labelText: 'Unit Measurement',
                                ),
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  entries[index].unit_measurement = value!;
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: () => {
                                if (_formKey.currentState!.validate())
                                  {
                                    _formKey.currentState!.save(),
                                    widget.polygon.metrics = entries,
                                    widget.onSaved(),
                                    Navigator.pop(context),
                                  }
                              },
                          child: const Text("Add"))
                    ],
                  ),
                ),
              ),
            )));
  }
}
