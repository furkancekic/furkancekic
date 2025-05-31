// screens/education/models/education_models.dart
import 'package:flutter/material.dart';

// --- ENUMS ---
enum Difficulty { beginner, intermediate, advanced, expert }

enum LessonType {
  theory,
  interactive,
  practice,
  quiz;

  static LessonType fromString(String? type) {
    if (type == null) return LessonType.theory;
    return LessonType.values.firstWhere(
      (e) => e.name.toLowerCase() == type.toLowerCase(),
      orElse: () => LessonType.theory,
    );
  }

  IconData get icon {
    switch (this) {
      case LessonType.theory:
        return Icons.menu_book_outlined;
      case LessonType.interactive:
        return Icons.touch_app_outlined;
      case LessonType.practice:
        return Icons.edit_outlined;
      case LessonType.quiz:
        return Icons.quiz_outlined;
    }
  }

  Color get color {
    switch (this) {
      case LessonType.theory:
        return Colors.blue.shade600;
      case LessonType.interactive:
        return Colors.purple.shade600;
      case LessonType.practice:
        return Colors.orange.shade700;
      case LessonType.quiz:
        return Colors.green.shade600;
    }
  }
}

enum ChartType {
  candlestick,
  line,
  area,
  indicator; // Bu genel amaçlı kalabilir, ama spesifikler daha iyi olabilir

  static ChartType fromString(String? type) {
    if (type == null) return ChartType.candlestick;
    return ChartType.values.firstWhere(
      (e) => e.name.toLowerCase() == type.toLowerCase(),
      orElse: () => ChartType.candlestick,
    );
  }
}

// --- MODELS ---
class EducationCategory {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Difficulty difficulty;
  final String estimatedTime;
  final int lessons;
  final int completedLessons;
  final List<String> topics;

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
  });
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final LessonType type;
  final String estimatedTime;
  final int order;
  bool isCompleted;
  bool isLocked;
  final List<String> prerequisites;
  final List<LessonContent> content;
  final Quiz? quiz;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.estimatedTime,
    required this.order,
    this.isCompleted = false,
    this.isLocked = false,
    this.prerequisites = const [],
    this.content = const [],
    this.quiz,
  });

  IconData get typeIcon => type.icon;
  Color get typeColor => type.color;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: LessonType.fromString(json['type'] as String?),
      estimatedTime: json['estimatedTime'] as String,
      order: json['order'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      prerequisites: (json['prerequisites'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      content: (json['content'] as List<dynamic>?)
              ?.map((contentJson) =>
                  LessonContent.fromJson(contentJson as Map<String, dynamic>))
              .toList() ??
          const [],
      quiz: json['quiz'] != null
          ? Quiz.fromJson(json['quiz'] as Map<String, dynamic>)
          : null,
    );
  }
}

abstract class LessonContent {
  final String id;
  final String type;
  final String title;
  final String explanation; // Ortak açıklama alanı

  LessonContent({
    required this.id,
    required this.type,
    required this.title,
    this.explanation = '', // Varsayılan boş
  });

  static LessonContent fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    // final explanation = json['explanation'] as String? ?? ''; // Bu artık constructor'da

    switch (type) {
      case 'textContent':
        return TextContent.fromJson(json);
      case 'interactiveChartContent': // Bu, genel teknik analiz grafiği için kalabilir
        return InteractiveChartContent.fromJson(json);
      case 'interactiveEducationChart': // Bu, indikatör eğitimleri için
        return InteractiveEducationChartContent.fromJson(json);
      case 'videoContent':
        return VideoContent.fromJson(json);
      case 'codeExampleContent':
        return CodeExampleContent.fromJson(json);
      case 'portfolioComparisonChart': // YENİ
        return PortfolioComparisonChartContent.fromJson(json);
      case 'fundamentalRatioComparisonChart': // YENİ
        return FundamentalRatioComparisonChartContent.fromJson(json);
      // case 'fundamentalRatioTimeSeriesChart': // YENİ (Eğer oluşturulursa)
      //   return FundamentalRatioTimeSeriesChartContent.fromJson(json);
      default:
        return TextContent(
            id: json['id'] ?? 'unknown_content_id',
            title: json['title'] ?? 'Unknown Title',
            explanation: json['explanation'] ?? 'Unknown Explanation',
            content: 'Content type "$type" not recognized or missing.');
    }
  }
}

