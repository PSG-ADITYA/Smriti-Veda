import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/everyday_memory.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/top_right_user_menu.dart';

class EverydayMemoryScreen extends StatefulWidget {
  final int initialSubTab;
  const EverydayMemoryScreen({super.key, this.initialSubTab = 0});

  @override
  State<EverydayMemoryScreen> createState() => _EverydayMemoryScreenState();
}

class _EverydayMemoryScreenState extends State<EverydayMemoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialSubTab.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.canvasIvory,
          appBar: AppBar(
            backgroundColor: AppColors.canvasIvory,
            elevation: 0,
            title: Text(
              'Everyday Memory',
              style: GoogleFonts.newsreader(
                fontWeight: FontWeight.bold,
                color: AppColors.terracottaPrimary,
                fontSize: 20 * appState.fontScale,
              ),
            ),
            actions: const [
              TopRightUserMenu(),
              SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.terracottaPrimary,
              labelColor: AppColors.terracottaPrimary,
              unselectedLabelColor: AppColors.secondaryText,
              labelStyle: GoogleFonts.atkinsonHyperlegible(
                fontWeight: FontWeight.bold,
                fontSize: 14 * appState.fontScale,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.push_pin_outlined), text: 'Reminders'),
                Tab(icon: Icon(Icons.alarm), text: 'Routine'),
                Tab(icon: Icon(Icons.people_outline), text: 'Familiar People'),
                Tab(icon: Icon(Icons.psychology_outlined), text: 'Recall Game'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _RemindersTab(appState: appState, isDark: isDark),
              _RoutineTab(appState: appState, isDark: isDark),
              _ParichayTab(appState: appState, isDark: isDark),
              _RecallGameTab(appState: appState, isDark: isDark),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// 1. THINGS TO REMEMBER (REMINDERS) TAB
// ==========================================
class _RemindersTab extends StatelessWidget {
  final AppState appState;
  final bool isDark;

  const _RemindersTab({required this.appState, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final today = appState.todayReminders;
    final upcoming = appState.upcomingReminders;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditReminderDialog(context, appState),
        backgroundColor: AppColors.primarySaffron,
        icon: const Icon(Icons.add, color: Colors.white, size: 26),
        label: Text(
          'Add Reminder',
          style: GoogleFonts.outfit(
            fontSize: 16 * appState.fontScale,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3D6B58).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3D6B58).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFF3D6B58), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Personal memory assistance to track your daily tasks & appointments.',
                      style: GoogleFonts.outfit(
                        fontSize: 13 * appState.fontScale,
                        color: isDark ? Colors.white70 : AppColors.textLightPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Today's Reminders Section
            Text(
              "TODAY'S REMINDERS",
              style: GoogleFonts.cinzel(
                fontSize: 14 * appState.fontScale,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.primaryGold,
              ),
            ),
            const SizedBox(height: 10),
            if (today.isEmpty)
              _buildEmptyState('No reminders yet for today.')
            else
              ...today.map((r) => _buildReminderCard(context, r)),

            const SizedBox(height: 24),

            // Upcoming Reminders Section
            Text(
              'UPCOMING REMINDERS',
              style: GoogleFonts.cinzel(
                fontSize: 14 * appState.fontScale,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.primaryGold,
              ),
            ),
            const SizedBox(height: 10),
            if (upcoming.isEmpty)
              _buildEmptyState('No upcoming reminders added yet.')
            else
              ...upcoming.map((r) => _buildReminderCard(context, r)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.outfit(
            fontSize: 15 * appState.fontScale,
            color: isDark ? Colors.white54 : Colors.black54,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, EverydayReminder r) {
    final catColor = ReminderCategory.getColor(r.category);
    final catIcon = ReminderCategory.getIcon(r.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: r.isCompleted ? Colors.green.withValues(alpha: 0.5) : catColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: GestureDetector(
          onTap: () => appState.toggleReminderComplete(r.id),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: r.isCompleted ? Colors.green.withValues(alpha: 0.2) : catColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: r.isCompleted ? Colors.green : catColor,
                width: 2,
              ),
            ),
            child: Icon(
              r.isCompleted ? Icons.check : catIcon,
              color: r.isCompleted ? Colors.green : catColor,
              size: 24,
            ),
          ),
        ),
        title: Text(
          r.title,
          style: GoogleFonts.outfit(
            fontSize: 17 * appState.fontScale,
            fontWeight: FontWeight.bold,
            decoration: r.isCompleted ? TextDecoration.lineThrough : null,
            color: r.isCompleted
                ? (isDark ? Colors.white38 : Colors.black38)
                : (isDark ? Colors.white : AppColors.textLightPrimary),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (r.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                r.description,
                style: GoogleFonts.outfit(
                  fontSize: 13 * appState.fontScale,
                  color: isDark ? Colors.white60 : AppColors.textLightSecondary,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    r.category,
                    style: GoogleFonts.outfit(
                      fontSize: 11 * appState.fontScale,
                      fontWeight: FontWeight.bold,
                      color: catColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 14, color: isDark ? Colors.white54 : Colors.black54),
                const SizedBox(width: 4),
                Text(
                  r.time.format(context),
                  style: GoogleFonts.outfit(
                    fontSize: 12 * appState.fontScale,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primaryGold),
              onPressed: () => _showAddEditReminderDialog(context, appState, reminder: r),
              tooltip: 'Edit Reminder',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, () => appState.deleteReminder(r.id)),
              tooltip: 'Delete Reminder',
            ),
          ],
        ),
      ),
    ),
  );
  }

  void _showAddEditReminderDialog(BuildContext context, AppState appState, {EverydayReminder? reminder}) {
    final titleController = TextEditingController(text: reminder?.title ?? '');
    final descController = TextEditingController(text: reminder?.description ?? '');
    String selectedCategory = reminder?.category ?? ReminderCategory.health;
    TimeOfDay selectedTime = reminder?.time ?? const TimeOfDay(hour: 9, minute: 0);
    DateTime selectedDate = reminder?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                reminder == null ? 'Add Reminder' : 'Edit Reminder',
                style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppColors.primaryGold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(fontSize: 16 * appState.fontScale),
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'e.g. Call daughter Lakshmi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: TextStyle(fontSize: 14 * appState.fontScale),
                      decoration: const InputDecoration(
                        labelText: 'Note / Details (Optional)',
                        hintText: 'e.g. After morning tea',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: ReminderCategory.all.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                            icon: const Icon(Icons.access_time),
                            label: Text(selectedTime.format(context)),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setDialogState(() => selectedTime = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.pop(dialogCtx);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySaffron,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    FocusManager.instance.primaryFocus?.unfocus();
                    if (reminder == null) {
                      appState.addReminder(
                        EverydayReminder(
                          id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
                          title: title,
                          description: descController.text.trim(),
                          date: selectedDate,
                          time: selectedTime,
                          category: selectedCategory,
                        ),
                      );
                    } else {
                      appState.updateReminder(
                        reminder.copyWith(
                          title: title,
                          description: descController.text.trim(),
                          category: selectedCategory,
                          time: selectedTime,
                        ),
                      );
                    }
                    Navigator.pop(dialogCtx);
                  },
                  child: Text(
                    reminder == null ? 'Save' : 'Update',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      titleController.dispose();
      descController.dispose();
    });
  }

  void _confirmDelete(BuildContext context, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: const Text('Are you sure you want to remove this reminder?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              onDelete();
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. ROUTINE MEMORY TAB
// ==========================================
class _RoutineTab extends StatelessWidget {
  final AppState appState;
  final bool isDark;

  const _RoutineTab({required this.appState, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final steps = appState.routineSteps;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditStepDialog(context, appState),
        backgroundColor: AppColors.primarySaffron,
        icon: const Icon(Icons.add, color: Colors.white, size: 26),
        label: Text(
          'Add Step',
          style: GoogleFonts.outfit(
            fontSize: 16 * appState.fontScale,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Routine Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF3D6B58), const Color(0xFF3D6B58).withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.format_list_numbered, color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY ROUTINE SEQUENCE',
                          style: GoogleFonts.cinzel(
                            fontSize: 15 * appState.fontScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Follow ordered daily habits to reinforce muscle & temporal memory.',
                          style: GoogleFonts.outfit(
                            fontSize: 12 * appState.fontScale,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (steps.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'No routine added yet.',
                    style: GoogleFonts.outfit(
                      fontSize: 16 * appState.fontScale,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  final isLast = index == steps.length - 1;

                  return Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: step.isCompleted
                                ? Colors.green.withValues(alpha: 0.6)
                                : AppColors.primaryGold.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            leading: GestureDetector(
                              onTap: () => appState.toggleStepComplete(step.id),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: step.isCompleted
                                    ? Colors.green
                                    : AppColors.primarySaffron,
                                child: Text(
                                  '${step.stepNumber}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18 * appState.fontScale,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              step.title,
                              style: GoogleFonts.outfit(
                                fontSize: 18 * appState.fontScale,
                                fontWeight: FontWeight.bold,
                                decoration: step.isCompleted ? TextDecoration.lineThrough : null,
                                color: step.isCompleted
                                    ? (isDark ? Colors.white38 : Colors.black38)
                                    : (isDark ? Colors.white : AppColors.textLightPrimary),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (step.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    step.description,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14 * appState.fontScale,
                                      color: isDark ? Colors.white70 : AppColors.textLightSecondary,
                                    ),
                                  ),
                                ],
                                if (step.targetTime.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 14, color: AppColors.primaryGold),
                                      const SizedBox(width: 4),
                                      Text(
                                        step.targetTime,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13 * appState.fontScale,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.primaryGold),
                              onPressed: () => _showAddEditStepDialog(context, appState, step: step),
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Icon(Icons.arrow_downward, color: AppColors.primaryGold, size: 24),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddEditStepDialog(BuildContext context, AppState appState, {RoutineStep? step}) {
    final titleController = TextEditingController(text: step?.title ?? '');
    final descController = TextEditingController(text: step?.description ?? '');
    final timeController = TextEditingController(text: step?.targetTime ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            step == null ? 'Add Routine Step' : 'Edit Routine Step',
            style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppColors.primaryGold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Step Name *',
                    hintText: 'e.g. Evening Walk',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g. Walk 20 mins in park',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Target Time',
                    hintText: 'e.g. 5:30 PM',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pop(dialogCtx);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySaffron),
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                FocusManager.instance.primaryFocus?.unfocus();
                if (step == null) {
                  appState.addRoutineStep(
                    RoutineStep(
                      id: 'step_${DateTime.now().millisecondsSinceEpoch}',
                      stepNumber: appState.routineSteps.length + 1,
                      title: title,
                      description: descController.text.trim(),
                      targetTime: timeController.text.trim(),
                    ),
                  );
                } else {
                  appState.updateRoutineStep(
                    step.copyWith(
                      title: title,
                      description: descController.text.trim(),
                      targetTime: timeController.text.trim(),
                    ),
                  );
                }
                Navigator.pop(dialogCtx);
              },
              child: Text(step == null ? 'Add' : 'Update', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((_) {
      titleController.dispose();
      descController.dispose();
      timeController.dispose();
    });
  }
}

// ==========================================
// 3. PARICHAY (FAMILIAR PEOPLE) TAB
// ==========================================
class _ParichayTab extends StatelessWidget {
  final AppState appState;
  final bool isDark;

  const _ParichayTab({required this.appState, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final people = appState.familiarPeople;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPersonDialog(context, appState),
        backgroundColor: AppColors.primarySaffron,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 26),
        label: Text(
          'Add Person',
          style: GoogleFonts.outfit(
            fontSize: 16 * appState.fontScale,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFB85028).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB85028).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Color(0xFFB85028), size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'परिचय (Parichay) helps you recognize and recall loved ones & family members.',
                      style: GoogleFonts.outfit(
                        fontSize: 13 * appState.fontScale,
                        color: isDark ? Colors.white70 : AppColors.textLightPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (people.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'No familiar people added yet.',
                    style: GoogleFonts.outfit(
                      fontSize: 16 * appState.fontScale,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisExtent: 140,
                  mainAxisSpacing: 12,
                ),
                itemCount: people.length,
                itemBuilder: (context, index) {
                  final person = people[index];

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: person.avatarColor.withValues(alpha: 0.5), width: 1.5),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: person.avatarColor,
                          child: Text(
                            person.initials,
                            style: GoogleFonts.outfit(
                              fontSize: 24 * appState.fontScale,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    person.name,
                                    style: GoogleFonts.cinzel(
                                      fontSize: 19 * appState.fontScale,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppColors.textLightPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: person.avatarColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      person.relationship,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12 * appState.fontScale,
                                        fontWeight: FontWeight.bold,
                                        color: person.avatarColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                person.note.isEmpty ? 'No notes added' : person.note,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 13 * appState.fontScale,
                                  color: isDark ? Colors.white70 : AppColors.textLightSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => appState.deleteFamiliarPerson(person.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddPersonDialog(BuildContext context, AppState appState) {
    final nameController = TextEditingController();
    final relController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Familiar Person',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppColors.primaryGold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'e.g. Lakshmi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relController,
                decoration: const InputDecoration(
                  labelText: 'Relationship *',
                  hintText: 'e.g. Daughter, Grandson',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Memory Note',
                  hintText: 'e.g. Calls every Sunday, likes tea',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(dialogCtx);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySaffron),
            onPressed: () {
              final name = nameController.text.trim();
              final rel = relController.text.trim();
              if (name.isEmpty || rel.isEmpty) return;

              FocusManager.instance.primaryFocus?.unfocus();
              final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
              appState.addFamiliarPerson(
                FamiliarPerson(
                  id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  relationship: rel,
                  note: noteController.text.trim(),
                  initials: initials,
                ),
              );
              Navigator.pop(dialogCtx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).then((_) {
      nameController.dispose();
      relController.dispose();
      noteController.dispose();
    });
  }
}

// ==========================================
// 4. SIMPLE FAMILIAR-PERSON RECALL GAME TAB
// ==========================================
class _RecallGameTab extends StatefulWidget {
  final AppState appState;
  final bool isDark;

  const _RecallGameTab({required this.appState, required this.isDark});

  @override
  State<_RecallGameTab> createState() => _RecallGameTabState();
}

class _RecallGameTabState extends State<_RecallGameTab> {
  int _currentIndex = 0;
  bool _isStudyMode = true;
  String? _selectedAnswer;
  bool _isAnswerChecked = false;
  int _score = 0;
  bool _gameFinished = false;

  void _startQuiz() {
    setState(() {
      _currentIndex = 0;
      _isStudyMode = false;
      _selectedAnswer = null;
      _isAnswerChecked = false;
      _score = 0;
      _gameFinished = false;
    });
  }

  void _submitAnswer(String chosenName, String correctName) {
    if (_isAnswerChecked) return;

    setState(() {
      _selectedAnswer = chosenName;
      _isAnswerChecked = true;
      if (chosenName == correctName) {
        _score += 10;
      }
    });
  }

  void _nextQuestion(int totalPeople) {
    if (_currentIndex + 1 < totalPeople) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _isAnswerChecked = false;
      });
    } else {
      setState(() {
        _gameFinished = true;
      });
      widget.appState.recordRecallScore(_score);
    }
  }

  @override
  Widget build(BuildContext context) {
    final people = widget.appState.familiarPeople;
    final fontScale = widget.appState.fontScale;

    if (people.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Add at least 1 person in Parichay to play the Recall Exercise.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16 * fontScale,
              color: widget.isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
      );
    }

    final currentPerson = people[_currentIndex % people.length];

    if (_gameFinished) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.military_tech_outlined, color: AppColors.primaryGold, size: 72),
              const SizedBox(height: 16),
              Text(
                'EXERCISE COMPLETED!',
                style: GoogleFonts.cinzel(
                  fontSize: 22 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your Recall Score: $_score Points',
                style: GoogleFonts.outfit(
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : AppColors.textLightPrimary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarySaffron,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  'Play Again',
                  style: GoogleFonts.outfit(fontSize: 16 * fontScale, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  setState(() {
                    _isStudyMode = true;
                    _gameFinished = false;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    if (_isStudyMode) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.remove_red_eye_outlined, color: AppColors.primaryGold, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Study Phase: Look at the name & relationship, then tap Start Recall Challenge.',
                      style: GoogleFonts.outfit(
                        fontSize: 13 * fontScale,
                        color: widget.isDark ? Colors.white70 : AppColors.textLightPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Person Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: currentPerson.avatarColor, width: 2),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: currentPerson.avatarColor,
                    child: Text(
                      currentPerson.initials,
                      style: GoogleFonts.outfit(
                        fontSize: 36 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentPerson.name,
                    style: GoogleFonts.cinzel(
                      fontSize: 24 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentPerson.relationship,
                    style: GoogleFonts.outfit(
                      fontSize: 16 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: currentPerson.avatarColor,
                    ),
                  ),
                  if (currentPerson.note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '"${currentPerson.note}"',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14 * fontScale,
                        fontStyle: FontStyle.italic,
                        color: widget.isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarySaffron,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                label: Text(
                  'Start Recall Challenge',
                  style: GoogleFonts.outfit(
                    fontSize: 18 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: _startQuiz,
              ),
            ),
          ],
        ),
      );
    }

    // Quiz Mode (Name Hidden)
    final options = people.map((p) => p.name).toList();
    // Shuffle options predictably or keep list
    final correctName = currentPerson.name;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Question ${_currentIndex + 1} of ${people.length}',
            style: GoogleFonts.cinzel(
              fontSize: 14 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(height: 16),

          // Hidden Name Avatar Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: currentPerson.avatarColor, width: 2),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: currentPerson.avatarColor,
                  child: Text(
                    currentPerson.initials,
                    style: GoogleFonts.outfit(
                      fontSize: 36 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'WHO IS THIS PERSON?',
                  style: GoogleFonts.cinzel(
                    fontSize: 18 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                  ),
                ),
                Text(
                  'Relationship: ${currentPerson.relationship}',
                  style: GoogleFonts.outfit(
                    fontSize: 15 * fontScale,
                    color: widget.isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Answer Options
          ...options.map((opt) {
            final isChosen = _selectedAnswer == opt;
            final isCorrect = opt == correctName;

            Color btnColor = widget.isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard;
            if (_isAnswerChecked) {
              if (isCorrect) {
                btnColor = Colors.green.withValues(alpha: 0.3);
              } else if (isChosen) {
                btnColor = Colors.red.withValues(alpha: 0.3);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    foregroundColor: widget.isDark ? Colors.white : AppColors.textLightPrimary,
                    side: BorderSide(
                      color: _isAnswerChecked
                          ? (isCorrect ? Colors.green : (isChosen ? Colors.red : Colors.grey))
                          : AppColors.primaryGold,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _submitAnswer(opt, correctName),
                  child: Text(
                    opt,
                    style: GoogleFonts.outfit(
                      fontSize: 18 * fontScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),

          if (_isAnswerChecked) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarySaffron,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                label: Text(
                  _currentIndex + 1 < people.length ? 'Next Person' : 'See Results',
                  style: GoogleFonts.outfit(
                    fontSize: 18 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: () => _nextQuestion(people.length),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
