class Ulke {
  final String ulkeAdi;
  final String ulkeAdiEn; final String ulkeId;

  Ulke({required this.ulkeAdi, required this.ulkeAdiEn, required this.ulkeId});

  factory Ulke.fromJson(Map<String, dynamic> json) => Ulke(
        ulkeAdi: json["UlkeAdi"] as String,
        ulkeAdiEn: json["UlkeAdiEn"] as String,
        ulkeId: json["UlkeID"] as String,
      );

  Map<String, dynamic> toJson() => {
        'UlkeAdi': ulkeAdi,
        'UlkeAdiEn': ulkeAdiEn,
        'UlkeID': ulkeId,
      };
}

class Sehir {
  final String sehirAdi;
  final String sehirAdiEn;
  final String sehirId;

  Sehir({required this.sehirAdi, required this.sehirAdiEn, required this.sehirId});

  factory Sehir.fromJson(Map<String, dynamic> json) => Sehir(
        sehirAdi: json["SehirAdi"] as String,
        sehirAdiEn: json["SehirAdiEn"] as String,
        sehirId: json["SehirID"] as String,
      );

  Map<String, dynamic> toJson() => {
        'SehirAdi': sehirAdi,
        'SehirAdiEn': sehirAdiEn,
        'SehirID': sehirId,
      };
}

class Ilce {
  final String ilceAdi;
  final String ilceAdiEn;
  final String ilceId;

  Ilce({required this.ilceAdi, required this.ilceAdiEn, required this.ilceId});

  factory Ilce.fromJson(Map<String, dynamic> json) => Ilce(
        ilceAdi: json["IlceAdi"] as String,
        ilceAdiEn: json["IlceAdiEn"] as String,
        ilceId: json["IlceID"] as String,
      );

  Map<String, dynamic> toJson() => {
        'IlceAdi': ilceAdi,
        'IlceAdiEn': ilceAdiEn,
        'IlceID': ilceId,
      };
}

/// A helper class to group location models for easier storage.
class SavedLocation {
  final Ulke ulke;
  final Sehir sehir;
  final Ilce ilce;

  SavedLocation({required this.ulke, required this.sehir, required this.ilce});

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      ulke: Ulke.fromJson(json['ulke'] as Map<String, dynamic>),
      sehir: Sehir.fromJson(json['sehir'] as Map<String, dynamic>),
      ilce: Ilce.fromJson(json['ilce'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'ulke': ulke.toJson(),
        'sehir': sehir.toJson(),
        'ilce': ilce.toJson(),
      };
}

double? _parseOptionalDouble(dynamic value) {
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '');
}

class Vakit {
  final String miladiTarihKisa;
  final String miladiTarihKisaIso8601;
  final String miladiTarihUzun;
  final String miladiTarihUzunIso8601;

  final String hicriTarihKisa;
  final String hicriTarihUzun;
  final String ayinSekliURL;

  final num greenwichOrtalamaZamani;

  final String imsak;
  final String gunes;
  final String ogle;
  final String ikindi;
  final String aksam;
  final String yatsi;

  final String kibleSaati;
  final double? kibleAcisi;

  Vakit({
    required this.miladiTarihKisa,
    required this.miladiTarihKisaIso8601,
    required this.miladiTarihUzun,
    required this.miladiTarihUzunIso8601,
    required this.hicriTarihKisa,
    required this.hicriTarihUzun,
    required this.ayinSekliURL,
    required this.greenwichOrtalamaZamani,
    required this.imsak,
    required this.gunes,
    required this.ogle,
    required this.ikindi,
    required this.aksam,
    required this.yatsi,
    required this.kibleSaati,
    this.kibleAcisi,
  });

  factory Vakit.fromJson(Map<String, dynamic> json) => Vakit(
    hicriTarihKisa: json["HicriTarihKisa"] as String,
    hicriTarihUzun: json["HicriTarihUzun"] as String,
    ayinSekliURL: json["AyinSekliURL"] as String,
    miladiTarihKisa: json["MiladiTarihKisa"] as String,
    miladiTarihKisaIso8601: json["MiladiTarihKisaIso8601"] as String,
    miladiTarihUzun: json["MiladiTarihUzun"] as String,
    miladiTarihUzunIso8601: json["MiladiTarihUzunIso8601"] as String,
    greenwichOrtalamaZamani: json["GreenwichOrtalamaZamani"] as num,
    imsak: json["Imsak"] as String,
    gunes: json["Gunes"] as String,
    ogle: json["Ogle"] as String,
    ikindi: json["Ikindi"] as String,
    aksam: json["Aksam"] as String,
    yatsi: json["Yatsi"] as String,
    kibleSaati: json["KibleSaati"] as String,
    kibleAcisi: _parseOptionalDouble(
      json["KibleAcisi"] ??
          json["QiblaDegree"] ??
          json["QiblaAngle"] ??
          json["kibleAcisi"],
    ),
  );

  Map<String, dynamic> toJson() => {
    "HicriTarihKisa": hicriTarihKisa,
    "HicriTarihUzun": hicriTarihUzun,
    "AyinSekliURL": ayinSekliURL,
    "MiladiTarihKisa": miladiTarihKisa,
    "MiladiTarihKisaIso8601": miladiTarihKisaIso8601,
    "MiladiTarihUzun": miladiTarihUzun,
    "MiladiTarihUzunIso8601": miladiTarihUzunIso8601,
    "GreenwichOrtalamaZamani": greenwichOrtalamaZamani,
    "Imsak": imsak,
    "Gunes": gunes,
    "Ogle": ogle,
    "Ikindi": ikindi,
    "Aksam": aksam,
    "Yatsi": yatsi,
    "KibleSaati": kibleSaati,
    "KibleAcisi": kibleAcisi,
  };
}
