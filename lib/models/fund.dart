// lib/models/fund.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ------------------------------------------------------------
/// FUND MODEL – REST API (fund_api.py) ile uyumlu, eksiksiz sürüm
/// ------------------------------------------------------------

class Fund {
  // Temel alanlar
  final String kod;
  final String fonAdi;
  final String sonFiyat;
  final String gunlukGetiri;
  final String kategori;
  final String?
      kategoriDerece; // Opsiyonel – bazı kayıtlarda seviye/derece bilgisi
  final int yatirimciSayisi;
  final String pazarPayi;
  final String? tefas; // "TEFAS'ta işlem görüyor" / "TEFAS'ta İşlem Görmüyor"
  final double fonToplamDeger;
  final int pay;
  final DateTime kayitTarihi;

  // İç içe modeller
  final FundProfile? fundProfile;
  final Map<String, double>? fundDistributions;
  final List<FundHistoricalPoint>? historical;

  const Fund({
    required this.kod,
    required this.fonAdi,
    required this.sonFiyat,
    required this.gunlukGetiri,
    required this.kategori,
    this.kategoriDerece,
    required this.yatirimciSayisi,
    required this.pazarPayi,
    this.tefas,
    required this.fonToplamDeger,
    required this.pay,
    required this.kayitTarihi,
    this.fundProfile,
    this.fundDistributions,
    this.historical,
  });

  /* ---------------------------- JSON PARSE ---------------------------- */

  factory Fund.fromJson(Map<String, dynamic> json) {
    // Kolaylaştırmak için kısa yardımcı
    T? _cast<T>(dynamic v) => v is T ? v : null;

    double _parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
    }

    return Fund(
      kod: json['kod'] ?? json['Kodu'] ?? '',
      fonAdi: json['fon_adi'] ?? json['fonAdi'] ?? '',
      sonFiyat: json['son_fiyat'] ?? json['sonFiyat'] ?? '0',
      gunlukGetiri: json['gunluk_getiri'] ?? json['gunlukGetiri'] ?? '0%',
      kategori: json['kategori'] ?? '',
      kategoriDerece: json['kategori_derece'] ?? json['kategoriDerece'],
      yatirimciSayisi: _cast<int>(json['yatirimci_sayisi']) ?? 0,
      pazarPayi: json['pazar_payi'] ?? '0%',
      tefas: json['tefas'],
      fonToplamDeger: _parseDouble(json['fon_toplam_deger']),
      pay: _cast<int>(json['pay']) ?? 0,
      kayitTarihi: DateTime.tryParse(json['kayit_tarihi']?.toString() ?? '') ??
          DateTime.now(),
      fundProfile: json['fund_profile'] != null
          ? FundProfile.fromJson(json['fund_profile'])
          : null,
      fundDistributions: json['fund_distributions'] != null
          ? Map<String, double>.from(json['fund_distributions']
              .map((k, v) => MapEntry(k, _parseDouble(v))))
          : null,
      historical: (json['historical'] as List?)
          ?.map((h) => FundHistoricalPoint.fromJson(h))
          .toList(),
    );
  }

  /* ----------------------------- HELPERS ------------------------------ */

  double get sonFiyatDouble => _stringToDouble(sonFiyat);
  double get gunlukGetiriDouble =>
      _stringToDouble(gunlukGetiri.replaceAll('%', ''));

  bool get isTefasActive =>
      tefas?.toLowerCase().contains('işlem görüyor') ?? false;

  int get riskLevel => int.tryParse(fundProfile?.fonunRiskDegeri ?? '0') ?? 0;

  Color getRiskColor(AppThemeExtension theme) {
    if (riskLevel <= 2) return theme.positiveColor;
    if (riskLevel <= 4) return theme.warningColor;
    return theme.negativeColor;
  }

  /* --------------------------- PRIVATE --------------------------- */

  double _stringToDouble(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
  }
}

/* ---------------------------------------------------------------------
   FUND PROFILE MODEL
   ------------------------------------------------------------------ */
