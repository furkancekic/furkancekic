// optimized_navigation_bars.dart
// lib/widgets/ klasörüne kaydedin

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

// ====================================================================
//  OPTIMIZED QUANTUM NAVIGATION BAR - Performans optimizasyonlu
// ====================================================================
class OptimizedQuantumNavigationBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexSelected;

  const OptimizedQuantumNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onIndexSelected,
  }) : super(key: key);

  @override
  State<OptimizedQuantumNavigationBar> createState() =>
      _OptimizedQuantumNavigationBarState();
}

class _OptimizedQuantumNavigationBarState
    extends State<OptimizedQuantumNavigationBar> with TickerProviderStateMixin {
  late List<AnimationController> _waveControllers;
  late AnimationController _quantumController;
  late List<QuantumParticle> _particles;

  // Görünürlük kontrolü için
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();

    // Sadece 3 wave controller (5 yerine)
    _waveControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: Duration(milliseconds: 2000 + index * 300),
        vsync: this,
      ),
    );

    // Ana animasyon daha yavaş
    _quantumController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Daha az parçacık (15 adet)
    _particles = List.generate(
      15,
      (index) => QuantumParticle(
        position: Offset(
          math.Random().nextDouble(),
          math.Random().nextDouble(),
        ),
        velocity: Offset(
          (math.Random().nextDouble() - 0.5) * 0.005, // Daha yavaş hareket
          (math.Random().nextDouble() - 0.5) * 0.005,
        ),
        phase: math.Random().nextDouble() * 2 * math.pi,
      ),
    );

    // Sadece seçili item için animasyon başlat
    if (widget.currentIndex < _waveControllers.length) {
      _waveControllers[widget.currentIndex].repeat();
    }
    _quantumController.repeat();
  }

  @override
  void didUpdateWidget(OptimizedQuantumNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Eski animasyonu durdur
      if (oldWidget.currentIndex < _waveControllers.length) {
        _waveControllers[oldWidget.currentIndex].stop();
      }
      // Yeni animasyonu başlat
      if (widget.currentIndex < _waveControllers.length) {
        _waveControllers[widget.currentIndex].repeat();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _waveControllers) {
      controller.dispose();
    }
    _quantumController.dispose();
    super.dispose();
  }

  void _updateParticles() {
    if (!_isVisible) return; // Görünmüyorsa güncelleme

    for (var particle in _particles) {
      particle.position += particle.velocity;

      // Basit sınır kontrolü
      if (particle.position.dx < 0 || particle.position.dx > 1) {
        particle.velocity = Offset(-particle.velocity.dx, particle.velocity.dy);
      }
      if (particle.position.dy < 0 || particle.position.dy > 1) {
        particle.velocity = Offset(particle.velocity.dx, -particle.velocity.dy);
      }

      particle.position = Offset(
        particle.position.dx.clamp(0, 1),
        particle.position.dy.clamp(0, 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      QuantumNavItem(Icons.dashboard_rounded, 'Dashboard'), // Index 0 (Home)
      QuantumNavItem(Icons.filter_alt_rounded, 'Filter'), // Index 1 (Screener)
      QuantumNavItem(Icons.show_chart_rounded, 'Charts'), // Index 2 (Chart)
      QuantumNavItem(Icons.science_rounded, 'Lab'), // Index 3 (Backtest)
      QuantumNavItem(Icons.play_circle_rounded, 'Watch'), // Index 4 (Reels)
      QuantumNavItem(
          Icons.school_rounded, 'Learn'), // Index 5 (YENİ - Education)
      QuantumNavItem(Icons.savings_rounded, 'Funds'), // Index 6 (Funds)
      QuantumNavItem(Icons.account_balance_wallet_rounded,
          'Wallet'), // Index 7 (Portfolio)
    ];

    return Container(
      height: 80, // Daha küçük boyut
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Stack(
        children: [
          // Optimize edilmiş quantum field background
          AnimatedBuilder(
            animation: _quantumController,
            builder: (context, child) {
              _updateParticles();
              return CustomPaint(
                size: Size(MediaQuery.of(context).size.width - 40, 80),
                painter: OptimizedQuantumFieldPainter(
                  particles: _particles,
                  animation: _quantumController.value,
                ),
              );
            },
          ),
          // Main navigation
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: Colors.black.withOpacity(0.6),
              border: Border.all(
                width: 1,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter:
                    ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Daha az blur
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(items.length, (index) {
                    final isSelected = widget.currentIndex == index;
                    final hasAnimation = index < _waveControllers.length;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onIndexSelected(index),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isSelected && hasAnimation)
                                AnimatedBuilder(
                                  animation: _waveControllers[index],
                                  builder: (context, child) {
                                    final wave = math.sin(
                                        _waveControllers[index].value *
                                            2 *
                                            math.pi);
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Sadece 1 halka
                                        Transform.scale(
                                          scale: 1 + (wave * 0.2),
                                          child: Container(
                                            width: 35,
                                            height: 35,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.cyan
                                                    .withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          items[index].icon,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ],
                                    );
                                  },
                                )
                              else
                                Icon(
                                  items[index].icon,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white54,
                                  size: isSelected ? 24 : 22,
                                ),
                              if (isSelected) ...[
                                const SizedBox(height: 2),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Colors.cyan,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Optimize edilmiş painter
class OptimizedQuantumFieldPainter extends CustomPainter {
  final List<QuantumParticle> particles;
  final double animation;

  OptimizedQuantumFieldPainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 10); // Daha az blur

    for (var particle in particles) {
      final wave = math.sin(animation * 2 * math.pi + particle.phase);
      final opacity = (wave + 1) / 4; // Daha düşük opacity

      // Basit renk yerine gradient kullanmıyoruz (performans için)
      paint.color = Colors.cyan.withOpacity(opacity * 0.4);

      canvas.drawCircle(
        Offset(
          particle.position.dx * size.width,
          particle.position.dy * size.height,
        ),
        6 + wave * 2, // Daha küçük parçacıklar
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ====================================================================
//  PARTICLE EFFECT NAVIGATION - Aynı ama 7 item için güncellenmiş
// ====================================================================
class ParticleNavigationBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexSelected;

  const ParticleNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onIndexSelected,
  }) : super(key: key);

  @override
  State<ParticleNavigationBar> createState() => _ParticleNavigationBarState();
}

class _ParticleNavigationBarState extends State<ParticleNavigationBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _particleControllers;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particleControllers = List.generate(
      20,
      (index) => AnimationController(
        duration: Duration(milliseconds: 1000 + (index * 100)),
        vsync: this,
      )..repeat(),
    );
    _particles = List.generate(
      20,
      (index) => Particle(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 3 + 1,
        color: Colors.purple.withOpacity(math.Random().nextDouble() * 0.5),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ParticleNavItem(Icons.home_work_rounded, 'Home'), // Index 0
      ParticleNavItem(Icons.manage_search_rounded, 'Search'), // Index 1
      ParticleNavItem(Icons.analytics_rounded, 'Analytics'), // Index 2
      ParticleNavItem(Icons.biotech_rounded, 'Test'), // Index 3
      ParticleNavItem(Icons.movie_filter_rounded, 'Reels'), // Index 4
      ParticleNavItem(
          Icons.school_outlined, 'Edu'), // Index 5 (YENİ - Education)
      ParticleNavItem(Icons.monetization_on_rounded, 'Money'), // Index 6
      ParticleNavItem(Icons.pie_chart_rounded, 'Port'), // Index 7
    ];

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Stack(
        children: [
          // Background with particles
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade900,
                    Colors.black,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: List.generate(_particles.length, (index) {
                  return AnimatedBuilder(
                    animation: _particleControllers[index],
                    builder: (context, child) {
                      final particle = _particles[index];
                      return Positioned(
                        left: particle.x * MediaQuery.of(context).size.width,
                        top: (particle.y + _particleControllers[index].value) %
                            1.0 *
                            80,
                        child: Container(
                          width: particle.size,
                          height: particle.size,
                          decoration: BoxDecoration(
                            color: particle.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ),
          // Navigation items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final isSelected = widget.currentIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onIndexSelected(index),
                  behavior: HitTestBehavior.opaque,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: isSelected ? 1 : 0,
                    ),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, value, child) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.purple.withOpacity(value * 0.5),
                            width: 1.5,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.withOpacity(value * 0.3),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              items[index].icon,
                              color: Color.lerp(
                                Colors.grey.shade500,
                                Colors.white,
                                value,
                              ),
                              size: 22 + (value * 2),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 2),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.purple,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// Model sınıfları
class QuantumParticle {
  Offset position;
  Offset velocity;
  final double phase;

  QuantumParticle({
    required this.position,
    required this.velocity,
    required this.phase,
  });
}

class Particle {
  final double x;
  final double y;
  final double size;
  final Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
  });
}

class ParticleNavItem {
  final IconData icon;
  final String label;
  ParticleNavItem(this.icon, this.label);
}

class QuantumNavItem {
  final IconData icon;
  final String label;
  QuantumNavItem(this.icon, this.label);
}

// ====================================================================
//  SIMPLE NAVIGATION PROVIDER - Basit state yönetimi
// ====================================================================
class SimpleNavigationProvider extends ChangeNotifier {
  bool _isQuantumMode = true;

  bool get isQuantumMode => _isQuantumMode;

  void toggleMode() {
    _isQuantumMode = !_isQuantumMode;
    notifyListeners();
  }

  void setMode(bool isQuantum) {
    if (_isQuantumMode != isQuantum) {
      _isQuantumMode = isQuantum;
      notifyListeners();
    }
  }
}

// ====================================================================
//  NAVIGATION BAR WITH SWITCH - Switch butonlu konteyner
// ====================================================================
class NavigationBarWithSwitch extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexSelected;

  const NavigationBarWithSwitch({
    Key? key,
    required this.currentIndex,
    required this.onIndexSelected,
  }) : super(key: key);

  @override
  State<NavigationBarWithSwitch> createState() =>
      _NavigationBarWithSwitchState();
}

class _NavigationBarWithSwitchState extends State<NavigationBarWithSwitch> {
  bool _isQuantumMode = true; // true: Quantum, false: Particle

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Navigation Bar
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(0, 0.1), end: Offset.zero),
                ),
                child: child,
              ),
            );
          },
          child: _isQuantumMode
              ? OptimizedQuantumNavigationBar(
                  key: const ValueKey('quantum'),
                  currentIndex: widget.currentIndex,
                  onIndexSelected: widget.onIndexSelected,
                )
              : ParticleNavigationBar(
                  key: const ValueKey('particle'),
                  currentIndex: widget.currentIndex,
                  onIndexSelected: widget.onIndexSelected,
                ),
        ),
        // Switch Button - Daha görünür konum
        Positioned(
          left: 0,
          right: 0,
          bottom: 100, // Navigation bar'ın hemen üstünde
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _isQuantumMode ? Colors.cyan : Colors.purple,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isQuantumMode ? Colors.cyan : Colors.purple)
                        .withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSwitchButton(
                    icon: Icons.blur_on,
                    isSelected: _isQuantumMode,
                    onTap: () => setState(() => _isQuantumMode = true),
                  ),
                  const SizedBox(width: 4),
                  _buildSwitchButton(
                    icon: Icons.scatter_plot,
                    isSelected: !_isQuantumMode,
                    onTap: () => setState(() => _isQuantumMode = false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected
              ? (_isQuantumMode ? Colors.cyan : Colors.purple).withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: isSelected
                ? (_isQuantumMode ? Colors.cyan : Colors.purple)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white54,
          size: 24,
        ),
      ),
    );
  }
}
