/// Abstract interface for cloud sync providers
abstract class CloudSyncService {
  /// Get the provider name (e.g., 'Google Drive', 'OneDrive')
  String get providerName;

  /// Check if the provider is configured and ready to use
  bool get isConfigured;

  /// Check if the user is signed in
  bool get isSignedIn;

  /// Get current user info (email, name, etc.)
  CloudUser? get currentUser;

  /// Sign in to the cloud provider
  Future<CloudAuthResult> signIn();

  /// Sign out from the cloud provider
  Future<void> signOut();

  /// Refresh the authentication token if needed
  Future<bool> refreshAuth();

  /// Upload notes data to cloud storage
  Future<CloudSyncResult> syncUp(Map<String, dynamic> notesData);

  /// Download notes data from cloud storage
  Future<CloudSyncResult> syncDown();

  /// Upload a blob (image, attachment) to cloud storage
  Future<CloudBlobResult> uploadBlob(String localPath, String remotePath);

  /// Download a blob from cloud storage
  Future<CloudBlobResult> downloadBlob(String remotePath, String localPath);

  /// Delete a blob from cloud storage
  Future<bool> deleteBlob(String remotePath);

  /// List blobs in cloud storage (for cleanup)
  Future<List<CloudBlob>> listBlobs({String? prefix});

  /// Get sync metadata (last sync time, etc.)
  Future<CloudSyncMetadata?> getSyncMetadata();

  /// Set sync metadata
  Future<void> setSyncMetadata(CloudSyncMetadata metadata);
}

/// Result of authentication operations
class CloudAuthResult {
  final bool success;
  final String? errorMessage;
  final CloudUser? user;

  CloudAuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });

  CloudAuthResult.success(this.user) : success = true, errorMessage = null;
  CloudAuthResult.failure(this.errorMessage) : success = false, user = null;
}

/// Result of sync operations
class CloudSyncResult {
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? data;
  final DateTime? lastModified;

  CloudSyncResult({
    required this.success,
    this.errorMessage,
    this.data,
    this.lastModified,
  });

  CloudSyncResult.success({this.data, this.lastModified})
      : success = true, errorMessage = null;
  CloudSyncResult.failure(this.errorMessage)
      : success = false, data = null, lastModified = null;
}

/// Result of blob operations
class CloudBlobResult {
  final bool success;
  final String? errorMessage;
  final String? remotePath;
  final String? localPath;
  final int? size;

  CloudBlobResult({
    required this.success,
    this.errorMessage,
    this.remotePath,
    this.localPath,
    this.size,
  });

  CloudBlobResult.success({
    this.remotePath,
    this.localPath,
    this.size,
  }) : success = true, errorMessage = null;
  
  CloudBlobResult.failure(this.errorMessage)
      : success = false, remotePath = null, localPath = null, size = null;
}

/// Information about a cloud storage blob
class CloudBlob {
  final String path;
  final int? size;
  final DateTime? lastModified;
  final String? etag;

  CloudBlob({
    required this.path,
    this.size,
    this.lastModified,
    this.etag,
  });
}

/// Cloud user information
class CloudUser {
  final String id;
  final String? email;
  final String? name;
  final String? avatarUrl;

  CloudUser({
    required this.id,
    this.email,
    this.name,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
    };
  }

  factory CloudUser.fromMap(Map<String, dynamic> map) {
    return CloudUser(
      id: map['id'] as String,
      email: map['email'] as String?,
      name: map['name'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
    );
  }
}

/// Sync metadata for tracking sync state
class CloudSyncMetadata {
  final DateTime lastSyncTime;
  final String? lastSyncId;
  final int notesCount;
  final List<String> syncedNoteIds;

  CloudSyncMetadata({
    required this.lastSyncTime,
    this.lastSyncId,
    required this.notesCount,
    required this.syncedNoteIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'lastSyncTime': lastSyncTime.toIso8601String(),
      'lastSyncId': lastSyncId,
      'notesCount': notesCount,
      'syncedNoteIds': syncedNoteIds,
    };
  }

  factory CloudSyncMetadata.fromMap(Map<String, dynamic> map) {
    return CloudSyncMetadata(
      lastSyncTime: DateTime.parse(map['lastSyncTime'] as String),
      lastSyncId: map['lastSyncId'] as String?,
      notesCount: map['notesCount'] as int,
      syncedNoteIds: List<String>.from(map['syncedNoteIds'] ?? []),
    );
  }
}