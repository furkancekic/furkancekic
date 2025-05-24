// screens/education/lesson_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'models/education_models.dart';
import 'widgets/interactive_chart_widget.dart';
import 'widgets/quiz_widget.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  final EducationCategory category;

  const LessonDetailScreen({
    Key? key,
    required this.lesson,
    required this.category,
  }) : super(key: key);

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  int _currentContentIndex = 0;
  bool _isLessonCompleted = false;
  Map<String, bool> _contentCompletionStatus = {};
  Map<String, String> _expandedDefinitions = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    _isLessonCompleted = widget.lesson.isCompleted;
    _initializeContentStatus();
  }

  void _initializeContentStatus() {
    for (var content in widget.lesson.content) {
      _contentCompletionStatus[content.id] = false;
    }
    if (widget.lesson.quiz != null) {
      _contentCompletionStatus['quiz'] = false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  int get _totalContentCount {
    int count = widget.lesson.content.length;
    if (widget.lesson.quiz != null) count++;
    return count;
  }

  double get _lessonProgress {
    if (_totalContentCount == 0) return 0.0;
    return _currentContentIndex / _totalContentCount;
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: themeExtension?.gradientBackgroundColors ??
                [
                  AppTheme.backgroundColor,
                  const Color(0xFF192138),
                ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildContent(),
              ),
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Top bar
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.cardColor,
                child: IconButton(
                  icon:
                      const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category.title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      widget.lesson.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor: AppTheme.cardColor,
                child: IconButton(
                  icon: Icon(
                    _isLessonCompleted ? Icons.bookmark : Icons.bookmark_border,
                    color: AppTheme.accentColor,
                  ),
                  onPressed: _toggleBookmark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          AdaptiveCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'İlerleme',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${_currentContentIndex + 1} / $_totalContentCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _lessonProgress,
                      backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.lesson.typeColor,
                      ),
                      minHeight: 6,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final allContent = <Widget>[];

    // Add lesson content
    for (var content in widget.lesson.content) {
      allContent.add(_buildContentWidget(content));
    }

    // Add quiz if exists
    if (widget.lesson.quiz != null) {
      allContent.add(_buildQuizWidget(widget.lesson.quiz!));
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: allContent.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: allContent[index],
        );
      },
    );
  }

  Widget _buildContentWidget(LessonContent content) {
    switch (content.runtimeType) {
      case TextContent:
        return _buildTextContent(content as TextContent);
      case InteractiveChartContent:
        return _buildInteractiveChartContent(
            content as InteractiveChartContent);
      case VideoContent:
        return _buildVideoContent(content as VideoContent);
      case CodeExampleContent:
        return _buildCodeExampleContent(content as CodeExampleContent);
      default:
        return _buildPlaceholderContent(content);
    }
  }

  Widget _buildTextContent(TextContent content) {
    return SingleChildScrollView(
      child: AdaptiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Main content
            Text(
              content.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: AppTheme.textPrimary,
              ),
            ),

            // Bullet points
            if (content.bulletPoints.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Önemli Noktalar:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...content.bulletPoints.map((point) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 8, right: 12),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: widget.lesson.typeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            point,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            // Definitions
            if (content.definitions != null &&
                content.definitions!.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Temel Kavramlar:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...content.definitions!.entries
                  .map((entry) => _buildDefinitionCard(entry.key, entry.value)),
            ],

            const SizedBox(height: 20),
            _buildContentCompletionButton(content.id),
          ],
        ),
      ),
    );
  }

  Widget _buildDefinitionCard(String term, String definition) {
    final isExpanded = _expandedDefinitions.containsKey(term);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedDefinitions.remove(term);
            } else {
              _expandedDefinitions[term] = definition;
            }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColorLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        term,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppTheme.accentColor,
                      size: 20,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 8),
                  Text(
                    definition,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveChartContent(InteractiveChartContent content) {
    return SingleChildScrollView(
      child: Column(
        children: [
          AdaptiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content.explanation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Interactive Chart Widget
          InteractiveChartWidget(
            content: content,
            onInteraction: (interaction) {
              // Handle chart interactions
              _markContentAsCompleted(content.id);
            },
          ),

          const SizedBox(height: 12),

          // Annotations
          if (content.annotations.isNotEmpty)
            AdaptiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grafik Açıklamaları:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...content.annotations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final annotation = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: widget.lesson.typeColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              annotation,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

          const SizedBox(height: 20),
          _buildContentCompletionButton(content.id),
        ],
      ),
    );
  }

  Widget _buildVideoContent(VideoContent content) {
    return AdaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Video placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.cardColorLight,
              borderRadius: BorderRadius.circular(12),
              image: content.thumbnail.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(content.thumbnail),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.textSecondary, size: 16),
              const SizedBox(width: 4),
              Text(
                content.duration,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _buildContentCompletionButton(content.id),
        ],
      ),
    );
  }

  Widget _buildCodeExampleContent(CodeExampleContent content) {
    return SingleChildScrollView(
      child: AdaptiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              content.explanation,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            // Code block
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Code header
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          content.language.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        const Spacer(),
                        if (content.isExecutable)
                          GestureDetector(
                            onTap: () {
                              // TODO: Execute code
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.positiveColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Çalıştır',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.positiveColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Code content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      content.code,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _buildContentCompletionButton(content.id),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderContent(LessonContent content) {
    return AdaptiveCard(
      child: Column(
        children: [
          Text(
            content.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bu içerik henüz hazır değil. Yakında yayınlanacak.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _buildContentCompletionButton(content.id),
        ],
      ),
    );
  }

  Widget _buildQuizWidget(Quiz quiz) {
    return QuizWidget(
      quiz: quiz,
      onQuizCompleted: (score) {
        _markContentAsCompleted('quiz');
        _checkLessonCompletion();
      },
    );
  }

  Widget _buildContentCompletionButton(String contentId) {
    final isCompleted = _contentCompletionStatus[contentId] ?? false;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            isCompleted ? null : () => _markContentAsCompleted(contentId),
        icon: Icon(
          isCompleted ? Icons.check_circle : Icons.check,
          color: isCompleted ? AppTheme.positiveColor : Colors.white,
        ),
        label: Text(
          isCompleted ? 'Tamamlandı' : 'Tamamla',
          style: TextStyle(
            color: isCompleted ? AppTheme.positiveColor : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted
              ? AppTheme.positiveColor.withOpacity(0.1)
              : widget.lesson.typeColor,
          elevation: isCompleted ? 0 : 4,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _currentContentIndex > 0 ? _goToPrevious : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Önceki'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.textSecondary),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Next button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _currentContentIndex < _totalContentCount - 1
                  ? _goToNext
                  : _finishLesson,
              icon: Icon(
                _currentContentIndex < _totalContentCount - 1
                    ? Icons.arrow_forward
                    : Icons.check,
              ),
              label: Text(
                _currentContentIndex < _totalContentCount - 1
                    ? 'Sonraki'
                    : 'Bitir',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.lesson.typeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentContentIndex = index;
    });
    _progressAnimationController.forward();
  }

  void _goToPrevious() {
    if (_currentContentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_currentContentIndex < _totalContentCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishLesson() {
    _checkLessonCompletion();
    if (_isLessonCompleted) {
      _showLessonCompletionDialog();
    }
  }

  void _markContentAsCompleted(String contentId) {
    setState(() {
      _contentCompletionStatus[contentId] = true;
    });
    _checkLessonCompletion();
  }

  void _checkLessonCompletion() {
    final allCompleted =
        _contentCompletionStatus.values.every((completed) => completed);
    if (allCompleted && !_isLessonCompleted) {
      setState(() {
        _isLessonCompleted = true;
      });
    }
  }

  void _showLessonCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.positiveColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.positiveColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tebrikler!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.lesson.title} dersini başarıyla tamamladınız!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to category
            },
            child: const Text(
              'Kategoriye Dön',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // TODO: Navigate to next lesson
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('Sonraki Ders'),
          ),
        ],
      ),
    );
  }

  void _toggleBookmark() {
    setState(() {
      // TODO: Implement bookmark functionality
    });
  }
}
