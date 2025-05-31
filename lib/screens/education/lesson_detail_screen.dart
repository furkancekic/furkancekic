// screens/education/lesson_detail_screen.dart
import 'dart:convert'; // Added for jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for rootBundle
import 'package:shared_preferences/shared_preferences.dart'; // Added for SharedPreferences
// import 'package:syncfusion_flutter_charts/charts.dart'; // Bu dosyada doğrudan artık gerek yok
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'models/education_models.dart';
import 'widgets/interactive_chart_widget.dart';
import 'widgets/interactive_education_chart_widget.dart';
import 'widgets/quiz_widget.dart';
import 'widgets/portfolio_comparison_chart_widget.dart'; // YENİ IMPORT
import 'widgets/fundamental_ratio_chart_widget.dart'; // YENİ IMPORT
import '../../models/portfolio.dart'; // Added for BalanceSheetPieChart
import '../../models/position.dart'; // Added for BalanceSheetPieChart
import '../../widgets/interactive_pie_chart.dart'; // Added for BalanceSheetPieChart

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
  static const String _completionStatusKeyPrefix =
      'lesson_completion_status_'; // Added constant
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
    // İlk içerik için ilerlemeyi ayarla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateProgressAnimation();
    });
  }

  void _initializeContentStatus() {
    for (var content in widget.lesson.content) {
      _contentCompletionStatus[content.id] = false;
    }
    if (widget.lesson.quiz != null) {
      _contentCompletionStatus['quiz_${widget.lesson.quiz!.id}'] = false;
    }
  }

  void _updateProgressAnimation() {
    if (!mounted) return;
    final targetProgress = (_totalContentCount > 0)
        ? ((_currentContentIndex + 1) / _totalContentCount)
        : 0.0;
    if (_progressAnimationController.value != targetProgress) {
      _progressAnimationController.animateTo(targetProgress);
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
    return count > 0 ? count : 1;
  }

  double get _lessonProgress {
    if (_totalContentCount == 0 ||
        (_totalContentCount == 1 &&
            widget.lesson.content.isEmpty &&
            widget.lesson.quiz == null)) {
      return 0.0;
    }
    // Sadece quiz varsa ve indeks 0 ise %100
    if (widget.lesson.content.isEmpty &&
        widget.lesson.quiz != null &&
        _currentContentIndex == 0) {
      return 1.0;
    }
    return (_currentContentIndex + 1) / _totalContentCount;
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: themeExtension.gradientBackgroundColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(themeExtension),
              Expanded(
                child: _buildContent(themeExtension),
              ),
              _buildBottomNavigation(themeExtension),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeExtension themeExtension) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: themeExtension.cardColor,
                child: IconButton(
                  icon:
                      Icon(Icons.arrow_back, color: themeExtension.textPrimary),
                  onPressed: () => Navigator.pop(context, _isLessonCompleted),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: themeExtension.textSecondary,
                      ),
                    ),
                    Text(
                      widget.lesson.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeExtension.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor: themeExtension.cardColor,
                child: IconButton(
                  icon: Icon(
                    widget.lesson.isBookmarked ? Icons.bookmark : Icons.bookmark_border, // Use widget.lesson.isBookmarked
                    color: themeExtension.accentColor,
                  ),
                  onPressed: _toggleBookmark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdaptiveCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'İlerleme',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeExtension.textSecondary,
                      ),
                    ),
                    Text(
                      '${_currentContentIndex + (widget.lesson.content.isEmpty && widget.lesson.quiz == null ? 0 : 1)} / $_totalContentCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: themeExtension.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _progressAnimationController,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _progressAnimationController.value,
                      backgroundColor:
                          themeExtension.textSecondary.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.lesson.typeColor,
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
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

  Widget _buildContent(AppThemeExtension themeExtension) {
    final allContentWidgets = <Widget>[];

    for (var content in widget.lesson.content) {
      allContentWidgets.add(
        _buildContentWidget(content, themeExtension),
      );
    }

    if (widget.lesson.quiz != null) {
      allContentWidgets.add(_buildQuizWidget(widget.lesson.quiz!));
    }
    if (allContentWidgets.isEmpty) {
      return Center(
        child: Text(
          "Bu ders için içerik bulunmuyor.",
          style: TextStyle(color: themeExtension.textSecondary),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: allContentWidgets.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(child: allContentWidgets[index]),
        );
      },
    );
  }

  Widget _buildContentWidget(
      LessonContent content, AppThemeExtension themeExtension) {
    // Ortak başlık/explanation kısmı:
    Widget headerSection = Padding(
      padding: const EdgeInsets.only(bottom: 12), // margin yerine Padding
      child: AdaptiveCard(
        color: themeExtension.cardColor.withOpacity(0.8),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeExtension.textPrimary,
              ),
            ),
            if (content.explanation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                content.explanation,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: themeExtension.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    Widget specificContent;
    switch (content.runtimeType) {
      case TextContent:
        specificContent =
            _buildTextContentWidget(content as TextContent, themeExtension);
        break;
      case InteractiveChartContent:
        specificContent = _buildInteractiveChartContentWidget(
          content as InteractiveChartContent,
          themeExtension,
        );
        break;
      case InteractiveEducationChartContent:
        specificContent = _buildInteractiveEducationChartContentWidget(
          content as InteractiveEducationChartContent,
          themeExtension,
        );
        break;
      case VideoContent:
        specificContent = _buildVideoContentWidget(
          content as VideoContent,
          themeExtension,
        );
        break;
      case CodeExampleContent:
        specificContent = _buildCodeExampleContentWidget(
          content as CodeExampleContent,
          themeExtension,
        );
        break;
      case PortfolioComparisonChartContent:
        specificContent = _buildPortfolioComparisonChartWidget(
          content as PortfolioComparisonChartContent,
          themeExtension,
        );
        break;
      case FundamentalRatioComparisonChartContent:
        specificContent = _buildFundamentalRatioComparisonChartWidget(
          content as FundamentalRatioComparisonChartContent,
          themeExtension,
        );
        break;
      case BalanceSheetPieChartContent: // New case
        specificContent = _buildBalanceSheetPieChartWidget(
          content as BalanceSheetPieChartContent,
          themeExtension,
        );
        break;
      // FUTURE_GRAPHICS_PLACEHOLDER:
      // To add a new interactive graphic/content widget:
      // 1. Ensure you've defined a new content type and model in education_models.dart.
      // 2. Create your new widget (e.g., MyNewGraphicWidget).
      // 3. Add a case for your new content model type here:
      //    case MyNewGraphicContent:
      //      specificContent = _buildMyNewGraphicWidget(content as MyNewGraphicContent, themeExtension);
      //      break;
      // 4. Implement the _buildMyNewGraphicWidget method in this class.
      default:
        specificContent =
            _buildPlaceholderContentWidget(content, themeExtension);
    }

    bool showCompletionButton = content.type != 'quiz';

    return Column(
      children: [
        headerSection,
        specificContent,
        if (showCompletionButton) ...[
          const SizedBox(height: 20),
          _buildContentCompletionButton(content.id, themeExtension),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // --- Specific Content Widget Builders ---

  Portfolio _createPortfolioFromData(
      Map<String, double> data, String portfolioId) {
    final positions = data.entries.map((entry) {
      return Position(
        ticker: entry.key,
        companyName: entry.key, // Using ticker as companyName for simplicity
        quantity: 1, // Dummy value
        averagePrice: entry.value, // Using value as averagePrice for simplicity
        currentValue: entry.value,
        purchaseDate: DateTime.now(), // Dummy value
      );
    }).toList();

    return Portfolio(
      id: portfolioId,
      name: portfolioId,
      positions: positions,
      createdAt: DateTime.now(), // Added missing required argument
      updatedAt: DateTime.now(), // Added missing required argument
      // totalValue, lastUpdated, etc., will be calculated by Portfolio model if needed
    );
  }

  Widget _buildBalanceSheetPieChartWidget(
      BalanceSheetPieChartContent content, AppThemeExtension themeExtension) {
    final assetsPortfolio =
        _createPortfolioFromData(content.assetData, 'Assets');
    final liabilitiesEquityPortfolio = _createPortfolioFromData(
        content.liabilityEquityData, 'Liabilities & Equity');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Explanation are handled by the common headerSection in _buildContentWidget
        // So, no need to add them here again unless a different styling is required.

        if (content.assetData.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InteractivePieChart(
              portfolio: assetsPortfolio,
              chartTitle: 'Varlık Dağılımı', // Asset Distribution
              size: 250, // Adjust size as needed
            ),
          ),
        if (content.liabilityEquityData.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InteractivePieChart(
              portfolio: liabilitiesEquityPortfolio,
              chartTitle:
                  'Kaynak Dağılımı', // Liability & Equity Distribution
              size: 250, // Adjust size as needed
            ),
          ),
        if (content.annotations.isNotEmpty) ...[
          const SizedBox(height: 12),
          AdaptiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notlar:', // Annotations Title
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeExtension.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...content.annotations.map(
                  (annotation) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6, right: 8),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: widget.lesson.typeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            annotation,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: themeExtension.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextContentWidget(
      TextContent content, AppThemeExtension themeExtension) {
    return AdaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.content,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: themeExtension.textPrimary,
            ),
          ),
          if (content.bulletPoints.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Önemli Noktalar:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeExtension.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...content.bulletPoints.map(
              (point) => Padding(
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
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: themeExtension.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (content.definitions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Temel Kavramlar:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeExtension.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...content.definitions.entries.map(
              (entry) =>
                  _buildDefinitionCard(entry.key, entry.value, themeExtension),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefinitionCard(
      String term, String definition, AppThemeExtension themeExtension) {
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
            color: themeExtension.cardColorLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: themeExtension.accentColor.withOpacity(0.3),
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: themeExtension.accentColor,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: themeExtension.accentColor,
                      size: 20,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 8),
                  Text(
                    definition,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: themeExtension.textPrimary,
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

  Widget _buildInteractiveChartContentWidget(
    InteractiveChartContent content,
    AppThemeExtension themeExtension,
  ) {
    return Column(
      children: [
        InteractiveChartWidget(
          content: content,
          onInteraction: (interaction) {
            _markContentAsCompleted(content.id);
            widget.lesson.isCompleted = _isLessonCompleted;
          },
        ),
        if (content.annotations.isNotEmpty) ...[
          const SizedBox(height: 12),
          AdaptiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grafik Açıklamaları:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeExtension.textPrimary,
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
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: themeExtension.textPrimary,
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
        ],
      ],
    );
  }

  Widget _buildInteractiveEducationChartContentWidget(
    InteractiveEducationChartContent content,
    AppThemeExtension themeExtension,
  ) {
    return InteractiveEducationChartWidget(
      indicatorType: content.indicatorType,
      title: content.title,
      description: content.explanation,
      learningPoints: content.learningPoints,
      onLearningProgress: (progress) {
        _handleLearningProgress(content.id, progress);
        widget.lesson.isCompleted = _isLessonCompleted;
      },
    );
  }

  Widget _buildVideoContentWidget(
      VideoContent content, AppThemeExtension themeExtension) {
    return AdaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: themeExtension.cardColorLight,
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
              Icon(Icons.schedule,
                  color: themeExtension.textSecondary, size: 16),
              const SizedBox(width: 4),
              Text(
                content.duration,
                style: TextStyle(
                  fontSize: 12,
                  color: themeExtension.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodeExampleContentWidget(
    CodeExampleContent content,
    AppThemeExtension themeExtension,
  ) {
    return AdaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: themeExtension.accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: themeExtension.accentColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        content.language.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: themeExtension.accentColor,
                        ),
                      ),
                      const Spacer(),
                      if (content.isExecutable)
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${content.language} kodu çalıştırma özelliği henüz eklenmedi.'),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  themeExtension.positiveColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Çalıştır',
                              style: TextStyle(
                                fontSize: 10,
                                color: themeExtension.positiveColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
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
        ],
      ),
    );
  }

  Widget _buildPortfolioComparisonChartWidget(
    PortfolioComparisonChartContent content,
    AppThemeExtension themeExtension,
  ) {
    return PortfolioComparisonChartWidget(
      content: content,
      onInteraction: (interactionDetails) {
        _markContentAsCompleted(content.id);
        widget.lesson.isCompleted = _isLessonCompleted;
      },
    );
  }

  Widget _buildFundamentalRatioComparisonChartWidget(
    FundamentalRatioComparisonChartContent content,
    AppThemeExtension themeExtension,
  ) {
    return FundamentalRatioChartWidget(
      content: content,
      onInteraction: (interactionDetails) {
        _markContentAsCompleted(content.id);
        widget.lesson.isCompleted = _isLessonCompleted;
      },
    );
  }

  Widget _buildPlaceholderContentWidget(
      LessonContent content, AppThemeExtension themeExtension) {
    return AdaptiveCard(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Bu içerik henüz hazır değil. Yakında yayınlanacak.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizWidget(Quiz quiz) {
    return QuizWidget(
      quiz: quiz,
      onQuizCompleted: (score) {
        _markContentAsCompleted('quiz_${quiz.id}');
        _checkLessonCompletion();
        widget.lesson.isCompleted = _isLessonCompleted;

        if (_currentContentIndex < _totalContentCount - 1) {
          _goToNext();
        } else {
          _finishLesson();
        }
      },
    );
  }

  Widget _buildContentCompletionButton(
      String contentId, AppThemeExtension themeExtension) {
    final isCompleted = _contentCompletionStatus[contentId] ?? false;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isCompleted
            ? null
            : () {
                _markContentAsCompleted(contentId);
                widget.lesson.isCompleted = _isLessonCompleted;
              },
        icon: Icon(
          isCompleted ? Icons.check_circle : Icons.check,
          color: isCompleted
              ? themeExtension.positiveColor
              : (themeExtension.isDark ? Colors.black : Colors.white),
        ),
        label: Text(
          isCompleted ? 'Tamamlandı' : 'Okundu Olarak İşaretle',
          style: TextStyle(
            color: isCompleted
                ? themeExtension.positiveColor
                : (themeExtension.isDark ? Colors.black : Colors.white),
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted
              ? themeExtension.positiveColor.withOpacity(0.1)
              : widget.lesson.typeColor,
          elevation: isCompleted ? 0 : 2,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(AppThemeExtension themeExtension) {
    bool isLastContent = _currentContentIndex >= _totalContentCount - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeExtension.cardColor,
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
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _currentContentIndex > 0 ? _goToPrevious : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Önceki'),
              style: OutlinedButton.styleFrom(
                foregroundColor: themeExtension.textPrimary,
                side: BorderSide(
                  color: themeExtension.textSecondary.withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isLastContent ? _finishLesson : _goToNext,
              icon: Icon(isLastContent
                  ? Icons.check_circle_outline
                  : Icons.arrow_forward),
              label: Text(isLastContent ? 'Dersi Bitir' : 'Sonraki'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.lesson.typeColor,
                foregroundColor: themeExtension.isDark ||
                        widget.lesson.typeColor == themeExtension.warningColor
                    ? Colors.black
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
    _updateProgressAnimation();
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
    final currentContentObject =
        widget.lesson.content.length > _currentContentIndex
            ? widget.lesson.content[_currentContentIndex]
            : null;

    if (currentContentObject != null &&
        _contentCompletionStatus[currentContentObject.id] == false) {
      _markContentAsCompleted(currentContentObject.id);
    }

    if (_currentContentIndex < _totalContentCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishLesson() {
    _checkLessonCompletion();
    widget.lesson.isCompleted = _isLessonCompleted;

    if (_isLessonCompleted) {
      _showLessonCompletionDialog(
        Theme.of(context).extension<AppThemeExtension>()!,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Dersi bitirmek için tüm içerikleri tamamlamalısınız.'),
          backgroundColor:
              Theme.of(context).extension<AppThemeExtension>()!.warningColor,
        ),
      );
    }
  }

  void _markContentAsCompleted(String contentId) {
    if (!mounted) return;
    setState(() {
      _contentCompletionStatus[contentId] = true;
    });
    _checkLessonCompletion();
  }

  void _checkLessonCompletion() {
    if (_contentCompletionStatus.isEmpty && _totalContentCount == 0) {
      if (!_isLessonCompleted) {
        if (mounted) {
          setState(() {
            _isLessonCompleted = true;
          });
        }
      }
      return;
    }
    final allCompleted =
        _contentCompletionStatus.values.every((completed) => completed);
    if (allCompleted && !_isLessonCompleted) {
      if (mounted) {
        setState(() {
          _isLessonCompleted = true;
        });
      }
    }
  }

  void _handleLearningProgress(
      String contentId, Map<String, dynamic> progress) {
    final action = progress['action'] as String?;
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;

    switch (action) {
      case 'data_loaded':
        break;
      case 'learning_point_completed':
        final totalCompleted = progress['total_completed'] as int? ?? 0;
        final totalPoints = progress['total_points'] as int? ?? 0;
        if (totalCompleted == totalPoints && totalPoints > 0) {
          _markContentAsCompleted(contentId);
        }
        break;
      case 'all_learning_points_completed':
        _markContentAsCompleted(contentId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                '🎉 Tebrikler! Tüm öğrenme hedeflerini tamamladınız!'),
            backgroundColor: themeExtension.positiveColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 3),
          ),
        );
        break;
    }
  }

  void _showLessonCompletionDialog(AppThemeExtension themeExtension) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: themeExtension.cardColor,
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
                color: themeExtension.positiveColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: themeExtension.positiveColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tebrikler!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeExtension.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.lesson.title} dersini başarıyla tamamladınız!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: themeExtension.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(_isLessonCompleted);
            },
            child: Text(
              'Kategoriye Dön',
              style: TextStyle(color: themeExtension.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Dismiss the dialog first
              Navigator.of(context).pop();

              List<Lesson> lessons =
                  await _fetchLessonsForCategory(widget.category.id);
              if (!mounted) return; // Check if the widget is still in the tree

              if (lessons.isEmpty) {
                // Should not happen if category ID is valid and JSON exists
                Navigator.of(context).pop(_isLessonCompleted); // Go back to category
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          "Dersler yüklenemedi. Kategoriye dönülüyor.")),
                );
                return;
              }

              int currentIndex =
                  lessons.indexWhere((l) => l.id == widget.lesson.id);
              Lesson? nextLesson;

              if (currentIndex != -1 && currentIndex < lessons.length - 1) {
                nextLesson = lessons[currentIndex + 1];
              }

              if (nextLesson != null && !nextLesson.isLocked) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LessonDetailScreen(
                      lesson: nextLesson!,
                      category: widget.category,
                    ),
                  ),
                );
              } else if (nextLesson != null && nextLesson.isLocked) {
                // This case should ideally not be hit if lock logic is correct
                // and lessons are completed sequentially.
                Navigator.of(context).pop(_isLessonCompleted); // Go back to category
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        "Sonraki ders henüz kilitli. Önceki dersleri tamamlayın."),
                    backgroundColor: themeExtension.warningColor,
                  ),
                );
              } else {
                // No next lesson or current lesson not found (edge case)
                Navigator.of(context).pop(_isLessonCompleted); // Go back to category
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        "Tebrikler! Bu kategorideki tüm dersleri tamamladınız."),
                    backgroundColor: themeExtension.positiveColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeExtension.accentColor,
              foregroundColor:
                  themeExtension.isDark ? Colors.black : Colors.white,
            ),
            child: const Text('Sonraki Ders'),
          ),
        ],
      ),
    );
  }

  void _toggleBookmark() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;
    setState(() {
      widget.lesson.isBookmarked = !widget.lesson.isBookmarked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.lesson.isBookmarked ? "Ders yer imlerine eklendi." : "Ders yer imlerinden kaldırıldı."),
        backgroundColor: themeExtension.accentColor,
      ),
    );
  }

  // Helper methods for fetching lessons and handling completion status
  Future<Map<String, bool>> _loadLessonCompletionStatusForCategory(
      String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, bool> completionStatus = {};
    final categoryKeyPrefix = '$_completionStatusKeyPrefix${categoryId}_';

    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith(categoryKeyPrefix)) {
        final lessonId = key.substring(categoryKeyPrefix.length);
        completionStatus[lessonId] = prefs.getBool(key) ?? false;
      }
    }
    return completionStatus;
  }

  List<Lesson> _applyCompletionAndLockLogic(
      List<Lesson> lessons, Map<String, bool> completionStatus) {
    lessons.sort((a, b) => a.order.compareTo(b.order));

    bool previousLessonCompleted = true;
    List<Lesson> updatedLessons = [];

    for (var lesson in lessons) {
      final isCompleted = completionStatus[lesson.id] ?? false;
      final isLocked = !previousLessonCompleted && !isCompleted;

      Lesson updatedLesson = lesson.copyWith(
        isCompleted: isCompleted,
        isLocked: isLocked,
      );
      updatedLessons.add(updatedLesson);

      // For the next lesson, this current lesson's completion status is critical
      previousLessonCompleted = isCompleted;
    }
    return updatedLessons;
  }

  Future<List<Lesson>> _fetchLessonsForCategory(String categoryId) async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/education/lessons/$categoryId.json');
      final data = await json.decode(response) as List;
      List<Lesson> lessons =
          data.map((json) => Lesson.fromJson(json)).toList();

      final completionStatus =
          await _loadLessonCompletionStatusForCategory(categoryId);
      lessons = _applyCompletionAndLockLogic(lessons, completionStatus);

      return lessons;
    } catch (e) {
      // Log error or handle appropriately
      debugPrint('Error fetching lessons for category $categoryId: $e');
      return []; // Return empty list on error
    }
  }
}
