import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/asset_repository.dart';
import '../domain/asset_model.dart';

final assetRepositoryProvider = Provider((ref) => AssetRepository());

final assetsProvider = StateNotifierProvider<AssetsNotifier, List<AssetModel>>((ref) {
  return AssetsNotifier(ref.read(assetRepositoryProvider));
});

class AssetsNotifier extends StateNotifier<List<AssetModel>> {
  final AssetRepository _repository;

  AssetsNotifier(this._repository) : super([]) {
    loadAssets();
  }

  void loadAssets() {
    // Veritabanından en güncel listeyi alıp state'i güncelliyoruz
    state = _repository.getAssets();
  }

  Future<void> addAsset(AssetModel asset) async {
    await _repository.addAsset(asset);
    loadAssets(); // Ekleme sonrası listeyi tazele
  }

  Future<void> deleteAsset(String id) async {
    await _repository.deleteAsset(id);
    loadAssets(); // Silme sonrası listeyi tazele
  }
}
