import '../../../common/error_messages.dart';
import 'attendance_status.dart';

class IosAttendeeDetails {
  IosAttendanceStatus? _attendanceStatus;

  /// The attendee's status for the event. This is read-only
  IosAttendanceStatus? get attendanceStatus => _attendanceStatus;

  IosAttendeeDetails();

  IosAttendeeDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    if (json['iOSAttendanceStatus'] != null &&
        json['iOSAttendanceStatus'] is int) {
      _attendanceStatus =
          IosAttendanceStatus.values[json['iOSAttendanceStatus']];
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'iOSAttendanceStatus': _attendanceStatus?.index};
  }
}