class FundProfile {
  final String kod;
  final String? isinKodu;
  final String? platformIslemDurumu;
  final String? islemBaslangicSaati;
  final String? sonIslemSaati;
  final String? fonAlisValoru;
  final String? fonSatisValoru;
  final String? minAlisIslemMiktari;
  final String? minSatisIslemMiktari;
  final String? maxAlisIslemMiktari;
  final String? maxSatisIslemMiktari;
  final String? girisKomisyonu;
  final String? cikisKomisyonu;
  final String? fonunFaizIcerigi;
  final String? fonunRiskDegeri; // ✔ risk değeri alanı
  final String? kapBilgiAdresi;

  const FundProfile({
    required this.kod,
    this.isinKodu,
    this.platformIslemDurumu,
    this.islemBaslangicSaati,
    this.sonIslemSaati,
    this.fonAlisValoru,
    this.fonSatisValoru,
    this.minAlisIslemMiktari,
    this.minSatisIslemMiktari,
    this.maxAlisIslemMiktari,
    this.maxSatisIslemMiktari,
    this.girisKomisyonu,
    this.cikisKomisyonu,
    this.fonunFaizIcerigi,
    this.fonunRiskDegeri,
    this.kapBilgiAdresi,
  });

  factory FundProfile.fromJson(Map<String, dynamic> json) => FundProfile(
        kod: json['Kodu'] ?? json['kod'] ?? '',
        isinKodu: json['ISIN Kodu'] ?? json['isinKodu'],
        platformIslemDurumu:
            json['Platform İşlem Durumu'] ?? json['platformIslemDurumu'],
        islemBaslangicSaati:
            json['İşlem Başlangıç Saati'] ?? json['islemBaslangicSaati'],
        sonIslemSaati: json['Son İşlem Saati'] ?? json['sonIslemSaati'],
        fonAlisValoru: json['Fon Alış Valörü'] ?? json['fonAlisValoru'],
        fonSatisValoru: json['Fon Satış Valörü'] ?? json['fonSatisValoru'],
        minAlisIslemMiktari:
            json['Min. Alış İşlem Miktarı'] ?? json['minAlisIslemMiktari'],
        minSatisIslemMiktari:
            json['Min. Satış İşlem Miktarı'] ?? json['minSatisIslemMiktari'],
        maxAlisIslemMiktari:
            json['Max. Alış İşlem Miktarı'] ?? json['maxAlisIslemMiktari'],
        maxSatisIslemMiktari:
            json['Max. Satış İşlem Miktarı'] ?? json['maxSatisIslemMiktari'],
        girisKomisyonu: json['Giriş Komisyonu'] ?? json['girisKomisyonu'],
        cikisKomisyonu: json['Çıkış Komisyonu'] ?? json['cikisKomisyonu'],
        fonunFaizIcerigi:
            json['Fonun Faiz İçeriği'] ?? json['fonunFaizIcerigi'],
        fonunRiskDegeri:
            json['Fonun Risk Değeri']?.toString() ?? json['fonunRiskDegeri'],
        kapBilgiAdresi: json['KAP Bilgi Adresi'] ?? json['kapBilgiAdresi'],
      );
}

/* ---------------------------------------------------------------------
   HISTORICAL POINT
   ------------------------------------------------------------------ */
class FundHistoricalPoint {
  final DateTime date;
  final double price;

  const FundHistoricalPoint({required this.date, required this.price});

  factory FundHistoricalPoint.fromJson(Map<String, dynamic> json) =>
      FundHistoricalPoint(
        date: DateTime.parse(json['date'].toString()),
        price: (json['price'] as num).toDouble(),
      );
}

/* ---------------------------------------------------------------------
   RISK METRICS MODEL
   ------------------------------------------------------------------ */
class FundRiskMetrics {
  final double sharpeRatio;
  final double beta;
  final double alpha;
  final double rSquared;
  final double maxDrawdown;
  final double stdDev;
  final double volatility;
  final double sortinoRatio;
  final double treynorRatio;
  final int riskLevel;

