import 'package:flutter/material.dart';

class Attribute {
  int? id;
  String? category;
  String? value;

  Attribute({
    this.id,
    this.category,
    this.value,
  });

  Map<String, dynamic> toMap() {
    return {"id": id, "category": category, "value": value};
  }

  @override
  String toString() {
    return """

 Attribute:
 id: $id,
 category: $category,
 value: $value
""";
  }
}

/// Stateful Widget to act as an attributes field on forms.
/// Allow adding, editing and deleting attributes entries from a list of
/// attribute choices.
class AttributesFormField extends StatefulWidget {
  final List<Attribute> choices;
  final List<Attribute> entries;

  const AttributesFormField({
    super.key,
    required this.choices,
    required this.entries,
  });

  @override
  State<AttributesFormField> createState() => _AttributesFormFieldState();
}

class _AttributesFormFieldState extends State<AttributesFormField> {
  @override
  void initState() {
    super.initState();
    // add a null choice to the choices list
    widget.choices.add(Attribute());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text("Attributes"),
            IconButton(
              tooltip: "Add new attribute",
              icon: const Icon(Icons.add),
              onPressed: () => {
                setState(() {
                  widget.entries.add(Attribute());
                }),
              },
            )
          ],
        ),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: widget.entries.length,
          itemBuilder: (context, index) {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Attribute $index'),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: (() {
                        setState(() {
                          widget.entries.removeAt(index);
                        });
                      }),
                    ),
                  ],
                ),
                AttributeField(
                  attribute: widget.entries[index],
                  choices: widget.choices,
                ),
              ],
            );
          },
          separatorBuilder: (context, index) {
            return const Divider();
          },
        )
      ],
    );
  }
}

class AttributeField extends StatefulWidget {
  const AttributeField({
    super.key,
    required this.attribute,
    required this.choices,
    this.onSaved,
  });

  final Attribute attribute;
  final List<Attribute> choices;
  final ValueSetter<Attribute>? onSaved;

  @override
  State<AttributeField> createState() => _AttributeFieldState();
}

class _AttributeFieldState extends State<AttributeField> {
  final List<Attribute> _choicesByCategory = [Attribute()];

  @override
  void initState() {
    super.initState();

    _choicesByCategory.addAll(widget.choices.where((choice) =>
        choice.category == widget.attribute.category &&
        choice.category != null));

    print(_choicesByCategory);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // category field
        DropdownButtonFormField(
          value: widget.attribute.category,
          items: widget.choices
              .map<String?>((choice) => choice.category)
              .toSet()
              .map<DropdownMenuItem<String>>((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category ?? ""),
                  ))
              .toList(),
          onChanged: (category) {
            setState(() {
              widget.attribute.category = category;
              // previous choice is not valid for the new selected category
              widget.attribute.value = null;
              // filter choices by the new selected category
              _choicesByCategory.replaceRange(
                1,
                _choicesByCategory.length,
                widget.choices.where((choice) =>
                    choice.category == widget.attribute.category &&
                    choice.category != null),
              );
            });
          },
          decoration: const InputDecoration(
            labelText: "Category",
          ),
        ),
        // value field
        DropdownButtonFormField(
          // value field complete choice selection
          value: widget.attribute.value,
          items: _choicesByCategory
              .map<DropdownMenuItem<String>>((choice) => DropdownMenuItem(
                    value: choice.value,
                    child: Text(choice.value ?? ""),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              widget.attribute.value = value;
              widget.attribute.id = _choicesByCategory
                  .firstWhere((choice) => choice.value == value)
                  .id;
            });
          },
          decoration: const InputDecoration(
            labelText: "Value",
          ),
        ),
      ],
    );
  }
}
