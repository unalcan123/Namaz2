import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

class FlagWidget extends StatelessWidget {
  final String countryNameEn;
  final double size;

  const FlagWidget({super.key, required this.countryNameEn, this.size = 40});

  static final Map<String, String> _countryCodeMap = {
    'TURKEY': 'TR',
    'GERMANY': 'DE',
    'UNITED STATES': 'US',
    'AFGHANISTAN': 'AF',
    'ALBANIA': 'AL',
    'ALGERIA': 'DZ',
    'ANDORRA': 'AD',
    'ANGOLA': 'AO',
    'ARGENTINA': 'AR',
    'AUSTRALIA': 'AU',
    'AUSTRIA': 'AT',
    'AZERBAIJAN': 'AZ',
    'BAHRAIN': 'BH',
    'BANGLADESH': 'BD',
    'BELGIUM': 'BE',
    'BOSNIA AND HERZEGOVINA': 'BA',
    'BRAZIL': 'BR',
    'BULGARIA': 'BG',
    'CANADA': 'CA',
    'CHINA': 'CN',
    'DENMARK': 'DK',
    'EGYPT': 'EG',
    'FINLAND': 'FI',
    'FRANCE': 'FR',
    'GEORGIA': 'GE',
    'INDIA': 'IN',
    'INDONESIA': 'ID',
    'IRAN': 'IR',
    'IRAQ': 'IQ',
    'ITALY': 'IT',
    'JAPAN': 'JP',
    'KAZAKHSTAN': 'KZ',
    'KOSOVO': 'XK',
    'KUWAIT': 'KW',
    'KYRGYZSTAN': 'KG',
    'LEBANON': 'LB',
    'LIBYA': 'LY',
    'MALAYSIA': 'MY',
    'MEXICO': 'MX',
    'MONTENEGRO': 'ME',
    'NETHERLANDS': 'NL',
    'NEW ZEALAND': 'NZ',
    'NIGERIA': 'NG',
    'NORTH MACEDONIA': 'MK',
    'NORWAY': 'NO',
    'PAKISTAN': 'PK',
    'PALESTINE': 'PS',
    'QATAR': 'QA',
    'ROMANIA': 'RO',
    'RUSSIA': 'RU',
    'SAUDI ARABIA': 'SA',
    'SOUTH KOREA': 'KR',
    'SPAIN': 'ES',
    'SWEDEN': 'SE',
    'SWITZERLAND': 'CH',
    'TANZANIA': 'TZ',
    'THAILAND': 'TH',
    'UNITED ARAB EMIRATES': 'AE',
    'UNITED KINGDOM': 'GB',
  };

  @override
  Widget build(BuildContext context) {
    final code = _countryCodeMap[countryNameEn.toUpperCase()];
    if (code == null) {
      return Icon(Icons.public, size: size, color: Colors.grey);
    }
    return CountryFlag.fromCountryCode(
      code,
      height: size,
      width: size * 1.5, // Oranları korumak için
      borderRadius: 8,
    );
  }
}
