import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_test/DataOperations.dart' as operation;
import 'package:flutter_map_test/Site.dart';
import 'package:flutter_map_test/attribute.dart';
import 'package:flutter_map_test/constants.dart';
import 'map.dart';

class SitesList extends StatefulWidget {
  const SitesList({super.key});

  @override
  State<SitesList> createState() => _SitesListState();
}

class _SitesListState extends State<SitesList> {
  List<Site> sitelist = [];
  late List<Site> sites = sitelist;
  bool isloadingSite = true;
  bool isloadingAttributes = true;
  List<Attribute> attributechoices = [];
  @override
  void initState() {
    super.initState();    
    operation.auxiliar(sitelist).whenComplete(() => setState(() {
          isloadingSite = false;
        }));
    operation.fetchAttributes(attributechoices).whenComplete(() => setState(() {
          isloadingAttributes = false;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Choose your site'),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset(
                  'assets/logo2.png',
                  width: 50.0,
                  height: 50.0,
                )
              ],
            )
          ],
        ),
        body: isloadingSite || isloadingAttributes
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Nome do Site',
                        border: OutlineInputBorder(
                            borderSide:
                                BorderSide(width: 1.0, color: Colors.black))),
                    onChanged: searchSite,
                  ),
                  Expanded(
                      child: ListView.separated(
                    separatorBuilder: (context, index) {
                      return const Divider();
                    },
                    itemCount: sites.length,
                    itemBuilder: (BuildContext context, index) {
                      final site = sites[index];
                      return ListTile(
                        title: Text(site.name!),
                        subtitle: Text('Id : ${site.id}'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapPage(
                                    site: site,
                                    attributechoices: attributechoices),
                              ));
                        },
                        iconColor: Colors.black,
                      );
                    },
                  ))
                ],
              ));
  }

  void searchSite(String query) {
    final suggestion = sitelist.where((site) {
      final sitename = site.name!.toLowerCase();
      final input = query.toLowerCase();
      return sitename.contains(input);
    }).toList();
    setState(() => sites = suggestion);
  }
}
