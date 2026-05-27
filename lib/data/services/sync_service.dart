import 'package:habitshare/domain/repositories/sync_repository.dart';

class SyncService {
  const SyncService(this._syncRepository);

  final ISyncRepository _syncRepository;

  Stream<SyncStatus> watchStatus() => _syncRepository.watchSyncStatus();

  Future<void> syncNow() async {
    await _syncRepository.syncPendingChanges();
  }
}
