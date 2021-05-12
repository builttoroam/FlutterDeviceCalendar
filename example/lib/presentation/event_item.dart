import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'recurring_event_dialog.dart';
import 'package:timezone/timezone.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class EventItem extends StatefulWidget {
  final Event? _calendarEvent;
  final DeviceCalendarPlugin _deviceCalendarPlugin;
  final bool _isReadOnly;

  final Function(Event) _onTapped;
  final VoidCallback _onLoadingStarted;
  final Function(bool) _onDeleteFinished;

  EventItem(
      this._calendarEvent,
      this._deviceCalendarPlugin,
      this._onLoadingStarted,
      this._onDeleteFinished,
      this._onTapped,
      this._isReadOnly,
      {Key? key})
      : super(key: key);

  @override
  _EventItemState createState() {
    return _EventItemState();
  }
}

class _EventItemState extends State<EventItem> {
  final double _eventFieldNameWidth = 75.0;
  Location? _currentLocation;

  @override
  void initState() {
    super.initState();
    setCurentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget._calendarEvent != null)
          widget._onTapped(widget._calendarEvent as Event);
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
                title: Text(widget._calendarEvent?.title ?? ''),
                subtitle: Text(widget._calendarEvent?.description ?? '')),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  if (_currentLocation != null)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Row(
                        children: [
                          Container(
                            width: _eventFieldNameWidth,
                            child: Text('Starts'),
                          ),
                          Text(
                            widget._calendarEvent == null
                                ? ''
                                : DateFormat('yyyy-MM-dd HH:mm:ss').format(
                                    TZDateTime.from(
                                        widget._calendarEvent!.start!,
                                        _currentLocation!)),
                          )
                        ],
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.0),
                  ),
                  if (_currentLocation != null)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Row(
                        children: [
                          Container(
                            width: _eventFieldNameWidth,
                            child: Text('Ends'),
                          ),
                          Text(
                            widget._calendarEvent?.end == null
                                ? ''
                                : DateFormat('yyyy-MM-dd HH:mm:ss').format(
                                    TZDateTime.from(widget._calendarEvent!.end!,
                                        _currentLocation!)),
                          ),
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
                        Text(widget._calendarEvent?.allDay != null &&
                                widget._calendarEvent?.allDay == true
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
                            widget._calendarEvent?.location ?? '',
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
                            widget._calendarEvent?.url?.data?.contentText ?? '',
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
                            widget._calendarEvent?.attendees
                                    ?.where((a) => a?.name?.isNotEmpty ?? false)
                                    .map((a) => a?.name)
                                    .join(', ') ??
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
                            widget._calendarEvent?.availability?.enumToString ??
                                '',
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
                if (!widget._isReadOnly) ...[
                  IconButton(
                    onPressed: () {
                      if (widget._calendarEvent != null)
                        widget._onTapped(widget._calendarEvent as Event);
                    },
                    icon: Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () async {
                      await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          if (widget._calendarEvent?.recurrenceRule == null) {
                            return AlertDialog(
                              title: Text(
                                  'Are you sure you want to delete this event?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    widget._onLoadingStarted();
                                    final deleteResult = await widget
                                        ._deviceCalendarPlugin
                                        .deleteEvent(
                                            widget._calendarEvent?.calendarId,
                                            widget._calendarEvent?.eventId);
                                    widget._onDeleteFinished(
                                        deleteResult.isSuccess &&
                                            deleteResult.data != null);
                                  },
                                  child: Text('Delete'),
                                ),
                              ],
                            );
                          } else {
                            if (widget._calendarEvent == null)
                              return SizedBox();
                            return RecurringEventDialog(
                                widget._deviceCalendarPlugin,
                                widget._calendarEvent!,
                                widget._onLoadingStarted,
                                widget._onDeleteFinished);
                          }
                        },
                      );
                    },
                    icon: Icon(Icons.delete),
                  ),
                ] else ...[
                  IconButton(
                    onPressed: () {
                      if (widget._calendarEvent != null)
                        widget._onTapped(widget._calendarEvent!);
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

  void setCurentLocation() async {
    String? timezone;
    try {
      timezone = await FlutterNativeTimezone.getLocalTimezone();
    } catch (e) {
      print('Could not get the local timezone');
    }
    timezone ??= 'Etc/UTC';
    _currentLocation = timeZoneDatabase.locations[timezone];
    setState(() {});
  }
}
