import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';
import '../../widgets/common_widgets.dart';

class SkillVerificationScreen extends StatefulWidget {
  final String? field;
  const SkillVerificationScreen({super.key, this.field});

  @override
  State<SkillVerificationScreen> createState() =>
      _SkillVerificationScreenState();
}

class _SkillVerificationScreenState extends State<SkillVerificationScreen> {
  final Map<String, List<_QuizQuestion>> _quizBank = {
    'Flutter': [
      _QuizQuestion(
          q: 'What is the base class for all Flutter widgets?',
          options: [
            'StatelessWidget',
            'Widget',
            'RenderObject',
            'BuildContext'
          ],
          correct: 1),
      _QuizQuestion(
          q: 'Which method is called when a StatefulWidget rebuilds?',
          options: ['initState', 'build', 'dispose', 'setState'],
          correct: 1),
      _QuizQuestion(
          q: 'What does `const` mean in Flutter widget constructors?',
          options: [
            'The widget is stateful',
            'The widget is compiled at runtime',
            'The widget is built at compile time (immutable)',
            'The widget cannot have children'
          ],
          correct: 2),
    ],
    'Dart': [
      _QuizQuestion(
          q: 'Which keyword is used for asynchronous operations in Dart?',
          options: ['sync', 'async', 'await only', 'future'],
          correct: 1),
      _QuizQuestion(
          q: 'What is the correct way to declare a nullable String in Dart?',
          options: [
            'String?',
            'nullable String',
            'String | null',
            'Optional<String>'
          ],
          correct: 0),
      _QuizQuestion(
          q: 'Which collection type in Dart is ordered and allows duplicates?',
          options: ['Set', 'Map', 'List', 'Queue'],
          correct: 2),
    ],
    'Python': [
      _QuizQuestion(
          q: 'What does `len([1,2,3])` return?',
          options: ['2', '3', '4', 'Error'],
          correct: 1),
      _QuizQuestion(
          q: 'Which keyword creates a generator in Python?',
          options: ['generate', 'yield', 'async', 'return'],
          correct: 1),
      _QuizQuestion(
          q: 'What is the output of `type(3.14)` in Python?',
          options: [
            "<class 'int'>",
            "<class 'float'>",
            "<class 'double'>",
            "<class 'number'>"
          ],
          correct: 1),
    ],
    'JavaScript': [
      _QuizQuestion(
          q: 'What does `===` check in JavaScript?',
          options: [
            'Value equality only',
            'Reference equality only',
            'Value and type equality',
            'Deep equality'
          ],
          correct: 2),
      _QuizQuestion(
          q: 'Which method converts a JSON string to a JS object?',
          options: [
            'JSON.stringify()',
            'JSON.parse()',
            'JSON.convert()',
            'JSON.decode()'
          ],
          correct: 1),
      _QuizQuestion(
          q: 'What is a closure in JavaScript?',
          options: [
            'A function that returns void',
            'A block of code that runs once',
            'A function with access to its outer scope variables',
            'A sealed class'
          ],
          correct: 2),
    ],
    'SQL': [
      _QuizQuestion(
          q: 'Which SQL clause filters results after GROUP BY?',
          options: ['WHERE', 'HAVING', 'FILTER', 'AND'],
          correct: 1),
      _QuizQuestion(
          q: 'What type of JOIN returns all rows from the left table?',
          options: ['INNER JOIN', 'RIGHT JOIN', 'LEFT JOIN', 'CROSS JOIN'],
          correct: 2),
      _QuizQuestion(
          q: 'Which keyword removes duplicate rows in SELECT results?',
          options: ['UNIQUE', 'DISTINCT', 'CLEAN', 'FILTER'],
          correct: 1),
    ],
  };

