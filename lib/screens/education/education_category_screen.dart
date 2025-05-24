// screens/education/education_category_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'models/education_models.dart';
import 'lesson_detail_screen.dart';

class EducationCategoryScreen extends StatefulWidget {
  final EducationCategory category;

  const EducationCategoryScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<EducationCategoryScreen> createState() => _EducationCategoryScreenState();
}

class _EducationCategoryScreenState extends State<EducationCategoryScreen> {
  late List<Lesson> _lessons;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  void _loadLessons() {
    setState(() {
      _isLoading = true;
    });

    // Simulated loading with predefined data
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _lessons = _getLessonsForCategory(widget.category.id);
          _isLoading = false;
        });
      }
    });
  }

  List<Lesson> _getLessonsForCategory(String categoryId) {
    // Assuming LessonData and its methods are defined elsewhere and return List<Lesson>
    // For example, in models/education_models.dart or a dedicated data file.
    // If they are not, you'll need to implement them or use placeholder data.
    switch (categoryId) {
      case 'basics':
        return LessonData.getBasicsLessons();
      case 'technical':
        return LessonData.getTechnicalAnalysisLessons();
      case 'indicators':
        return LessonData.getIndicatorLessons();
      // Add cases for 'fundamental', 'portfolio', 'strategies' if they have specific lesson data
      case 'fundamental':
         return _createPlaceholderLessons(categoryId); // Or LessonData.getFundamentalLessons();
      case 'portfolio':
         return _createPlaceholderLessons(categoryId); // Or LessonData.getPortfolioLessons();
      case 'strategies':
         return _createPlaceholderLessons(categoryId); // Or LessonData.getStrategiesLessons();
      default:
        return _createPlaceholderLessons(categoryId);
    }
  }

  List<Lesson> _createPlaceholderLessons(String categoryId) {
    // Create placeholder lessons for categories not yet implemented
    return List.generate(widget.category.lessons, (index) {
      return Lesson(
        id: '${categoryId}_${index + 1}',
        title: 'Ders ${index + 1}: ${widget.category.topics.isNotEmpty ? widget.category.topics[index % widget.category.topics.length] : "Genel Konu"}',
        description: 'Bu ders ${widget.category.title} kategorisinin ${index + 1}. dersidir.',
        type: index % 4 == 0 ? LessonType.quiz :
              index % 3 == 0 ? LessonType.interactive :
              index % 2 == 0 ? LessonType.practice : LessonType.theory,
        estimatedTime: '${5 + (index * 2)} dk',
        order: index + 1,
        isCompleted: index < widget.category.completedLessons,
        isLocked: index > 0 && index > widget.category.completedLessons, // Corrected: lock if previous not completed
        content: [], // Assuming content is List<LessonContent> or similar
        prerequisites: [], // Added to match usage in _buildLessonItem
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();

    return Scaffold(
      backgroundColor: Colors.transparent, // Ensure parent provides background or this is intended
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: themeExtension?.gradientBackgroundColors ?? [
              AppTheme.backgroundColor,
              const Color(0xFF192138),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _buildLessonsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Assuming progressPercentage is a getter in EducationCategory model
    final progress = widget.category.lessons > 0 
        ? widget.category.completedLessons / widget.category.lessons 
        : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Top bar with back button and menu
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.cardColor,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Spacer(),
              CircleAvatar(
                backgroundColor: AppTheme.cardColor,
                child: IconButton(
                  icon: const Icon(Icons.bookmark_border, color: AppTheme.accentColor),
                  onPressed: () => _toggleBookmark(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppTheme.cardColor,
                child: IconButton(
                  icon: const Icon(Icons.share, color: AppTheme.accentColor),
                  onPressed: () => _shareCategory(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category header
          AdaptiveCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.category.color,
                            widget.category.color.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.category.icon,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.category.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress section
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'İlerleme',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: widget.category.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(widget.category.color),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4), // Optional: for rounded corners
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // To space out items
                  children: [
                    _buildStatItem(
                      Icons.schedule,
                      widget.category.estimatedTime,
                      'Süre',
                    ),
                    _buildStatItem(
                      Icons.menu_book,
                      '${widget.category.lessons}',
                      'Ders',
                    ),
                    _buildStatItem(
                      Icons.star,
                      _getDifficultyText(widget.category.difficulty),
                      'Seviye',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentColor, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getDifficultyText(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.beginner:
        return 'Başlangıç';
      case Difficulty.intermediate:
        return 'Orta';
      case Difficulty.advanced:
        return 'İleri';
      case Difficulty.expert:
        return 'Uzman';
      // No default needed as Difficulty is an enum and all cases are covered.
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildLessonsList() {
    if (_lessons.isEmpty) {
      return const Center(
        child: Text(
          'Bu kategori için henüz ders bulunmuyor.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 12.0), // Added top padding
            child: Text(
              'Dersler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero, // Remove default ListView padding
              itemCount: _lessons.length,
              itemBuilder: (context, index) {
                final lesson = _lessons[index];
                final isLast = index == _lessons.length - 1;
                return _buildLessonItem(lesson, isLast);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonItem(Lesson lesson, bool isLast) {
    final canAccess = !lesson.isLocked;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 16 : 12),
      child: AdaptiveCard(
        onTap: canAccess ? () => _navigateToLesson(lesson) : null,
        color: lesson.isLocked
            ? AppTheme.cardColor.withOpacity(0.5)
            : AppTheme.cardColor, // Use default card color if not locked
        child: Row(
          children: [
            // Lesson number and type icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: lesson.isCompleted
                    ? AppTheme.positiveColor.withOpacity(0.2)
                    : lesson.isLocked
                        ? AppTheme.textSecondary.withOpacity(0.1)
                        // Use typeColor from Lesson model if available, otherwise default
                        : (lesson.typeColor ?? AppTheme.accentColor).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: lesson.isCompleted
                  ? const Icon(
                      Icons.check_circle,
                      color: AppTheme.positiveColor,
                      size: 24,
                    )
                  : lesson.isLocked
                      ? const Icon(
                          Icons.lock,
                          color: AppTheme.textSecondary,
                          size: 20,
                        )
                      : Icon(
                          lesson.typeIcon, // Use typeIcon from Lesson model
                          color: lesson.typeColor ?? AppTheme.accentColor,
                          size: 20,
                        ),
            ),
            const SizedBox(width: 16),

            // Lesson content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: lesson.isLocked
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!lesson.isLocked) // Show badge only if not locked
                         _buildLessonTypeBadge(lesson.type),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: lesson.isLocked
                          ? AppTheme.textSecondary.withOpacity(0.7)
                          : AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lesson.estimatedTime,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (lesson.prerequisites.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.link,
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${lesson.prerequisites.length} ön koşul',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow or status
            if (canAccess && !lesson.isCompleted) // Show arrow if accessible and not completed
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.accentColor,
                size: 16,
              )
            else if (lesson.isCompleted) // Show check if completed
              const Icon(
                Icons.check,
                color: AppTheme.positiveColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonTypeBadge(LessonType type) {
    // MODIFICATION START: Replaced Dart 3 pattern destructuring from switch expression
    // with a traditional switch statement for broader compatibility.
    String text;
    Color color;

    switch (type) {
      case LessonType.theory:
        text = 'Teori';
        color = Colors.blue.shade600; // Using a slightly darker shade
        break;
      case LessonType.interactive:
        text = 'İnteraktif';
        color = Colors.purple.shade600;
        break;
      case LessonType.practice:
        text = 'Pratik';
        color = Colors.orange.shade700;
        break;
      case LessonType.quiz:
        text = 'Test';
        color = Colors.green.shade600;
        break;
      // No default case is needed if LessonType is an enum and all cases are covered.
    }
    // MODIFICATION END

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  void _navigateToLesson(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(
          lesson: lesson,
          category: widget.category,
        ),
      ),
    ).then((_) {
      // Potentially refresh lesson list or progress if a lesson was completed
      // For now, we'll just reload to reflect potential changes.
      // This could be optimized to only update if necessary.
      _loadLessons();
    });
  }

  void _toggleBookmark() {
    // TODO: Implement bookmark functionality (e.g., save to local storage or backend)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kategori yer imlerine eklendi/kaldırıldı.'), // Placeholder message
        backgroundColor: AppTheme.accentColor, // Use accent or positive color based on action
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareCategory() {
    // TODO: Implement share functionality (e.g., using share_plus package)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paylaşım özelliği yakında eklenecektir.'),
        backgroundColor: AppTheme.accentColor,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Dummy LessonData for compilation. Replace with your actual data source.
class LessonData {
  static List<Lesson> getBasicsLessons() {
    return List.generate(8, (index) => Lesson(
      id: 'basics_${index+1}',
      title: 'Temel Ders ${index+1}',
      description: 'Temel yatırım kavramları hakkında ${index+1}. ders.',
      type: LessonType.values[index % LessonType.values.length],
      estimatedTime: '${10 + index * 2} dk',
      order: index + 1,
      isCompleted: index < 2, // Example: first 2 completed
      isLocked: index > 2,    // Example: lessons after 2nd are locked initially
      content: [],
      prerequisites: []
    ));
  }
  static List<Lesson> getTechnicalAnalysisLessons() {
     return List.generate(12, (index) => Lesson(
      id: 'tech_${index+1}',
      title: 'Teknik Analiz Dersi ${index+1}',
      description: 'Teknik analiz üzerine ${index+1}. ders.',
      type: LessonType.values[index % LessonType.values.length],
      estimatedTime: '${12 + index * 2} dk',
      order: index + 1,
      isCompleted: index < 1,
      isLocked: index > 1,
      content: [],
      prerequisites: []
    ));
  }
  static List<Lesson> getIndicatorLessons() {
    return List.generate(10, (index) => Lesson(
      id: 'indicator_${index+1}',
      title: 'Gösterge Dersi ${index+1}',
      description: 'Teknik göstergeler hakkında ${index+1}. ders.',
      type: LessonType.values[index % LessonType.values.length],
      estimatedTime: '${15 + index * 2} dk',
      order: index + 1,
      isCompleted: false,
      isLocked: index > 0,
      content: [],
      prerequisites: []
    ));
  }
}