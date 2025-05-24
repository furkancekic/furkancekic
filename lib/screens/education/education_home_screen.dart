// screens/education/education_home_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'education_category_screen.dart';
import 'models/education_models.dart';

class EducationHomeScreen extends StatefulWidget {
  const EducationHomeScreen({Key? key}) : super(key: key);

  @override
  State<EducationHomeScreen> createState() => _EducationHomeScreenState();
}

class _EducationHomeScreenState extends State<EducationHomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<EducationCategory> _categories = [
    EducationCategory(
      id: 'basics',
      title: 'Yatırım Temelleri',
      description: 'Hisse senedi yatırımının temel kavramları',
      icon: Icons.school,
      color: const Color(0xFF4CAF50),
      difficulty: Difficulty.beginner,
      estimatedTime: '45 dk',
      lessons: 8,
      completedLessons: 0,
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
    EducationCategory(
      id: 'indicators',
      title: 'Teknik Göstergeler',
      description: 'RSI, MACD, Bollinger ve diğer göstergeler',
      icon: Icons.show_chart,
      color: const Color(0xFF9C27B0),
      difficulty: Difficulty.advanced,
      estimatedTime: '1.5 saat',
      lessons: 10,
      completedLessons: 0,
      topics: [
        'Momentum Göstergeleri',
        'Trend Göstergeleri',
        'Volatilite Göstergeleri',
        'Hacim Göstergeleri',
      ],
    ),
    EducationCategory(
      id: 'portfolio',
      title: 'Portföy Yönetimi',
      description: 'Risk yönetimi ve portföy çeşitlendirme',
      icon: Icons.pie_chart,
      color: const Color(0xFFE91E63),
      difficulty: Difficulty.advanced,
      estimatedTime: '1 saat',
      lessons: 8,
      completedLessons: 0,
      topics: [
        'Çeşitlendirme',
        'Risk Yönetimi',
        'Pozisyon Boyutlama',
        'Rebalancing',
      ],
    ),
    EducationCategory(
      id: 'strategies',
      title: 'Yatırım Stratejileri',
      description: 'Farklı yatırım yaklaşımları ve stratejiler',
      icon: Icons.psychology,
      color: const Color(0xFF795548),
      difficulty: Difficulty.expert,
      estimatedTime: '2.5 saat',
      lessons: 12,
      completedLessons: 0,
      topics: [
        'Değer Yatırımı',
        'Büyüme Yatırımı',
        'Swing Trading',
        'Day Trading',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    // final isDark = themeExtension?.isDark ?? true; // isDark is not used

    return Container(
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
            // Header
            _buildHeader(context),
            
            // Progress Overview
            _buildProgressOverview(context),
            
            // Categories Grid
            Expanded(
              child: _buildCategoriesGrid(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: themeExtension?.gradientColors ?? [
                      AppTheme.primaryColor,
                      AppTheme.accentColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yatırım Akademisi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Adım adım öğren, bilinçli yatırım yap',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showAchievements(context),
                icon: const Icon(
                  Icons.emoji_events,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(BuildContext context) {
    final totalLessons = _categories.fold<int>(0, (sum, cat) => sum + cat.lessons);
    final completedLessons = _categories.fold<int>(0, (sum, cat) => sum + cat.completedLessons);
    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AdaptiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Genel İlerleme',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildProgressStat('Tamamlanan', '$completedLessons'),
                const SizedBox(width: 24),
                _buildProgressStat('Toplam', '$totalLessons'),
                const Spacer(),
                const Icon(Icons.trending_up, color: AppTheme.positiveColor, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
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

  Widget _buildCategoriesGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(context, category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, EducationCategory category) {
    final progress = category.lessons > 0 ? category.completedLessons / category.lessons : 0.0;
    // final themeExtension = Theme.of(context).extension<AppThemeExtension>(); // Not used here
    
    return AdaptiveCard(
      onTap: () => _navigateToCategory(context, category),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and difficulty
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 20,
                ),
              ),
              const Spacer(),
              _buildDifficultyBadge(category.difficulty),
            ],
          ),
          const SizedBox(height: 12),
          
          // Title and description
          Text(
            category.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            category.description,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          // Progress
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(category.color),
            minHeight: 4,
          ),
          const SizedBox(height: 8),
          
          // Stats
          Row(
            children: [
              Icon(Icons.schedule, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                category.estimatedTime,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${category.completedLessons}/${category.lessons}',
                style: TextStyle(
                  fontSize: 10,
                  color: category.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(Difficulty difficulty) {
    // MODIFICATION START: Replaced Dart 3 pattern destructuring from switch expression
    // with a traditional switch statement for broader compatibility.
    String text;
    Color color;

    switch (difficulty) {
      case Difficulty.beginner:
        text = 'Başlangıç';
        color = AppTheme.positiveColor;
        break;
      case Difficulty.intermediate:
        text = 'Orta';
        color = AppTheme.warningColor;
        break;
      case Difficulty.advanced:
        text = 'İleri';
        color = AppTheme.negativeColor;
        break;
      case Difficulty.expert:
        text = 'Uzman';
        color = const Color(0xFF9C27B0);
        break;
      // No default case is needed if Difficulty is an enum and all cases are covered.
      // The Dart compiler will enforce definite assignment for 'text' and 'color'.
    }
    // MODIFICATION END

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2), // Uses the 'color' variable defined above
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text, // Uses the 'text' variable defined above
        style: TextStyle(
          fontSize: 8,
          color: color, // Uses the 'color' variable defined above
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
    );
  }

  void _showAchievements(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AchievementsSheet(),
    );
  }
}

// Achievement system
class AchievementsSheet extends StatelessWidget {
  const AchievementsSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final achievements = [
      Achievement(
        id: 'first_lesson',
        title: 'İlk Adım',
        description: 'İlk dersi tamamladın!',
        icon: Icons.play_arrow,
        isUnlocked: true,
        progress: 1.0,
      ),
      Achievement(
        id: 'technical_master',
        title: 'Teknik Analiz Ustası',
        description: 'Tüm teknik analiz derslerini bitir',
        icon: Icons.trending_up,
        isUnlocked: false,
        progress: 0.3,
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor, // Assuming AppTheme.backgroundColor is dark for this context
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          // Title
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Başarımlar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          
          // Achievements list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return _buildAchievementItem(achievement);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdaptiveCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: achievement.isUnlocked 
                    ? AppTheme.accentColor.withOpacity(0.2)
                    : AppTheme.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                achievement.icon,
                color: achievement.isUnlocked 
                    ? AppTheme.accentColor 
                    : AppTheme.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: achievement.isUnlocked 
                          ? AppTheme.textPrimary 
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (!achievement.isUnlocked && achievement.progress > 0) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: achievement.progress,
                      backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                      minHeight: 4,
                    ),
                  ],
                ],
              ),
            ),
            if (achievement.isUnlocked)
              const Icon(
                Icons.check_circle,
                color: AppTheme.positiveColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}