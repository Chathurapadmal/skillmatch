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
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
          title: Text('${widget.field} Roadmap'),
          backgroundColor: AppTheme.bgDark),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: roadmap.isEmpty
                  ? const Text('Could not generate roadmap.',
                      style: TextStyle(color: AppTheme.textMuted))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Target card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF1A0B35), Color(0xFF2D1B69)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: AppTheme.accent.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Text('🎯',
                                    style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                const Text('RECOMMENDED TARGET ROLE',
                                    style: TextStyle(
                                        color: AppTheme.accentLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2)),
                              ]),
                              const SizedBox(height: 8),
                              Text(
                                  roadmap['targetRole']?.toString() ??
                                      'Learning Path',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              Text(roadmap['targetCompany']?.toString() ?? '',
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 13)),
                              const SizedBox(height: 14),
                              Row(children: [
                                _matchPill(
                                    'Current Match',
                                    '${roadmap['currentMatch'] ?? 0}%',
                                    AppTheme.warning),
                                const SizedBox(width: 10),
                                const Icon(Icons.arrow_forward,
                                    color: Colors.white38, size: 18),
                                const SizedBox(width: 10),
                                _matchPill(
                                    'Target',
                                    '${roadmap['targetMatch'] ?? 100}%',
                                    AppTheme.success),
                              ]),
                            ],
                          ),
                        ).animate().fade(),
                        const SizedBox(height: 24),

                        // Missing skills
                        if (missing.isNotEmpty) ...[
                          const Text('Focus Areas',
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: missing
                                .map((s) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.info.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color:
                                                AppTheme.info.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.stars_outlined,
                                                color: AppTheme.info, size: 12),
                                            const SizedBox(width: 4),
                                            Text(s,
                                                style: const TextStyle(
                                                    color: AppTheme.info,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ]),
                                    ))
                                .toList(),
                          ).animate(delay: 100.ms).fade(),
                          const SizedBox(height: 24),
                        ],

                        // Roadmap steps
                        const Text('Your Learning Path',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
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
                                  isProject: isProject)
                              .animate(
                                  delay: Duration(milliseconds: e.key * 100))
                              .fade()
                              .slideX(begin: -0.08, end: 0);
                        }),
                        const SizedBox(height: 20),
                        GradientButton(
                                label: 'Regenerate Path',
                                onTap: _loadData,
                                icon: Icons.refresh)
                            .animate(delay: 600.ms)
                            .fade(),
                      ],
                    ),
            ),
    );
  }

  Widget _matchPill(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _StepCard extends StatelessWidget {
  final int index;
  final Map step;
  final bool isProject;
  const _StepCard(
      {required this.index, required this.step, required this.isProject});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        Column(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: isProject
                  ? AppTheme.primaryGradient
                  : const LinearGradient(
                      colors: [Color(0xFF1E1B4B), Color(0xFF2D1B69)]),
              shape: BoxShape.circle,
              border: Border.all(
                  color: isProject
                      ? AppTheme.primary
                      : AppTheme.accent.withOpacity(0.3)),
            ),
            child: Center(
                child: Text('$index',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14))),
          ),
          if (index < 5)
            Container(width: 2, height: 50, color: const Color(0xFF2D2D5E)),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isProject
                  ? AppTheme.primary.withOpacity(0.08)
                  : AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isProject
                      ? AppTheme.primary.withOpacity(0.2)
                      : const Color(0xFF2D2D5E)),
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
                        borderRadius: BorderRadius.circular(5)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.build_circle_outlined,
                          color: AppTheme.primaryLight, size: 11),
                      SizedBox(width: 3),
                      Text('SIMULATED PROJECT',
                          style: TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                    ]),
                  ),
                Text(step['title']?.toString() ?? 'Step',
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(step['description']?.toString() ?? 'Details...',
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.5)),
                if (step['duration'] != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.access_time,
                        color: AppTheme.textMuted, size: 13),
                    const SizedBox(width: 4),
                    Text(step['duration'] as String,
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12)),
                  ]),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }
}
