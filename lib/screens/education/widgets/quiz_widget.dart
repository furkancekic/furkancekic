// screens/education/widgets/quiz_widget.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';
import '../models/education_models.dart';

class QuizWidget extends StatefulWidget {
  final Quiz quiz;
  final Function(double) onQuizCompleted;

  const QuizWidget({
    Key? key,
    required this.quiz,
    required this.onQuizCompleted,
  }) : super(key: key);

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  Map<String, dynamic> _userAnswers = {};
  bool _isQuizCompleted = false;
  bool _showResults = false;
  double _score = 0.0;
  Timer? _timer;
  int _remainingTime = 0;

  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  late AnimationController _questionAnimationController;
  late Animation<Offset> _questionSlideAnimation;

  // For DragDropQuestion
  Map<String, String?> _dragDropUserMatches = {}; // {target: item}
  String? _draggingItem;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startQuiz();
  }

  void _initializeAnimations() {
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    _questionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _questionSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startQuiz() {
    _currentQuestionIndex = 0;
    _userAnswers.clear();
    _dragDropUserMatches.clear(); // Reset drag-drop answers
    _isQuizCompleted = false;
    _showResults = false;
    _score = 0.0;

    if (widget.quiz.timeLimit > 0) {
      _remainingTime = widget.quiz.timeLimit * 60; // Convert to seconds
      _startTimer();
    }
    _progressAnimationController.forward();
    _questionAnimationController.forward();
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingTime--;
      });

      if (_remainingTime <= 0) {
        _timer?.cancel();
        _completeQuiz();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressAnimationController.dispose();
    _questionAnimationController.dispose();
    super.dispose();
  }

  double get _quizProgress {
    if (widget.quiz.questions.isEmpty) return 0.0;
    // Ensure progress doesn't exceed 1.0 if _currentQuestionIndex somehow goes beyond length
    return (_currentQuestionIndex / widget.quiz.questions.length)
        .clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;
    if (_showResults) {
      return _buildResultsView(themeExtension);
    }

    if (widget.quiz.questions.isEmpty) {
      return AdaptiveCard(
        child: Center(
          child: Text(
            'Bu quiz için soru bulunmuyor.',
            style: TextStyle(color: themeExtension.textSecondary),
          ),
        ),
      );
    }

    // Ensure current question index is valid
    if (_currentQuestionIndex >= widget.quiz.questions.length) {
      // This case should ideally not be reached if navigation is handled correctly.
      // If it is, it might indicate an issue with _goToNextQuestion or _completeQuiz logic.
      // For safety, reset to the first question or show an error.
      // For now, let's show the results if this happens unexpectedly.
      _completeQuiz(); // Or handle as an error state
      return _buildResultsView(themeExtension);
    }

    return SingleChildScrollView(
      // Added for long questions/options
      child: Column(
        children: [
          _buildQuizHeader(themeExtension),
          const SizedBox(height: 16),
          _buildQuestionCard(themeExtension),
          const SizedBox(height: 16),
          _buildNavigationButtons(themeExtension),
        ],
      ),
    );
  }

  Widget _buildQuizHeader(AppThemeExtension themeExtension) {
    return AdaptiveCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeExtension.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.quiz,
                  color: themeExtension.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.quiz.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeExtension.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Geçer not: %${widget.quiz.passingScore}',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeExtension.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.quiz.timeLimit > 0) _buildTimerWidget(themeExtension),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Soru ${_currentQuestionIndex + 1} / ${widget.quiz.questions.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: themeExtension.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${(_quizProgress * 100).toStringAsFixed(0)}%',
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
            // Replaced LinearProgressIndicator with AnimatedBuilder for smoother animation
            animation:
                _progressAnimationController, // Use the controller directly
            builder: (context, child) {
              // Calculate progress based on current question index and total questions
              double currentProgress = widget.quiz.questions.isEmpty
                  ? 0.0
                  : (_currentQuestionIndex / widget.quiz.questions.length);
              if (_isQuizCompleted || _showResults) currentProgress = 1.0;

              return LinearProgressIndicator(
                value: currentProgress,
                backgroundColor: themeExtension.textSecondary.withOpacity(0.2),
                valueColor:
                    AlwaysStoppedAnimation<Color>(themeExtension.accentColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimerWidget(AppThemeExtension themeExtension) {
    final minutes = _remainingTime ~/ 60;
    final seconds = _remainingTime % 60;
    final isLowTime = _remainingTime > 0 &&
        _remainingTime < 60; // Only low if time is running and < 60

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLowTime
            ? themeExtension.negativeColor.withOpacity(0.2)
            : themeExtension.accentColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: isLowTime
                ? themeExtension.negativeColor
                : themeExtension.accentColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isLowTime
                  ? themeExtension.negativeColor
                  : themeExtension.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(AppThemeExtension themeExtension) {
    if (_currentQuestionIndex >= widget.quiz.questions.length) {
      return const SizedBox.shrink(); // Should not happen
    }

    final question = widget.quiz.questions[_currentQuestionIndex];

    // Reset drag-drop state when question changes to DragDropQuestion
    if (question is DragDropQuestion && _userAnswers[question.id] == null) {
      _dragDropUserMatches.clear();
      // Initialize _dragDropUserMatches for the current question if needed
      // For example, if you want to pre-fill or restore previous attempts for this specific question
      var existingAnswer = _userAnswers[question.id];
      if (existingAnswer is Map<String, String?>) {
        _dragDropUserMatches = Map<String, String?>.from(existingAnswer);
      } else {
        _dragDropUserMatches = {
          for (var target in question.targets) target: null
        };
      }
    }

    return SlideTransition(
      position: _questionSlideAnimation,
      child: AdaptiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soru ${_currentQuestionIndex + 1}',
              style: TextStyle(
                fontSize: 12,
                color: themeExtension.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.question,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeExtension.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _buildQuestionWidget(question, themeExtension),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(
      Question question, AppThemeExtension themeExtension) {
    switch (question.runtimeType) {
      case MultipleChoiceQuestion:
        return _buildMultipleChoiceWidget(
            question as MultipleChoiceQuestion, themeExtension);
      case TrueFalseQuestion:
        return _buildTrueFalseWidget(
            question as TrueFalseQuestion, themeExtension);
      case DragDropQuestion:
        return _buildDragDropWidget(
            question as DragDropQuestion, themeExtension);
      default:
        return Text('Bilinmeyen soru türü',
            style: TextStyle(color: themeExtension.textPrimary));
    }
  }

  Widget _buildMultipleChoiceWidget(
      MultipleChoiceQuestion question, AppThemeExtension themeExtension) {
    final selectedAnswer = _userAnswers[question.id] as int?;

    return Column(
      children: question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = selectedAnswer == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _userAnswers[question.id] = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? themeExtension.accentColor.withOpacity(0.1)
                    : themeExtension.cardColorLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? themeExtension.accentColor
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? themeExtension.accentColor
                            : themeExtension.textSecondary,
                        width: 2,
                      ),
                      color: isSelected
                          ? themeExtension.accentColor
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors
                                .white, // Or themeExtension.textPrimary if accent is light
                            size: 12,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? themeExtension.accentColor
                            : themeExtension.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseWidget(
      TrueFalseQuestion question, AppThemeExtension themeExtension) {
    final selectedAnswer = _userAnswers[question.id] as bool?;

    return Row(
      children: [
        Expanded(
          child: _buildTrueFalseOption(question, true, 'Doğru',
              selectedAnswer == true, Icons.check_circle, themeExtension),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTrueFalseOption(question, false, 'Yanlış',
              selectedAnswer == false, Icons.cancel, themeExtension),
        ),
      ],
    );
  }

  Widget _buildTrueFalseOption(
      TrueFalseQuestion question,
      bool value,
      String label,
      bool isSelected,
      IconData icon,
      AppThemeExtension themeExtension) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _userAnswers[question.id] = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? (value
                      ? themeExtension.positiveColor
                      : themeExtension.negativeColor)
                  .withOpacity(0.1)
              : themeExtension.cardColorLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (value
                    ? themeExtension.positiveColor
                    : themeExtension.negativeColor)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (value
                      ? themeExtension.positiveColor
                      : themeExtension.negativeColor)
                  : themeExtension.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (value
                        ? themeExtension.positiveColor
                        : themeExtension.negativeColor)
                    : themeExtension.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragDropWidget(
      DragDropQuestion question, AppThemeExtension themeExtension) {
    // Ensure _dragDropUserMatches is initialized for the current question
    // This map stores {target: item_name_if_matched_else_null}
    if (_userAnswers[question.id] == null) {
      _dragDropUserMatches = {
        for (var target in question.targets) target: null
      };
      _userAnswers[question.id] =
          _dragDropUserMatches; // Store it as the initial answer
    } else {
      // If an answer already exists, ensure it's in the correct format
      var currentAnswer = _userAnswers[question.id];
      if (currentAnswer is Map) {
        _dragDropUserMatches = Map<String, String?>.from(
            currentAnswer.map((k, v) => MapEntry(k.toString(), v?.toString())));
      } else {
        // If not a map (e.g., from a previous incorrect state), reinitialize
        _dragDropUserMatches = {
          for (var target in question.targets) target: null
        };
        _userAnswers[question.id] = _dragDropUserMatches;
      }
    }

    List<String> availableItems = List.from(question.items);
    _dragDropUserMatches.values
        .where((item) => item != null)
        .forEach(availableItems.remove);

    return Column(
      children: [
        Text(
          'Aşağıdaki öğeleri uygun hedeflere sürükleyin:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: themeExtension.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Draggable Items Area
        Text('Sürüklenecek Öğeler:',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: themeExtension.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: availableItems.map((item) {
            return Draggable<String>(
              data: item,
              onDragStarted: () {
                setState(() {
                  _draggingItem = item;
                });
              },
              onDragEnd: (_) {
                setState(() {
                  _draggingItem = null;
                });
              },
              feedback: Material(
                // Ensures text style during drag
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: themeExtension.accentColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(2, 2))
                      ]),
                  child: Text(
                    item,
                    style: TextStyle(
                        color:
                            themeExtension.isDark ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              childWhenDragging: Container(
                // Placeholder for the item being dragged
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: themeExtension.cardColorLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: themeExtension.textSecondary.withOpacity(0.3),
                      style: BorderStyle.solid),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                      color: themeExtension.textSecondary.withOpacity(0.7),
                      fontSize: 12),
                ),
              ),
              child: Container(
                // Normal appearance of the draggable item
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: themeExtension.cardColorLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: themeExtension.textSecondary.withOpacity(0.5)),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                      color: themeExtension.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        Divider(color: themeExtension.textSecondary.withOpacity(0.3)),
        const SizedBox(height: 16),

        // Drop Targets Area
        Text('Hedefler:',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: themeExtension.textPrimary)),
        const SizedBox(height: 8),
        Column(
          children: question.targets.map((target) {
            final matchedItem = _dragDropUserMatches[target];
            bool isTargetFilled = matchedItem != null;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: DragTarget<String>(
                onWillAccept: (item) {
                  // Allow dropping only if the target is empty OR if the item being dragged is different from what's already in the target
                  return !isTargetFilled ||
                      (item != null && item != matchedItem);
                },
                onAccept: (item) {
                  setState(() {
                    // If another item was in this target, make it available again
                    // (This logic is complex if items can be swapped directly between targets.
                    //  For simplicity, assume an item dropped on a filled target replaces it,
                    //  and the old item returns to the available pool - handled by `availableItems` list)

                    // Remove item from any other target it might have been in
                    _dragDropUserMatches.forEach((key, value) {
                      if (value == item) {
                        _dragDropUserMatches[key] = null;
                      }
                    });
                    // Place item in the new target
                    _dragDropUserMatches[target] = item;
                    _userAnswers[question.id] = Map<String, String?>.from(
                        _dragDropUserMatches); // Update main answers
                    _draggingItem = null;
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  bool isHighlighted = candidateData.isNotEmpty;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(minHeight: 60),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? themeExtension.accentColor.withOpacity(0.2)
                          : (isTargetFilled
                              ? themeExtension.cardColorLight
                              : themeExtension.cardColor.withOpacity(0.7)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isHighlighted
                            ? themeExtension.accentColor
                            : (isTargetFilled
                                ? themeExtension.positiveColor.withOpacity(0.5)
                                : themeExtension.textSecondary
                                    .withOpacity(0.3)),
                        width: isHighlighted ? 2 : 1,
                      ),
                      boxShadow: isTargetFilled || isHighlighted
                          ? [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 3,
                                  offset: Offset(1, 1))
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            target,
                            style: TextStyle(
                                fontSize: 14,
                                color: themeExtension.textPrimary,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (isTargetFilled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: themeExtension.positiveColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              matchedItem!,
                              style: TextStyle(
                                color: themeExtension.isDark
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (isHighlighted)
                          Icon(Icons.add_link,
                              color:
                                  themeExtension.accentColor.withOpacity(0.7),
                              size: 20)
                        else
                          Text(
                            "Öğeyi buraya sürükleyin",
                            style: TextStyle(
                                fontSize: 12,
                                color: themeExtension.textSecondary
                                    .withOpacity(0.7),
                                fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(AppThemeExtension themeExtension) {
    final isLastQuestion =
        _currentQuestionIndex == widget.quiz.questions.length - 1;
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];

    bool hasAnswer = _userAnswers.containsKey(currentQuestion.id) &&
        _userAnswers[currentQuestion.id] != null;
    if (currentQuestion is DragDropQuestion) {
      // For drag-drop, consider answered if all targets have an item or if user explicitly "completes" it.
      // For simplicity, let's say if _dragDropUserMatches has been initialized (which it is), it's considered 'touched'.
      // A better check would be if all targets are filled.
      final ddAnswer =
          _userAnswers[currentQuestion.id] as Map<String, String?>?;
      hasAnswer = ddAnswer?.values.any((v) => v != null) ??
          false; // Considered answered if at least one match is made
    }

    return Padding(
      // Added padding for buttons
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _goToPreviousQuestion,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Önceki'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: themeExtension.textPrimary,
                  side: BorderSide(
                      color: themeExtension.textSecondary.withOpacity(0.7)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          if (_currentQuestionIndex > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: hasAnswer
                  ? (isLastQuestion ? _completeQuiz : _goToNextQuestion)
                  : null, // Disable if no answer
              icon: Icon(isLastQuestion
                  ? Icons.check_circle_outline
                  : Icons.arrow_forward),
              label: Text(isLastQuestion ? 'Testi Bitir' : 'Sonraki'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeExtension.accentColor,
                foregroundColor:
                    themeExtension.isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                disabledBackgroundColor:
                    themeExtension.accentColor.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(AppThemeExtension themeExtension) {
    final totalQuestions = widget.quiz.questions.length;
    if (totalQuestions == 0) {
      return Center(
          child: Text("Quiz sonuçları yüklenemedi.",
              style: TextStyle(color: themeExtension.textSecondary)));
    }
    final correctAnswers = _calculateCorrectAnswers();
    final percentage =
        totalQuestions > 0 ? (correctAnswers / totalQuestions * 100) : 0.0;
    final passed = percentage >= widget.quiz.passingScore;

    return SingleChildScrollView(
      // Added for long result lists
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          AdaptiveCard(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: passed
                        ? themeExtension.positiveColor.withOpacity(0.2)
                        : themeExtension.negativeColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    passed ? Icons.check_circle_outline : Icons.highlight_off,
                    color: passed
                        ? themeExtension.positiveColor
                        : themeExtension.negativeColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  passed ? 'Tebrikler!' : 'Tekrar Deneyin',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: themeExtension.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  passed
                      ? 'Testi başarıyla tamamladınız!'
                      : 'Maalesef geçer notu alamadınız.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: themeExtension.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildScoreItem('Doğru', '$correctAnswers',
                        themeExtension.positiveColor, themeExtension),
                    _buildScoreItem(
                        'Yanlış',
                        '${totalQuestions - correctAnswers}',
                        themeExtension.negativeColor,
                        themeExtension),
                    _buildScoreItem('Puan', '%${percentage.toStringAsFixed(0)}',
                        themeExtension.accentColor, themeExtension),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (widget.quiz.questions.isNotEmpty)
            AdaptiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Soru İnceleme',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeExtension.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: widget.quiz.questions.length,
                    itemBuilder: (context, index) {
                      final question = widget.quiz.questions[index];
                      final isCorrect = _isAnswerCorrect(question);
                      return _buildQuestionReviewItem(
                          question, index + 1, isCorrect, themeExtension);
                    },
                    separatorBuilder: (context, index) => Divider(
                        color: themeExtension.textSecondary.withOpacity(0.2)),
                  )
                ],
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.refresh),
                  onPressed: _retakeQuiz,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: themeExtension.textPrimary,
                    side: BorderSide(
                        color: themeExtension.textSecondary.withOpacity(0.7)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  label: const Text('Tekrar Dene'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () => widget.onQuizCompleted(_score),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeExtension.accentColor,
                    foregroundColor:
                        themeExtension.isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  label: const Text('Devam Et'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, Color color,
      AppThemeExtension themeExtension) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: themeExtension.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionReviewItem(Question question, int number, bool isCorrect,
      AppThemeExtension themeExtension) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCorrect
                  ? themeExtension.positiveColor.withOpacity(0.15)
                  : themeExtension.negativeColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCorrect ? Icons.check_circle_outline : Icons.highlight_off,
              color: isCorrect
                  ? themeExtension.positiveColor
                  : themeExtension.negativeColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soru $number: ${question.question}',
                  style: TextStyle(
                      fontSize: 14,
                      color: themeExtension.textPrimary,
                      fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isCorrect &&
                    question.explanation != null &&
                    question.explanation!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Açıklama: ${question.explanation!}",
                    style: TextStyle(
                      fontSize: 12,
                      color: themeExtension.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      // Before moving to the next question, ensure the current question's answer is "finalized"
      final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
      if (currentQuestion is DragDropQuestion) {
        _userAnswers[currentQuestion.id] =
            Map<String, String?>.from(_dragDropUserMatches);
      }

      setState(() {
        _currentQuestionIndex++;
      });
      // Update progress animation for the next question
      _progressAnimationController.animateTo(
          (_currentQuestionIndex / widget.quiz.questions.length)
              .clamp(0.0, 1.0));

      _questionAnimationController.reset();
      _questionAnimationController.forward();

      // Reset drag drop matches for the new question if it's a DragDropQuestion
      final nextQuestion = widget.quiz.questions[_currentQuestionIndex];
      if (nextQuestion is DragDropQuestion) {
        var existingAnswer = _userAnswers[nextQuestion.id];
        if (existingAnswer is Map) {
          _dragDropUserMatches = Map<String, String?>.from(existingAnswer
              .map((k, v) => MapEntry(k.toString(), v?.toString())));
        } else {
          _dragDropUserMatches = {
            for (var target in nextQuestion.targets) target: null
          };
        }
      }
    } else {
      _completeQuiz(); // If it's the last question, complete the quiz
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      // Finalize answer for current question before moving
      final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
      if (currentQuestion is DragDropQuestion) {
        _userAnswers[currentQuestion.id] =
            Map<String, String?>.from(_dragDropUserMatches);
      }

      setState(() {
        _currentQuestionIndex--;
      });
      // Update progress animation for the previous question
      _progressAnimationController.animateTo(
          (_currentQuestionIndex / widget.quiz.questions.length)
              .clamp(0.0, 1.0));

      _questionAnimationController.reset();
      _questionAnimationController
          .forward(); // Or a reverse animation if desired

      // Restore drag drop matches for the previous question if it's a DragDropQuestion
      final prevQuestion = widget.quiz.questions[_currentQuestionIndex];
      if (prevQuestion is DragDropQuestion) {
        var existingAnswer = _userAnswers[prevQuestion.id];
        if (existingAnswer is Map) {
          _dragDropUserMatches = Map<String, String?>.from(existingAnswer
              .map((k, v) => MapEntry(k.toString(), v?.toString())));
        } else {
          // Should ideally not happen if answers are stored correctly
          _dragDropUserMatches = {
            for (var target in prevQuestion.targets) target: null
          };
        }
      }
    }
  }

  void _completeQuiz() {
    _timer?.cancel();

    // Finalize answer for the last question if it's a DragDropQuestion
    if (_currentQuestionIndex < widget.quiz.questions.length) {
      final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
      if (currentQuestion is DragDropQuestion) {
        _userAnswers[currentQuestion.id] =
            Map<String, String?>.from(_dragDropUserMatches);
      }
    }

    final correctAnswers = _calculateCorrectAnswers();
    final totalQuestions = widget.quiz.questions.length;
    _score = totalQuestions > 0 ? (correctAnswers / totalQuestions * 100) : 0.0;

    _progressAnimationController.animateTo(1.0); // Mark progress as 100%

    if (!mounted) return;
    setState(() {
      _isQuizCompleted = true;
      _showResults = true;
    });
  }

  void _retakeQuiz() {
    _startQuiz(); // Re-initialize everything
  }

  int _calculateCorrectAnswers() {
    int correct = 0;
    for (var question in widget.quiz.questions) {
      if (_isAnswerCorrect(question)) {
        correct++;
      }
    }
    return correct;
  }

  bool _isAnswerCorrect(Question question) {
    final userAnswer = _userAnswers[question.id];

    if (userAnswer == null) return false; // No answer given

    switch (question.runtimeType) {
      case MultipleChoiceQuestion:
        final mcq = question as MultipleChoiceQuestion;
        return userAnswer == mcq.correctAnswerIndex;

      case TrueFalseQuestion:
        final tfq = question as TrueFalseQuestion;
        return userAnswer == tfq.correctAnswer;

      case DragDropQuestion:
        final ddq = question as DragDropQuestion;
        if (userAnswer is! Map<String, String?>)
          return false; // Ensure correct type
        final userMatches = userAnswer; // {target: item}

        if (userMatches.length != ddq.targets.length)
          return false; // Must attempt all targets

        // Check if user's item for each target matches the correct item for that target
        // ddq.correctMatches is {item: target}
        // We need to invert ddq.correctMatches or iterate carefully
        bool allCorrect = true;
        for (var target in ddq.targets) {
          String? userSelectedItemForTarget = userMatches[target];
          // Find the correct item that should go to this 'target'
          String? correctItemForTarget;
          ddq.correctMatches.forEach((item, correctTarget) {
            if (correctTarget == target) {
              correctItemForTarget = item;
            }
          });

          if (userSelectedItemForTarget != correctItemForTarget) {
            allCorrect = false;
            break;
          }
        }
        return allCorrect;

      default:
        return false;
    }
  }
}
