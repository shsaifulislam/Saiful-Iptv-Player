import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_state_model.freezed.dart';
part 'sync_state_model.g.dart';

/// Entity types that can be synced.
enum SyncEntityType {
  @JsonValue('playlists')
  playlists,
  @JsonValue('favorites')
  favorites,
  @JsonValue('history')
  history,
  @JsonValue('settings')
  settings,
  @JsonValue('downloads')
  downloads,
}

/// Status of a sync operation.
enum SyncStatus {
  @JsonValue('idle')
  idle,
  @JsonValue('syncing')
  syncing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('conflict')
  conflict,
}

/// Sync status for a particular entity type.
@freezed
class SyncState with _$SyncState {
  const SyncState._();

  const factory SyncState({
    required SyncEntityType entityType,
    DateTime? lastSyncedAt,
    @Default(0) int pendingChanges,
    @Default(SyncStatus.idle) SyncStatus status,
    String? errorMessage,
    DateTime? nextScheduledSync,
  }) = _SyncState;

  factory SyncState.fromJson(Map<String, dynamic> json) =>
      _$SyncStateFromJson(json);

  /// Whether there are pending changes to sync.
  bool get hasPendingChanges => pendingChanges > 0;

  /// Whether the last sync failed.
  bool get hasError => status == SyncStatus.failed && errorMessage != null;

  /// Whether sync is currently in progress.
  bool get isSyncing => status == SyncStatus.syncing;
}
