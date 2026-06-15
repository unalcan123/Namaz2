import '../../settings/data/prefs_repository.dart';
import 'ezan_api.dart';
import 'models.dart';

class LocationRepository {
  final EzanApi _api;
  final PrefsRepository _prefs;

  LocationRepository(this._api, this._prefs);

  Future<List<Ulke>> ulkeler() => _api.getUlkeler();
  Future<List<Sehir>> sehirler(String ulkeId) => _api.getSehirler(ulkeId);
  Future<List<Ilce>> ilceler(String sehirId) => _api.getIlceler(sehirId);

  Future<List<Vakit>> vakitler(String ilceId) async {
    try {
      // 1. İnternetten çekmeyi dene
      final list = await _api.getVakitler(ilceId);
      
      // 2. Başarılıysa lokale kaydet (Offline kullanım için)
      await _prefs.saveVakitler(ilceId, list);
      
      return list;
    } catch (e) {
      // 3. İnternet yoksa veya hata varsa cached veriyi çek
      final cached = _prefs.getCachedVakitler(ilceId);
      if (cached != null) {
        return cached;
      }
      rethrow; // Cache de yoksa hatayı fırlat
    }
  }
}