class TextContent extends LessonContent {
  final String content;
  final List<String> bulletPoints;
  final Map<String, String> definitions;

  TextContent({
    required String id,
    required String title,
    required String explanation,
    required this.content,
    this.bulletPoints = const [],
    this.definitions = const {},
  }) : super(
            id: id,
            type: 'textContent',
            title: title,
            explanation: explanation);

  factory TextContent.fromJson(Map<String, dynamic> json) {
    return TextContent(
      id: json['id'] as String,
      title: json['title'] as String,
      explanation: json['explanation'] as String? ?? '',
      content: json['content'] as String? ?? '',
      bulletPoints: (json['bulletPoints'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      definitions: (json['definitions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );
  }
}

class InteractiveChartContent extends LessonContent {
  // Bu sınıf genel teknik analiz grafiği için kullanılacak
  final String symbol;
  final String timeframe;
  final ChartType chartType;
  final List<IndicatorConfig> indicators;
  final List<String> annotations;

  InteractiveChartContent({
    required String id,
    required String title,
    required String explanation,
    required this.symbol,
    required this.timeframe,
    required this.chartType,
    this.indicators = const [],
    this.annotations = const [],
  }) : super(
            id: id,
            type: 'interactiveChartContent',
            title: title,
            explanation: explanation);

  factory InteractiveChartContent.fromJson(Map<String, dynamic> json) {
    return InteractiveChartContent(
      id: json['id'] as String,
      title: json['title'] as String,
      explanation: json['explanation'] as String? ??
          json['description'] as String? ??
          '', // eski 'description' ile uyumluluk
      symbol: json['symbol'] as String? ?? 'N/A',
      timeframe: json['timeframe'] as String? ?? 'N/A',
      chartType: ChartType.fromString(json['chartType'] as String?),
      indicators: (json['indicators'] as List<dynamic>?)
              ?.map((indicatorJson) => IndicatorConfig.fromJson(
                  indicatorJson as Map<String, dynamic>))
              .toList() ??
          const [],
      annotations: (json['annotations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

class InteractiveEducationChartContent extends LessonContent {
  // Bu sınıf indikatör eğitimleri için (RSI, MACD vb.)
  final String indicatorType; // 'rsi', 'macd', 'stochastic', 'bollingerBands'
  final List<String> learningPoints;

  InteractiveEducationChartContent({
    required String id,
    required String title,
    required String explanation,
    required this.indicatorType,
    required this.learningPoints,
  }) : super(
            id: id,
            type: 'interactiveEducationChart',
            title: title,
            explanation: explanation);

  factory InteractiveEducationChartContent.fromJson(Map<String, dynamic> json) {
    return InteractiveEducationChartContent(
      id: json['id'] as String,
      title: json['title'] as String,
      explanation: json['explanation'] as String? ??
          json['description'] as String? ??
          '', // eski 'description' ile uyumluluk
      indicatorType: json['indicatorType'] as String? ?? 'rsi',
      learningPoints: (json['learningPoints'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

// YENİ İÇERİK TÜRLERİ
class PortfolioScenario {
  final String name;
  final String colorHex; // Renk için HEX string (örn: "#FF5733")
  final double initialValue;
  final double averageReturn;
  final double volatility;

  PortfolioScenario({
    required this.name,
    required this.colorHex,
    required this.initialValue,
    required this.averageReturn,
    required this.volatility,
  });

  factory PortfolioScenario.fromJson(Map<String, dynamic> json) {
    return PortfolioScenario(
      name: json['name'] as String,
      colorHex: json['colorHex'] as String? ?? '#CCCCCC',
      initialValue: (json['initialValue'] as num?)?.toDouble() ?? 10000.0,
      averageReturn: (json['averageReturn'] as num?)?.toDouble() ?? 0.0,
      volatility: (json['volatility'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PortfolioComparisonChartContent extends LessonContent {
  final List<PortfolioScenario> portfolios;
  final int durationYears;
  final List<String> annotations;

  PortfolioComparisonChartContent({
    required String id,
    required String title,
    required String explanation,
    required this.portfolios,
    required this.durationYears,
    this.annotations = const [],
  }) : super(
            id: id,
            type: 'portfolioComparisonChart',
            title: title,
            explanation: explanation);

  factory PortfolioComparisonChartContent.fromJson(Map<String, dynamic> json) {
    return PortfolioComparisonChartContent(
      id: json['id'] as String,
      title: json['title'] as String,
      explanation: json['explanation'] as String? ?? '',
      portfolios: (json['portfolios'] as List<dynamic>?)
              ?.map(
                  (e) => PortfolioScenario.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      durationYears: json['durationYears'] as int? ?? 10,
      annotations: (json['annotations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

class CompanyRatioData {
  final String name;
  final double value;

  CompanyRatioData({required this.name, required this.value});

  factory CompanyRatioData.fromJson(Map<String, dynamic> json) {
    return CompanyRatioData(
      name: json['name'] as String,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FundamentalRatioComparisonChartContent extends LessonContent {
  final String ratioType; // "FK", "PDD" etc.
  final List<CompanyRatioData> companies;
  final double? averageRatio; // Opsiyonel sektör ortalaması
  final List<String> learningPoints;

  FundamentalRatioComparisonChartContent({
    required String id,
    required String title,
    required String explanation,
    required this.ratioType,
    required this.companies,
    this.averageRatio,
    this.learningPoints = const [],
  }) : super(
            id: id,
            type: 'fundamentalRatioComparisonChart',
            title: title,
            explanation: explanation);

  factory FundamentalRatioComparisonChartContent.fromJson(
      Map<String, dynamic> json) {
    return FundamentalRatioComparisonChartContent(
      id: json['id'] as String,
      title: json['title'] as String,
      explanation: json['explanation'] as String? ?? '',
      ratioType: json['ratioType'] as String? ?? 'N/A',
      companies: (json['companies'] as List<dynamic>?)
              ?.map((e) => CompanyRatioData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      averageRatio: (json['averageRatio'] as num?)?.toDouble(),
      learningPoints: (json['learningPoints'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

class IndicatorConfig {
  final String type;
  final Map<String, dynamic> parameters;
  final bool isVisible;

  IndicatorConfig({
    required this.type,
    this.parameters = const {},
    this.isVisible = true,
  });

  factory IndicatorConfig.fromJson(Map<String, dynamic> json) {
    return IndicatorConfig(
      type: json['type'] as String,
      parameters: (json['parameters'] as Map<String, dynamic>?) ?? const {},
      isVisible: json['isVisible'] as bool? ?? true,
    );
  }
}

class VideoContent extends LessonContent {
  final String videoUrl;
  final String duration;
  final String thumbnail;

  VideoContent({
    required String id,
    required String title,
    required String explanation,
    required this.videoUrl,
    required this.duration,
    this.thumbnail = '',
  }) : super(
            id: id,
            type: 'videoContent',
            title: title,
            explanation: explanation);

  factory VideoContent.fromJson(Map<String, dynamic> json) {
    return VideoContent(
      id: json['id'] as String,
      title: json['title'] as String,
      explanation: json['explanation'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
      duration: json['duration'] as String? ?? '0:00',
      thumbnail: json['thumbnail'] as String? ?? '',
    );
  }
}

class CodeExampleContent extends LessonContent {
  final String language;
  final String code;
  // final String explanation; // Bu artık LessonContent'tan geliyor
  final bool isExecutable;

  CodeExampleContent({
    required String id,
    required String title,
    required String explanation,
    required this.language,
    required this.code,
    this.isExecutable = false,
  }) : super(
            id: id,
            type: 'codeExampleContent',
            title: title,
            explanation: explanation);

  factory CodeExampleContent.fromJson(Map<String, dynamic> json) {
    return CodeExampleContent(
      id: json['id'] as String,
      title: json['title'] as String,
      explanation: json['explanation'] as String? ?? '',
      language: json['language'] as String? ?? 'plaintext',
      code: json['code'] as String? ?? '',
      isExecutable: json['isExecutable'] as bool? ?? false,
    );
  }
}

class Quiz {
  final String id;
  final String title;
  final int passingScore;
  final int timeLimit; // Dakika cinsinden
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.passingScore,
    required this.timeLimit,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      title: json['title'] as String,
      passingScore: json['passingScore'] as int? ?? 70,
      timeLimit: json['timeLimit'] as int? ?? 0,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((qJson) => Question.fromJson(qJson as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

abstract class Question {
  final String id;
  final String type;
  final String question;
  final String? explanation;

  Question({
    required this.id,
    required this.type,
    required this.question,
    this.explanation,
  });

  static Question fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'multipleChoice':
        return MultipleChoiceQuestion.fromJson(json);
      case 'trueFalse':
        return TrueFalseQuestion.fromJson(json);
      case 'dragDrop':
        return DragDropQuestion.fromJson(json);
      default:
        return MultipleChoiceQuestion(
            id: json['id'] ?? 'unknown_q_id',
            question: json['question'] ?? 'Unknown Question',
            options: const [],
            correctAnswerIndex: 0,
            explanation: 'Question type "$type" not recognized.');
    }
  }
}

class MultipleChoiceQuestion extends Question {
  final List<String> options;
  final int correctAnswerIndex;

  MultipleChoiceQuestion({
    required String id,
    required String question,
    required this.options,
    required this.correctAnswerIndex,
    String? explanation,
  }) : super(
            id: id,
            type: 'multipleChoice',
            question: question,
            explanation: explanation);

  factory MultipleChoiceQuestion.fromJson(Map<String, dynamic> json) {
    return MultipleChoiceQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? 0,
      explanation: json['explanation'] as String?,
    );
  }
}

class TrueFalseQuestion extends Question {
  final bool correctAnswer;

  TrueFalseQuestion({
    required String id,
    required String question,
    required this.correctAnswer,
    String? explanation,
  }) : super(
            id: id,
            type: 'trueFalse',
            question: question,
            explanation: explanation);

  factory TrueFalseQuestion.fromJson(Map<String, dynamic> json) {
    return TrueFalseQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      correctAnswer: json['correctAnswer'] as bool? ?? false,
      explanation: json['explanation'] as String?,
    );
  }
}

class DragDropQuestion extends Question {
  final List<String> items;
  final List<String> targets;
  final Map<String, String> correctMatches;

  DragDropQuestion({
    required String id,
    required String question,
    required this.items,
    required this.targets,
    required this.correctMatches,
    String? explanation,
  }) : super(
            id: id,
            type: 'dragDrop',
            question: question,
            explanation: explanation);

  factory DragDropQuestion.fromJson(Map<String, dynamic> json) {
    return DragDropQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      items:
          (json['items'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      targets: (json['targets'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      correctMatches: (json['correctMatches'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      explanation: json['explanation'] as String?,
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final double progress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.progress = 0.0,
  });
}

class CandleData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  CandleData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory CandleData.fromJson(Map<String, dynamic> json) {
    return CandleData(
      date: DateTime.parse(json['Date']),
      open: json['Open'].toDouble(),
      high: json['High'].toDouble(),
      low: json['Low'].toDouble(),
      close: json['Close'].toDouble(),
      volume: json['Volume'] is int ? json['Volume'] : json['Volume'].toInt(),
    );
  }
}
