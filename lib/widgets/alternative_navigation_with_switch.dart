// alternative_navigation_with_switch.dart
// Switch'i navigation bar'a entegre eden alternatif tasarım

import 'package:flutter/material.dart';
import 'dart:async';
import 'optimized_navigation_bars.dart';

class NavigationBarWithIntegratedSwitch extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexSelected;

  const NavigationBarWithIntegratedSwitch({
    Key? key,
    required this.currentIndex,
    required this.onIndexSelected,
  }) : super(key: key);

  @override
  State<NavigationBarWithIntegratedSwitch> createState() =>
      _NavigationBarWithIntegratedSwitchState();
}

class _NavigationBarWithIntegratedSwitchState
    extends State<NavigationBarWithIntegratedSwitch> {
  bool _isQuantumMode = true;
  bool _showSwitch = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showSwitch = false;
        });
      }
    });
  }

  void _showSwitchTemporarily() {
    setState(() {
      _showSwitch = true;
    });
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Switch Container - Navigation bar'ın üstünde
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _showSwitch ? 50 : 0,
          margin: EdgeInsets.only(bottom: _showSwitch ? 5 : 0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _showSwitch ? 1.0 : 0.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Switch göstergesi
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isQuantumMode ? Colors.cyan : Colors.purple,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Quantum',
                        style: TextStyle(
                          color: _isQuantumMode ? Colors.cyan : Colors.white54,
                          fontSize: 12,
                          fontWeight: _isQuantumMode
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Animasyonlu switch
                      GestureDetector(
                        onTap: () {
                          setState(() => _isQuantumMode = !_isQuantumMode);
                          _startHideTimer(); // Switch'e tıklandığında timer'ı yenile
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 50,
                          height: 26,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            gradient: LinearGradient(
                              colors: _isQuantumMode
                                  ? [
                                      Colors.cyan.withOpacity(0.3),
                                      Colors.cyan.withOpacity(0.5)
                                    ]
                                  : [
                                      Colors.purple.withOpacity(0.3),
                                      Colors.purple.withOpacity(0.5)
                                    ],
                            ),
                            border: Border.all(
                              color:
                                  _isQuantumMode ? Colors.cyan : Colors.purple,
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                left: _isQuantumMode ? 2 : 24,
                                top: 2,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isQuantumMode
                                        ? Colors.cyan
                                        : Colors.purple,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isQuantumMode
                                                ? Colors.cyan
                                                : Colors.purple)
                                            .withOpacity(0.5),
                                        blurRadius: 5,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Particle',
                        style: TextStyle(
                          color:
                              !_isQuantumMode ? Colors.purple : Colors.white54,
                          fontSize: 12,
                          fontWeight: !_isQuantumMode
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Navigation Bar with gesture detector
        GestureDetector(
          onLongPress: _showSwitchTemporarily, // Uzun basınca switch'i göster
          child: AnimatedSwitcher(
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
        ),
      ],
    );
  }
}

// Daha da basit versiyon - Floating Action Button olarak
class NavigationBarWithFABSwitch extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexSelected;

  const NavigationBarWithFABSwitch({
    Key? key,
    required this.currentIndex,
    required this.onIndexSelected,
  }) : super(key: key);

  @override
  State<NavigationBarWithFABSwitch> createState() =>
      _NavigationBarWithFABSwitchState();
}

class _NavigationBarWithFABSwitchState
    extends State<NavigationBarWithFABSwitch> {
  bool _isQuantumMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const SizedBox.shrink(), // HomeScreen body'si burada olacak
      bottomNavigationBar: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
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
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton.small(
          backgroundColor: _isQuantumMode ? Colors.cyan : Colors.purple,
          onPressed: () => setState(() => _isQuantumMode = !_isQuantumMode),
          child: Icon(
            _isQuantumMode ? Icons.blur_on : Icons.scatter_plot,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
