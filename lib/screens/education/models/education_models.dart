// screens/education/models/education_models.dart
import 'package:flutter/material.dart';

enum Difficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

enum LessonType {
  theory,
  interactive,
  practice,
  quiz,
}

enum ChartType {
  candlestick,
  line,
  area,
  bar,
  indicator,
}

class EducationCategory {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Difficulty difficulty;
  final String estimatedTime;
  final int lessons;
  int completedLessons; // Made non-final to allow updates
  final List<String> topics;
  final List<Lesson>? detailedLessons;

  EducationCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.difficulty,
    required this.estimatedTime,
    required this.lessons,
    required this.completedLessons,
    required this.topics,
    this.detailedLessons,
  });

  double get progressPercentage =>
      lessons > 0 ? completedLessons / lessons : 0.0;
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final LessonType type;
  final String estimatedTime;
  bool isCompleted; // Made non-final
  bool isLocked; // Made non-final
  final int order;
  final List<LessonContent> content;
  final Quiz? quiz;
  final List<String> prerequisites;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.estimatedTime,
    this.isCompleted = false,
    this.isLocked = false,
    required this.order,
    required this.content,
    this.quiz,
    this.prerequisites = const [],
  });

  // MODIFICATION START: Replaced Dart 3 switch expressions with traditional switch statements
  IconData get typeIcon {
    switch (type) {
      case LessonType.theory:
        return Icons.book;
      case LessonType.interactive:
        return Icons.touch_app;
      case LessonType.practice:
        return Icons.fitness_center;
      case LessonType.quiz:
        return Icons.quiz;
    }
  }

  Color get typeColor {
    switch (type) {
      case LessonType.theory:
        return Colors.blue;
      case LessonType.interactive:
        return Colors.purple;
      case LessonType.practice:
        return Colors.orange;
      case LessonType.quiz:
        return Colors.green;
    }
  }
  // MODIFICATION END
}

abstract class LessonContent {
  final String id;
  final String title;
  final int order;

  LessonContent({
    required this.id,
    required this.title,
    required this.order,
  });
}

class TextContent extends LessonContent {
  final String content;
  final List<String> bulletPoints;
  final String? imageUrl;
  final Map<String, String>? definitions; // Terim açıklamaları

  TextContent({
    required super.id,
    required super.title,
    required super.order,
    required this.content,
    this.bulletPoints = const [],
    this.imageUrl,
    this.definitions,
  });
}

class InteractiveChartContent extends LessonContent {
  final ChartType chartType;
  final String symbol;
  final String timeframe;
  final Map<String, dynamic> chartConfig;
  final List<String> annotations; // Grafikte gösterilecek açıklamalar
  final List<TechnicalIndicatorConfig> indicators;
  final String explanation; // Grafiğin ne gösterdiği

  InteractiveChartContent({
    required super.id,
    required super.title,
    required super.order,
    required this.chartType,
    required this.symbol,
    required this.timeframe,
    required this.chartConfig,
    required this.annotations,
    this.indicators = const [],
    required this.explanation,
  });
}

class TechnicalIndicatorConfig {
  final String type; // SMA, EMA, RSI, MACD, etc.
  final Map<String, dynamic> parameters; // period, color, etc.
  final String description;
  final bool isVisible;

  TechnicalIndicatorConfig({
    required this.type,
    required this.parameters,
    required this.description,
    this.isVisible = true,
  });
}

class VideoContent extends LessonContent {
  final String videoUrl;
  final String thumbnail;
  final String duration;
  final String transcript;

  VideoContent({
    required super.id,
    required super.title,
    required super.order,
    required this.videoUrl,
    required this.thumbnail,
    required this.duration,
    required this.transcript,
  });
}

class CodeExampleContent extends LessonContent {
  final String code;
  final String language;
  final String explanation;
  final bool isExecutable;

  CodeExampleContent({
    required super.id,
    required super.title,
    required super.order,
    required this.code,
    required this.language,
    required this.explanation,
    this.isExecutable = false,
  });
}

class Quiz {
  final String id;
  final String title;
  final List<Question> questions;
  final int passingScore; // Percentage needed to pass
  final int timeLimit; // in minutes, 0 for no limit

  Quiz({
    required this.id,
    required this.title,
    required this.questions,
    this.passingScore = 70,
    this.timeLimit = 0,
  });
}

