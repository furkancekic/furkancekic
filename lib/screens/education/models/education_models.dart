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

  // !!! DÜZELTME: icon ve color getter'ları buraya eklendi !!!
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
    // Tema renkleriyle uyumlu olması için AppTheme'den renkler alınabilir
    // veya burada sabit renkler tanımlanabilir. Şimdilik sabit renkler:
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
  indicator;

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

  // Getter'lar LessonType içinden çağrılacak
  IconData get typeIcon => type.icon;
  Color get typeColor => type.color;

  // !!! DÜZELTME: fromJson fabrika kurucusu burada olmalı !!!
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

  LessonContent({required this.id, required this.type, required this.title});

  factory LessonContent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'textContent':
        return TextContent.fromJson(json);
      case 'interactiveChartContent':
        return InteractiveChartContent.fromJson(json);
      case 'videoContent': // Eğer eklediyseniz
        return VideoContent.fromJson(json);
      case 'codeExampleContent': // Eğer eklediyseniz
        return CodeExampleContent.fromJson(json);
      default:
        return TextContent(
            id: json['id'] ?? 'unknown_content_id',
            title: json['title'] ?? 'Unknown Title',
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
    required this.content,
    this.bulletPoints = const [],
    this.definitions = const {},
  }) : super(id: id, type: 'textContent', title: title);

  factory TextContent.fromJson(Map<String, dynamic> json) {
    return TextContent(
      id: json['id'] as String,
      title: json['title'] as String,
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
  final String explanation;
  final String symbol;
  final String timeframe;
  final ChartType chartType;
  final List<IndicatorConfig> indicators;
  final List<String> annotations;

  InteractiveChartContent({
    required String id,
    required String title,
    required this.explanation,
    required this.symbol,
    required this.timeframe,
    required this.chartType,
    this.indicators = const [],
    this.annotations = const [],
  }) : super(id: id, type: 'interactiveChartContent', title: title);

  factory InteractiveChartContent.fromJson(Map<String, dynamic> json) {
    return InteractiveChartContent(
      id: json['id'] as String,
      title: json['title'] as String,
      explanation: json['explanation'] as String? ?? '',
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
    required this.videoUrl,
    required this.duration,
    this.thumbnail = '',
  }) : super(id: id, type: 'videoContent', title: title);

  factory VideoContent.fromJson(Map<String, dynamic> json) {
    return VideoContent(
      id: json['id'] as String,
      title: json['title'] as String,
      videoUrl: json['videoUrl'] as String? ?? '',
      duration: json['duration'] as String? ?? '0:00',
      thumbnail: json['thumbnail'] as String? ?? '',
    );
  }
}

class CodeExampleContent extends LessonContent {
  final String language;
  final String code;
  final String explanation;
  final bool isExecutable;

  CodeExampleContent({
    required String id,
    required String title,
    required this.language,
    required this.code,
    required this.explanation,
    this.isExecutable = false,
  }) : super(id: id, type: 'codeExampleContent', title: title);

  factory CodeExampleContent.fromJson(Map<String, dynamic> json) {
    return CodeExampleContent(
      id: json['id'] as String,
      title: json['title'] as String,
      language: json['language'] as String? ?? 'plaintext',
      code: json['code'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      isExecutable: json['isExecutable'] as bool? ?? false,
    );
  }
}

// --- QUIZ MODELS ---
// ... (Quiz, Question, MultipleChoiceQuestion, TrueFalseQuestion, DragDropQuestion modelleri önceki gibi kalacak) ...
// ... (Quiz ve alt sınıflarının fromJson metodlarının doğru olduğundan emin olun) ...
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
      timeLimit: json['timeLimit'] as int? ?? 0, // 0 limitsiz demek olabilir
      questions: (json['questions'] as List<dynamic>?)
              ?.map((qJson) => Question.fromJson(qJson as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

abstract class Question {
  final String id;
  final String type; // 'multipleChoice', 'trueFalse', 'dragDrop'
  final String question;
  final String? explanation;

  Question({
    required this.id,
    required this.type,
    required this.question,
    this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
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
            options: [],
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
