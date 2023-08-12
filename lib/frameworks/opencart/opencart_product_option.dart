import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../models/app_model.dart';

List allowedTypes = [
  'select',
  'text',
  'textarea',
  'date',
  'time',
  'datetime',
  'radio',
  'checkbox'
];

class OpencartOptionInput extends StatefulWidget {
  final Map<String, dynamic>? option;
  final dynamic value;
  final bool? required;
  final Function? onChanged;
  final Function? onPriceChanged;
  final Function? onRemoved;

  const OpencartOptionInput(
      {this.option,
      this.required,
      this.onChanged,
      this.value,
      this.onPriceChanged,
      this.onRemoved});

  @override
  State<OpencartOptionInput> createState() => _OpencartOptionInputState();
}

class _OpencartOptionInputState extends State<OpencartOptionInput> {
  String? valueTxt;
  List? selectedValue;

  @override
  void initState() {
    super.initState();
    if (['select', 'radio'].contains(widget.option!['type'])) {
      var options = List<Map<String, dynamic>>.from(
          widget.option!['product_option_value']);
      final selectedOption = options.firstWhereOrNull(
          (o) => o['product_option_value_id'] == widget.value);
      valueTxt = selectedOption != null ? selectedOption['name'] : '';
    } else if (widget.option!['type'] == 'checkbox') {
      selectedValue = widget.value ?? [];
    } else {
      valueTxt = widget.value ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyRate = Provider.of<AppModel>(context).currencyRate;
    String? type = widget.option!['type'];
    var name = HtmlUnescape().convert(widget.option!['name']);
    var options =
        List<Map<String, dynamic>>.from(widget.option!['product_option_value'])
            .where((element) => element['quantity'] != '0')
            .toList();
    final isRequired = widget.option!['required'] == '1';
    final requiredTxt = isRequired ? ' (*)' : '';

    if (!allowedTypes.contains(type)) return Container();

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Text(
              name + requiredTxt,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          if (type == 'select')
            InputSelection(
              name: name,
              options: options,
              value: valueTxt,
              onChanged: (item) {
                setState(() {
                  valueTxt =
                      "${item['name']} (${item["price_prefix"]}${PriceTools.getCurrencyFormatted(item["price"], currencyRate)})";
                });
                widget.onChanged!({
                  widget.option!['product_option_id']:
                      item['product_option_value_id']
                });
                var extraPrice = item['price_prefix'] == '+'
                    ? double.parse(item['price'])
                    : double.parse(item['price']) * (-1);
                widget.onPriceChanged!(
                    {widget.option!['product_option_id']: extraPrice});
              },
            ),
          if (type == 'text' || type == 'textarea')
            InputText(
              name: name,
              value: valueTxt,
              maxLines: type == 'textarea' ? 5 : 1,
              onChanged: (item) {
                setState(() {
                  valueTxt = item;
                });
                widget.onChanged!({widget.option!['product_option_id']: item});
              },
            ),
          if (type == 'date' || type == 'time' || type == 'datetime')
            InputDateTime(
              name: name,
              value: valueTxt,
              type: type,
              onChanged: (item) {
                setState(() {
                  valueTxt = item;
                });
                widget.onChanged!({widget.option!['product_option_id']: item});
              },
            ),
          if (type == 'radio')
            InputRadio(
              name: name,
              options: options,
              value: valueTxt,
              onChanged: (item) {
                setState(() {
                  valueTxt = item['product_option_value_id'];
                });
                widget.onChanged!({
                  widget.option!['product_option_id']:
                      item['product_option_value_id']
                });
                var extraPrice = item['price_prefix'] == '+'
                    ? double.parse(item['price'])
                    : double.parse(item['price']) * (-1);
                widget.onPriceChanged!(
                    {widget.option!['product_option_id']: extraPrice});
              },
            ),
          if (type == 'checkbox')
            InputCheckBox(
              name: name,
              options: options,
              selectedValue: selectedValue,
              onChanged: (id) {
                if (selectedValue!.contains(id)) {
                  setState(() {
                    selectedValue!.removeWhere((o) => o == id);
                  });
                } else {
                  setState(() {
                    selectedValue!.add(id);
                  });
                }
                if ((selectedValue ?? []).isNotEmpty) {
                  widget.onChanged!(
                      {widget.option!['product_option_id']: selectedValue});
                } else {
                  widget.onRemoved!(widget.option!['product_option_id']);
                }
                var extraPrice = options.fold(0.0, (dynamic sum, option) {
                  if (selectedValue != null &&
                      selectedValue!
                          .contains(option['product_option_value_id'])) {
                    var extra = option['price_prefix'] == '+'
                        ? double.parse(option['price'])
                        : double.parse(option['price']) * (-1);
                    return sum + extra;
                  } else {
                    return sum;
                  }
                });
                widget.onPriceChanged!(
                    {widget.option!['product_option_id']: extraPrice});
              },
            ),
        ],
      ),
    );
  }
}

