// services/education_service.dart
import 'dart:convert';
import 'package:flutter/material.dart'; // <-- ADDED for Icons and Color
import 'package:flutter/foundation.dart'; // <-- ADDED for debugPrint
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/education/models/education_models.dart';
import '../models/candle_data.dart'; // Assuming this path is correct and CandleData is defined
import 'dart:math' as math; // <-- ADDED THIS IMPORT

class EducationService {
  static const String _baseUrl =
      'https://your-api-url.com/api/education'; // Replace with your actual API URL
  static const String _progressKey = 'education_progress';
  static const String _achievementsKey = 'education_achievements';

  // Get all education categories
  static Future<List<EducationCategory>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> categoriesJson = data['categories'];

        return categoriesJson
            .map((json) => _parseCategoryFromJson(json))
            .toList();
      } else {
        // Return default categories if API fails
        debugPrint(
            'API failed to get categories, status: ${response.statusCode}. Returning default.');
        return _getDefaultCategories();
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return _getDefaultCategories();
    }
  }

  // Get lessons for a specific category
  static Future<List<Lesson>> getLessonsForCategory(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/categories/$categoryId/lessons'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> lessonsJson = data['lessons'];

        return lessonsJson.map((json) => _parseLessonFromJson(json)).toList();
      } else {
        // Return default lessons based on category
        debugPrint(
            'API failed to get lessons for $categoryId, status: ${response.statusCode}. Returning default.');
        return _getDefaultLessonsForCategory(categoryId);
      }
    } catch (e) {
      debugPrint('Error fetching lessons for category $categoryId: $e');
      return _getDefaultLessonsForCategory(categoryId);
    }
  }

  // Get specific lesson content
  static Future<Lesson> getLessonById(String lessonId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/lessons/$lessonId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseLessonFromJson(data['lesson']);
      } else {
        debugPrint(
            'API failed to get lesson $lessonId, status: ${response.statusCode}.');
        throw Exception(
            'Lesson not found (API status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error fetching lesson $lessonId: $e');
      throw Exception('Failed to load lesson $lessonId');
    }
  }

  // Get educational chart data
  static Future<List<CandleData>> getEducationalChartData({
    required String symbol,
    required String timeframe,
    required String lessonId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/chart-data?symbol=$symbol&timeframe=$timeframe&lesson=$lessonId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> chartDataJson = data['chart_data'];

        return chartDataJson
            .map((json) => CandleData(
                  date: DateTime.parse(json['date']),
                  open: json['open'].toDouble(),
                  high: json['high'].toDouble(),
                  low: json['low'].toDouble(),
                  close: json['close'].toDouble(),
                  volume:
                      (json['volume'] as num).toInt(), // <-- ADJUSTED FOR INT
                ))
            .toList();
      } else {
        // Return sample data if API fails
        debugPrint(
            'API failed to get chart data for $symbol, status: ${response.statusCode}. Returning sample.');
        return _generateSampleChartData(symbol, timeframe);
      }
    } catch (e) {
      debugPrint('Error fetching chart data for $symbol: $e');
      return _generateSampleChartData(symbol, timeframe);
    }
  }

  // Submit quiz results
  static Future<bool> submitQuizResult({
    required String lessonId,
    required String quizId,
    required Map<String, dynamic> answers,
    required double score,
    required int timeSpent,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/quiz-results'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'lesson_id': lessonId,
          'quiz_id': quizId,
          'answers': answers,
          'score': score,
          'time_spent': timeSpent,
          'completed_at': DateTime.now().toIso8601String(),
        }),
      );
      debugPrint(
          'Quiz result submission for lesson $lessonId: Status ${response.statusCode}');
      return response.statusCode == 200 ||
          response.statusCode == 201; // 201 for created
    } catch (e) {
      debugPrint('Error submitting quiz result for lesson $lessonId: $e');
      return false;
    }
  }

  // Save lesson progress
  static Future<bool> saveLessonProgress({
    required String categoryId,
    required String lessonId,
    required bool isCompleted,
    required int timeSpent,
    double? score,
  }) async {
    bool apiSuccess = false;
    try {
      // Save to API
      final response = await http.post(
        Uri.parse('$_baseUrl/progress'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'category_id': categoryId,
          'lesson_id': lessonId,
          'is_completed': isCompleted,
          'time_spent': timeSpent,
          'score': score,
          'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
        }),
      );
      apiSuccess = response.statusCode == 200 || response.statusCode == 201;
      debugPrint(
          'Lesson progress save for $lessonId to API: Status ${response.statusCode}');
    } catch (e) {
      debugPrint('Error saving progress for $lessonId to API: $e');
      apiSuccess = false; // Explicitly set to false on error
    }

    // Always save locally
    try {
      await _saveLocalProgress(
          categoryId, lessonId, isCompleted, timeSpent, score);
      debugPrint('Lesson progress for $lessonId saved locally.');
    } catch (e) {
      debugPrint('Error saving progress for $lessonId locally: $e');
    }
    return apiSuccess; // Return API success status
  }

  // Get user progress
  static Future<List<UserProgress>> getUserProgress() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/progress'), // Assuming this is the correct endpoint for GET
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> progressJson = data['progress'];

        return progressJson
            .map((json) => UserProgress(
                  userId: json['user_id'], // Assuming your API returns user_id
                  categoryId: json['category_id'],
                  lessonId: json['lesson_id'],
                  isCompleted: json['is_completed'],
                  completedAt: json['completed_at'] != null
                      ? DateTime.parse(json['completed_at'])
                      : null,
                  score: json['score']?.toDouble() ?? 0.0,
                  timeSpent: json['time_spent'] ?? 0,
                ))
            .toList();
      } else {
        // Return local progress if API fails
        debugPrint(
            'API failed to get user progress, status: ${response.statusCode}. Returning local.');
        return await _getLocalProgress();
      }
    } catch (e) {
      debugPrint('Error fetching user progress from API: $e');
      return await _getLocalProgress();
    }
  }

  // Get achievements
  static Future<List<Achievement>> getAchievements() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/achievements'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> achievementsJson = data['achievements'];

        return achievementsJson
            .map((json) => Achievement(
                  id: json['id'],
                  title: json['title'],
                  description: json['description'],
                  icon: _parseIconData(json['icon']),
                  isUnlocked: json['is_unlocked'],
                  progress: json['progress'].toDouble(),
                  unlockedAt: json['unlocked_at'] != null
                      ? DateTime.parse(json['unlocked_at'])
                      : null,
                ))
            .toList();
      } else {
        debugPrint(
            'API failed to get achievements, status: ${response.statusCode}. Returning default.');
        return _getDefaultAchievements();
      }
    } catch (e) {
      debugPrint('Error fetching achievements: $e');
      return _getDefaultAchievements();
    }
  }

  // Check for new achievements
  static Future<List<Achievement>> checkAchievements(
      UserProgress progress) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/check-achievements'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'category_id': progress.categoryId,
          'lesson_id': progress.lessonId,
          'is_completed': progress.isCompleted,
          'score': progress.score,
          'time_spent': progress.timeSpent,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newAchievementsJson =
            data['new_achievements'] ?? [];
        debugPrint(
            'Checked achievements for lesson ${progress.lessonId}, found ${newAchievementsJson.length} new.');
        return newAchievementsJson
            .map((json) => Achievement(
                  id: json['id'],
                  title: json['title'],
                  description: json['description'],
                  icon: _parseIconData(json['icon']),
                  isUnlocked:
                      true, // Assuming API returns only newly unlocked ones
                  progress: 1.0,
                  unlockedAt: DateTime.now(), // Or parse from API if available
                ))
            .toList();
      } else {
        debugPrint(
            'API failed to check achievements, status: ${response.statusCode}.');
      }
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
    return [];
  }

  // Get learning analytics
  static Future<Map<String, dynamic>> getLearningAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/analytics'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint(
            'API failed to get learning analytics, status: ${response.statusCode}. Returning default.');
        return _getDefaultAnalytics();
      }
    } catch (e) {
      debugPrint('Error fetching learning analytics: $e');
      return _getDefaultAnalytics();
    }
  }

  // Private helper methods
  static EducationCategory _parseCategoryFromJson(Map<String, dynamic> json) {
    return EducationCategory(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: _parseIconData(json['icon']),
      color: Color(int.parse(json['color'].replaceFirst('#', ''),
          radix: 16)), // Ensure # is removed if present
      difficulty: _parseDifficulty(json['difficulty']),
      estimatedTime: json['estimated_time'],
      lessons: json['lessons_count'] ?? 0, // Provide default if null
      completedLessons:
          json['completed_lessons'] ?? 0, // Provide default if null
      topics: List<String>.from(json['topics'] ?? []),
    );
  }

  static Lesson _parseLessonFromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      type: _parseLessonType(json['type']),
      estimatedTime: json['estimated_time'] ?? 'N/A',
      isCompleted: json['is_completed'] ?? false,
      isLocked: json['is_locked'] ?? false,
      order: json['order'] ?? 0,
      content: (json['content'] as List<dynamic>? ?? [])
          .map((contentJson) => _parseLessonContent(contentJson))
          .toList(),
      quiz: json['quiz'] != null ? _parseQuiz(json['quiz']) : null,
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
    );
  }

  static LessonContent _parseLessonContent(Map<String, dynamic> json) {
    // Ensure 'id' and 'order' are present and have defaults
    final String id = json['id'] ??
        'unknown_content_id_${DateTime.now().millisecondsSinceEpoch}';
    final int order = json['order'] ?? 0;
    final String title = json['title'] ?? 'Untitled Content';

    switch (json['type']) {
      case 'text':
        return TextContent(
          id: id,
          title: title,
          order: order,
          content: json['content'] ?? '',
          bulletPoints: List<String>.from(json['bullet_points'] ?? []),
          imageUrl: json['image_url'],
          definitions: json['definitions'] != null
              ? Map<String, String>.from(json['definitions'])
              : null,
        );
      case 'interactive_chart':
        return InteractiveChartContent(
          id: id,
          title: title,
          order: order,
          chartType: _parseChartType(json['chart_type'] ?? 'candlestick'),
          symbol: json['symbol'] ?? 'DEFAULT_SYMBOL',
          timeframe: json['timeframe'] ?? '1D',
          explanation: json['explanation'] ?? '',
          annotations: List<String>.from(json['annotations'] ?? []),
          chartConfig: Map<String, dynamic>.from(json['chart_config'] ?? {}),
          indicators: (json['indicators'] as List<dynamic>? ?? [])
              .map((indicatorJson) => TechnicalIndicatorConfig(
                    type: indicatorJson['type'] ?? 'SMA',
                    parameters: Map<String, dynamic>.from(
                        indicatorJson['parameters'] ?? {}),
                    description: indicatorJson['description'] ?? '',
                    isVisible: indicatorJson['is_visible'] ?? true,
                  ))
              .toList(),
        );
      case 'video':
        return VideoContent(
          id: id,
          title: title,
          order: order,
          videoUrl: json['video_url'] ?? '',
          thumbnail: json['thumbnail'],
          duration: json['duration'] ?? 0,
          transcript: json['transcript'] ?? '',
        );
      case 'code_example':
        return CodeExampleContent(
          id: id,
          title: title,
          order: order,
          code: json['code'] ?? '',
          language: json['language'] ?? 'plaintext',
          explanation: json['explanation'] ?? '',
          isExecutable: json['is_executable'] ?? false,
        );
      default:
        debugPrint(
            'Unknown content type: ${json['type']}, defaulting to TextContent.');
        return TextContent(
          // Default to a generic TextContent if type is unknown
          id: id,
          title: title,
          order: order,
          content:
              'Unsupported content type: ${json['type']}. Data: ${json.toString()}',
        );
    }
  }

  static Quiz _parseQuiz(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] ?? 'unknown_quiz_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] ?? 'Quiz',
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((questionJson) => _parseQuestion(questionJson))
          .toList(),
      passingScore: json['passing_score'] ?? 70,
      timeLimit: json['time_limit'] ?? 0, // 0 means no time limit
    );
  }

  static Question _parseQuestion(Map<String, dynamic> json) {
    final String id = json['id'] ??
        'unknown_question_${DateTime.now().millisecondsSinceEpoch}';
    final String questionText =
        json['question'] ?? 'No question text provided.';
    final String explanationText =
        json['explanation'] ?? 'No explanation provided.';
    final int pointsValue = json['points'] ?? 1;

    switch (json['type']) {
      case 'multiple_choice':
        return MultipleChoiceQuestion(
          id: id,
          question: questionText,
          explanation: explanationText,
          points: pointsValue,
          options: List<String>.from(json['options'] ?? []),
          correctAnswerIndex: json['correct_answer_index'] ?? 0,
        );
      case 'true_false':
        return TrueFalseQuestion(
          id: id,
          question: questionText,
          explanation: explanationText,
          points: pointsValue,
          correctAnswer: json['correct_answer'] ?? false,
        );
      case 'drag_drop':
        return DragDropQuestion(
          id: id,
          question: questionText,
          explanation: explanationText,
          points: pointsValue,
          items: List<String>.from(json['items'] ?? []),
          targets: List<String>.from(json['targets'] ?? []),
          correctMatches:
              Map<String, String>.from(json['correct_matches'] ?? {}),
        );
      default:
        debugPrint(
            'Unknown question type: ${json['type']}, defaulting to MultipleChoiceQuestion.');
        return MultipleChoiceQuestion(
          // Default to a generic question
          id: id,
          question:
              'Unsupported question type: ${json['type']}. Data: ${json.toString()}',
          explanation: 'Please check the data source.',
          points: pointsValue,
          options: ['Option A', 'Option B'],
          correctAnswerIndex: 0,
        );
    }
  }

  static IconData _parseIconData(String? iconName) {
    switch (iconName?.toLowerCase()) {
      // Added null check and toLowerCase for robustness
      case 'school':
        return Icons.school;
      case 'analytics':
        return Icons.analytics;
      case 'trending_up':
        return Icons.trending_up;
      case 'show_chart':
        return Icons.show_chart;
      case 'pie_chart':
        return Icons.pie_chart;
      case 'psychology':
        return Icons.psychology;
      case 'play_arrow':
        return Icons.play_arrow;
      case 'flash_on':
        return Icons.flash_on;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.book; // Default icon
    }
  }

  static Difficulty _parseDifficulty(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      // Added null check and toLowerCase
      case 'beginner':
        return Difficulty.beginner;
      case 'intermediate':
        return Difficulty.intermediate;
      case 'advanced':
        return Difficulty.advanced;
      case 'expert':
        return Difficulty.expert;
      default:
        return Difficulty.beginner; // Default difficulty
    }
  }

  static LessonType _parseLessonType(String? type) {
    switch (type?.toLowerCase()) {
      // Added null check and toLowerCase
      case 'theory':
        return LessonType.theory;
      case 'interactive':
        return LessonType.interactive;
      case 'practice':
        return LessonType.practice;
      case 'quiz':
        return LessonType.quiz;
      default:
        return LessonType.theory; // Default lesson type
    }
  }

  static ChartType _parseChartType(String? type) {
    switch (type?.toLowerCase()) {
      // Added null check and toLowerCase
      case 'candlestick':
        return ChartType.candlestick;
      case 'line':
        return ChartType.line;
      case 'area':
        return ChartType.area;
      case 'bar':
        return ChartType.bar;
      case 'indicator':
        return ChartType.indicator;
      default:
        return ChartType.candlestick; // Default chart type
    }
  }

  // Local storage methods
  static Future<void> _saveLocalProgress(
    String categoryId,
    String lessonId,
    bool isCompleted,
    int timeSpent,
    double? score,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = await _getLocalProgress();

    // Remove existing progress for this lesson if any
    progressData.removeWhere(
        (p) => p.categoryId == categoryId && p.lessonId == lessonId);

    // Add new/updated progress
    progressData.add(UserProgress(
      userId:
          'local_user', // Consider making this dynamic if you have multiple local users
      categoryId: categoryId,
      lessonId: lessonId,
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
      score: score ?? 0.0,
      timeSpent: timeSpent,
    ));

    // Save to preferences
    final progressJsonList = progressData
        .map((p) => {
              'user_id': p.userId,
              'category_id': p.categoryId,
              'lesson_id': p.lessonId,
              'is_completed': p.isCompleted,
              'completed_at': p.completedAt?.toIso8601String(),
              'score': p.score,
              'time_spent': p.timeSpent,
            })
        .toList();

    await prefs.setString(_progressKey, json.encode(progressJsonList));
  }

  static Future<List<UserProgress>> _getLocalProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressString = prefs.getString(_progressKey);

    if (progressString == null || progressString.isEmpty) return [];

    try {
      final List<dynamic> progressJsonList = json.decode(progressString);
      return progressJsonList
          .map((jsonItem) => UserProgress(
                userId: jsonItem['user_id'],
                categoryId: jsonItem['category_id'],
                lessonId: jsonItem['lesson_id'],
                isCompleted: jsonItem['is_completed'],
                completedAt: jsonItem['completed_at'] != null
                    ? DateTime.parse(jsonItem['completed_at'])
                    : null,
                score: jsonItem['score']?.toDouble() ?? 0.0,
                timeSpent: jsonItem['time_spent'] ?? 0,
              ))
          .toList();
    } catch (e) {
      debugPrint(
          "Error decoding local progress: $e. Progress string: $progressString");
      // Optionally, clear corrupted data
      // await prefs.remove(_progressKey);
      return [];
    }
  }

  // --- Default Data Methods ---
  // (Assuming LessonData is a class you've defined elsewhere with static methods)
  // If LessonData is not defined, you'll need to provide these implementations.
  // For now, I'll keep them as placeholders.

  static List<EducationCategory> _getDefaultCategories() {
    // This data was originally in EducationHomeScreen, moved here for fallback.
    // Ensure your EducationCategory model matches these fields.
    return [
      EducationCategory(
        id: 'basics',
        title: 'Yatırım Temelleri',
        description: 'Hisse senedi yatırımının temel kavramları',
        icon: Icons.school,
        color: const Color(0xFF4CAF50),
        difficulty: Difficulty.beginner,
        estimatedTime: '45 dk',
        lessons:
            8, // This would ideally come from the sum of lessons in this category
        completedLessons: 0, // This should be calculated based on UserProgress
        topics: [
          'Hisse Senedi Nedir?',
          'Borsa Nasıl Çalışır?',
          'Temel Kavramlar',
          'Risk ve Getiri',
        ],
      ),
      EducationCategory(
        id: 'fundamental',
        title: 'Temel Analiz',
        description: 'Şirketlerin finansal durumunu analiz etme',
        icon: Icons.analytics,
        color: const Color(0xFF2196F3),
        difficulty: Difficulty.intermediate,
        estimatedTime: '1.5 saat',
        lessons: 12,
        completedLessons: 0,
        topics: [
          'Mali Tablolar',
          'Finansal Oranlar',
          'Değerleme Yöntemleri',
          'Sektör Analizi',
        ],
      ),
      // Add other default categories as needed from your original list
      EducationCategory(
        id: 'technical',
        title: 'Teknik Analiz',
        description: 'Grafik okuma ve teknik göstergeler',
        icon: Icons.trending_up,
        color: const Color(0xFFFF9800),
        difficulty: Difficulty.intermediate,
        estimatedTime: '2 saat',
        lessons: 15,
        completedLessons: 0,
        topics: [
          'Grafik Türleri',
          'Hareketli Ortalamalar',
          'Momentum Göstergeleri',
          'Destek ve Direnç',
        ],
      ),
    ];
  }

  static List<Lesson> _getDefaultLessonsForCategory(String categoryId) {
    // You'll need to provide actual default lesson data here
    // or use the LessonData class if it's defined.
    // Example:
    if (categoryId == 'basics') {
      // return LessonData.getBasicsLessons(); // If LessonData exists
      return [
        // Placeholder default lessons
        Lesson(
            id: 'b1',
            title: 'Basics Lesson 1',
            description: 'Intro to basics',
            type: LessonType.theory,
            estimatedTime: '10 dk',
            order: 1,
            content: [
              TextContent(
                  id: 'b1c1',
                  title: 'Intro Text',
                  order: 1,
                  content: 'Welcome!')
            ]),
        Lesson(
            id: 'b2',
            title: 'Basics Lesson 2',
            description: 'More basics',
            type: LessonType.theory,
            estimatedTime: '15 dk',
            order: 2,
            content: [
              TextContent(
                  id: 'b2c1',
                  title: 'Details',
                  order: 1,
                  content: 'Some details here.')
            ]),
      ];
    } else if (categoryId == 'technical') {
      // return LessonData.getTechnicalAnalysisLessons();
      return [
        Lesson(
            id: 't1',
            title: 'Technical Lesson 1',
            description: 'Intro to TA',
            type: LessonType.theory,
            estimatedTime: '20 dk',
            order: 1,
            content: [
              TextContent(
                  id: 't1c1',
                  title: 'TA Intro',
                  order: 1,
                  content: 'Welcome to TA!')
            ]),
      ];
    }
    // Add more cases for other categories like 'indicators'
    return [];
  }

  static List<Achievement> _getDefaultAchievements() {
    // This data was originally in EducationHomeScreen (AchievementsSheet)
    return [
      Achievement(
        id: 'first_lesson',
        title: 'İlk Adım',
        description: 'İlk dersi tamamladın!',
        icon: Icons.play_arrow,
        isUnlocked: false, // Default is not unlocked
        progress: 0.0,
      ),
      Achievement(
        id: 'technical_master',
        title: 'Teknik Analiz Ustası',
        description: 'Tüm teknik analiz derslerini bitir',
        icon: Icons.trending_up,
        isUnlocked: false,
        progress: 0.0,
      ),
      Achievement(
        id: 'speed_learner',
        title: 'Hızlı Öğrenci',
        description: 'Bir günde 5 ders tamamla',
        icon: Icons.flash_on,
        isUnlocked: false,
        progress: 0.0,
      ),
    ];
  }

  static List<CandleData> _generateSampleChartData(
      String symbol, String timeframe) {
    final List<CandleData> data = [];
    final now = DateTime.now();
    double basePrice = 100.0;
    final random = math.Random(); // <-- Use math.Random()

    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: 30 - i));
      // Make open and close fluctuate around basePrice
      final openOffset =
          random.nextDouble() * 10 - 5; // Fluctuation between -5 and +5
      final open = basePrice + openOffset;

      final closeOffset =
          random.nextDouble() * 10 - 5; // Fluctuation between -5 and +5
      final close = open +
          closeOffset; // Close fluctuates relative to open for more dynamism

      // Ensure high is the highest and low is the lowest
      final high = math.max(open, close) +
          random.nextDouble() * 5; // Add a bit more for wick
      final low = math.min(open, close) -
          random.nextDouble() * 5; // Subtract a bit more for wick

      data.add(CandleData(
        date: date,
        open: open.clamp(0.01, double.infinity), // Ensure price is positive
        high: high.clamp(0.01, double.infinity),
        low: low.clamp(0.01, double.infinity),
        close: close.clamp(0.01, double.infinity),
        volume:
            (1000000 + random.nextInt(500000)), // volume is int then toDouble
      ));
      basePrice = close; // Next day's base price starts from previous close
    }
    return data;
  }

  static Map<String, dynamic> _getDefaultAnalytics() {
    return {
      'total_time_spent': 0,
      'lessons_completed': 0,
      'average_score': 0.0,
      'streak_days': 0,
      'favorite_category': 'N/A',
      'learning_pace': 'normal',
      'weekly_progress': [
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
      ], // Assuming double for progress
      'category_progress': {
        'basics': 0.0,
        'fundamental': 0.0,
        'technical': 0.0,
        'indicators': 0.0,
        'portfolio': 0.0,
        'strategies': 0.0,
      },
    };
  }
}

// Helper for _generateSampleChartData if not available from dart:math
// (dart:math is usually available, but just in case of minimal context)
T max<T extends Comparable<T>>(T a, T b) => a.compareTo(b) > 0 ? a : b;
T min<T extends Comparable<T>>(T a, T b) => a.compareTo(b) < 0 ? a : b;

class Random {
  // Simple Random if dart:math.Random is not implicitly available
  final _random = math.Random(); // Use dart:math.Random
  double nextDouble() => _random.nextDouble();
  int nextInt(int max) => _random.nextInt(max);
}
