enum IosAttendanceStatus {
  Unknown,
  Pending,
  Accepted,
  Declined,
  Tentative,
  Delegated,
  Completed,
  InProcess,
}

extension IosAttendanceStatusExtensions on IosAttendanceStatus {
  String _enumToString(IosAttendanceStatus enumValue) {
    return enumValue.toString().split('.').last;
  }

  String get enumToString => _enumToString(this);
}
