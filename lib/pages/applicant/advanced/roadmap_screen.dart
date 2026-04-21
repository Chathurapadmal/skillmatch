import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../../services/ai_service.dart';
import '../../../widgets/common_widgets.dart';

class RoadmapScreen extends StatefulWidget {
  final String field;
  const RoadmapScreen({super.key, required this.field});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  Map<String, dynamic>? _roadmap;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final roadmap = await AiService.generateLearningRoadmap(widget.field);
      if (mounted) {
        setState(() {
          _roadmap = roadmap;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _roadmap = {};
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roadmap = _roadmap ?? {};
    final steps = (roadmap['steps'] as List?) ?? [];
    final missing = (roadmap['missingSkills'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('${widget.field} Roadmap'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: roadmap.isEmpty
                  ? const Text(
                      'Could not generate roadmap.',
                      style: TextStyle(color: Colors.grey),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔥 TARGET CARD (small improvement: shadow)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFDCE3F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: const [
                                Text('🎯', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 8),
                                Text('RECOMMENDED TARGET ROLE',
                                    style: TextStyle(
                                        color: Color(0xFF1565C0),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2)),
                              ]),
                              const SizedBox(height: 8),
                              Text(
                                roadmap['targetRole']?.toString() ??
                                    'Learning Path',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                roadmap['targetCompany']?.toString() ?? '',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 14),

                              // 🔥 centered row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _matchPill(
                                      'Current Match',
                                      '${roadmap['currentMatch'] ?? 0}%',
                                      AppTheme.warning),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.arrow_forward,
                                      color: Colors.black38, size: 18),
                                  const SizedBox(width: 10),
                                  _matchPill(
                                      'Target',
                                      '${roadmap['targetMatch'] ?? 100}%',
                                      AppTheme.success),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fade(),
                        const SizedBox(height: 24),

                        // 🔥 FOCUS AREAS (spacing improved)
                        if (missing.isNotEmpty) ...[
                          const Text('Focus Areas',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: missing
                                .map((s) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF2FF),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: const Color(0xFFCDE1FF)),
                                      ),
                                      child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.stars_outlined,
                                                color: AppTheme.info, size: 12),
                                            const SizedBox(width: 4),
                                            Text(s,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF1565C0))),
                                          ]),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 🔥 STEPS
                        const Text('Your Learning Path',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 14),

                        ...steps.asMap().entries.map((e) {
                          final step = e.value as Map;
                          final isProject = step['title']
                              .toString()
                              .toLowerCase()
                              .contains('project');

                          return _StepCard(
                            index: e.key + 1,
                            step: step,
                            isProject: isProject,
                            isLast: e.key == steps.length - 1,
                          )
                              .animate(
                                  delay: Duration(milliseconds: e.key * 100))
                              .fade()
                              .slideX(begin: -0.08);
                        }),

                        const SizedBox(height: 28),

                        GradientButton(
                          label: 'Regenerate Path',
                          onTap: _loadData,
                          icon: Icons.refresh,
                        ).animate(delay: 600.ms).fade(),
                      ],
                    ),
            ),
    );
  }

  Widget _matchPill(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.black54, fontSize: 10)),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

// 🔥 STEP CARD (minimal improvements only)
class _StepCard extends StatelessWidget {
  final int index;
  final Map step;
  final bool isProject;
  final bool isLast;

  const _StepCard({
    required this.index,
    required this.step,
    required this.isProject,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            width: 38, // slightly bigger
            height: 38,
            decoration: BoxDecoration(
              gradient: isProject
                  ? AppTheme.primaryGradient
                  : const LinearGradient(
                      colors: [Color(0xFF1E1B4B), Color(0xFF2D1B69)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text('$index',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),

          // 🔥 FIXED LINE
          if (!isLast)
            Container(
              width: 2,
              height: 60,
              color: Colors.grey.shade300,
            ),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color:
                  isProject ? AppTheme.primary.withOpacity(0.10) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isProject
                    ? AppTheme.primary.withOpacity(0.2)
                    : const Color(0xFFDCE3F0),
              ),
              boxShadow: isProject
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isProject)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'SIMULATED PROJECT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Text(step['title'] ?? 'Step',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(step['description'] ?? '',
                    style: const TextStyle(
                        fontSize: 12, height: 1.5, color: Colors.black54)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
