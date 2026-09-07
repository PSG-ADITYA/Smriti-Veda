class ConnectedSenior {
  final String patientId;
  final String name;
  final String relationship;
  final String email;
  final String phoneNumber;
  final DateTime connectedAt;
  final DateTime? lastActiveAt;
  final bool isAuthorized;
  final String? notes;

  const ConnectedSenior({
    required this.patientId,
    required this.name,
    required this.relationship,
    this.email = '',
    this.phoneNumber = '',
    required this.connectedAt,
    this.lastActiveAt,
    this.isAuthorized = true,
    this.notes,
  });

  ConnectedSenior copyWith({
    String? patientId,
    String? name,
    String? relationship,
    String? email,
    String? phoneNumber,
    DateTime? connectedAt,
    DateTime? lastActiveAt,
    bool? isAuthorized,
    String? notes,
  }) {
    return ConnectedSenior(
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      connectedAt: connectedAt ?? this.connectedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isAuthorized: isAuthorized ?? this.isAuthorized,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'name': name,
      'relationship': relationship,
      'email': email,
      'phoneNumber': phoneNumber,
      'connectedAt': connectedAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'isAuthorized': isAuthorized,
      'notes': notes,
    };
  }

  factory ConnectedSenior.fromMap(Map<String, dynamic> map) {
    return ConnectedSenior(
      patientId: map['patientId'] as String? ?? '',
      name: map['name'] as String? ?? 'Senior Member',
      relationship: map['relationship'] as String? ?? 'Family Member',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      connectedAt: map['connectedAt'] != null
          ? (DateTime.tryParse(map['connectedAt'] as String) ?? DateTime.now())
          : DateTime.now(),
      lastActiveAt: map['lastActiveAt'] != null
          ? DateTime.tryParse(map['lastActiveAt'] as String)
          : null,
      isAuthorized: map['isAuthorized'] as bool? ?? true,
      notes: map['notes'] as String?,
    );
  }
}
