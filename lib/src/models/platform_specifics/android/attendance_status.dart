enum AndroidAttendanceStatus {
  None,
  Accepted,
  Declined,
  Invited,
  Tentative,
}

extension AndroidAttendanceStatusExtensions on AndroidAttendanceStatus {
  String _enumToString(AndroidAttendanceStatus enumValue) {
    return enumValue.toString().split('.').last;
  }

  String get enumToString => _enumToString(this);
}
