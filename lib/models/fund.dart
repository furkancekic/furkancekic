// models/fund.dart
class Fund {
  final String? id;
  final String kod;
  final String? fonAdi;
  final String? sonFiyat;
  final String? gunlukGetiri;
  final dynamic pay;
  final dynamic fonToplamDeger;
  final String? kategori;
  final String? kategoriDerece;
  final dynamic yatirimciSayisi;
  final String? pazarPayi;
  final DateTime? kayitTarihi;
  final String? tefas;
  final List<HistoricalData>? historical;
  final Map<String, dynamic>? fundDistributions;
  final Map<String, dynamic>? fundProfile;
  final dynamic flow;
  final String? haftalikGetiri;
  final String? aylikGetiri;
  final String? altiAylikGetiri;
  final String? yillikGetiri;
  final String? yatirimciDegisim;
  final String? degerDegisim;

  Fund({
    this.id,
    required this.kod,
    this.fonAdi,
    this.sonFiyat,
    this.gunlukGetiri,
    this.pay,
    this.fonToplamDeger,
    this.kategori,
    this.kategoriDerece,
    this.yatirimciSayisi,
    this.pazarPayi,
    this.kayitTarihi,
    this.tefas,
    this.historical,
    this.fundDistributions,
    this.fundProfile,
    this.flow,
    this.haftalikGetiri,
    this.aylikGetiri,
    this.altiAylikGetiri,
    this.yillikGetiri,
    this.yatirimciDegisim,
    this.degerDegisim,
  });

  factory Fund.fromJson(Map<String, dynamic> json) {
    return Fund(
      id: json['_id']?.toString(),
      kod: json['kod'] ?? '',
      fonAdi: json['fon_adi'],
      sonFiyat: json['son_fiyat'],
      gunlukGetiri: json['gunluk_getiri'],
      pay: json['pay'],
      fonToplamDeger: json['fon_toplam_deger'],
      kategori: json['kategori'],
      kategoriDerece: json['kategori_drecece'],
      yatirimciSayisi: json['yatirimci_sayisi'],
      pazarPayi: json['pazar_payi'],
      kayitTarihi: json['kayit_tarihi'] != null 
          ? DateTime.tryParse(json['kayit_tarihi'])
          : null,
      tefas: json['tefas'],
      historical: json['historical'] != null
          ? (json['historical'] as List)
              .map((h) => HistoricalData.fromJson(h))
              .toList()
          : null,
      fundDistributions: json['fund_distributions'],
      fundProfile: json['fund_profile'],
      flow: json['flow'],
      haftalikGetiri: json['haftalik_getiri'] ?? '0%',
      aylikGetiri: json['aylik_getiri'] ?? '0%',
      altiAylikGetiri: json['alti_aylik_getiri'] ?? '0%',
      yillikGetiri: json['yillik_getiri'] ?? '0%',
      yatirimciDegisim: json['yatirimci_degisim'] ?? '0',
      degerDegisim: json['deger_degisim'] ?? '0%',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'kod': kod,
      if (fonAdi != null) 'fon_adi': fonAdi,
      if (sonFiyat != null) 'son_fiyat': sonFiyat,
      if (gunlukGetiri != null) 'gunluk_getiri': gunlukGetiri,
      if (pay != null) 'pay': pay,
      if (fonToplamDeger != null) 'fon_toplam_deger': fonToplamDeger,
      if (kategori != null) 'kategori': kategori,
      if (kategoriDerece != null) 'kategori_drecece': kategoriDerece,
      if (yatirimciSayisi != null) 'yatirimci_sayisi': yatirimciSayisi,
      if (pazarPayi != null) 'pazar_payi': pazarPayi,
      if (kayitTarihi != null) 'kayit_tarihi': kayitTarihi!.toIso8601String(),
      if (tefas != null) 'tefas': tefas,
      if (historical != null) 
        'historical': historical!.map((h) => h.toJson()).toList(),
      if (fundDistributions != null) 'fund_distributions': fundDistributions,
      if (fundProfile != null) 'fund_profile': fundProfile,
      if (flow != null) 'flow': flow,
      if (haftalikGetiri != null) 'haftalik_getiri': haftalikGetiri,
      if (aylikGetiri != null) 'aylik_getiri': aylikGetiri,
      if (altiAylikGetiri != null) 'alti_aylik_getiri': altiAylikGetiri,
      if (yillikGetiri != null) 'yillik_getiri': yillikGetiri,
      if (yatirimciDegisim != null) 'yatirimci_degisim': yatirimciDegisim,
      if (degerDegisim != null) 'deger_degisim': degerDegisim,
    };
  }