  String? _activeSkill;
  int _currentQ = 0;
  int _score = 0;
  bool _quizDone = false;
  bool _generatingQuiz = false;
  int? _selectedAnswer;
  bool _answered = false;
  String _industry = 'IT & Software';
  List<String> _verifiedSkills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVerifiedSkills();
  }

  Future<void> _loadVerifiedSkills() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final profile = await FirestoreService.getUserProfile(uid);
    if (mounted) {
      setState(() {
        final raw = profile?['verifiedSkills'] as List? ?? [];
        _verifiedSkills = raw.map((s) => s.toString()).toList();
        _industry = (widget.field ??
                    (profile?['industry'] as String?) ??
                    (profile?['field'] as String?) ??
                    'IT & Software')
                .trim()
                .isNotEmpty
            ? (widget.field ??
                (profile?['industry'] as String?) ??
                (profile?['field'] as String?) ??
                'IT & Software')
            : 'IT & Software';
        _loading = false;
      });
    }
  }

  Future<void> _startQuiz(String skill) async {
    setState(() {
      _activeSkill = skill;
      _currentQ = 0;
      _score = 0;
      _quizDone = false;
      _selectedAnswer = null;
      _answered = false;
      _generatingQuiz = true;
    });

    final aiQuiz = await AiService.generateSkillQuiz(
      field: _industry,
      skill: skill,
      questionCount: 5,
    );
    final questionsRaw = aiQuiz['questions'];

    if (questionsRaw is List && questionsRaw.isNotEmpty) {
      final parsed = <_QuizQuestion>[];
      for (final item in questionsRaw) {
        if (item is! Map) continue;
        final questionText = (item['q'] ?? '').toString().trim();
        final options =
            ((item['options'] as List?) ?? const []).map((e) => '$e').toList();
        final correct = int.tryParse('${item['correct']}') ?? 0;

        if (questionText.isEmpty || options.length < 4) continue;
        parsed.add(
          _QuizQuestion(
            q: questionText,
            options: options.take(4).toList(),
            correct: correct.clamp(0, 3),
          ),
        );
      }

      if (parsed.length >= 3) {
        _quizBank[skill] = parsed;
      }
    }

    if (mounted) {
      setState(() => _generatingQuiz = false);
    }
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    final questions = _quizBank[_activeSkill]!;
    final isCorrect = index == questions[_currentQ].correct;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (isCorrect) _score++;
    });
  }

  void _nextQuestion() {
    final questions = _quizBank[_activeSkill]!;
    if (_currentQ < questions.length - 1) {
      setState(() {
        _currentQ++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      setState(() => _quizDone = true);
      _finalizeQuiz();
    }
  }

  Future<void> _finalizeQuiz() async {
    final questions = _quizBank[_activeSkill]!;
    final passed = _score >= (questions.length * 0.7).ceil();
    if (passed && !_verifiedSkills.contains(_activeSkill)) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final updated = [..._verifiedSkills, _activeSkill!];
        final profile = await FirestoreService.getUserProfile(uid);
        final rawSkills =
            ((profile?['skills'] as List?) ?? []).map((e) => '$e').toList();
        final mergedSkills = <String>{...rawSkills, ...updated}.toList();

        await FirestoreService.updateUserProfile(uid, {
          'skills': mergedSkills,
          'verifiedSkills': updated,
        });
        if (mounted) setState(() => _verifiedSkills = updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Skill Verification'),
        backgroundColor: AppTheme.bgDark,
        leading: _activeSkill != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _activeSkill = null;
                  _quizDone = false;
                }),
              )
            : null,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _activeSkill == null
              ? _buildSkillPicker()
              : _generatingQuiz
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _quizDone
                      ? _buildResult()
                      : _buildQuiz(),
    );
  }

  Widget _buildSkillPicker() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Verify Your Skills',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
              'Pass an AI-generated industry-based quiz to add a verified skill badge to your profile.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Industry: $_industry',
              style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          if (_verifiedSkills.isNotEmpty) ...[
            const Text('Verified Skills',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _verifiedSkills
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.success.withOpacity(0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.verified,
                              color: AppTheme.success, size: 13),
                          const SizedBox(width: 5),
                          Text(s,
                              style: const TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ))
                  .toList(),
            ).animate().fade(),
            const SizedBox(height: 24),
          ],
          const Text('Available Tests',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._quizBank.entries.map((entry) {
            final skill = entry.key;
            final alreadyVerified = _verifiedSkills.contains(skill);
            final questions = entry.value;
            return GestureDetector(
              onTap: () async => _startQuiz(skill),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: alreadyVerified
                      ? AppTheme.success.withOpacity(0.07)
                      : AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: alreadyVerified
                        ? AppTheme.success.withOpacity(0.25)
                        : const Color(0xFF2D2D5E),
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(_skillEmoji(skill),
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(skill,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${questions.length} questions · ~3 min',
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (alreadyVerified)
                    const Icon(Icons.verified,
                        color: AppTheme.success, size: 22)
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Start',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                ]),
              ),
            )
                .animate(
                    delay: Duration(
                        milliseconds:
                            _quizBank.keys.toList().indexOf(skill) * 60))
                .fade()
                .slideX(begin: -0.05, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    final skill = _activeSkill!;
    final questions = _quizBank[skill]!;
    final q = questions[_currentQ];
    final progress = (_currentQ + 1) / questions.length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          Row(children: [
            Text('$skill Quiz',
                style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${_currentQ + 1} / ${questions.length}',
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF2D2D5E),
            valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 28),

          // Question
          Text('Q${_currentQ + 1}.',
              style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(q.q,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.4)),
          const SizedBox(height: 24),

          // Options
          ...q.options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final isSelected = _selectedAnswer == idx;
            final isCorrect = idx == q.correct;
            Color borderColor = const Color(0xFF2D2D5E);
            Color bgColor = AppTheme.bgCard;
            if (_answered) {
              if (isCorrect) {
                borderColor = AppTheme.success;
                bgColor = AppTheme.success.withOpacity(0.12);
              } else if (isSelected && !isCorrect) {
                borderColor = AppTheme.error;
                bgColor = AppTheme.error.withOpacity(0.1);
              }
            } else if (isSelected) {
              borderColor = AppTheme.primary;
              bgColor = AppTheme.primary.withOpacity(0.1);
            }
            return GestureDetector(
              onTap: () => _selectAnswer(idx),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withOpacity(0.2)
                          : AppTheme.bgDark,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : const Color(0xFF2D2D5E)),
                    ),
                    child: Center(
                      child: Text(String.fromCharCode(65 + idx),
                          style: TextStyle(
                              color: isSelected
                                  ? AppTheme.primaryLight
                                  : AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(opt,
                        style: TextStyle(
                            color: _answered && isCorrect
                                ? AppTheme.success
                                : AppTheme.textPrimary,
                            fontSize: 13)),
                  ),
                  if (_answered && isCorrect)
                    const Icon(Icons.check_circle,
                        color: AppTheme.success, size: 18),
                  if (_answered && isSelected && !isCorrect)
                    const Icon(Icons.cancel, color: AppTheme.error, size: 18),
                ]),
              ),
            );
          }),

          const Spacer(),
          if (_answered)
            GradientButton(
              label: _currentQ < questions.length - 1
                  ? 'Next Question'
                  : 'See Results',
              onTap: _nextQuestion,
              icon: Icons.arrow_forward,
            ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final skill = _activeSkill!;
    final questions = _quizBank[skill]!;
    final passed = _score >= (questions.length * 0.7).ceil();
    final pct = (_score / questions.length * 100).round();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(passed ? '🏆' : '📚', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(passed ? 'Skill Verified!' : 'Not Quite Yet',
                style: TextStyle(
                    color: passed ? AppTheme.success : AppTheme.warning,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('You scored $pct% on the $skill quiz',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('$_score out of ${questions.length} correct',
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 24),
            if (passed)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.verified, color: AppTheme.success, size: 18),
                  SizedBox(width: 8),
                  Text('Added to profile',
                      style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            const SizedBox(height: 32),
            GradientButton(
              label: 'Back to Skills',
              onTap: () => setState(() {
                _activeSkill = null;
                _quizDone = false;
              }),
              icon: Icons.arrow_back,
            ),
          ],
        ).animate().fade().scale(begin: const Offset(0.9, 0.9)),
      ),
    );
  }

  String _skillEmoji(String skill) {
    switch (skill) {
      case 'Flutter':
        return '🦋';
      case 'Dart':
        return '🎯';
      case 'Python':
        return '🐍';
      case 'JavaScript':
        return '🌐';
      case 'SQL':
        return '🗄️';
      default:
        return '💡';
    }
  }
}

class _QuizQuestion {
  final String q;
  final List<String> options;
  final int correct;
  const _QuizQuestion(
      {required this.q, required this.options, required this.correct});
}
