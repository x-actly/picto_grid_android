import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        // Responsive Layout für alle Orientierungen
        final isPortrait = orientation == Orientation.portrait;
        final screenSize = MediaQuery.of(context).size;
        
        return Scaffold(
          backgroundColor: const Color(0xFF7DDBD4), // Mint/Teal background wie im Bild
          body: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenSize.height * 0.8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            // Logo und Hauptbild
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          // Hauptlogo Text
                          const Text(
                            'Picto Grid',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // Tablet Mockup - responsive Größe
                          Container(
                            width: isPortrait ? 250 : 300,
                            height: isPortrait ? 320 : 400,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Tablet Header
                                Container(
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF7DDBD4),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 20),
                                        child: Icon(
                                          Icons.arrow_back_ios,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Spacer(),
                                      Padding(
                                        padding: EdgeInsets.only(right: 20),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Grid Area - responsive
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.all(isPortrait ? 15 : 20),
                                    child: GridView.builder(
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isPortrait ? 2 : 3,
                                        crossAxisSpacing: isPortrait ? 6 : 8,
                                        mainAxisSpacing: isPortrait ? 6 : 8,
                                      ),
                                      itemCount: isPortrait ? 8 : 12,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.grey,
                                            size: 24,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                
                                // Home Button
                                Container(
                                  height: 40,
                                  child: const Center(
                                    child: CircleAvatar(
                                      radius: 15,
                                      backgroundColor: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 40),
            
            // Loading Indicator
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: isPortrait ? 15 : 20),
                  Text(
                    'Piktogramme werden geladen...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: isPortrait ? 14 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 