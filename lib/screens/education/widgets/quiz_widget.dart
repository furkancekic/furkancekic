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
    if (widget.quiz.timeLimit > 0) {
      _remainingTime = widget.quiz.timeLimit * 60; // Convert to seconds
      _startTimer();
    }
    _progressAnimationController.forward();
    _questionAnimationController.forward();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    return (_currentQuestionIndex + 1) / widget.quiz.questions.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) {
      return _buildResultsView();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildQuizHeader(),
          const SizedBox(height: 16),
          _buildQuestionCard(),
          const SizedBox(height: 16),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildQuizHeader() {
    return AdaptiveCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz,
                  color: AppTheme.accentColor,
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Geçer not: %${widget.quiz.passingScore}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.quiz.timeLimit > 0) _buildTimerWidget(),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Row(
            children: [
              Text(
                'Soru ${_currentQuestionIndex + 1} / ${widget.quiz.questions.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${(_quizProgress * 100).toInt()}%',
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
                value: _quizProgress,
                backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                minHeight: 8,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimerWidget() {
    final minutes = _remainingTime ~/ 60;
    final seconds = _remainingTime % 60;
    final isLowTime = _remainingTime < 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLowTime
            ? AppTheme.negativeColor.withOpacity(0.2)
            : AppTheme.accentColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: isLowTime ? AppTheme.negativeColor : AppTheme.accentColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isLowTime ? AppTheme.negativeColor : AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    if (_currentQuestionIndex >= widget.quiz.questions.length) {
      return const SizedBox.shrink();
    }

    final question = widget.quiz.questions[_currentQuestionIndex];

    return SlideTransition(
      position: _questionSlideAnimation,
      child: AdaptiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soru ${_currentQuestionIndex + 1}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _buildQuestionWidget(question),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(Question question) {
    switch (question.runtimeType) {
      case MultipleChoiceQuestion:
        return _buildMultipleChoiceWidget(question as MultipleChoiceQuestion);
      case TrueFalseQuestion:
        return _buildTrueFalseWidget(question as TrueFalseQuestion);
      case DragDropQuestion:
        return _buildDragDropWidget(question as DragDropQuestion);
      default:
        return const Text('Bilinmeyen soru türü');
    }
  }

  Widget _buildMultipleChoiceWidget(MultipleChoiceQuestion question) {
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
                    ? AppTheme.accentColor.withOpacity(0.1)
                    : AppTheme.cardColorLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.accentColor : Colors.transparent,
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
                            ? AppTheme.accentColor
                            : AppTheme.textSecondary,
                        width: 2,
                      ),
                      color: isSelected
                          ? AppTheme.accentColor
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
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
                            ? AppTheme.accentColor
                            : AppTheme.textPrimary,
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

  Widget _buildTrueFalseWidget(TrueFalseQuestion question) {
    final selectedAnswer = _userAnswers[question.id] as bool?;

    return Row(
      children: [
        Expanded(
          child: _buildTrueFalseOption(
            question,
            true,
            'Doğru',
            selectedAnswer == true,
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTrueFalseOption(
            question,
            false,
            'Yanlış',
            selectedAnswer == false,
            Icons.cancel,
          ),
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
  ) {
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
              ? (value ? AppTheme.positiveColor : AppTheme.negativeColor)
                  .withOpacity(0.1)
              : AppTheme.cardColorLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (value ? AppTheme.positiveColor : AppTheme.negativeColor)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (value ? AppTheme.positiveColor : AppTheme.negativeColor)
                  : AppTheme.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (value ? AppTheme.positiveColor : AppTheme.negativeColor)
                    : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragDropWidget(DragDropQuestion question) {
    final userMatches = _userAnswers[question.id] as Map<String, String>? ?? {};

    return Column(
      children: [
        const Text(
          'Eşleştirme yapın:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Items to drag
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: question.items.map((item) {
            final isMatched = userMatches.containsKey(item);
            return Draggable<String>(
              data: item,
              feedback: Material(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              childWhenDragging: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMatched
                      ? AppTheme.positiveColor.withOpacity(0.2)
                      : AppTheme.cardColorLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isMatched
                        ? AppTheme.positiveColor
                        : AppTheme.textSecondary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    color: isMatched
                        ? AppTheme.positiveColor
                        : AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: isMatched ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Drop targets
        Column(
          children: question.targets.map((target) {
            final matchedItem = userMatches.entries
                .where((entry) => entry.value == target)
                .map((entry) => entry.key)
                .firstOrNull;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DragTarget<String>(
                onAccept: (item) {
                  setState(() {
                    // Remove existing match for this item
                    userMatches.removeWhere((key, value) => key == item);
                    // Add new match
                    userMatches[item] = target;
                    _userAnswers[question.id] = userMatches;
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: matchedItem != null
                          ? AppTheme.accentColor.withOpacity(0.1)
                          : AppTheme.cardColorLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: candidateData.isNotEmpty
                            ? AppTheme.accentColor
                            : matchedItem != null
                                ? AppTheme.accentColor
                                : AppTheme.textSecondary.withOpacity(0.3),
                        width: candidateData.isNotEmpty ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            target,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (matchedItem != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              matchedItem,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildNavigationButtons() {
    final isLastQuestion =
        _currentQuestionIndex == widget.quiz.questions.length - 1;
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    final hasAnswer = _userAnswers.containsKey(currentQuestion.id);

    return Row(
      children: [
        // Previous button
        if (_currentQuestionIndex > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _goToPreviousQuestion,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Önceki'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.textSecondary),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

        if (_currentQuestionIndex > 0) const SizedBox(width: 12),

        // Next/Finish button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: hasAnswer
                ? (isLastQuestion ? _completeQuiz : _goToNextQuestion)
                : null,
            icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
            label: Text(isLastQuestion ? 'Testi Bitir' : 'Sonraki'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    final totalQuestions = widget.quiz.questions.length;
    final correctAnswers = _calculateCorrectAnswers();
    final percentage = (correctAnswers / totalQuestions * 100).round();
    final passed = percentage >= widget.quiz.passingScore;

    return Column(
      children: [
        AdaptiveCard(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: passed
                      ? AppTheme.positiveColor.withOpacity(0.2)
                      : AppTheme.negativeColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  passed ? Icons.check_circle : Icons.error,
                  color:
                      passed ? AppTheme.positiveColor : AppTheme.negativeColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                passed ? 'Tebrikler!' : 'Tekrar Deneyin',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                passed
                    ? 'Testi başarıyla tamamladınız!'
                    : 'Maalesef geçer notu alamadınız.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Score details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildScoreItem(
                      'Doğru', '$correctAnswers', AppTheme.positiveColor),
                  _buildScoreItem(
                      'Yanlış',
                      '${totalQuestions - correctAnswers}',
                      AppTheme.negativeColor),
                  _buildScoreItem('Puan', '%$percentage', AppTheme.accentColor),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Question review
        AdaptiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Soru İnceleme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.quiz.questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                final isCorrect = _isAnswerCorrect(question);

                return _buildQuestionReviewItem(question, index + 1, isCorrect);
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _retakeQuiz,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.textSecondary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Tekrar Dene'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.onQuizCompleted(_score),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Devam Et'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionReviewItem(
      Question question, int number, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCorrect
                  ? AppTheme.positiveColor.withOpacity(0.2)
                  : AppTheme.negativeColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCorrect ? Icons.check : Icons.close,
              color:
                  isCorrect ? AppTheme.positiveColor : AppTheme.negativeColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soru $number',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isCorrect && question.explanation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    question.explanation!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
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
      setState(() {
        _currentQuestionIndex++;
      });
      _questionAnimationController.reset();
      _questionAnimationController.forward();
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _questionAnimationController.reset();
      _questionAnimationController.forward();
    }
  }

  void _completeQuiz() {
    _timer?.cancel();

    final correctAnswers = _calculateCorrectAnswers();
    final totalQuestions = widget.quiz.questions.length;
    _score = (correctAnswers / totalQuestions * 100);

    setState(() {
      _isQuizCompleted = true;
      _showResults = true;
    });
  }

  void _retakeQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _userAnswers.clear();
      _isQuizCompleted = false;
      _showResults = false;
      _score = 0.0;
    });

    if (widget.quiz.timeLimit > 0) {
      _remainingTime = widget.quiz.timeLimit * 60;
      _startTimer();
    }

    _progressAnimationController.reset();
    _questionAnimationController.reset();
    _progressAnimationController.forward();
    _questionAnimationController.forward();
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

    switch (question.runtimeType) {
      case MultipleChoiceQuestion:
        final mcq = question as MultipleChoiceQuestion;
        return userAnswer == mcq.correctAnswerIndex;

      case TrueFalseQuestion:
        final tfq = question as TrueFalseQuestion;
        return userAnswer == tfq.correctAnswer;

      case DragDropQuestion:
        final ddq = question as DragDropQuestion;
        final userMatches = userAnswer as Map<String, String>? ?? {};
        return userMatches.length == ddq.correctMatches.length &&
            ddq.correctMatches.entries.every(
              (entry) => userMatches[entry.key] == entry.value,
            );

      default:
        return false;
    }
  }
}
