import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'recurring_event_dialog.dart';

class EventItem extends StatelessWidget {
  final Event _calendarEvent;
  final DeviceCalendarPlugin _deviceCalendarPlugin;
  final bool _isReadOnly;

  final Function(Event) _onTapped;
  final VoidCallback _onLoadingStarted;
  final Function(bool) _onDeleteFinished;

  final double _eventFieldNameWidth = 75.0;

  EventItem(
      this._calendarEvent,
      this._deviceCalendarPlugin,
      this._onLoadingStarted,
      this._onDeleteFinished,
      this._onTapped,
      this._isReadOnly);

  @override
  Widget build(BuildContext context) {
    print(_calendarEvent.title);
    return GestureDetector(
      onTap: () {
        _onTapped(_calendarEvent);
      },
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: FlutterLogo(),
            ),
            ListTile(
                title: Text(_calendarEvent.title ?? ''),
                subtitle: Text(_calendarEvent.description ?? '')),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        Container(
                          width: _eventFieldNameWidth,
                          child: Text('Starts'),
                        ),
                        Text(_calendarEvent == null
                            ? ''
                            : _formatDateTime(dateTime: _calendarEvent.start)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.0),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        Container(
                          width: _eventFieldNameWidth,
                          child: Text('Ends'),
                        ),
                        Text(_calendarEvent.end == null
                            ? ''
                            : _formatDateTime(
                                dateTime: _calendarEvent.end, isEndDate: true)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        Container(
                          width: _eventFieldNameWidth,
                          child: Text('All day?'),
                        ),
                        Text(_calendarEvent.allDay != null &&
                                _calendarEvent.allDay
                            ? 'Yes'
                            : 'No')
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        Container(
                          width: _eventFieldNameWidth,
                          child: Text('Location'),
                        ),
                        Expanded(
                          child: Text(
                            _calendarEvent?.location ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        Container(
                          width: _eventFieldNameWidth,
                          child: Text('URL'),
                        ),
                        Expanded(
                          child: Text(
                            _calendarEvent?.url?.data?.contentText ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        Container(
                          width: _eventFieldNameWidth,
                          child: Text('Attendees'),
                        ),
                        Expanded(
                          child: Text(
                            _calendarEvent?.attendees
                                    ?.where((a) => a.name?.isNotEmpty ?? false)
                                    ?.map((a) => a.name)
                                    ?.join(', ') ??
                                '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        Container(
                          width: _eventFieldNameWidth,
                          child: Text('Availability'),
                        ),
                        Expanded(
                          child: Text(
                            _calendarEvent?.availability.enumToString ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ButtonBar(
              children: [
                if (!_isReadOnly) ...[
                  IconButton(
                    onPressed: () {
                      _onTapped(_calendarEvent);
                    },
                    icon: Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () async {
                      await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          if (_calendarEvent.recurrenceRule == null) {
                            return AlertDialog(
                              title: Text(
                                  'Are you sure you want to delete this event?'),
                              actions: [
                                FlatButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Cancel'),
                                ),
                                FlatButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    _onLoadingStarted();
                                    final deleteResult =
                                        await _deviceCalendarPlugin.deleteEvent(
                                            _calendarEvent.calendarId,
                                            _calendarEvent.eventId);
                                    _onDeleteFinished(deleteResult.isSuccess &&
                                        deleteResult.data);
                                  },
                                  child: Text('Delete'),
                                ),
                              ],
                            );
                          } else {
                            return RecurringEventDialog(
                                _deviceCalendarPlugin,
                                _calendarEvent,
                                _onLoadingStarted,
                                _onDeleteFinished);
                          }
                        },
                      );
                    },
                    icon: Icon(Icons.delete),
                  ),
                ] else ...[
                  IconButton(
                    onPressed: () {
                      _onTapped(_calendarEvent);
                    },
                    icon: Icon(Icons.remove_red_eye),
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  /// Formats [dateTime] into a human-readable string.
  /// If [_calendarEvent] is an allDay event, then the output will omit the time.
  /// For Android allDay events, the Calendar Provider returns the time
  /// adjusted into local time, which may change the date. In that case
  /// (Android allDay event), the time is adjusted back to UTC before
  /// formatting the date.
  /// Also, for Android allDay events, the End Date falls on midnight at the
  /// beginning of the day after the End Date, so this function subtracts a
  /// day before printing the date when [isEndDate] = true
  String _formatDateTime({DateTime dateTime, bool isEndDate = false}) {
    if (dateTime == null) {
      return 'Error';
    }
    var output = '';
    if (Platform.isAndroid &&
        _calendarEvent.allDay != null &&
        _calendarEvent.allDay) {
      var offset = dateTime.timeZoneOffset.inMilliseconds;
      // subtract the offset to get back to midnight on the correct date
      dateTime = dateTime.subtract(Duration(milliseconds: offset));
      if (isEndDate) {
        // The Event End Date for allDay events is midnight of the next day, so
        // subtract one day
        dateTime = dateTime.subtract(Duration(days: 1));
      }
      // just the dates, no times
      output = DateFormat.yMd().format(dateTime);
    } else {
      output = DateFormat.yMd().add_jm().format(dateTime);
    }
    return output;
  }
}
