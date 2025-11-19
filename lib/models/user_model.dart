import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String photoUrl;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime lastSeen;

  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl = "",
    this.isOnline = false,
    required this.createdAt,
    required this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'createdAt': _dateToTimestamp(createdAt),
      'lastSeen': _dateToTimestamp(lastSeen),
    };
  }

  static dynamic _dateToTimestamp(DateTime date) {
    try {
      // Check if the date is reasonable (between 1970 and 2100)
      // Also check if the milliseconds since epoch is within Firestore's range
      final millisSinceEpoch = date.millisecondsSinceEpoch;
      final secondsSinceEpoch = millisSinceEpoch ~/ 1000;
      
      // Firestore Timestamp range: roughly -62135596800 to 253402300799 seconds
      if (secondsSinceEpoch > -62135596800 && secondsSinceEpoch < 253402300799) {
        return Timestamp.fromDate(date);
      } else {
        // Date out of valid range, use current time
        return Timestamp.fromDate(DateTime.now());
      }
    } catch (e) {
      // Error converting date, use current time
      return Timestamp.fromDate(DateTime.now());
    }
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      displayName: map['displayName'],
      email: map['email'],
      photoUrl: map['photoUrl'] ?? '',
      isOnline: map['isOnline'] ?? false,
      createdAt: _parseDate(map['createdAt']),
      lastSeen: _parseDate(map['lastSeen']),
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    try {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is int) {
        // Check if the value looks like seconds or milliseconds
        if (dateValue > 1000000000000) { // If greater than year 2001 in milliseconds
          return DateTime.fromMillisecondsSinceEpoch(dateValue);
        } else {
          return DateTime.fromMillisecondsSinceEpoch(dateValue * 1000);
        }
      } else if (dateValue is String) {
        return DateTime.tryParse(dateValue) ?? DateTime.now();
      } else if (dateValue is double) {
        // Handle double values (sometimes timestamps come as doubles)
        int milliseconds = dateValue.toInt();
        if (milliseconds > 1000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(milliseconds);
        } else {
          return DateTime.fromMillisecondsSinceEpoch(milliseconds * 1000);
        }
      }
    } catch (e) {
      // Error parsing date, return current time
      return DateTime.now();
    }
    
    return DateTime.now();
  }

  UserModel copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    bool? isOnline,
    DateTime? createdAt,
    DateTime? lastSeen,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}