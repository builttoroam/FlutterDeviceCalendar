import '../../device_calendar.dart';
import '../common/calendar_enums.dart';
import '../common/error_messages.dart';
import 'attendee.dart';
import 'recurrence_rule.dart';
import 'package:timezone/timezone.dart';
import 'package:collection/collection.dart';

/// An event associated with a calendar
class Event {
  /// Read-only. The unique identifier for this event. This is auto-generated when a new event is created
  String? eventId;

  /// Read-only. The identifier of the calendar that this event is associated with
  String? calendarId;

  /// The title of this event
  String? title;

  /// The description for this event
  String? description;

  /// Indicates when the event starts
  TZDateTime? start;

  /// Indicates when the event ends
  TZDateTime? end;

  /// Indicates if this is an all-day event
  bool? allDay;

  /// The location of this event
  String? location;

  /// An URL for this event
  Uri? url;

  /// A list of attendees for this event
  List<Attendee?>? attendees;

  /// The recurrence rule for this event
  RecurrenceRule? recurrenceRule;

  /// A list of reminders (by minutes) for this event
  List<Reminder>? reminders;

  /// Indicates if this event counts as busy time, tentative, unavaiable or is still free time
  late Availability availability;

  Event(this.calendarId,
      {this.eventId,
      this.title,
      this.start,
      this.end,
      this.description,
      this.attendees,
      this.recurrenceRule,
      this.reminders,
      this.url,
      required this.availability,
      this.allDay = false});

  Event.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    eventId = json['eventId'];
    calendarId = json['calendarId'];
    title = json['title'];
    description = json['description'];

    final int? startTimestamp = json['start'];
    final String? startLocationName = json['startTimeZone'];
    var startTimeZone = timeZoneDatabase.locations[startLocationName];
    startTimeZone ??= local;
    start = startTimestamp != null
        ? TZDateTime.fromMillisecondsSinceEpoch(startTimeZone, startTimestamp)
        : TZDateTime.now(local);

    final int? endTimestamp = json['end'];
    final String? endLocationName = json['endTimeZone'];
    var endLocation = timeZoneDatabase.locations[endLocationName];
    endLocation ??= local;
    end = endTimestamp != null
        ? TZDateTime.fromMillisecondsSinceEpoch(endLocation, endTimestamp)
        : TZDateTime.now(local);

    allDay = json['allDay'];
    location = json['location'];
    availability = parseStringToAvailability(json['availability']);

    var foundUrl = json['url']?.toString();
    if (foundUrl?.isEmpty ?? true) {
      url = null;
    } else {
      url = Uri.dataFromString(foundUrl as String);
    }

    availability = parseStringToAvailability(json['availability']);

    if (json['attendees'] != null) {
      attendees = json['attendees'].map<Attendee>((decodedAttendee) {
        return Attendee.fromJson(decodedAttendee);
      }).toList();
    }

    if (json['organizer'] != null) {
      // Getting and setting an organiser for iOS
      var organiser = Attendee.fromJson(json['organizer']);

      var attendee = attendees?.firstWhereOrNull((at) =>
          at?.name == organiser.name &&
          at?.emailAddress == organiser.emailAddress);
      if (attendee != null) {
        attendee.isOrganiser = true;
      }
    }

    if (json['recurrenceRule'] != null) {
      recurrenceRule = RecurrenceRule.fromJson(json['recurrenceRule']);
    }

    if (json['reminders'] != null) {
      reminders = json['reminders'].map<Reminder>((decodedReminder) {
        return Reminder.fromJson(decodedReminder);
      }).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    data['calendarId'] = calendarId;
    data['eventId'] = eventId;
    data['eventTitle'] = title;
    data['eventDescription'] = description;
    data['eventStartDate'] = start!.millisecondsSinceEpoch;
    data['eventStartTimeZone'] = start?.location.name;
    data['eventEndDate'] = end!.millisecondsSinceEpoch;
    data['eventEndTimeZone'] = end?.location.name;
    data['eventAllDay'] = allDay;
    data['eventLocation'] = location;
    data['eventURL'] = url?.data?.contentText;
    data['availability'] = availability.enumToString;

    if (attendees != null) {
      data['attendees'] = attendees?.map((a) => a?.toJson()).toList();
    }

    if (attendees != null) {
      data['organizer'] =
          attendees?.firstWhereOrNull((a) => a!.isOrganiser)?.toJson();
    }

    if (recurrenceRule != null) {
      data['recurrenceRule'] = recurrenceRule?.toJson();
    }

    if (reminders != null) {
      data['reminders'] = reminders?.map((r) => r.toJson()).toList();
    }

    return data;
  }

  Availability parseStringToAvailability(String? value) {
    var testValue = value?.toUpperCase();
    switch (testValue) {
      case 'BUSY':
        return Availability.Busy;
      case 'FREE':
        return Availability.Free;
      case 'TENTATIVE':
        return Availability.Tentative;
      case 'UNAVAILABLE':
        return Availability.Unavailable;
    }
    return Availability.Busy;
  }

  bool updateStartLocation(String? newStartLocation) {
    if (newStartLocation == null) return false;
    try {
      var location = timeZoneDatabase.get(newStartLocation);
      start = TZDateTime.from(start as TZDateTime, location);
      return true;
    } on LocationNotFoundException {
      return false;
    }
  }

  bool updateEndLocation(String? newEndLocation) {
    if (newEndLocation == null) return false;
    try {
      var location = timeZoneDatabase.get(newEndLocation);
      end = TZDateTime.from(end as TZDateTime, location);
      return true;
    } on LocationNotFoundException {
      return false;
    }
  }
}
