import '../../../common/error_messages.dart';
import 'attendance_status.dart';

class AndroidAttendeeDetails {
  AndroidAttendanceStatus? _attendanceStatus;

  /// The attendee's status for the event. This is read-only
  AndroidAttendanceStatus? get attendanceStatus => _attendanceStatus;

  AndroidAttendeeDetails();

  AndroidAttendeeDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    if (json['androidAttendanceStatus'] != null &&
        json['androidAttendanceStatus'] is int) {
      _attendanceStatus =
          AndroidAttendanceStatus.values[json['androidAttendanceStatus']];
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'androidAttendanceStatus': _attendanceStatus?.index
    };
  }
}
