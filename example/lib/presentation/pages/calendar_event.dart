import 'dart:io';

import 'package:collection/collection.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../date_time_picker.dart';
import '../recurring_event_dialog.dart';
import 'event_attendee.dart';
import 'event_reminders.dart';

enum RecurrenceRuleEndType { Indefinite, MaxOccurrences, SpecifiedEndDate }

class CalendarEventPage extends StatefulWidget {
  final Calendar _calendar;
  final Event _event;
  final RecurringEventDialog _recurringEventDialog;

  CalendarEventPage(this._calendar, [this._event, this._recurringEventDialog]);

  @override
  _CalendarEventPageState createState() {
    return _CalendarEventPageState(_calendar, _event, _recurringEventDialog);
  }
}

class _CalendarEventPageState extends State<CalendarEventPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Calendar _calendar;

  Event _event;
  DeviceCalendarPlugin _deviceCalendarPlugin;
  final RecurringEventDialog _recurringEventDialog;

  DateTime _startDate;
  TimeOfDay _startTime;

  DateTime _endDate;
  TimeOfDay _endTime;

  bool _autovalidate = false;
  DayOfWeekGroup _dayOfWeekGroup = DayOfWeekGroup.None;

  bool _isRecurringEvent = false;
  bool _isByDayOfMonth = false;
  RecurrenceRuleEndType _recurrenceRuleEndType;
  int _totalOccurrences;
  int _interval;
  DateTime _recurrenceEndDate;
  RecurrenceFrequency _recurrenceFrequency = RecurrenceFrequency.Daily;
  List<DayOfWeek> _daysOfWeek = List<DayOfWeek>();
  int _dayOfMonth;
  List<int> _validDaysOfMonth = List<int>();
  MonthOfYear _monthOfYear;
  WeekNumber _weekOfMonth;
  DayOfWeek _selectedDayOfWeek = DayOfWeek.Monday;
  Availability _availability = Availability.Busy;

  List<Attendee> _attendees = <Attendee>[];
  List<Reminder> _reminders = <Reminder>[];

  _CalendarEventPageState(
      this._calendar, this._event, this._recurringEventDialog) {
    _deviceCalendarPlugin = DeviceCalendarPlugin();

    _attendees = <Attendee>[];
    _reminders = <Reminder>[];
    _recurrenceRuleEndType = RecurrenceRuleEndType.Indefinite;

    if (_event == null) {
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(Duration(hours: 1));
      _event = Event(_calendar.id, start: _startDate, end: _endDate);

      _recurrenceEndDate = _endDate;
      _dayOfMonth = 1;
      _monthOfYear = MonthOfYear.January;
      _weekOfMonth = WeekNumber.First;
      _availability = Availability.Busy;
    } else {
      _startDate = _event.start;
      _endDate = _event.end;
      _isRecurringEvent = _event.recurrenceRule != null;

      if (_event.attendees.isNotEmpty) {
        _attendees.addAll(_event.attendees);
      }

      if (_event.reminders.isNotEmpty) {
        _reminders.addAll(_event.reminders);
      }

      if (_isRecurringEvent) {
        _interval = _event.recurrenceRule.interval;
        _totalOccurrences = _event.recurrenceRule.totalOccurrences;
        _recurrenceFrequency = _event.recurrenceRule.recurrenceFrequency;

        if (_totalOccurrences != null) {
          _recurrenceRuleEndType = RecurrenceRuleEndType.MaxOccurrences;
        }

        if (_event.recurrenceRule.endDate != null) {
          _recurrenceRuleEndType = RecurrenceRuleEndType.SpecifiedEndDate;
          _recurrenceEndDate = _event.recurrenceRule.endDate;
        }

        _isByDayOfMonth = _event.recurrenceRule.weekOfMonth == null;
        _daysOfWeek = _event.recurrenceRule.daysOfWeek ?? <DayOfWeek>[];
        _monthOfYear = _event.recurrenceRule.monthOfYear ?? MonthOfYear.January;
        _weekOfMonth = _event.recurrenceRule.weekOfMonth ?? WeekNumber.First;
        _selectedDayOfWeek =
            _daysOfWeek.isNotEmpty ? _daysOfWeek.first : DayOfWeek.Monday;
        _dayOfMonth = _event.recurrenceRule.dayOfMonth ?? 1;

        if (_daysOfWeek.isNotEmpty) {
          _updateDaysOfWeekGroup();
        }
      }

      _availability = _event.availability;
    }

    _startTime = TimeOfDay(hour: _startDate.hour, minute: _startDate.minute);
    _endTime = TimeOfDay(hour: _endDate.hour, minute: _endDate.minute);

    // Getting days of the current month (or a selected month for the yearly recurrence) as a default
    _getValidDaysOfMonth(_recurrenceFrequency);
  }

  void printAttendeeDetails(Attendee attendee) {
    print(
        'attendee name: ${attendee.name}, email address: ${attendee.emailAddress}, type: ${attendee.iosAttendeeDetails?.role?.enumToString}');
    print(
        'ios specifics - status: ${attendee.iosAttendeeDetails?.attendanceStatus}, type: ${attendee.iosAttendeeDetails?.role?.enumToString}');
    print(
        'android specifics - status ${attendee.androidAttendeeDetails?.attendanceStatus}, type: ${attendee.androidAttendeeDetails?.role?.enumToString}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_event.eventId?.isEmpty ?? true
            ? 'Create event'
            : _calendar.isReadOnly
                ? 'View event ${_event.title}'
                : 'Edit event ${_event.title}'),
      ),
      body: SingleChildScrollView(
        child: AbsorbPointer(
          absorbing: _calendar.isReadOnly,
          child: Column(
            children: [
              Form(
                autovalidate: _autovalidate,
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        key: Key('titleField'),
                        initialValue: _event.title,
                        decoration: const InputDecoration(
                            labelText: 'Title',
                            hintText: 'Meeting with Gloria...'),
                        validator: _validateTitle,
                        onSaved: (String value) {
                          _event.title = value;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        initialValue: _event.description,
                        decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Remember to buy flowers...'),
                        onSaved: (String value) {
                          _event.description = value;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        initialValue: _event.location,
                        decoration: const InputDecoration(
                            labelText: 'Location',
                            hintText: 'Sydney, Australia'),
                        onSaved: (String value) {
                          _event.location = value;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        initialValue: _event.url?.data?.contentText ?? '',
                        decoration: const InputDecoration(
                            labelText: 'URL', hintText: 'https://google.com'),
                        onSaved: (String value) {
                          var uri = Uri.dataFromString(value);
                          _event.url = uri;
                        },
                      ),
                    ),
                    ListTile(
                      leading: Text(
                        'Availability',
                        style: TextStyle(fontSize: 16),
                      ),
                      trailing: DropdownButton<Availability>(
                        value: _availability,
                        onChanged: (Availability newValue) {
                          setState(() {
                            _availability = newValue;
                            _event.availability = newValue;
                          });
                        },
                        items: Availability.values
                            .map<DropdownMenuItem<Availability>>(
                                (Availability value) {
                          return DropdownMenuItem<Availability>(
                            value: value,
                            child: Text(value.enumToString ?? ''),
                          );
                        }).toList(),
                      ),
                    ),
                    SwitchListTile(
                      value: _event.allDay,
                      onChanged: (value) =>
                          setState(() => _event.allDay = value),
                      title: Text('All Day'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: DateTimePicker(
                        labelText: 'From',
                        enableTime: !_event.allDay,
                        selectedDate: _startDate,
                        selectedTime: _startTime,
                        selectDate: (DateTime date) {
                          setState(() {
                            _startDate = date;
                            _event.start =
                                _combineDateWithTime(_startDate, _startTime);
                          });
                        },
                        selectTime: (TimeOfDay time) {
                          setState(
                            () {
                              _startTime = time;
                              _event.start =
                                  _combineDateWithTime(_startDate, _startTime);
                            },
                          );
                        },
                      ),
                    ),
                    if (!_event.allDay)
                      if (Platform.isAndroid)
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextFormField(
                            initialValue: _event.startTimeZone,
                            decoration: const InputDecoration(
                                labelText: 'Start date time zone',
                                hintText: 'Australia/Sydney'),
                            onSaved: (String value) {
                              _event.startTimeZone = value;
                            },
                          ),
                        ),
                    if (!_event.allDay || Platform.isAndroid)
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: DateTimePicker(
                          labelText: 'To',
                          enableTime: !_event.allDay,
                          selectedDate: _endDate,
                          selectedTime: _endTime,
                          selectDate: (DateTime date) {
                            setState(
                              () {
                                _endDate = date;
                                _event.end =
                                    _combineDateWithTime(_endDate, _endTime);
                              },
                            );
                          },
                          selectTime: (TimeOfDay time) {
                            setState(
                              () {
                                _endTime = time;
                                _event.end =
                                    _combineDateWithTime(_endDate, _endTime);
                              },
                            );
                          },
                        ),
                      ),
                    if (!_event.allDay)
                      if (Platform.isAndroid)
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextFormField(
                            initialValue: Platform.isAndroid
                                ? _event.endTimeZone
                                : _event.startTimeZone,
                            decoration: InputDecoration(
                                labelText: Platform.isAndroid
                                    ? 'End date time zone'
                                    : 'Start and end time zone',
                                hintText: 'Australia/Sydney'),
                            onSaved: (String value) => Platform.isAndroid
                                ? _event.endTimeZone = value
                                : _event.startTimeZone = value,
                          ),
                        ),
                    GestureDetector(
                      onTap: () async {
                        var result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EventAttendeePage()));
                        if (result == null) return;
                        _attendees.add(result);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10.0,
                            children: [
                              Icon(Icons.people),
                              Text(!_calendar.isReadOnly
                                  ? 'Add Attendees'
                                  : 'Attendees')
                            ],
                          ),
                        ),
                      ),
                    ),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _attendees.length,
                      itemBuilder: (context, index) {
                        return Container(
                          color: _attendees[index].isOrganiser
                              ? Colors.greenAccent[100]
                              : Colors.transparent,
                          child: ListTile(
                            title: GestureDetector(
                                child:
                                    Text('${_attendees[index].emailAddress}'),
                                onTap: () async {
                                  var result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              EventAttendeePage(
                                                  attendee:
                                                      _attendees[index])));
                                  if (result == null) return;
                                  _attendees[index] = result;
                                }),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  margin: const EdgeInsets.all(10.0),
                                  padding: const EdgeInsets.all(3.0),
                                  decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.blueAccent)),
                                  child: Text(
                                      '${_attendees[index].role.enumToString}'),
                                ),
                                IconButton(
                                  padding: const EdgeInsets.all(0),
                                  onPressed: () {
                                    setState(() {
                                      _attendees.removeAt(index);
                                    });
                                  },
                                  icon: Icon(
                                    Icons.remove_circle,
                                    color: Colors.redAccent,
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    GestureDetector(
                      onTap: () async {
                        var result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    EventRemindersPage(_reminders)));
                        if (result == null) {
                          return;
                        }
                        _reminders = result;
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10.0,
                            children: [
                              Icon(Icons.alarm),
                              if (_reminders.isEmpty)
                                Text(!_calendar.isReadOnly
                                    ? 'Add reminders'
                                    : 'Reminders'),
                              for (var reminder in _reminders)
                                Text('${reminder.minutes} minutes before; ')
                            ],
                          ),
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      value: _isRecurringEvent,
                      title: Text('Is recurring'),
                      onChanged: (isChecked) {
                        setState(() {
                          _isRecurringEvent = isChecked;
                        });
                      },
                    ),
                    if (_isRecurringEvent) ...[
                      ListTile(
                        leading: Text('Select a Recurrence Type'),
                        trailing: DropdownButton<RecurrenceFrequency>(
                          onChanged: (selectedFrequency) {
                            setState(() {
                              _recurrenceFrequency = selectedFrequency;
                              _getValidDaysOfMonth(_recurrenceFrequency);
                            });
                          },
                          value: _recurrenceFrequency,
                          items: RecurrenceFrequency.values
                              .map((frequency) => DropdownMenuItem(
                                    value: frequency,
                                    child:
                                        _recurrenceFrequencyToText(frequency),
                                  ))
                              .toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                        child: Row(
                          children: <Widget>[
                            Text('Repeat Every '),
                            Flexible(
                              child: TextFormField(
                                initialValue: _interval?.toString() ?? '1',
                                decoration:
                                    const InputDecoration(hintText: '1'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  WhitelistingTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2)
                                ],
                                validator: _validateInterval,
                                textAlign: TextAlign.right,
                                onSaved: (String value) {
                                  _interval = int.tryParse(value);
                                },
                              ),
                            ),
                            _recurrenceFrequencyToIntervalText(
                                _recurrenceFrequency),
                          ],
                        ),
                      ),
                      if (_recurrenceFrequency ==
                          RecurrenceFrequency.Weekly) ...[
                        Column(
                          children: [
                            ...DayOfWeek.values.map((day) {
                              return CheckboxListTile(
                                title: Text(day.enumToString),
                                value: _daysOfWeek?.any((dow) => dow == day) ??
                                    false,
                                onChanged: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _daysOfWeek.add(day);
                                    } else {
                                      _daysOfWeek.remove(day);
                                    }
                                    _updateDaysOfWeekGroup(selectedDay: day);
                                  });
                                },
                              );
                            }),
                            Divider(color: Colors.black),
                            ...DayOfWeekGroup.values.map((group) {
                              return RadioListTile(
                                  title: Text(group.enumToString),
                                  value: group,
                                  groupValue: _dayOfWeekGroup,
                                  onChanged: (selected) {
                                    setState(() {
                                      _dayOfWeekGroup = selected;
                                      _updateDaysOfWeek();
                                    });
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.trailing);
                            }),
                          ],
                        )
                      ],
                      if (_recurrenceFrequency == RecurrenceFrequency.Monthly ||
                          _recurrenceFrequency ==
                              RecurrenceFrequency.Yearly) ...[
                        SwitchListTile(
                          value: _isByDayOfMonth,
                          onChanged: (value) =>
                              setState(() => _isByDayOfMonth = value),
                          title: Text('By day of the month'),
                        )
                      ],
                      if (_recurrenceFrequency == RecurrenceFrequency.Yearly &&
                          _isByDayOfMonth) ...[
                        ListTile(
                          leading: Text('Month of the year'),
                          trailing: DropdownButton<MonthOfYear>(
                            onChanged: (value) {
                              setState(() {
                                _monthOfYear = value;
                                _getValidDaysOfMonth(_recurrenceFrequency);
                              });
                            },
                            value: _monthOfYear,
                            items: MonthOfYear.values
                                .map((month) => DropdownMenuItem(
                                      value: month,
                                      child: Text(month.enumToString),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                      if (_isByDayOfMonth &&
                          (_recurrenceFrequency ==
                                  RecurrenceFrequency.Monthly ||
                              _recurrenceFrequency ==
                                  RecurrenceFrequency.Yearly)) ...[
                        ListTile(
                          leading: Text('Day of the month'),
                          trailing: DropdownButton<int>(
                            onChanged: (value) {
                              setState(() {
                                _dayOfMonth = value;
                              });
                            },
                            value: _dayOfMonth,
                            items: _validDaysOfMonth
                                .map((day) => DropdownMenuItem(
                                      value: day,
                                      child: Text(day.toString()),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                      if (!_isByDayOfMonth &&
                          (_recurrenceFrequency ==
                                  RecurrenceFrequency.Monthly ||
                              _recurrenceFrequency ==
                                  RecurrenceFrequency.Yearly)) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(_recurrenceFrequencyToText(
                                          _recurrenceFrequency)
                                      .data +
                                  ' on the ')),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Flexible(
                                child: DropdownButton<WeekNumber>(
                                  onChanged: (value) {
                                    setState(() {
                                      _weekOfMonth = value;
                                    });
                                  },
                                  value: _weekOfMonth ?? WeekNumber.First,
                                  items: WeekNumber.values
                                      .map((weekNum) => DropdownMenuItem(
                                            value: weekNum,
                                            child: Text(weekNum.enumToString),
                                          ))
                                      .toList(),
                                ),
                              ),
                              Flexible(
                                child: DropdownButton<DayOfWeek>(
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDayOfWeek = value;
                                    });
                                  },
                                  value: DayOfWeek
                                      .values[_selectedDayOfWeek.index],
                                  items: DayOfWeek.values
                                      .map((day) => DropdownMenuItem(
                                            value: day,
                                            child: Text(day.enumToString),
                                          ))
                                      .toList(),
                                ),
                              ),
                              if (_recurrenceFrequency ==
                                  RecurrenceFrequency.Yearly) ...[
                                Text('of'),
                                Flexible(
                                  child: DropdownButton<MonthOfYear>(
                                    onChanged: (value) {
                                      setState(() {
                                        _monthOfYear = value;
                                      });
                                    },
                                    value: _monthOfYear,
                                    items: MonthOfYear.values
                                        .map((month) => DropdownMenuItem(
                                              value: month,
                                              child: Text(month.enumToString),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ],
                      ListTile(
                        leading: Text('Event ends'),
                        trailing: DropdownButton<RecurrenceRuleEndType>(
                          onChanged: (value) {
                            setState(() {
                              _recurrenceRuleEndType = value;
                            });
                          },
                          value: _recurrenceRuleEndType,
                          items: RecurrenceRuleEndType.values
                              .map((frequency) => DropdownMenuItem(
                                    value: frequency,
                                    child:
                                        _recurrenceRuleEndTypeToText(frequency),
                                  ))
                              .toList(),
                        ),
                      ),
                      if (_recurrenceRuleEndType ==
                          RecurrenceRuleEndType.MaxOccurrences)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                          child: Row(
                            children: <Widget>[
                              Text('For the next '),
                              Flexible(
                                child: TextFormField(
                                  initialValue:
                                      _totalOccurrences?.toString() ?? '1',
                                  decoration:
                                      const InputDecoration(hintText: '1'),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    WhitelistingTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                  validator: _validateTotalOccurrences,
                                  textAlign: TextAlign.right,
                                  onSaved: (String value) {
                                    _totalOccurrences = int.tryParse(value);
                                  },
                                ),
                              ),
                              Text(' occurrences'),
                            ],
                          ),
                        ),
                      if (_recurrenceRuleEndType ==
                          RecurrenceRuleEndType.SpecifiedEndDate)
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: DateTimePicker(
                            labelText: 'Date',
                            enableTime: false,
                            selectedDate: _recurrenceEndDate,
                            selectDate: (DateTime date) {
                              setState(() {
                                _recurrenceEndDate = date;
                              });
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              if (!_calendar.isReadOnly &&
                  (_event.eventId?.isNotEmpty ?? false)) ...[
                RaisedButton(
                  key: Key('deleteEventButton'),
                  textColor: Colors.white,
                  color: Colors.red,
                  child: Text('Delete'),
                  onPressed: () async {
                    var result = true;
                    if (!_isRecurringEvent) {
                      await _deviceCalendarPlugin.deleteEvent(
                          _calendar.id, _event.eventId);
                    } else {
                      result = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return _recurringEventDialog;
                          });
                    }

                    if (result) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
              ]
            ],
          ),
        ),
      ),
      floatingActionButton: Visibility(
        visible: !_calendar.isReadOnly,
        child: FloatingActionButton(
          key: Key('saveEventButton'),
          onPressed: () async {
            final form = _formKey.currentState;
            if (!form.validate()) {
              _autovalidate = true; // Start validating on every change.
              showInSnackBar('Please fix the errors in red before submitting.');
            } else {
              form.save();
              if (_isRecurringEvent) {
                if (!_isByDayOfMonth &&
                    (_recurrenceFrequency == RecurrenceFrequency.Monthly ||
                        _recurrenceFrequency == RecurrenceFrequency.Yearly)) {
                  // Setting day of the week parameters for WeekNumber to avoid clashing with the weekly recurrence values
                  _daysOfWeek.clear();
                  _daysOfWeek.add(_selectedDayOfWeek);
                } else {
                  _weekOfMonth = null;
                }

                _event.recurrenceRule = RecurrenceRule(_recurrenceFrequency,
                    interval: _interval,
                    totalOccurrences: _totalOccurrences,
                    endDate: _recurrenceRuleEndType ==
                            RecurrenceRuleEndType.SpecifiedEndDate
                        ? _recurrenceEndDate
                        : null,
                    daysOfWeek: _daysOfWeek,
                    dayOfMonth: _dayOfMonth,
                    monthOfYear: _monthOfYear,
                    weekOfMonth: _weekOfMonth);
              }
              _event.attendees = _attendees;
              _event.reminders = _reminders;
              _event.availability = _availability;
              var createEventResult =
                  await _deviceCalendarPlugin.createOrUpdateEvent(_event);
              if (createEventResult.isSuccess) {
                Navigator.pop(context, true);
              } else {
                showInSnackBar(createEventResult.errors
                    .map((err) => '[${err.errorCode}] ${err.errorMessage}')
                    .join(' | '));
              }
            }
          },
          child: Icon(Icons.check),
        ),
      ),
    );
  }

  Text _recurrenceFrequencyToText(RecurrenceFrequency recurrenceFrequency) {
    switch (recurrenceFrequency) {
      case RecurrenceFrequency.Daily:
        return Text('Daily');
      case RecurrenceFrequency.Weekly:
        return Text('Weekly');
      case RecurrenceFrequency.Monthly:
        return Text('Monthly');
      case RecurrenceFrequency.Yearly:
        return Text('Yearly');
      default:
        return Text('');
    }
  }

  Text _recurrenceFrequencyToIntervalText(
      RecurrenceFrequency recurrenceFrequency) {
    switch (recurrenceFrequency) {
      case RecurrenceFrequency.Daily:
        return Text(' Day(s)');
      case RecurrenceFrequency.Weekly:
        return Text(' Week(s) on');
      case RecurrenceFrequency.Monthly:
        return Text(' Month(s)');
      case RecurrenceFrequency.Yearly:
        return Text(' Year(s)');
      default:
        return Text('');
    }
  }

  Text _recurrenceRuleEndTypeToText(RecurrenceRuleEndType endType) {
    switch (endType) {
      case RecurrenceRuleEndType.Indefinite:
        return Text('Indefinitely');
      case RecurrenceRuleEndType.MaxOccurrences:
        return Text('After a set number of times');
      case RecurrenceRuleEndType.SpecifiedEndDate:
        return Text('Continues until a specified date');
      default:
        return Text('');
    }
  }

  // Get total days of a month
  void _getValidDaysOfMonth(RecurrenceFrequency frequency) {
    _validDaysOfMonth.clear();
    var totalDays = 0;

    // Year frequency: Get total days of the selected month
    if (frequency == RecurrenceFrequency.Yearly) {
      totalDays = DateTime(DateTime.now().year, _monthOfYear.value + 1, 0).day;
    } else {
      // Otherwise, get total days of the current month
      var now = DateTime.now();
      totalDays = DateTime(now.year, now.month + 1, 0).day;
    }

    for (var i = 1; i <= totalDays; i++) {
      _validDaysOfMonth.add(i);
    }
  }

  void _updateDaysOfWeek() {
    var days = _dayOfWeekGroup.getDays;

    switch (_dayOfWeekGroup) {
      case DayOfWeekGroup.Weekday:
      case DayOfWeekGroup.Weekend:
      case DayOfWeekGroup.AllDays:
        _daysOfWeek.clear();
        _daysOfWeek.addAll(days.where((a) => _daysOfWeek.every((b) => a != b)));
        break;
      case DayOfWeekGroup.None:
        _daysOfWeek.clear();
        break;
    }
  }

  void _updateDaysOfWeekGroup({DayOfWeek selectedDay}) {
    var deepEquality = const DeepCollectionEquality.unordered().equals;

    // If _daysOfWeek contains nothing
    if (_daysOfWeek.isEmpty && _dayOfWeekGroup != DayOfWeekGroup.None) {
      _dayOfWeekGroup = DayOfWeekGroup.None;
    }
    // If _daysOfWeek contains Monday to Friday
    else if (deepEquality(_daysOfWeek, DayOfWeekGroup.Weekday.getDays) &&
        _dayOfWeekGroup != DayOfWeekGroup.Weekday) {
      _dayOfWeekGroup = DayOfWeekGroup.Weekday;
    }
    // If _daysOfWeek contains Saturday and Sunday
    else if (deepEquality(_daysOfWeek, DayOfWeekGroup.Weekend.getDays) &&
        _dayOfWeekGroup != DayOfWeekGroup.Weekend) {
      _dayOfWeekGroup = DayOfWeekGroup.Weekend;
    }
    // If _daysOfWeek contains all days
    else if (deepEquality(_daysOfWeek, DayOfWeekGroup.AllDays.getDays) &&
        _dayOfWeekGroup != DayOfWeekGroup.AllDays) {
      _dayOfWeekGroup = DayOfWeekGroup.AllDays;
    }
    // Otherwise null
    else {
      _dayOfWeekGroup = null;
    }
  }

  String _validateTotalOccurrences(String value) {
    if (value.isNotEmpty && int.tryParse(value) == null) {
      return 'Total occurrences needs to be a valid number';
    }
    return null;
  }

  String _validateInterval(String value) {
    if (value.isNotEmpty && int.tryParse(value) == null) {
      return 'Interval needs to be a valid number';
    }
    return null;
  }

  String _validateTitle(String value) {
    if (value.isEmpty) {
      return 'Name is required.';
    }

    return null;
  }

  DateTime _combineDateWithTime(DateTime date, TimeOfDay time) {
    if (date == null && time == null) {
      return null;
    }
    final dateWithoutTime =
        DateTime.parse(DateFormat('y-MM-dd 00:00:00').format(date));
    return dateWithoutTime
        .add(Duration(hours: time.hour, minutes: time.minute));
  }

  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(value)));
  }
}
