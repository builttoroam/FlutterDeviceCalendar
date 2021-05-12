import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';

class RecurringEventDialog extends StatefulWidget {
  final DeviceCalendarPlugin _deviceCalendarPlugin;
  final Event _calendarEvent;

  final VoidCallback _onLoadingStarted;
  final Function(bool) _onDeleteFinished;

  RecurringEventDialog(this._deviceCalendarPlugin, this._calendarEvent,
      this._onLoadingStarted, this._onDeleteFinished,
      {Key? key})
      : super(key: key);

  @override
  _RecurringEventDialogState createState() =>
      _RecurringEventDialogState(_deviceCalendarPlugin, _calendarEvent,
          onLoadingStarted: _onLoadingStarted,
          onDeleteFinished: _onDeleteFinished);
}

class _RecurringEventDialogState extends State<RecurringEventDialog> {
  late DeviceCalendarPlugin _deviceCalendarPlugin;
  late Event _calendarEvent;
  VoidCallback? _onLoadingStarted;
  Function(bool)? _onDeleteFinished;

  _RecurringEventDialogState(
      DeviceCalendarPlugin deviceCalendarPlugin, Event calendarEvent,
      {VoidCallback? onLoadingStarted, Function(bool)? onDeleteFinished}) {
    _deviceCalendarPlugin = deviceCalendarPlugin;
    _calendarEvent = calendarEvent;
    _onLoadingStarted = onLoadingStarted;
    _onDeleteFinished = onDeleteFinished;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text('Are you sure you want to delete this event?'),
      children: <Widget>[
        SimpleDialogOption(
          onPressed: () async {
            Navigator.of(context).pop(true);
            if (_onLoadingStarted != null) _onLoadingStarted!();
            final deleteResult =
                await _deviceCalendarPlugin.deleteEventInstance(
                    _calendarEvent.calendarId,
                    _calendarEvent.eventId,
                    _calendarEvent.start?.millisecondsSinceEpoch,
                    _calendarEvent.end?.millisecondsSinceEpoch,
                    false);
            if (_onDeleteFinished != null)
              _onDeleteFinished!(
                  deleteResult.isSuccess && deleteResult.data != null);
          },
          child: Text('This instance only'),
        ),
        SimpleDialogOption(
          onPressed: () async {
            Navigator.of(context).pop(true);
            if (_onLoadingStarted != null) _onLoadingStarted!();
            final deleteResult =
                await _deviceCalendarPlugin.deleteEventInstance(
                    _calendarEvent.calendarId,
                    _calendarEvent.eventId,
                    _calendarEvent.start?.millisecondsSinceEpoch,
                    _calendarEvent.end?.millisecondsSinceEpoch,
                    true);
            if (_onDeleteFinished != null)
              _onDeleteFinished!(
                  deleteResult.isSuccess && deleteResult.data != null);
          },
          child: Text('This and following instances'),
        ),
        SimpleDialogOption(
          onPressed: () async {
            Navigator.of(context).pop(true);
            if (_onLoadingStarted != null) _onLoadingStarted!();
            final deleteResult = await _deviceCalendarPlugin.deleteEvent(
                _calendarEvent.calendarId, _calendarEvent.eventId);
            if (_onDeleteFinished != null)
              _onDeleteFinished!(
                  deleteResult.isSuccess && deleteResult.data != null);
          },
          child: Text('All instances'),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text('Cancel'),
        )
      ],
    );
  }
}