abstract class Question {
  final String id;
  final String question;
  final String? explanation;
  final int points;

  Question({
    required this.id,
    required this.question,
    this.explanation,
    this.points = 1,
  });
}

class MultipleChoiceQuestion extends Question {
  final List<String> options;
  final int correctAnswerIndex;

  MultipleChoiceQuestion({
    required super.id,
    required super.question,
    super.explanation,
    super.points,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class TrueFalseQuestion extends Question {
  final bool correctAnswer;

  TrueFalseQuestion({
    required super.id,
    required super.question,
    super.explanation,
    super.points,
    required this.correctAnswer,
  });
}

class DragDropQuestion extends Question {
  final List<String> items;
  final List<String> targets;
  final Map<String, String> correctMatches; // item -> target

  DragDropQuestion({
    required super.id,
    required super.question,
    super.explanation,
    super.points,
    required this.items,
    required this.targets,
    required this.correctMatches,
  });
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  bool isUnlocked; // Made non-final
  double progress; // Made non-final // 0.0 to 1.0
  DateTime? unlockedAt; // Made non-final

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.progress,
    this.unlockedAt,
  });
}

class UserProgress {
  final String userId;
  final String categoryId;
  final String lessonId;
  bool isCompleted; // Made non-final
  DateTime? completedAt; // Made non-final
  double score; // Made non-final // For quizzes
  int timeSpent; // Made non-final // in minutes

  UserProgress({
    required this.userId,
    required this.categoryId,
    required this.lessonId,
    required this.isCompleted,
    this.completedAt,
    this.score = 0.0,
    this.timeSpent = 0,
  });
}

// Predefined lesson data
class LessonData {
  static List<Lesson> getBasicsLessons() {
    return [
      Lesson(
        id: 'basics_1',
        title: 'Hisse Senedi Nedir?',
        description: 'Hisse senedinin temel tanımı ve kavramları',
        type: LessonType.theory,
        estimatedTime: '5 dk',
        order: 1,
        content: [
          TextContent(
            id: 'content_1',
            title: 'Hisse Senedi Tanımı',
            order: 1,
            content:
                'Hisse senedi, bir şirketin sahiplik haklarını temsil eden finansal araçlardır. Hisse senedi sahibi olmak, o şirketin küçük bir ortağı olmak anlamına gelir.',
            bulletPoints: [
              'Şirketin kârından pay alma hakkı',
              'Şirket yönetiminde söz hakkı',
              'Varlık satışında pay alma hakkı',
            ],
            definitions: {
              'Temettü': 'Şirketin hissedarlarına dağıttığı kâr payı',
              'Nominal Değer': 'Hisse senedinin üzerinde yazılı değeri',
              'Piyasa Değeri': 'Hisse senedinin borsada işlem gördüğü değer',
            },
          ),
          InteractiveChartContent(
            id: 'chart_1',
            title: 'Hisse Fiyat Hareketleri',
            order: 2,
            chartType: ChartType.line,
            symbol: 'AAPL',
            timeframe: '1M',
            explanation:
                'Bu grafik Apple hisse senedinin son 1 aylık fiyat hareketlerini göstermektedir.',
            annotations: [
              'Fiyatların günlük değişimi görülmektedir',
              // 'Yeşil çizgiler yükseliş, kırmızı çizgiler düşüşü gösterir', // This is usually for candlestick, not line
            ],
            chartConfig: {
              'showVolume': true,
              'showMA': false,
            },
          ),
        ],
        quiz: Quiz(
          id: 'quiz_basics_1',
          title: 'Hisse Senedi Temelleri Testi',
          questions: [
            MultipleChoiceQuestion(
              id: 'q1',
              question: 'Hisse senedi sahibi olmak ne anlama gelir?',
              options: [
                'Şirketin müşterisi olmak',
                'Şirketin ortağı olmak',
                'Şirketin çalışanı olmak',
                'Şirketin alacaklısı olmak',
              ],
              correctAnswerIndex: 1,
              explanation:
                  'Hisse senedi sahibi, şirketin küçük bir ortağıdır ve şirketin sahiplik haklarına sahiptir.',
            ),
            TrueFalseQuestion(
              id: 'q2',
              question: 'Hisse senedi sahipleri temettü alma hakkına sahiptir.',
              correctAnswer: true,
              explanation:
                  'Evet, hisse senedi sahipleri şirketin kârından pay alma hakkına sahiptir.',
            ),
          ],
        ),
      ),
      Lesson(
        id: 'basics_2',
        title: 'Borsa Nasıl Çalışır?',
        description: 'Borsa mekanizması ve alım-satım süreci',
        type: LessonType.interactive,
        estimatedTime: '8 dk',
        order: 2,
        isLocked: true, // Example: Initially locked
        content: [
          TextContent(
            id: 'content_2_1',
            title: 'Borsa Mekanizması',
            order: 1,
            content:
                'Borsa, hisse senetlerinin alınıp satıldığı organize piyasadır. Alıcılar ve satıcılar burada buluşarak fiyat oluşturur.',
            bulletPoints: [
              'Emir defteri sistemi',
              'Alış ve satış emirleri',
              'Fiyat keşif mekanizması',
              'İşlem hacmi ve likidite',
            ],
          ),
          InteractiveChartContent(
            id: 'chart_2_1',
            title: 'Emir Defteri Simülasyonu',
            order: 2,
            chartType:
                ChartType.bar, // Or a custom visualization for order book
            symbol: 'TSLA',
            timeframe: '1D',
            explanation:
                'Bu grafik alış ve satış emirlerinin nasıl eşleştiğini gösterir.',
            annotations: [
              'Yeşil barlar alış emirlerini (bid) gösterir',
              'Kırmızı barlar satış emirlerini (ask) gösterir',
              'Emirler fiyat önceliğine göre sıralanır',
            ],
            chartConfig: {
              'showOrderBook': true,
              'interactive': true,
            },
          ),
        ],
      ),
    ];
  }

