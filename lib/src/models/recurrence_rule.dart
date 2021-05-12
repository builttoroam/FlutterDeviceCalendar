import 'package:device_calendar/src/common/calendar_enums.dart';

import '../common/error_messages.dart';
import '../common/recurrence_frequency.dart';

class RecurrenceRule {
  int? totalOccurrences;

  /// The interval between instances of a recurring event
  int? interval;

  /// The date a series of recurring events should end
  DateTime? endDate;

  /// The frequency of recurring events
  RecurrenceFrequency? recurrenceFrequency;

  /// The days of the week that this event occurs on. Only applicable to recurrence rules with a weekly, monthly or yearly frequency
  List<DayOfWeek>? daysOfWeek = [];

  /// A day of the month that this event occurs on. Only applicable to recurrence rules with a monthly or yearly frequency
  int? dayOfMonth;

  /// A month of the year that the event occurs on. Only applicable to recurrence rules with a yearly frequency
  MonthOfYear? monthOfYear;

  /// Filters which recurrences to include in the recurrence rule’s frequency. Only applicable when _isByDayOfMonth is false
  WeekNumber? weekOfMonth;

  final String _totalOccurrencesKey = 'totalOccurrences';
  final String _recurrenceFrequencyKey = 'recurrenceFrequency';
  final String _intervalKey = 'interval';
  final String _endDateKey = 'endDate';
  final String _daysOfWeekKey = 'daysOfWeek';
  final String _dayOfMonthKey = 'dayOfMonth';
  final String _monthOfYearKey = 'monthOfYear';
  final String _weekOfMonthKey = 'weekOfMonth';

  RecurrenceRule(this.recurrenceFrequency,
      {this.totalOccurrences,
      this.interval,
      this.endDate,
      this.daysOfWeek,
      this.dayOfMonth,
      this.monthOfYear,
      this.weekOfMonth})
      : assert(!(endDate != null && totalOccurrences != null),
            'Cannot specify both an end date and total occurrences for a recurring event');

  RecurrenceRule.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    int? recurrenceFrequencyIndex = json[_recurrenceFrequencyKey];
    if (recurrenceFrequencyIndex == null ||
        recurrenceFrequencyIndex >= RecurrenceFrequency.values.length) {
      throw ArgumentError(ErrorMessages.invalidRecurrencyFrequency);
    }
    recurrenceFrequency = RecurrenceFrequency.values[recurrenceFrequencyIndex];

    totalOccurrences = json[_totalOccurrencesKey];

    interval = json[_intervalKey];

    int? endDateMillisecondsSinceEpoch = json[_endDateKey];
    if (endDateMillisecondsSinceEpoch != null) {
      endDate =
          DateTime.fromMillisecondsSinceEpoch(endDateMillisecondsSinceEpoch);
    }

    List<dynamic>? daysOfWeekValues = json[_daysOfWeekKey];
    if (daysOfWeekValues != null && daysOfWeekValues is! List<int>) {
      daysOfWeek = daysOfWeekValues
          .cast<int>()
          .map((value) => value.getDayOfWeekEnumValue)
          .toList();
    }

    dayOfMonth = json[_dayOfMonthKey];
    monthOfYear =
        convertDynamicToInt(json[_monthOfYearKey])?.getMonthOfYearEnumValue;
    weekOfMonth =
        convertDynamicToInt(json[_weekOfMonthKey])?.getWeekNumberEnumValue;
  }

  int? convertDynamicToInt(dynamic value) {
    value = value?.toString();
    return value != null ? int.tryParse(value) : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    if (totalOccurrences != null) {
      data[_totalOccurrencesKey] = totalOccurrences;
    }

    if (interval != null) {
      data[_intervalKey] = interval;
    }

    if (endDate != null) {
      data[_endDateKey] = endDate!.millisecondsSinceEpoch;
    }

    data[_recurrenceFrequencyKey] = recurrenceFrequency?.index;

    if (daysOfWeek?.isNotEmpty == true) {
      data[_daysOfWeekKey] = daysOfWeek!.map((d) => d.value).toList();
    }

    if (monthOfYear != null &&
        recurrenceFrequency == RecurrenceFrequency.Yearly) {
      data[_monthOfYearKey] = monthOfYear!.value;
    }

    if (recurrenceFrequency == RecurrenceFrequency.Monthly ||
        recurrenceFrequency == RecurrenceFrequency.Yearly) {
      if (weekOfMonth != null) {
        data[_weekOfMonthKey] = weekOfMonth!.value;
      } else {
        // Days of the month should not be added to the recurrence parameter when WeekOfMonth is used
        if (dayOfMonth != null) {
          data[_dayOfMonthKey] = dayOfMonth;
        }
      }
    }

    return data;
  }
}
