import 'package:hive/hive.dart';
import '../domain/asset_model.dart';
import '../../../core/database/local_db_service.dart';

class AssetRepository {
  final Box _box = LocalDbService.assetsBox;

  // Tüm varlıkları listele
  List<AssetModel> getAssets() {
    return _box.values.cast<AssetModel>().toList();
  }

  // Yeni varlık ekle
  Future<void> addAsset(AssetModel asset) async {
    // id'yi key olarak kullanıyoruz
    await _box.put(asset.id, asset);
  }

  // Varlık sil
  Future<void> deleteAsset(String id) async {
    await _box.delete(id);
  }
}