  const FundRiskMetrics({
    required this.sharpeRatio,
    required this.beta,
    required this.alpha,
    required this.rSquared,
    required this.maxDrawdown,
    required this.stdDev,
    required this.volatility,
    required this.sortinoRatio,
    required this.treynorRatio,
    required this.riskLevel,
  });

  factory FundRiskMetrics.fromJson(Map<String, dynamic> json) =>
      FundRiskMetrics(
        sharpeRatio: (json['sharpeRatio'] as num?)?.toDouble() ?? 0,
        beta: (json['beta'] as num?)?.toDouble() ?? 0,
        alpha: (json['alpha'] as num?)?.toDouble() ?? 0,
        rSquared: (json['rSquared'] as num?)?.toDouble() ?? 0,
        maxDrawdown: (json['maxDrawdown'] as num?)?.toDouble() ?? 0,
        stdDev: (json['stdDev'] as num?)?.toDouble() ?? 0,
        volatility: (json['volatility'] as num?)?.toDouble() ?? 0,
        sortinoRatio: (json['sortinoRatio'] as num?)?.toDouble() ?? 0,
        treynorRatio: (json['treynorRatio'] as num?)?.toDouble() ?? 0,
        riskLevel: (json['riskLevel'] as num?)?.toInt() ?? 0,
      );
}

/* ---------------------------------------------------------------------
   MONTE CARLO SIMULATION MODEL
   ------------------------------------------------------------------ */
class MonteCarloSimulation {
  final double initialPrice;
  final int periods;
  final int simulations;
  final Map<String, List<double>> scenarios; // pessimistic / expected …

  const MonteCarloSimulation({
    required this.initialPrice,
    required this.periods,
    required this.simulations,
    required this.scenarios,
  });

  factory MonteCarloSimulation.fromJson(Map<String, dynamic> json) =>
      MonteCarloSimulation(
        initialPrice: (json['initial_price'] as num?)?.toDouble() ?? 0,
        periods: json['periods'] ?? 0,
        simulations: json['simulations'] ?? 0,
        scenarios: (json['scenarios'] as Map<String, dynamic>).map((k, v) =>
            MapEntry(
                k, (v as List).map((e) => (e as num).toDouble()).toList())),
      );
}

/* ---------------------------------------------------------------------
   FILTRE MODEL (Query param builder)
   ------------------------------------------------------------------ */
class FundFilter {
  final String? category;
  final bool? onlyTefas;
  final double? minReturn;
  final double? maxReturn;
  final int? minRiskLevel;
  final int? maxRiskLevel;
  final String? sortBy;
  final bool sortDescending;

  const FundFilter({
    this.category,
    this.onlyTefas,
    this.minReturn,
    this.maxReturn,
    this.minRiskLevel,
    this.maxRiskLevel,
    this.sortBy,
    this.sortDescending = true,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (category != null) params['category'] = category!;
    if (onlyTefas != null) params['only_tefas'] = onlyTefas.toString();
    if (minReturn != null) params['min_return'] = minReturn.toString();
    if (maxReturn != null) params['max_return'] = maxReturn.toString();
    if (minRiskLevel != null) params['min_risk'] = minRiskLevel.toString();
    if (maxRiskLevel != null) params['max_risk'] = maxRiskLevel.toString();
    if (sortBy != null) params['sort_by'] = sortBy!;
    params['sort_desc'] = sortDescending.toString();
    return params;
  }

  FundFilter copyWith({
    String? category,
    bool? onlyTefas,
    double? minReturn,
    double? maxReturn,
    int? minRiskLevel,
    int? maxRiskLevel,
    String? sortBy,
    bool? sortDescending,
  }) {
    return FundFilter(
      category: category ?? this.category,
      onlyTefas: onlyTefas ?? this.onlyTefas,
      minReturn: minReturn ?? this.minReturn,
      maxReturn: maxReturn ?? this.maxReturn,
      minRiskLevel: minRiskLevel ?? this.minRiskLevel,
      maxRiskLevel: maxRiskLevel ?? this.maxRiskLevel,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }
}
