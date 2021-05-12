import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'input_dropdown.dart';

class DateTimePicker extends StatelessWidget {
  const DateTimePicker(
      {Key? key,
      this.labelText,
      this.selectedDate,
      this.selectedTime,
      this.selectDate,
      this.selectTime,
      this.enableTime = true})
      : super(key: key);

  final String? labelText;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final ValueChanged<DateTime>? selectDate;
  final ValueChanged<TimeOfDay>? selectTime;
  final bool enableTime;

  Future<Null> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate != null
            ? DateTime.parse(selectedDate.toString())
            : DateTime.now(),
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate && selectDate != null)
      selectDate!(picked);
  }

  Future<Null> _selectTime(BuildContext context) async {
    if (selectedTime == null) return;
    final picked =
        await showTimePicker(context: context, initialTime: selectedTime!);
    if (picked != null && picked != selectedTime) selectTime!(picked);
  }

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.headline6;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 4,
          child: InputDropdown(
            labelText: labelText,
            valueText: selectedDate == null
                ? ''
                : DateFormat.yMMMd().format(selectedDate as DateTime),
            valueStyle: valueStyle,
            onPressed: () {
              _selectDate(context);
            },
          ),
        ),
        if (enableTime) ...[
          const SizedBox(width: 12.0),
          Expanded(
            flex: 3,
            child: InputDropdown(
              valueText: selectedTime?.format(context) ?? '',
              valueStyle: valueStyle,
              onPressed: () {
                _selectTime(context);
              },
            ),
          ),
        ]
      ],
    );
  }
}
