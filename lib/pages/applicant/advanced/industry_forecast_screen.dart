import 'package:flutter/material.dart';

import '../../../services/ai_service.dart';
import '../../../shared/applicant_notification_button.dart';

class IndustryForecastScreen extends StatefulWidget {
  final String field;

  const IndustryForecastScreen({super.key, required this.field});

  @override
  State<IndustryForecastScreen> createState() => _IndustryForecastScreenState();
}

class _IndustryForecastScreenState extends State<IndustryForecastScreen> {
  bool _loading = true;
  Map<String, dynamic> _trends = const {};

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    final data = await AiService.generateIndustryTrends(widget.field);

    if (!mounted) return;

    setState(() {
      _trends = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final industry = (_trends['industry'] as String?) ?? widget.field;

    final overview = (_trends['overview'] as String?) ??
        'AI trend model indicates demand is increasing for practical, tool-based skills in IT & Software roles.';

    final trendItems = ((_trends['trends'] as List?) ?? [])
        .whereType<Map>()
        .map((item) => {
              'skill': (item['skill'] ?? 'Skill').toString(),
              'demandPct': int.tryParse('${item['demandPct']}') ?? 50,
              'yoy': (item['yoy'] ?? '+0% YoY').toString(),
              'direction': (item['direction'] ?? 'up').toString(),
            })
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('$industry Forecast'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: const [ApplicantNotificationButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDCE3F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.trending_up, color: Color(0xFF3692FF)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Market Intelligence: $industry',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              overview,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Forecasted Skills',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...trendItems.map((item) {
                  final demand = item['demandPct'] as int;
                  final direction = item['direction'] as String;

                  final color = direction == 'down'
                      ? Colors.red
                      : direction == 'flat'
                          ? Colors.orange
                          : Colors.green;

                  final icon = direction == 'down'
                      ? Icons.trending_down
                      : direction == 'flat'
                          ? Icons.trending_flat
                          : Icons.trending_up;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          color.withOpacity(0.03),
                        ],
                      ),
                      border: Border.all(color: color.withOpacity(0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.12),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: color, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item['skill'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$demand%',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              item['yoy'] as String,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
