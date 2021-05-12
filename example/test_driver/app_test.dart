import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

/// NOTE: These integration tests are currently made to be run on a physical Android device where there is at least a calendar that can be written to.
/// They will currently need to be run on a Mac as well
void main() {
  group('Calendar plugin example', () {
    FlutterDriver? driver;
    final eventTitle = Uuid().v1();
    final saveEventButtonFinder = find.byValueKey('saveEventButton');
    final eventTitleFinder = find.text(eventTitle);
    setUpAll(() async {
      // workaround for handling permissions based on info taken from https://github.com/flutter/flutter/issues/12561
      // this is to be run in a Mac environment
      final envVars = Platform.environment;
      final adbPath = envVars['ANDROID_HOME'] != null
          ? envVars['ANDROID_HOME']! + '/platform-tools/adb'
          : '';
      await Process.run(adbPath, [
        'shell',
        'pm',
        'grant',
        'com.builttoroam.devicecalendarexample',
        'android.permission.INTERNET'
      ]);
      await Process.run(adbPath, [
        'shell',
        'pm',
        'grant',
        'com.builttoroam.devicecalendarexample',
        'android.permission.READ_CALENDAR'
      ]);
      await Process.run(adbPath, [
        'shell',
        'pm',
        'grant',
        'com.builttoroam.devicecalendarexample',
        'android.permission.WRITE_CALENDAR'
      ]);

      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('check flutter driver health', () async {
      final health = await driver?.checkHealth();
      print('flutter driver status: ${health?.status}');
    });

    test('starts on calendars page', () async {
      await driver?.waitFor(find.byValueKey('calendarsPage'));
    });
    test('select first writable calendar', () async {
      final writableCalendarFinder = find.byValueKey('writableCalendar0');
      await driver?.waitFor(writableCalendarFinder,
          timeout: Duration(milliseconds: 500));
      await driver?.tap(writableCalendarFinder);
    });
    test('go to add event page', () async {
      final addEventButtonFinder = find.byValueKey('addEventButton');
      await driver?.waitFor(addEventButtonFinder);
      print('found add event button');
      await driver?.tap(addEventButtonFinder);
      await driver?.waitFor(saveEventButtonFinder);
    });
    test('try to save event without entering mandatory fields', () async {
      await driver?.tap(saveEventButtonFinder);
      await driver?.waitFor(
          find.text('Please fix the errors in red before submitting.'));
    });
    test('save event with title $eventTitle', () async {
      final titleFieldFinder = find.byValueKey('titleField');
      await driver?.waitFor(titleFieldFinder);
      await driver?.tap(titleFieldFinder);
      await driver?.enterText(eventTitle);
      await driver?.tap(saveEventButtonFinder);
      await driver?.waitFor(eventTitleFinder);
    });
    test('delete event with title $eventTitle', () async {
      await driver?.tap(eventTitleFinder);
      final deleteButtonFinder = find.byValueKey('deleteEventButton');
      await driver?.scrollIntoView(deleteButtonFinder);
      await driver?.tap(deleteButtonFinder);
      await driver?.waitForAbsent(eventTitleFinder);
    });
  });
}