  // Convenience getters
  String get name => fonAdi ?? kod;
  String get category => kategori ?? 'Bilinmiyor';
  String get dailyReturn => gunlukGetiri ?? '0%';
  
  double get currentPrice {
    if (sonFiyat == null) return 0.0;
    try {
      return double.parse(sonFiyat!.replaceAll(',', '.'));
    } catch (e) {
      return 0.0;
    }
  }

  double get totalValue {
    if (fonToplamDeger == null) return 0.0;
    if (fonToplamDeger is double) return fonToplamDeger;
    if (fonToplamDeger is int) return fonToplamDeger.toDouble();
    try {
      return double.parse(fonToplamDeger.toString().replaceAll(',', '.'));
    } catch (e) {
      return 0.0;
    }
  }

  int get investorCount {
    if (yatirimciSayisi == null) return 0;
    if (yatirimciSayisi is int) return yatirimciSayisi;
    try {
      return int.parse(yatirimciSayisi.toString());
    } catch (e) {
      return 0;
    }
  }

  double get dailyReturnValue {
    if (gunlukGetiri == null) return 0.0;
    try {
      final cleanReturn = gunlukGetiri!
          .replaceAll('%', '')
          .replaceAll(',', '.');
      return double.parse(cleanReturn);
    } catch (e) {
      return 0.0;
    }
  }

  bool get isPositiveReturn => dailyReturnValue >= 0;
  
  bool get isAvailableOnTefas => 
      tefas?.contains('işlem görüyor') == true;

  // Get risk level from fund profile
  int get riskLevel {
    if (fundProfile == null) return 0;
    final riskStr = fundProfile!['Fonun Risk Değeri']?.toString();
    if (riskStr == null) return 0;
    try {
      return int.parse(riskStr);
    } catch (e) {
      return 0;
    }
  }
  double get weeklyReturnValue {
    if (haftalikGetiri == null) return 0.0;
    try {
      final cleanReturn = haftalikGetiri!
          .replaceAll('%', '')
          .replaceAll(',', '.');
      return double.parse(cleanReturn);
    } catch (e) {
      return 0.0;
    }
  }
  
  double get monthlyReturnValue {
    if (aylikGetiri == null) return 0.0;
    try {
      final cleanReturn = aylikGetiri!
          .replaceAll('%', '')
          .replaceAll(',', '.');
      return double.parse(cleanReturn);
    } catch (e) {
      return 0.0;
    }
  }
  
  double get sixMonthReturnValue {
    if (altiAylikGetiri == null) return 0.0;
    try {
      final cleanReturn = altiAylikGetiri!
          .replaceAll('%', '')
          .replaceAll(',', '.');
      return double.parse(cleanReturn);
    } catch (e) {
      return 0.0;
    }
  }
  
  double get yearlyReturnValue {
    if (yillikGetiri == null) return 0.0;
    try {
      final cleanReturn = yillikGetiri!
          .replaceAll('%', '')
          .replaceAll(',', '.');
      return double.parse(cleanReturn);
    } catch (e) {
      return 0.0;
    }
  }
  
  int get investorChangeValue {
    if (yatirimciDegisim == null) return 0;
    try {
      final cleanChange = yatirimciDegisim!.replaceAll('+', '');
      return int.parse(cleanChange);
    } catch (e) {
      return 0;
    }
  }
  
  double get valueChangeValue {
    if (degerDegisim == null) return 0.0;
    try {
      final cleanChange = degerDegisim!
          .replaceAll('%', '')
          .replaceAll(',', '.')
          .replaceAll('+', '');
      return double.parse(cleanChange);
    } catch (e) {
      return 0.0;
    }
  }
  
  bool get isWeeklyPositive => weeklyReturnValue >= 0;
  bool get isMonthlyPositive => monthlyReturnValue >= 0;
  bool get isSixMonthPositive => sixMonthReturnValue >= 0;
  bool get isYearlyPositive => yearlyReturnValue >= 0;
  bool get isInvestorChangePositive => investorChangeValue >= 0;
  bool get isValueChangePositive => valueChangeValue >= 0;
}


class HistoricalData {
  final DateTime date;
  final double price;

  HistoricalData({
    required this.date,
    required this.price,
  });

  factory HistoricalData.fromJson(Map<String, dynamic> json) {
    return HistoricalData(
      date: DateTime.parse(json['date']),
      price: json['price'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'price': price,
    };
  }
}