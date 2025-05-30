// screens/education/education_category_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart'; // EKLENDİ
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
  State<EducationCategoryScreen> createState() =>
      _EducationCategoryScreenState();
}

class _EducationCategoryScreenState extends State<EducationCategoryScreen> {
  List<Lesson> _lessons = [];
  bool _isLoading = true;
  bool _isBookmarked = false;

  // SharedPreferences için anahtar öneki
  static const String _completionStatusKeyPrefix = 'lesson_completion_';
  static const String _bookmarkKeyPrefix = 'category_bookmark_';


  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadLessons(); // Dersleri ve tamamlanma durumlarını yükle
    await _loadBookmarkStatus(); // Yer imi durumunu yükle
  }

  // --- SharedPreferences Yardımcı Fonksiyonları ---

  Future<void> _loadBookmarkStatus() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final bookmarkKey = '$_bookmarkKeyPrefix${widget.category.id}';
    setState(() {
      _isBookmarked = prefs.getBool(bookmarkKey) ?? false;
    });
  }

  Future<void> _toggleBookmarkAndSave(AppThemeExtension themeExtension) async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    bool newBookmarkStatus = !_isBookmarked;
    final bookmarkKey = '$_bookmarkKeyPrefix${widget.category.id}';
    await prefs.setBool(bookmarkKey, newBookmarkStatus);

    setState(() {
      _isBookmarked = newBookmarkStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked
            ? 'Kategori yer imlerine eklendi.'
            : 'Kategori yer imlerinden kaldırıldı.'),
        backgroundColor: themeExtension.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<Map<String, bool>> _loadLessonCompletionStatusForCategory(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_completionStatusKeyPrefix$categoryId';
    final String? jsonString = prefs.getString(key);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final Map<String, dynamic> decodedMap = jsonDecode(jsonString);
        return decodedMap.map((lessonId, completed) => MapEntry(lessonId, completed as bool));
      } catch (e) {
        print("Kategori $categoryId için tamamlama durumu parse edilirken HATA: $e");
        return {}; // Hata durumunda boş map
      }
    }
    return {}; // Kayıt yoksa boş map
  }

  Future<void> _saveLessonCompletionStatus(String categoryId, String lessonId, bool isCompleted) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_completionStatusKeyPrefix$categoryId';
    
    Map<String, bool> categoryCompletion = await _loadLessonCompletionStatusForCategory(categoryId);
    categoryCompletion[lessonId] = isCompleted;
    
    final String jsonString = jsonEncode(categoryCompletion);
    await prefs.setString(key, jsonString);
    print("'$lessonId' dersi ($categoryId) için durum kaydedildi: $isCompleted");
  }

  // --- Ders Yükleme ve Kilit Mantığı ---

  Future<String> _loadJsonAsset(String assetPath) async {
    try {
      return await rootBundle.loadString(assetPath);
    } catch (e) {
      print("Varlık yüklenirken hata $assetPath: $e");
      return "[]";
    }
  }

  Future<void> _loadLessons() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    try {
      // Dersleri JSON'dan yükle
      List<Lesson> loadedLessons = await _fetchLessonsFromJson(widget.category.id);
      
      // SharedPreferences'ten tamamlanma durumlarını al
      Map<String, bool> completionStatus = await _loadLessonCompletionStatusForCategory(widget.category.id);

      // Derslerin tamamlanma durumlarını ve kilitlerini güncelle
      _applyCompletionAndLockLogic(loadedLessons, completionStatus);

      if (mounted) {
        setState(() {
          _lessons = loadedLessons;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("${widget.category.id} kategorisi için dersler yüklenirken HATA: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lessons = [];
        });
      }
    }
  }

  Future<List<Lesson>> _fetchLessonsFromJson(String categoryId) async {
    String assetPath;
    switch (categoryId.toLowerCase()) {
      case 'basics': assetPath = 'assets/data/basics_lessons.json'; break;
      case 'technical': assetPath = 'assets/data/technical_lessons.json'; break;
      case 'indicators': assetPath = 'assets/data/indicators_lessons.json'; break;
      case 'fundamental': assetPath = 'assets/data/fundamental_lessons.json'; break;
      case 'portfolio': assetPath = 'assets/data/portfolio_lessons.json'; break;
      case 'strategies': assetPath = 'assets/data/strategies_lessons.json'; break;
      default: return [];
    }

    final jsonString = await _loadJsonAsset(assetPath);
    if (jsonString.isEmpty || jsonString == "[]") {
      return [];
    }
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((jsonItem) => Lesson.fromJson(jsonItem as Map<String, dynamic>))
        .toList();
  }

  void _applyCompletionAndLockLogic(List<Lesson> lessons, Map<String, bool> completionStatus) {
    // Tamamlanma durumlarını uygula
    for (var lesson in lessons) {
      lesson.isCompleted = completionStatus[lesson.id] ?? lesson.isCompleted; // JSON'daki isCompleted varsayılan olur
    }

    lessons.sort((a, b) => a.order.compareTo(b.order));

    // Kilit mantığını uygula
    bool canAccessNext = true;
    for (int i = 0; i < lessons.length; i++) {
      if (i == 0) {
        lessons[i].isLocked = false; // İlk ders her zaman açık.
      } else {
        lessons[i].isLocked = !(lessons[i - 1].isCompleted && canAccessNext);
      }
      if (!lessons[i].isCompleted || lessons[i].isLocked) {
        if (!lessons[i].isCompleted) { // Sadece gerçekten tamamlanmadıysa bir sonrakine erişimi engelle
            canAccessNext = false;
        }
      }
    }
  }
  
  void _navigateToLesson(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(
          lesson: lesson, // Mevcut 'isCompleted' durumuyla gönderiliyor
          category: widget.category,
        ),
      ),
    ).then((lessonWasCompletedByDetailScreen) async {
      if (lessonWasCompletedByDetailScreen != null && lessonWasCompletedByDetailScreen is bool) {
        // SharedPreferences'e kaydet
        await _saveLessonCompletionStatus(widget.category.id, lesson.id, lessonWasCompletedByDetailScreen);
        
        // UI'ı güncellemek için dersleri yeniden yükle (SharedPreferences'ten okuyarak)
        await _loadLessons(); 
        print("Ders '${lesson.title}' (${widget.category.id}) durumu: ${lessonWasCompletedByDetailScreen ? "Tamamlandı" : "Tamamlanmadı"}. Kilitler güncellendi.");
      } else {
        // Eğer bir şey dönmediyse veya yanlış türde döndüyse, yine de UI'ı yenileyebiliriz.
        await _loadLessons();
        print("LessonDetailScreen'den belirsiz dönüş. Kilitler güncellendi.");
      }
    });
  }


  // --- UI Widget'ları ---
  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: themeExtension.gradientBackgroundColors,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, themeExtension),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState(themeExtension)
                    : _buildLessonsList(themeExtension),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeExtension themeExtension) {
    final completedLessonsCount = _lessons.where((l) => l.isCompleted).length;
    final totalLessonsCount = _lessons.length;
    final progress =
        totalLessonsCount > 0 ? completedLessonsCount / totalLessonsCount : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: themeExtension.cardColor,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: themeExtension.textPrimary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Spacer(),
              CircleAvatar(
                backgroundColor: themeExtension.cardColor,
                child: IconButton(
                  icon: Icon(
                      _isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border_outlined,
                      color: themeExtension.accentColor),
                  onPressed: () => _toggleBookmarkAndSave(themeExtension), // Kaydetme eklendi
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: themeExtension.cardColor,
                child: IconButton(
                  icon: Icon(Icons.share_outlined,
                      color: themeExtension.accentColor),
                  onPressed: () => _shareCategory(themeExtension),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: widget.category.color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ]),
                      child: Icon(
                        widget.category.icon,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: themeExtension.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.category.description,
                            style: TextStyle(
                                fontSize: 13,
                                color: themeExtension.textSecondary,
                                height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (totalLessonsCount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'İlerleme',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: themeExtension.textPrimary,
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
                    backgroundColor:
                        themeExtension.textSecondary.withOpacity(0.2),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(widget.category.color),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                        Icons.timer_outlined,
                        widget.category.estimatedTime,
                        'Tahmini Süre',
                        themeExtension),
                    _buildStatItem(Icons.menu_book_outlined,
                        '$totalLessonsCount', 'Ders', themeExtension),
                    _buildStatItem(
                        Icons.signal_cellular_alt_outlined,
                        _getDifficultyText(widget.category.difficulty),
                        'Seviye',
                        themeExtension),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label,
      AppThemeExtension themeExtension) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: themeExtension.accentColor, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: themeExtension.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: themeExtension.textSecondary,
          ),
        ),
      ],
    );
  }

  String _getDifficultyText(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.beginner: return 'Başlangıç';
      case Difficulty.intermediate: return 'Orta';
      case Difficulty.advanced: return 'İleri';
      case Difficulty.expert: return 'Uzman';
    }
  }

  Widget _buildLoadingState(AppThemeExtension themeExtension) {
    return Center(
      child: CircularProgressIndicator(
        color: themeExtension.accentColor,
      ),
    );
  }

  Widget _buildLessonsList(AppThemeExtension themeExtension) {
    if (_lessons.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_outlined,
                  size: 60,
                  color: themeExtension.textSecondary.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'Bu kategori için henüz ders bulunmuyor.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: themeExtension.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Yakında yeni dersler eklenecektir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: themeExtension.textSecondary.withOpacity(0.7),
                    fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Text(
              'Dersler (${_lessons.length})',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeExtension.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _lessons.length,
              itemBuilder: (context, index) {
                final lesson = _lessons[index];
                final isLast = index == _lessons.length - 1;
                return _buildLessonItem(
                    lesson, isLast, themeExtension, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonItem(Lesson lesson, bool isLast,
      AppThemeExtension themeExtension, int lessonNumber) {
    final canAccess = !lesson.isLocked;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 16 : 12),
      child: AdaptiveCard(
        onTap: canAccess
            ? () => _navigateToLesson(lesson)
            : () => _showLockedLessonSnackbar(themeExtension),
        color: lesson.isLocked
            ? themeExtension.cardColor.withOpacity(0.6)
            : themeExtension.cardColor,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: lesson.isCompleted
                        ? themeExtension.positiveColor.withOpacity(0.15)
                        : lesson.isLocked
                            ? themeExtension.textSecondary.withOpacity(0.1)
                            : lesson.typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: lesson.isCompleted
                      ? Icon(
                          Icons.check_circle,
                          color: themeExtension.positiveColor,
                          size: 28,
                        )
                      : lesson.isLocked
                          ? Icon(
                              Icons.lock_outline,
                              color:
                                  themeExtension.textSecondary.withOpacity(0.7),
                              size: 26,
                            )
                          : Icon(
                              lesson.typeIcon,
                              color: lesson.typeColor,
                              size: 26,
                            ),
                ),
                if (!lesson.isCompleted && !lesson.isLocked)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                          color: lesson.typeColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        '$lessonNumber',
                        style: TextStyle(
                          fontSize: 9,
                          color: themeExtension.isDark ||
                                  lesson.typeColor ==
                                      themeExtension.warningColor
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: lesson.isLocked
                                ? themeExtension.textSecondary.withOpacity(0.8)
                                : themeExtension.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!lesson.isLocked)
                        _buildLessonTypeBadge(lesson.type, themeExtension),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    lesson.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: lesson.isLocked
                          ? themeExtension.textSecondary.withOpacity(0.6)
                          : themeExtension.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: themeExtension.textSecondary.withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lesson.estimatedTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: themeExtension.textSecondary.withOpacity(0.8),
                        ),
                      ),
                      if (lesson.prerequisites.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.link_outlined,
                          size: 14,
                          color: themeExtension.textSecondary.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${lesson.prerequisites.length} ön koşul',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                themeExtension.textSecondary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (canAccess && !lesson.isCompleted)
              Icon(
                Icons.arrow_forward_ios,
                color: themeExtension.accentColor,
                size: 18,
              )
            else if (lesson.isCompleted)
              Icon(
                Icons.check_circle_outline,
                color: themeExtension.positiveColor.withOpacity(0.8),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonTypeBadge(
      LessonType type, AppThemeExtension themeExtension) {
    String text;
    Color color = type.color;
    Color textColor =
        themeExtension.isDark || color == themeExtension.warningColor
            ? Colors.black.withOpacity(0.8)
            : Colors.white;

    if (color == themeExtension.positiveColor && !themeExtension.isDark) {
      textColor = Colors.white;
    }

    switch (type) {
      case LessonType.theory: text = 'Teori'; break;
      case LessonType.interactive: text = 'İnteraktif'; break;
      case LessonType.practice: text = 'Pratik'; break;
      case LessonType.quiz: text = 'Test'; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(themeExtension.isDark ? 0.7 : 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showLockedLessonSnackbar(AppThemeExtension themeExtension) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
            'Bu derse erişmek için önceki dersleri tamamlamanız gerekiyor.'),
        backgroundColor: themeExtension.warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _shareCategory(AppThemeExtension themeExtension) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Paylaşım özelliği yakında eklenecektir.'),
        backgroundColor: themeExtension.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}