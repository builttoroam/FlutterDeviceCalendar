import 'dart:io' show Platform;

import '../common/calendar_enums.dart';
import '../common/error_messages.dart';
import 'platform_specifics/android/attendee_details.dart';
import 'platform_specifics/ios/attendee_details.dart';

/// A person attending an event
class Attendee {
  /// The name of the attendee
  String? name;

  /// The email address of the attendee
  String? emailAddress;

  /// An attendee role: None, Optional, Required or Resource
  AttendeeRole? role;

  /// Read-only. Returns true if the attendee is an organiser, else false
  bool isOrganiser = false;

  /// Details about the attendee that are specific to iOS.
  /// When reading details for an existing event, this will only be populated on iOS devices.
  IosAttendeeDetails? iosAttendeeDetails;

  /// Details about the attendee that are specific to Android.
  /// When reading details for an existing event, this will only be populated on Android devices.
  AndroidAttendeeDetails? androidAttendeeDetails;

  Attendee(
      {this.name, this.emailAddress, this.role, this.isOrganiser = false}) {
    if (Platform.isAndroid) {
      androidAttendeeDetails = AndroidAttendeeDetails();
    }

    if (Platform.isIOS) {
      iosAttendeeDetails = IosAttendeeDetails();
    }
  }

  Attendee.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    name = json['name'];
    emailAddress = json['emailAddress'];
    role = AttendeeRole.values[json['role'] ?? 0];
    isOrganiser = json['isOrganizer'] ??
        false; // Getting and setting an organiser for Android

    if (Platform.isAndroid) {
      androidAttendeeDetails = AndroidAttendeeDetails.fromJson(json);
    }

    if (Platform.isIOS) {
      iosAttendeeDetails = IosAttendeeDetails.fromJson(json);
    }
  }

  Map<String, dynamic> toJson() {
    final data = {
      'name': name,
      'emailAddress': emailAddress,
      'role': role?.index,
      'isOrganizer': isOrganiser
    };

    if (iosAttendeeDetails != null) {
      data.addEntries(iosAttendeeDetails!.toJson().entries);
    }
    if (androidAttendeeDetails != null) {
      data.addEntries(androidAttendeeDetails!.toJson().entries);
    }

    return data;
  }
}
