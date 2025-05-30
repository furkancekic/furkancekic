// screens/education/education_home_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart'; // AdaptiveCard için
import 'education_category_screen.dart';
import 'models/education_models.dart';

class EducationHomeScreen extends StatefulWidget {
  const EducationHomeScreen({Key? key}) : super(key: key);

  @override
  State<EducationHomeScreen> createState() => _EducationHomeScreenState();
}

class _EducationHomeScreenState extends State<EducationHomeScreen> {
  // Kategori verileri burada tanımlanmaya devam edecek.
  // Gerçek uygulamada bu veriler de bir backend'den veya lokal bir DB'den gelebilir.
  // Şimdilik, ders sayıları ve tamamlanan ders sayıları manuel olarak girilmiştir.
  // EducationCategoryScreen'de JSON'dan dersler yüklendiğinde, bu değerler
  // kategori bazında ilerleme takibi için kullanılabilir veya güncellenebilir.
  final List<EducationCategory> _categories = [
    EducationCategory(
      id: 'basics',
      title: 'Yatırım Temelleri',
      description: 'Hisse senedi yatırımının temel kavramlarını öğrenin.',
      icon: Icons.school_outlined,
      color: const Color(0xFF4CAF50), // Yeşil
      difficulty: Difficulty.beginner,
      estimatedTime: '1 saat',
      lessons:
          8, // Bu kategorideki toplam ders sayısı (JSON'a göre güncellenebilir)
      completedLessons:
          0, // Kullanıcının tamamladığı ders sayısı (dinamik olmalı)
      topics: [
        'Piyasalar Ne İşe Yarar?',
        'Hisse Senedi Nedir?',
        'Borsa Nasıl Çalışır?',
        'Risk ve Getiri Kavramları',
        'Temel Emir Tipleri',
        'Yatırımcı Psikolojisi',
        'Portföy Çeşitlendirmesi Giriş',
        'Yatırım Araçları (Genel Bakış)',
      ],
    ),
    EducationCategory(
      id: 'technical',
      title: 'Teknik Analiz',
      description: 'Grafik okuma ve fiyat hareketlerini yorumlama.',
      icon: Icons.insights_outlined, // Daha uygun bir ikon
      color: const Color(0xFFFF9800), // Turuncu
      difficulty: Difficulty.intermediate,
      estimatedTime: '2.5 saat',
      lessons: 12,
      completedLessons: 0,
      topics: [
        'Teknik Analize Giriş',
        'Grafik Türleri (Çizgi, Bar, Mum)',
        'Trendler ve Trend Çizgileri',
        'Destek ve Direnç Seviyeleri',
        'Formasyonlar (Giriş)',
        'Hareketli Ortalamalar (SMA, EMA)',
        'İşlem Hacmi Analizi',
      ],
    ),
    EducationCategory(
      id: 'indicators',
      title: 'Teknik Göstergeler',
      description: 'RSI, MACD, Bollinger gibi popüler göstergeler.',
      icon: Icons.stacked_line_chart_outlined,
      color: const Color(0xFF9C27B0), // Mor
      difficulty: Difficulty.advanced,
      estimatedTime: '2 saat',
      lessons: 10,
      completedLessons: 0,
      topics: [
        'Gösterge Türleri',
        'RSI (Göreceli Güç Endeksi)',
        'MACD',
        'Bollinger Bantları',
        'Stokastik Osilatör',
        'Fibonacci Düzeltmeleri',
        'Ichimoku Bulutu (Giriş)',
      ],
    ),
    EducationCategory(
      id: 'fundamental',
      title: 'Temel Analiz',
      description: 'Şirketlerin finansal sağlığını değerlendirme.',
      icon: Icons.business_center_outlined,
      color: const Color(0xFF2196F3), // Mavi
      difficulty: Difficulty.intermediate,
      estimatedTime: '3 saat',
      lessons: 10,
      completedLessons: 0,
      topics: [
        'Temel Analize Giriş',
        'Bilanço Okuma',
        'Gelir Tablosu Analizi',
        'Nakit Akış Tablosu',
        'Önemli Finansal Oranlar (F/K, PD/DD)',
        'Sektör Analizi',
        'Ekonomik Göstergelerin Etkisi',
      ],
    ),
    EducationCategory(
      id: 'portfolio',
      title: 'Portföy Yönetimi',
      description: 'Riskleri dengeleme ve çeşitlendirme stratejileri.',
      icon: Icons.pie_chart_outline_outlined,
      color: const Color(0xFFE91E63), // Pembe
      difficulty: Difficulty.advanced,
      estimatedTime: '1.5 saat',
      lessons: 7,
      completedLessons: 0,
      topics: [
        'Portföy Nedir?',
        'Risk ve Getiri Dengesi',
        'Çeşitlendirmenin Önemi',
        'Varlık Dağılımı Stratejileri',
        'Portföy Yeniden Dengeleme',
        'Risk Yönetimi Teknikleri',
      ],
    ),
    EducationCategory(
      id: 'strategies',
      title: 'Yatırım Stratejileri',
      description: 'Farklı yatırım yaklaşımları ve taktikleri.',
      icon: Icons.lightbulb_outline,
      color: const Color(0xFF795548), // Kahverengi
      difficulty: Difficulty.expert,
      estimatedTime: '3.5 saat',
      lessons: 9,
      completedLessons: 0,
      topics: [
        'Değer Yatırımı',
        'Büyüme Yatırımı',
        'Temettü Yatırımı',
        'Kısa Vadeli Ticaret (Swing/Day Trading Giriş)',
        'Algoritmik Ticaret (Genel Bakış)',
        'Piyasa Zamanlaması vs. Uzun Vadeli Yatırım',
      ],
    ),
  ];

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
        // Scaffold eklendi
        backgroundColor:
            Colors.transparent, // Scaffold'un arka planını şeffaf yap
        appBar: AppBar(
          // AppBar eklendi
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, color: themeExtension.accentColor, size: 28),
              const SizedBox(width: 8),
              Text(
                'Yatırım Akademisi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: themeExtension.textPrimary,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _showAchievements(context, themeExtension),
              icon: Icon(
                Icons.emoji_events_outlined,
                color: themeExtension.accentColor,
                size: 26,
              ),
              tooltip: 'Başarımlar',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildProgressOverview(context, themeExtension),
              Expanded(
                child: _buildCategoriesGrid(context, themeExtension),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressOverview(
      BuildContext context, AppThemeExtension themeExtension) {
    final totalLessons =
        _categories.fold<int>(0, (sum, cat) => sum + cat.lessons);
    final completedLessons =
        _categories.fold<int>(0, (sum, cat) => sum + cat.completedLessons);
    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AdaptiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Genel İlerleme',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeExtension.textPrimary,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeExtension.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: themeExtension.textSecondary.withOpacity(0.2),
              valueColor:
                  AlwaysStoppedAnimation<Color>(themeExtension.accentColor),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildProgressStat(
                    'Tamamlanan Ders', '$completedLessons', themeExtension),
                _buildProgressStat(
                    'Toplam Ders', '$totalLessons', themeExtension),
                Icon(Icons.auto_stories_outlined,
                    color: themeExtension.accentColor.withOpacity(0.7),
                    size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(
      String label, String value, AppThemeExtension themeExtension) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: themeExtension.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
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

  Widget _buildCategoriesGrid(
      BuildContext context, AppThemeExtension themeExtension) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0,
          16.0), // Top padding removed, progress overview gives space
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.9, // Adjusted for potentially more content
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(context, category, themeExtension);
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, EducationCategory category,
      AppThemeExtension themeExtension) {
    final progress = category.lessons > 0
        ? category.completedLessons / category.lessons
        : 0.0;

    return AdaptiveCard(
      onTap: () => _navigateToCategory(context, category),
      padding: const EdgeInsets.all(12.0), // Slightly reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Spreads content vertically
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: 28,
                    ),
                  ),
                  _buildDifficultyBadge(category.difficulty, themeExtension),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                category.title,
                style: TextStyle(
                  fontSize: 15, // Slightly larger for title
                  fontWeight: FontWeight.bold,
                  color: themeExtension.textPrimary,
                ),
                maxLines: 2, // Allow for longer titles
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                category.description,
                style: TextStyle(
                  fontSize: 11,
                  color: themeExtension.textSecondary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (category.lessons > 0) ...[
                // Show progress only if there are lessons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${category.completedLessons}/${category.lessons} Ders',
                      style: TextStyle(
                        fontSize: 10,
                        color: themeExtension.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: category.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor:
                      themeExtension.textSecondary.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(category.color),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ] else ...[
                Text(
                  'Yakında', // Placeholder if no lessons defined
                  style: TextStyle(
                    fontSize: 10,
                    color: themeExtension.textSecondary.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 13, color: themeExtension.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    category.estimatedTime,
                    style: TextStyle(
                      fontSize: 10,
                      color: themeExtension.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(
      Difficulty difficulty, AppThemeExtension themeExtension) {
    String text;
    Color color;
    Color textColor;

    switch (difficulty) {
      case Difficulty.beginner:
        text = 'Başlangıç';
        color = themeExtension.positiveColor;
        break;
      case Difficulty.intermediate:
        text = 'Orta';
        color = themeExtension.warningColor;
        break;
      case Difficulty.advanced:
        text = 'İleri';
        color = themeExtension.negativeColor;
        break;
      case Difficulty.expert:
        text = 'Uzman';
        color = const Color(0xFF7E57C2); // Deeper purple for expert
        break;
    }
    textColor = themeExtension.isDark || color == themeExtension.warningColor
        ? Colors.black.withOpacity(0.8)
        : Colors.white;
    if (color == themeExtension.positiveColor && !themeExtension.isDark)
      textColor = Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(themeExtension.isDark ? 0.8 : 1.0),
        borderRadius: BorderRadius.circular(20), // Pill shape
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

  void _navigateToCategory(BuildContext context, EducationCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EducationCategoryScreen(category: category),
      ),
    ).then((_) {
      // Kategori ekranından dönüldüğünde ilerlemeyi güncellemek için
      // _loadProgressData(); // Eğer bir ilerleme kaydetme sisteminiz varsa
      setState(() {}); // Basit bir yeniden çizim için
    });
  }

  void _showAchievements(
      BuildContext context, AppThemeExtension themeExtension) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AchievementsSheet(themeExtension: themeExtension),
    );
  }
}

// Achievement system
class AchievementsSheet extends StatelessWidget {
  final AppThemeExtension themeExtension;
  const AchievementsSheet({Key? key, required this.themeExtension})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Örnek Başarımlar - Bu veriler dinamik olarak yönetilmeli
    final achievements = [
      Achievement(
        id: 'first_lesson',
        title: 'İlk Adım',
        description: 'İlk dersini başarıyla tamamladın!',
        icon: Icons.flag_outlined,
        isUnlocked: true, // Örnek
        progress: 1.0,
      ),
      Achievement(
        id: 'basics_master',
        title: 'Temel Bilgi Uzmanı',
        description: '"Yatırım Temelleri" kategorisini bitir.',
        icon: Icons.school_outlined,
        isUnlocked: false, // Örnek
        progress: 0.4, // %40 tamamlanmış
      ),
      Achievement(
        id: 'quiz_whiz',
        title: 'Quiz Canavarı',
        description: 'Bir quizden %90 üzeri puan al.',
        icon: Icons.star_outline,
        isUnlocked: true, // Örnek
        progress: 1.0,
      ),
      Achievement(
        id: 'consistent_learner',
        title: 'Düzenli Öğrenci',
        description: '3 gün üst üste ders çalış.',
        icon: Icons.calendar_today_outlined,
        isUnlocked: false, // Örnek
        progress: 0.66, // 2/3 gün
      ),
    ];

    return DraggableScrollableSheet(
      // Daha iyi kontrol için DraggableScrollableSheet
      initialChildSize: 0.6, // Başlangıç yüksekliği
      minChildSize: 0.3, // Minimum yükseklik
      maxChildSize: 0.85, // Maksimum yükseklik
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
              color: themeExtension.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                )
              ]),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: themeExtension.textSecondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Başarımlar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeExtension.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: achievements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sentiment_dissatisfied_outlined,
                                size: 48, color: themeExtension.textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz kazanılmış bir başarım yok.\nÖğrenmeye devam et!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: themeExtension.textSecondary,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller:
                            scrollController, // ScrollController'ı ListView'e ata
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: achievements.length,
                        itemBuilder: (context, index) {
                          final achievement = achievements[index];
                          return _buildAchievementItem(
                              achievement, themeExtension);
                        },
                        separatorBuilder: (context, index) => Divider(
                          color: themeExtension.textSecondary.withOpacity(0.1),
                          height: 16,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementItem(
      Achievement achievement, AppThemeExtension themeExtension) {
    final Color iconColor = achievement.isUnlocked
        ? themeExtension.accentColor
        : themeExtension.textSecondary.withOpacity(0.7);
    final Color iconBgColor = achievement.isUnlocked
        ? themeExtension.accentColor.withOpacity(0.15)
        : themeExtension.textSecondary.withOpacity(0.1);

    return Opacity(
      // Kilitli başarımlar için hafif opaklık
      opacity: achievement.isUnlocked ? 1.0 : 0.7,
      child: AdaptiveCard(
        padding: const EdgeInsets.all(12),
        color: achievement.isUnlocked
            ? themeExtension.cardColorLight
            : themeExtension.cardColor,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                achievement.icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: achievement.isUnlocked
                          ? themeExtension.textPrimary
                          : themeExtension.textSecondary.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(
                        fontSize: 12,
                        color: themeExtension.textSecondary,
                        height: 1.3),
                  ),
                  if (!achievement.isUnlocked &&
                      achievement.progress > 0 &&
                      achievement.progress < 1.0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: achievement.progress,
                            backgroundColor:
                                themeExtension.textSecondary.withOpacity(0.2),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(iconColor),
                            minHeight: 5,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(achievement.progress * 100).toInt()}%',
                          style: TextStyle(
                              fontSize: 10,
                              color: iconColor,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (achievement.isUnlocked)
              Icon(
                Icons.check_circle,
                color: themeExtension.positiveColor,
                size: 28,
              )
            else
              Icon(
                Icons.lock_outline,
                color: themeExtension.textSecondary.withOpacity(0.5),
                size: 24,
              )
          ],
        ),
      ),
    );
  }
}
