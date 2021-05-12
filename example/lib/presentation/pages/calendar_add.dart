import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

class CalendarAddPage extends StatefulWidget {
  @override
  _CalendarAddPageState createState() {
    return _CalendarAddPageState();
  }
}

class _CalendarAddPageState extends State<CalendarAddPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late DeviceCalendarPlugin _deviceCalendarPlugin;

  bool _autovalidate = false;
  String _calendarName = '';
  ColorChoice? _colorChoice;
  String _localAccountName = '';

  _CalendarAddPageState() {
    _deviceCalendarPlugin = DeviceCalendarPlugin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Create Calendar'),
      ),
      body: Form(
        autovalidate: _autovalidate,
        key: _formKey,
        child: Container(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Calendar Name',
                  hintText: 'My New Calendar',
                ),
                validator: _validateCalendarName,
                onSaved: (String? value) => _calendarName = value ?? '',
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Calendar Color'),
                  DropdownButton<ColorChoice>(
                    onChanged: (selectedColor) {
                      setState(() => _colorChoice = selectedColor);
                    },
                    value: _colorChoice,
                    items: ColorChoice.values
                        .map((color) => DropdownMenuItem(
                              value: color,
                              child: Text(color.toString().split('.').last),
                            ))
                        .toList(),
                  ),
                ],
              ),
              if (Platform.isAndroid)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Local Account Name',
                    hintText: 'Device Calendar',
                  ),
                  onSaved: (String? value) => _localAccountName = value ?? '',
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final form = _formKey.currentState;
          if (form?.validate() == false) {
            _autovalidate = true; // Start validating on every change.
            showInSnackBar('Please fix the errors in red before submitting.');
          } else {
            form?.save();
            var result = await _deviceCalendarPlugin.createCalendar(
              _calendarName,
              calendarColor: _colorChoice?.value,
              localAccountName: _localAccountName,
            );

            if (result.isSuccess) {
              Navigator.pop(context, true);
            } else {
              showInSnackBar(result.errors
                  .map((err) => '[${err.errorCode}] ${err.errorMessage}')
                  .join(' | '));
            }
          }
        },
        child: Icon(Icons.check),
      ),
    );
  }

  String? _validateCalendarName(String? value) {
    if (value == null) return null;
    if (value.isEmpty) {
      return 'Calendar name is required.';
    }

    return null;
  }

  void showInSnackBar(String value) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(value)));
  }
}

enum ColorChoice {
  Red,
  Orange,
  Yellow,
  Green,
  Blue,
  Purple,
  Brown,
  Black,
  White
}

extension ColorChoiceExtension on ColorChoice {
  static Color _value(ColorChoice val) {
    switch (val) {
      case ColorChoice.Red:
        return Colors.red;
      case ColorChoice.Orange:
        return Colors.orange;
      case ColorChoice.Yellow:
        return Colors.yellow;
      case ColorChoice.Green:
        return Colors.green;
      case ColorChoice.Blue:
        return Colors.blue;
      case ColorChoice.Purple:
        return Colors.purple;
      case ColorChoice.Brown:
        return Colors.brown;
      case ColorChoice.Black:
        return Colors.black;
      case ColorChoice.White:
        return Colors.white;
      default:
        return Colors.red;
    }
  }

  Color get value => _value(this);
}