  static List<Lesson> getTechnicalAnalysisLessons() {
    return [
      Lesson(
        id: 'technical_1',
        title: 'Grafik Okuma Temelleri',
        description: 'Mum çubukları ve grafik türleri',
        type: LessonType.interactive,
        estimatedTime: '10 dk',
        order: 1,
        content: [
          TextContent(
            id: 'content_t1',
            title: 'Mum Çubukları',
            order: 1,
            content:
                'Mum çubukları, belirli bir süredeki fiyat hareketlerini gösteren en popüler grafik türüdür.',
            bulletPoints: [
              'Açılış fiyatı (Open)',
              'Kapanış fiyatı (Close)',
              'En yüksek fiyat (High)',
              'En düşük fiyat (Low)',
            ],
            definitions: {
              'Gövde': 'Açılış ve kapanış fiyatları arasındaki alan',
              'Fitil': 'En yüksek ve en düşük fiyatları gösteren çizgiler',
              'Boğa Mumu': 'Kapanış > Açılış (genelde yeşil)',
              'Ayı Mumu': 'Kapanış < Açılış (genelde kırmızı)',
            },
          ),
          InteractiveChartContent(
            id: 'chart_t1',
            title: 'İnteraktif Mum Çubukları',
            order: 2,
            chartType: ChartType.candlestick,
            symbol: 'BTC-USD',
            timeframe: '1D',
            explanation:
                'Her mum 1 günlük fiyat hareketini gösterir. Mumların üzerine tıklayarak detaylarını görün.',
            annotations: [
              'Yeşil mumlar yükselişi gösterir',
              'Kırmızı mumlar düşüşü gösterir',
              'Fitillerin uzunluğu volatiliteyi gösterir',
            ],
            chartConfig: {
              'clickable': true,
              'showOHLC': true,
            },
          ),
        ],
        quiz: Quiz(
          id: 'quiz_technical_1',
          title: 'Grafik Okuma Testi',
          questions: [
            MultipleChoiceQuestion(
              id: 'qt1',
              question: 'Yeşil (boğa) mumu neyi gösterir?',
              options: [
                'Kapanış fiyatı açılış fiyatından düşük',
                'Kapanış fiyatı açılış fiyatından yüksek',
                'Hacim artışı',
                'Volatilite artışı',
              ],
              correctAnswerIndex: 1,
              explanation:
                  'Yeşil mum, kapanış fiyatının açılış fiyatından yüksek olduğunu gösterir.',
            ),
          ],
        ),
      ),
      Lesson(
        id: 'technical_2',
        title: 'Hareketli Ortalamalar',
        description: 'SMA ve EMA göstergeleri',
        type: LessonType.interactive,
        estimatedTime: '12 dk',
        order: 2,
        isLocked: true, // Example: Initially locked
        content: [
          TextContent(
            id: 'content_t2',
            title: 'Hareketli Ortalama Türleri',
            order: 1,
            content:
                'Hareketli ortalamalar, fiyat trendlerini daha net görmek için kullanılan önemli göstergelerdir.',
            bulletPoints: [
              'Basit Hareketli Ortalama (SMA)',
              'Üssel Hareketli Ortalama (EMA)',
              'Popüler periyotlar: 20, 50, 200',
              'Trend yönü belirleme',
            ],
            definitions: {
              'SMA': 'Belirli periyottaki fiyatların aritmetik ortalaması',
              'EMA': 'Yeni fiyatlara daha fazla ağırlık veren ortalama',
              'Golden Cross':
                  '50 günlük MA\'nın 200 günlük MA\'yı yukarı kesmesi',
              'Death Cross':
                  '50 günlük MA\'nın 200 günlük MA\'yı aşağı kesmesi',
            },
          ),
          InteractiveChartContent(
            id: 'chart_t2',
            title: 'Hareketli Ortalamalar Karşılaştırması',
            order: 2,
            chartType: ChartType.line, // Could be candlestick with MAs overlaid
            symbol: 'SPY',
            timeframe: '3M',
            explanation:
                'SMA ve EMA\'nın fiyat hareketlerine nasıl tepki verdiğini karşılaştırın.',
            annotations: [
              // These would typically be part of the indicator config if drawn on chart
              // 'Mavi çizgi 20 günlük SMA',
              // 'Turuncu çizgi 20 günlük EMA',
              'EMA fiyat değişimlerine daha hızlı tepki verir',
            ],
            chartConfig: {
              // 'indicators': ['SMA20', 'EMA20'], // This is vague, better to use the indicators list
              'interactive': true,
            },
            indicators: [
              TechnicalIndicatorConfig(
                type: 'SMA',
                parameters: {'period': 20, 'color': 'blue'},
                description: '20 günlük basit hareketli ortalama',
              ),
              TechnicalIndicatorConfig(
                type: 'EMA',
                parameters: {'period': 20, 'color': 'orange'},
                description: '20 günlük üssel hareketli ortalama',
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static List<Lesson> getIndicatorLessons() {
    return [
      Lesson(
        id: 'indicator_1',
        title: 'RSI (Relative Strength Index)',
        description: 'Momentum göstergesi ve aşırı alım/satım seviyeleri',
        type: LessonType.interactive,
        estimatedTime: '15 dk',
        order: 1,
        content: [
          TextContent(
            id: 'content_i1',
            title: 'RSI Nedir?',
            order: 1,
            content:
                'RSI, fiyat hareketlerinin momentum değişimlerini ölçen bir osilatördür. 0-100 arasında değer alır.',
            bulletPoints: [
              'Aşırı alım seviyesi: 70 üzeri',
              'Aşırı satım seviyesi: 30 altı',
              'Standart periyot: 14',
              'Diverjans sinyalleri',
            ],
            definitions: {
              'Aşırı Alım': 'Fiyatın normalden yüksek olduğu durum',
              'Aşırı Satım': 'Fiyatın normalden düşük olduğu durum',
              'Diverjans': 'Fiyat ve gösterge arasındaki uyumsuzluk',
              'Osilatör': 'Belirli seviyeler arasında salınan gösterge',
            },
          ),
          InteractiveChartContent(
            id: 'chart_i1',
            title: 'RSI İnteraktif Analizi',
            order: 2,
            chartType: ChartType
                .indicator, // This might mean a chart showing only the RSI line
            symbol: 'NVDA',
            timeframe: '3M',
            explanation:
                'RSI değerlerini takip ederek alım-satım fırsatlarını belirleyebilirsiniz.',
            annotations: [
              'RSI 70 üzerinde aşırı alım bölgesi',
              'RSI 30 altında aşırı satım bölgesi',
              'Orta hat (50) trend gücünü gösterir',
            ],
            chartConfig: {
              // 'showRSI': true, // Redundant if chartType is indicator and uses indicators list
              // 'period': 14,
              // 'overbought': 70,
              // 'oversold': 30,
            },
            indicators: [
              TechnicalIndicatorConfig(
                type: 'RSI',
                parameters: {
                  'period': 14,
                  'overbought': 70,
                  'oversold': 30,
                },
                description: '14 periyotluk RSI göstergesi',
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
