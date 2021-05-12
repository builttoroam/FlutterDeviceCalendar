import 'package:flutter/foundation.dart';

class Reminder {
  /// The time when the reminder should be triggered expressed in terms of minutes before the start of the event
  int? minutes;

  Reminder({@required this.minutes})
      : assert(minutes != null && minutes >= 0,
            'Minutes must be greater than or equal than zero');

  Reminder.fromJson(Map<String, dynamic> json) {
    minutes = json['minutes'] as int;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'minutes': minutes};
  }
}
