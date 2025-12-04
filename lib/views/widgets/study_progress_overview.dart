import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/study_progress_providers.dart';

class StudyProgressOverview extends ConsumerWidget {
  const StudyProgressOverview({super.key, required this.userId});

  final String userId;

  static const Color _navy = Color(0xFF101828);
  static const Color _brandBlue = Color(0xFF1A73E8);
  static const Color _accentGreen = Color(0xFF10B981);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(studyProgressProvider(userId));

    return progressAsync.when(
      loading: () => _buildLoadingState(),
      error: (_, __) => const SizedBox.shrink(),
      data: (progress) {
        if (progress.totalCourses == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                offset: const Offset(0, 4),
                color: Colors.black.withOpacity(0.03),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Study Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 20),
              // Overall progress
              _ProgressBar(
                label: 'Overall Progress',
                progress: progress.overallProgress,
                color: _brandBlue,
              ),
              const SizedBox(height: 16),
              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.school,
                      label: 'Courses',
                      value: progress.totalCourses.toString(),
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.description,
                      label: 'Materials',
                      value: progress.totalMaterials.toString(),
                      color: _brandBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.quiz,
                      label: 'Quizzes',
                      value: '${progress.completedQuizzes}/${progress.totalQuizzes}',
                      color: _accentGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.trending_up,
                      label: 'Avg Score',
                      value: progress.averageQuizScore > 0
                          ? '${progress.averageQuizScore.toStringAsFixed(0)}%'
                          : '—',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.03),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Study Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 20),
          // Overall progress loading
          _ProgressBar(
            label: 'Overall Progress',
            progress: 0,
            color: _brandBlue,
            isLoading: true,
          ),
          const SizedBox(height: 16),
          // Stats grid loading
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.school,
                  label: 'Courses',
                  value: '—',
                  color: Colors.purple,
                  isLoading: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.description,
                  label: 'Materials',
                  value: '—',
                  color: _brandBlue,
                  isLoading: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.quiz,
                  label: 'Quizzes',
                  value: '—',
                  color: _accentGreen,
                  isLoading: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up,
                  label: 'Avg Score',
                  value: '—',
                  color: Colors.orange,
                  isLoading: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.label,
    required this.progress,
    required this.color,
    this.isLoading = false,
  });

  final String label;
  final double progress;
  final Color color;
  final bool isLoading;

  static const Color _navy = Color(0xFF101828);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _navy,
              ),
            ),
            isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isLoading
              ? LinearProgressIndicator(
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                )
              : LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