class InputSelection extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final String name;
  final String? value;
  final double width;
  final double height;
  final Function? onChanged;

  const InputSelection(
      {required this.name,
      required this.options,
      required this.value,
      this.width = double.infinity,
      this.height = 42.0,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onChanged != null) {
          showOptions(context);
        }
      },
      child: Container(
        decoration:
            BoxDecoration(border: Border.all(width: 1.0, color: kGrey200)),
        height: height,
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  value!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: kGrey600)
            ],
          ),
        ),
      ),
    );
  }

  void showOptions(context) {
    final currencyRate =
        Provider.of<AppModel>(context, listen: false).currencyRate;
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(options.length, (index) {
                      final option = options[index];
                      return ListTile(
                          onTap: () {
                            onChanged!(option);
                            Navigator.pop(context);
                          },
                          title: Text(
                            "${option['name']} (${option["price_prefix"]}${PriceTools.getCurrencyFormatted(option["price"], currencyRate)})",
                            textAlign: TextAlign.center,
                          ));
                    }),
                  ),
                ),
              ),
              Container(
                height: 1,
                decoration: const BoxDecoration(color: kGrey200),
              ),
              ListTile(
                title: Text(
                  name,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        });
  }
}

class InputText extends StatelessWidget {
  final String name;
  final String? value;
  final int maxLines;
  final Function? onChanged;

  const InputText(
      {required this.name,
      required this.value,
      this.onChanged,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: maxLines,
      decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 5), isDense: true),
      onChanged: onChanged as void Function(String)?,
    );
  }
}

class InputDateTime extends StatelessWidget {
  final String name;
  final String? value;
  final String? type;
  final double width;
  final double height;
  final Function? onChanged;

  const InputDateTime(
      {required this.name,
      required this.value,
      this.type = 'date',
      this.width = double.infinity,
      this.height = 42.0,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onChanged != null) {
          switch (type) {
            case 'date':
              _selectDate(context);
              break;
            case 'time':
              _selectTime(context);
              break;
            case 'datetime':
              _selectDateTime(context);
              break;
          }
        }
      },
      child: Container(
        decoration:
            BoxDecoration(border: Border.all(width: 1.0, color: kGrey200)),
        height: height,
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(type != 'time' ? Icons.calendar_today : Icons.access_time,
                  size: 18, color: kGrey400),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  value!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _selectDate(context) async {
    var picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now()
            .add(const Duration(days: 1))
            .subtract(const Duration(hours: 1)),
        lastDate: DateTime(2101));
    if (picked != null) {
      onChanged!(DateFormat.yMMMd().format(picked).toString());
    }
  }

  Future _selectTime(context) async {
    var picked = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(DateTime.now()));
    if (picked != null) {
      onChanged!(picked.format(context));
    }
  }

  Future _selectDateTime(context) async {
    var selectedDate = DateTime.now();
    final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      onChanged!(DateFormat.yMd().add_jm().format(picked).toString());
    }
  }
}

class InputRadio extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final String name;
  final String? value;
  final double width;
  final double height;
  final Function? onChanged;

  const InputRadio(
      {required this.name,
      required this.options,
      required this.value,
      this.width = double.infinity,
      this.height = 42.0,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    final currencyRate = Provider.of<AppModel>(context).currencyRate;
    return Column(
      children: List.generate(options.length, (index) {
        final option = options[index];
        return GestureDetector(
          onTap: () {
            if (onChanged != null) {
              onChanged!(option);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Radio(
                  value: value,
                  groupValue: option['product_option_value_id'],
                  onChanged: null),
              Expanded(
                child: Text(
                  "${option['name']} (${option["price_prefix"]}${PriceTools.getCurrencyFormatted(option["price"], currencyRate)})",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class InputCheckBox extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final String name;
  final List? selectedValue;
  final double width;
  final double height;
  final Function? onChanged;

  const InputCheckBox(
      {required this.name,
      required this.options,
      required this.selectedValue,
      this.width = double.infinity,
      this.height = 42.0,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    final currencyRate = Provider.of<AppModel>(context).currencyRate;
    return Column(
      children: List.generate(options.length, (index) {
        final option = options[index];
        return GestureDetector(
          onTap: () {
            if (onChanged != null) {
              onChanged!(option['product_option_value_id']);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Checkbox(
                  value: selectedValue!
                      .contains(option['product_option_value_id']),
                  onChanged: null),
              Expanded(
                child: Text(
                  "${option['name']} (${option["price_prefix"]}${PriceTools.getCurrencyFormatted(option["price"], currencyRate)})",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
