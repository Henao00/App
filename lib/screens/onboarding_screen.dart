import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

/// Introducción de 3 pasos que se muestra solo la primera vez.
///
/// Reduce la fricción del usuario nuevo explicando las 3 acciones clave:
/// configurar precios, cotizar y compartir.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    (
      icon: '👋',
      title: 'Bienvenido a T&M',
      text: 'Cotiza materiales de construcción en segundos y envía una cotización profesional por WhatsApp o PDF.',
    ),
    (
      icon: '🧱',
      title: 'Arma tu lista',
      text: 'Elige materiales del catálogo, ajusta cantidades y el grosor del porón. También puedes crear tus propios materiales.',
    ),
    (
      icon: '💾',
      title: 'Guarda y comparte',
      text: 'Cada cotización queda en tu historial con su estado (borrador, enviada, aceptada) lista para reutilizar.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onDone,
                child: const Text('Saltar', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Center(child: Text(s.icon, style: const TextStyle(fontSize: 64))),
                        ),
                        const SizedBox(height: 40),
                        Text(s.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.syne(fontSize: 26, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 14),
                        Text(s.text,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                                fontSize: 15, height: 1.5, color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primary : AppTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: TmButton(
                label: last ? 'Comenzar' : 'Siguiente',
                icon: last ? Icons.check_rounded : Icons.arrow_forward_rounded,
                fullWidth: true,
                onPressed: () {
                  if (last) {
                    widget.onDone();
                  } else {
                    _controller.nextPage(
                        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
