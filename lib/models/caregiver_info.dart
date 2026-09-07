class CaregiverInfo {
  final String id;
  final String name;
  final String relationship;
  final String email;
  final String phoneNumber;
  final bool isConnected;
  final DateTime? connectedAt;
  final DateTime? lastSyncedAt;
  final String? syncStatusNote;

  const CaregiverInfo({
    required this.id,
    required this.name,
    required this.relationship,
    required this.email,
    required this.phoneNumber,
    this.isConnected = true,
    this.connectedAt,
    this.lastSyncedAt,
    this.syncStatusNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'email': email,
      'phoneNumber': phoneNumber,
      'isConnected': isConnected,
      'connectedAt': connectedAt?.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncStatusNote': syncStatusNote,
    };
  }

  factory CaregiverInfo.fromMap(Map<String, dynamic> map) {
    return CaregiverInfo(
      id: map['id'] as String? ?? 'caregiver_',
      name: map['name'] as String? ?? 'Primary Caregiver',
      relationship: map['relationship'] as String? ?? 'Family Member',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      isConnected: map['isConnected'] as bool? ?? true,
      connectedAt: map['connectedAt'] != null ? DateTime.tryParse(map['connectedAt'] as String) : null,
      lastSyncedAt: map['lastSyncedAt'] != null ? DateTime.tryParse(map['lastSyncedAt'] as String) : null,
      syncStatusNote: map['syncStatusNote'] as String?,
    );
  }
}
