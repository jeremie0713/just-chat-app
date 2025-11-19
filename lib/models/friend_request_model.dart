enum FriendRequestStatus {
  pending,
  accepted,
  declined,
}

class FriendRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? message;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
    this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
      'message': message,
    };
  }

  static FriendRequestModel fromMap(Map<String, dynamic> map) {
    return FriendRequestModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: _convertToDateTime(map['createdAt']) ?? DateTime.now(),
      respondedAt: map['respondedAt'] != null
          ? _convertToDateTime(map['respondedAt'])
          : null,
      message: map['message'],
    );
  }

  static DateTime? _convertToDateTime(dynamic value) {
    if (value == null) return null;
    
    // If it's already a DateTime
    if (value is DateTime) return value;
    
    // If it's a Firestore Timestamp (check by checking if it has toDate method)
    try {
      if (value.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate();
      }
    } catch (e) {
      // Continue to other checks if this fails
    }
    
    // If it's an integer (milliseconds since epoch)
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    
    // If it's a string representation of int
    if (value is String) {
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return DateTime.fromMillisecondsSinceEpoch(intValue);
      }
    }
    
    return null;
  }

  FriendRequestModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? message,
  }) {
    return FriendRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message ?? this.message,
    );
  }
}