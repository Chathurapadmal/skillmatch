import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ---------------------------
  // MOCK USER DATA (replace with DB later)
  // ---------------------------
  String fullName = "Alex Johnson";
  String headline = "Computer Science at Stanford University";
  String classOf = "Class of 2025";
  String location = "Palo Alto,CA";

  // Simulated profile image (network or asset)
  // Later: use image_picker and store file path / upload URL
  final String profileImageUrl =
      "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400";

  final Set<String> skills = {
    "Python",
    "Machine Learning",
    "UI Design",
    "React",
    "Data Analysis",
    "SQL",
    "Agile",
  };

  final List<Certification> certifications = [
    Certification(
      title: "Google Data Analytics",
      issuer: "Coursera",
      date: "Dec 2023",
    ),
    Certification(
      title: "AWS Cloud Practitioner",
      issuer: "Coursera",
      date: "Dec 2023",
    ),
    Certification(
      title: "Full-Stack Bootcamp",
      issuer: "Coursera",
      date: "Dec 2023",
    ),
  ];

  // Suggested jobs (skillsRequired used for match rate)
  final List<JobVacancy> suggestedJobs = [
    JobVacancy(
      title: "Junior Data Analyst",
      company: "Nova Insights",
      location: "Remote",
      skillsRequired: ["SQL", "Data Analysis", "Python"],
    ),
    JobVacancy(
      title: "Frontend Developer (React)",
      company: "PixelWorks",
      location: "Hybrid",
      skillsRequired: ["React", "UI Design", "Agile"],
    ),
    JobVacancy(
      title: "ML Intern",
      company: "DeepVision Labs",
      location: "On-site",
      skillsRequired: ["Machine Learning", "Python", "Data Analysis"],
    ),
  ];

  // ---------------------------
  // MATCH RATE CALC
  // ---------------------------
  int calculateMatchRate(JobVacancy job) {
    final userSkills = skills.map((e) => e.toLowerCase()).toSet();
    final required = job.skillsRequired.map((e) => e.toLowerCase()).toSet();

    if (required.isEmpty) return 0;

    final matchedSkills = required.intersection(userSkills).length;
    final skillScore = matchedSkills / required.length; // 0..1

    // Add small bonus for certs (you can change logic)
    final certBonus = min(certifications.length * 0.03, 0.15); // max +15%

    final score = (skillScore + certBonus).clamp(0.0, 1.0);
    return (score * 100).round();
  }

  int get overallMatchRate {
    if (suggestedJobs.isEmpty) return 0;
    final avg =
        suggestedJobs.map(calculateMatchRate).reduce((a, b) => a + b) /
        suggestedJobs.length;
    return avg.round();
  }

  // ---------------------------
  // UI HELPERS (Dialogs)
  // ---------------------------
  Future<void> showEditProfileDialog() async {
    final nameCtrl = TextEditingController(text: fullName);
    final headlineCtrl = TextEditingController(text: headline);
    final classCtrl = TextEditingController(text: classOf);
    final locCtrl = TextEditingController(text: location);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Profile"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              TextField(
                controller: headlineCtrl,
                decoration: const InputDecoration(
                  labelText: "Headline / Degree",
                ),
              ),
              TextField(
                controller: classCtrl,
                decoration: const InputDecoration(labelText: "Class"),
              ),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(labelText: "Location"),
              ),
              const SizedBox(height: 8),
              const Text(
                "Profile photo: connect Image Picker later (image_picker package).",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                fullName = nameCtrl.text.trim().isEmpty
                    ? fullName
                    : nameCtrl.text.trim();
                headline = headlineCtrl.text.trim().isEmpty
                    ? headline
                    : headlineCtrl.text.trim();
                classOf = classCtrl.text.trim().isEmpty
                    ? classOf
                    : classCtrl.text.trim();
                location = locCtrl.text.trim().isEmpty
                    ? location
                    : locCtrl.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> showAddSkillDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Skill"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: "e.g., Flutter, Java, Figma",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final s = ctrl.text.trim();
              if (s.isNotEmpty) {
                setState(() => skills.add(s));
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> showCertDialog({Certification? cert, int? index}) async {
    final titleCtrl = TextEditingController(text: cert?.title ?? "");
    final issuerCtrl = TextEditingController(text: cert?.issuer ?? "");
    final dateCtrl = TextEditingController(text: cert?.date ?? "");

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(cert == null ? "Add Certification" : "Edit Certification"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: issuerCtrl,
                decoration: const InputDecoration(labelText: "Issuer"),
              ),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: "Date (e.g., Dec 2023)",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final t = titleCtrl.text.trim();
              if (t.isEmpty) return;
              setState(() {
                final newCert = Certification(
                  title: t,
                  issuer: issuerCtrl.text.trim().isEmpty
                      ? "Unknown"
                      : issuerCtrl.text.trim(),
                  date: dateCtrl.text.trim().isEmpty
                      ? "-"
                      : dateCtrl.text.trim(),
                );
                if (cert == null) {
                  certifications.add(newCert);
                } else if (index != null) {
                  certifications[index] = newCert;
                }
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // THE PAGE UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = const Color(0xFFEFF5FF);
    final primary = const Color(0xFF3B4CC0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Profile", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            // Top header card area
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                children: [
                  // Avatar with edit icon overlay
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primary, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundImage: NetworkImage(profileImageUrl),
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                      InkWell(
                        onTap: showEditProfileDialog,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: primary,
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    fullName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        classOf,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(width: 18),
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        location,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Buttons row
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: showEditProfileDialog,
                            child: const Text(
                              "Edit Profile",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 46,
                        width: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Share feature: connect deep link later.",
                                ),
                              ),
                            );
                          },
                          child: const Icon(Icons.share, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Stats cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      value: "${skills.length}",
                      label: "SKILLS",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      value: "$overallMatchRate%",
                      label: "MATCH RATE",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      value: "${certifications.length}",
                      label: "CERTIFICATES",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Skills Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "Technical Skills",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: Color(0xFF3B4CC0),
                        ),
                        SizedBox(width: 6),
                        Text(
                          "AI Verified",
                          style: TextStyle(
                            color: Color(0xFF3B4CC0),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ...skills.map(
                    (s) => _SkillChip(
                      label: s,
                      onDelete: () => setState(() => skills.remove(s)),
                    ),
                  ),
                  _AddChip(onTap: showAddSkillDialog),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Certifications section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "Certifications",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => showCertDialog(),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),

            ListView.builder(
              itemCount: certifications.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, i) {
                final c = certifications[i];
                return _CertTile(
                  cert: c,
                  onTap: () => showCertDialog(cert: c, index: i),
                  onDelete: () => setState(() => certifications.removeAt(i)),
                );
              },
            ),

            const SizedBox(height: 20),

            // Suggested Jobs section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "Suggested Job Vacancies",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            const SizedBox(height: 10),

            ListView.builder(
              itemCount: suggestedJobs.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, i) {
                final job = suggestedJobs[i];
                final rate = calculateMatchRate(job);
                return _JobCard(
                  job: job,
                  matchRate: rate,
                  onApply: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Applied to ${job.title} ✅ (demo)"),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------
// MODELS
// ---------------------------
class Certification {
  final String title;
  final String issuer;
  final String date;

  Certification({
    required this.title,
    required this.issuer,
    required this.date,
  });
}

class JobVacancy {
  final String title;
  final String company;
  final String location;
  final List<String> skillsRequired;

  JobVacancy({
    required this.title,
    required this.company,
    required this.location,
    required this.skillsRequired,
  });
}

// ---------------------------
// WIDGETS
// ---------------------------
class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF3B4CC0),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;

  const _SkillChip({required this.label, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bool highlighted = label.toLowerCase() == "python";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFF3B4CC0) : Colors.black87,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close, size: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add, size: 18),
            SizedBox(width: 8),
            Text("Add", style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _CertTile extends StatelessWidget {
  final Certification cert;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CertTile({
    required this.cert,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.description_outlined, color: Colors.black87),
        ),
        title: Text(
          cert.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text("${cert.issuer}  •  ${cert.date}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobVacancy job;
  final int matchRate;
  final VoidCallback onApply;

  const _JobCard({
    required this.job,
    required this.matchRate,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF3B4CC0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${job.company} • ${job.location}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "$matchRate% match",
                  style: const TextStyle(
                    color: Color(0xFF3B4CC0),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: job.skillsRequired
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onApply,
              child: const Text(
                "Apply Now",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
