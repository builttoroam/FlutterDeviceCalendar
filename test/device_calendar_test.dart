import 'package:device_calendar/device_calendar.dart';
import 'package:device_calendar/src/common/error_codes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final channel =
      const MethodChannel('plugins.builttoroam.com/device_calendar');
  var deviceCalendarPlugin = DeviceCalendarPlugin();

  final log = <MethodCall>[];

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      print('Calling channel method ${methodCall.method}');
      log.add(methodCall);

      return null;
    });

    log.clear();
  });

  test('HasPermissions_Returns_Successfully', () async {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return true;
    });

    final result = await deviceCalendarPlugin.hasPermissions();
    expect(result.isSuccess, true);
    expect(result.errors, isEmpty);
    expect(result.data, true);
  });

  test('RequestPermissions_Returns_Successfully', () async {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return true;
    });

    final result = await deviceCalendarPlugin.requestPermissions();
    expect(result.isSuccess, true);
    expect(result.errors, isEmpty);
    expect(result.data, true);
  });

  test('RetrieveCalendars_Returns_Successfully', () async {
    final fakeCalendarName = 'fakeCalendarName';
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '[{\"id\":\"1\",\"isReadOnly\":false,\"name\":\"$fakeCalendarName\"}]';
    });

    final result = await deviceCalendarPlugin.retrieveCalendars();
    expect(result.isSuccess, true);
    expect(result.errors, isEmpty);
    expect(result.data, isNotNull);
    expect(result.data, isNotEmpty);
    expect(result.data?[0].name, fakeCalendarName);
  });

  test('RetrieveEvents_CalendarId_IsRequired', () async {
    final String? calendarId = null;
    final params = RetrieveEventsParams();

    final result = await deviceCalendarPlugin.retrieveEvents(calendarId, params);
    expect(result.isSuccess, false);
    expect(result.errors.length, greaterThan(0));
    expect(result.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
  });

  test('DeleteEvent_CalendarId_IsRequired', () async {
    final String? calendarId = null;
    final eventId = 'fakeEventId';

    final result = await deviceCalendarPlugin.deleteEvent(calendarId, eventId);
    expect(result.isSuccess, false);
    expect(result.errors.length, greaterThan(0));
    expect(result.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
  });

  test('DeleteEvent_EventId_IsRequired', () async {
    final calendarId = 'fakeCalendarId';
    final String? eventId = null;

    final result = await deviceCalendarPlugin.deleteEvent(calendarId, eventId);
    expect(result.isSuccess, false);
    expect(result.errors.length, greaterThan(0));
    expect(result.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
  });

  test('DeleteEvent_PassesArguments_Correctly', () async {
    final calendarId = 'fakeCalendarId';
    final eventId = 'fakeEventId';

    await deviceCalendarPlugin.deleteEvent(calendarId, eventId);
    expect(log, <Matcher>[
      isMethodCall('deleteEvent', arguments: <String, dynamic>{
        'calendarId': calendarId,
        'eventId': eventId
      })
    ]);
  });

  test('CreateEvent_Arguments_Invalid', () async {
    final String? fakeCalendarId = null;
    final event = Event(fakeCalendarId, availability: Availability.Busy);

    final result = await deviceCalendarPlugin.createOrUpdateEvent(event);
    expect(result!.isSuccess, false);
    expect(result.errors, isNotEmpty);
    expect(result.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
  });

  test('CreateEvent_Returns_Successfully', () async {
    final fakeNewEventId = 'fakeNewEventId';
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return fakeNewEventId;
    });

    final fakeCalendarId = 'fakeCalendarId';
    final event = Event(fakeCalendarId, availability: Availability.Busy);
    event.title = 'fakeEventTitle';
    event.start = TZDateTime.now(local);
    event.end = event.start!.add(Duration(hours: 1));

    final result = await deviceCalendarPlugin.createOrUpdateEvent(event);
    expect(result?.isSuccess, true);
    expect(result?.errors, isEmpty);
    expect(result?.data, isNotEmpty);
    expect(result?.data, fakeNewEventId);
  });

  test('UpdateEvent_Returns_Successfully', () async {
    final fakeNewEventId = 'fakeNewEventId';
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      final arguments = methodCall.arguments as Map<dynamic, dynamic>;
      if (!arguments.containsKey('eventId') || arguments['eventId'] == null) {
        return null;
      }

      return fakeNewEventId;
    });

    final fakeCalendarId = 'fakeCalendarId';
    final event = Event(fakeCalendarId, availability: Availability.Busy);
    event.eventId = 'fakeEventId';
    event.title = 'fakeEventTitle';
    event.start = TZDateTime.now(local);
    event.end = event.start!.add(Duration(hours: 1));

    final result = await deviceCalendarPlugin.createOrUpdateEvent(event);
    expect(result?.isSuccess, true);
    expect(result?.errors, isEmpty);
    expect(result?.data, isNotEmpty);
    expect(result?.data, fakeNewEventId);
  });

  test('Attendee_Serialises_Correctly', () async {
    final attendee = Attendee(
        name: 'Test Attendee',
        emailAddress: 'test@t.com',
        role: AttendeeRole.Required,
        isOrganiser: true);
    final stringAttendee = attendee.toJson();
    expect(stringAttendee, isNotNull);
    final newAttendee = Attendee.fromJson(stringAttendee);
    expect(newAttendee, isNotNull);
    expect(newAttendee.name, equals(attendee.name));
    expect(newAttendee.emailAddress, equals(attendee.emailAddress));
    expect(newAttendee.role, equals(attendee.role));
    expect(newAttendee.isOrganiser, equals(attendee.isOrganiser));
    expect(newAttendee.iosAttendeeDetails, isNull);
    expect(newAttendee.androidAttendeeDetails, isNull);
  });

  test('Event_Serialises_Correctly', () async {
    final event = Event('calendarId',eventId: 'eventId',start: TZDateTime(
      timeZoneDatabase.locations.entries.skip(20).first.value, 1980, 10,1,0,0,0), availability: Availability.Busy);
    final stringEvent = event.toJson();
    expect(stringEvent, isNotNull);
    final newEvent = Event.fromJson(stringEvent);
    expect(newEvent, isNotNull);
    expect(newEvent.calendarId, equals(event.calendarId));
    expect(newEvent.eventId, equals(event.eventId));
    expect(newEvent.start, equals(event.start));
  });
}
