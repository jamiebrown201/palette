import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:uuid/uuid.dart';

/// Room creation flow: name -> direction -> usage time -> mood -> budget.
class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  static const _totalSteps = 5;
  int _currentStep = 0;
  final _nameController = TextEditingController();
  CompassDirection? _direction;
  UsageTime _usageTime = UsageTime.allDay;
  final _moods = <RoomMood>{};
  BudgetBracket _budget = BudgetBracket.midRange;
  bool _isRenterMode = false;

  static const _presetNames = [
    'Living Room',
    'Bedroom',
    'Kitchen',
    'Bathroom',
    'Hallway',
    'Dining Room',
    'Home Office',
    'Nursery',
    'Guest Room',
  ];

  static const _stepTitles = [
    'What room is this?',
    'Which way does the light come in?',
    'When do you use this room?',
    'How should it feel?',
    'Budget & ownership',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    if (_currentStep == 0) return _nameController.text.trim().isNotEmpty;
    return true;
  }

  void _next() {
    if (!_canContinue) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _saveRoom();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _detectWithCompass() async {
    StreamSubscription<CompassEvent>? sub;

    final detected = await showDialog<CompassDirection>(
      context: context,
      builder: (ctx) {
        CompassDirection? detected;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            sub ??= FlutterCompass.events?.listen((event) {
              final heading = event.heading;
              if (heading == null) return;
              final dir = _headingToDirection(heading);
              setDialogState(() => detected = dir);
            });

            return AlertDialog(
              title: const Text('Point towards the window'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Hold your phone and point it towards this room's main window.",
                  ),
                  const SizedBox(height: 16),
                  if (detected != null) ...[
                    const Icon(Icons.explore,
                        size: 48, color: PaletteColours.sageGreen),
                    const SizedBox(height: 8),
                    Text(
                      '${detected!.displayName}-facing',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                  ] else
                    const CircularProgressIndicator(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                if (detected != null)
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, detected),
                    child: const Text('Use this direction'),
                  ),
              ],
            );
          },
        );
      },
    );

    await sub?.cancel();
    if (detected != null && mounted) {
      setState(() => _direction = detected);
    }
  }

  CompassDirection _headingToDirection(double heading) {
    final h = heading % 360;
    if (h >= 315 || h < 45) return CompassDirection.north;
    if (h >= 45 && h < 135) return CompassDirection.east;
    if (h >= 135 && h < 225) return CompassDirection.south;
    return CompassDirection.west;
  }

  Future<void> _saveRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final roomRepo = ref.read(roomRepositoryProvider);
    final roomCount = await roomRepo.roomCount();

    await roomRepo.insertRoom(
      RoomsCompanion.insert(
        id: const Uuid().v4(),
        name: name,
        direction: Value(_direction),
        usageTime: _usageTime,
        moods: _moods.toList(),
        budget: _budget,
        isRenterMode: _isRenterMode,
        sortOrder: roomCount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentStep == _totalSteps - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Room'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    minHeight: 6,
                    backgroundColor: PaletteColours.warmGrey,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      PaletteColours.sageGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_currentStep + 1} of $_totalSteps',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: PaletteColours.textTertiary,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stepTitles[_currentStep],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildStepContent(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side:
                              const BorderSide(color: PaletteColours.divider),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: _currentStep > 0 ? 2 : 1,
                    child: FilledButton(
                      onPressed: _canContinue ? _next : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(isLast ? 'Create Room' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _NameStep(
          key: const ValueKey('name'),
          controller: _nameController,
          presetNames: _presetNames,
          onChanged: () => setState(() {}),
        );
      case 1:
        return _DirectionStep(
          key: const ValueKey('direction'),
          direction: _direction,
          onDirectionChanged: (d) => setState(() => _direction = d),
          onDetectWithCompass: _detectWithCompass,
        );
      case 2:
        return _UsageTimeStep(
          key: const ValueKey('usage'),
          usageTime: _usageTime,
          onChanged: (v) => setState(() => _usageTime = v),
        );
      case 3:
        return _MoodStep(
          key: const ValueKey('mood'),
          moods: _moods,
          onToggle: (mood, selected) {
            setState(() {
              if (selected && _moods.length < 3) {
                _moods.add(mood);
              } else {
                _moods.remove(mood);
              }
            });
          },
        );
      case 4:
        return _BudgetStep(
          key: const ValueKey('budget'),
          budget: _budget,
          isRenterMode: _isRenterMode,
          onBudgetChanged: (v) => setState(() => _budget = v),
          onRenterChanged: (v) => setState(() => _isRenterMode = v),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({
    super.key,
    required this.controller,
    required this.presetNames,
    required this.onChanged,
  });

  final TextEditingController controller;
  final List<String> presetNames;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter room name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 20),
        Text(
          'Or pick a preset:',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: PaletteColours.textSecondary,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presetNames.map((name) {
            final isSelected = controller.text == name;
            return ChoiceChip(
              label: Text(name),
              selected: isSelected,
              selectedColor: PaletteColours.sageGreenLight,
              onSelected: (_) {
                controller.text = name;
                onChanged();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DirectionStep extends StatelessWidget {
  const _DirectionStep({
    super.key,
    required this.direction,
    required this.onDirectionChanged,
    required this.onDetectWithCompass,
  });

  final CompassDirection? direction;
  final ValueChanged<CompassDirection?> onDirectionChanged;
  final VoidCallback onDetectWithCompass;

  static const _directionIcons = {
    CompassDirection.north: Icons.north,
    CompassDirection.east: Icons.east,
    CompassDirection.south: Icons.south,
    CompassDirection.west: Icons.west,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which way does the main window face?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PaletteColours.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        // Direction grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: CompassDirection.values.map((dir) {
            final isSelected = direction == dir;
            return Material(
              color: isSelected
                  ? PaletteColours.sageGreenLight
                  : PaletteColours.cardBackground,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onDirectionChanged(dir),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? PaletteColours.sageGreen
                          : PaletteColours.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _directionIcons[dir],
                        size: 20,
                        color: isSelected
                            ? PaletteColours.sageGreenDark
                            : PaletteColours.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dir.displayName,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? PaletteColours.sageGreenDark
                              : PaletteColours.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: onDetectWithCompass,
              icon: const Icon(Icons.explore, size: 16),
              label: const Text('Detect with compass'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => onDirectionChanged(null),
              child: const Text("I'm not sure"),
            ),
          ],
        ),
      ],
    );
  }
}

class _UsageTimeStep extends StatelessWidget {
  const _UsageTimeStep({
    super.key,
    required this.usageTime,
    required this.onChanged,
  });

  final UsageTime usageTime;
  final ValueChanged<UsageTime> onChanged;

  static const _usageIcons = {
    UsageTime.morning: Icons.wb_sunny_outlined,
    UsageTime.afternoon: Icons.light_mode_outlined,
    UsageTime.evening: Icons.nightlight_outlined,
    UsageTime.allDay: Icons.schedule_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: UsageTime.values.map((time) {
        final isSelected = usageTime == time;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: isSelected
                ? PaletteColours.sageGreenLight
                : PaletteColours.cardBackground,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => onChanged(time),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? PaletteColours.sageGreen
                        : PaletteColours.divider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _usageIcons[time],
                      color: isSelected
                          ? PaletteColours.sageGreenDark
                          : PaletteColours.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      time.displayName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: PaletteColours.sageGreen,
                        size: 22,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MoodStep extends StatelessWidget {
  const _MoodStep({
    super.key,
    required this.moods,
    required this.onToggle,
  });

  final Set<RoomMood> moods;
  final void Function(RoomMood mood, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose up to 3',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PaletteColours.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: RoomMood.values.map((mood) {
            final isSelected = moods.contains(mood);
            return FilterChip(
              label: Text(mood.displayName),
              selected: isSelected,
              onSelected: (selected) => onToggle(mood, selected),
              selectedColor: PaletteColours.sageGreenLight,
              checkmarkColor: PaletteColours.sageGreenDark,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            );
          }).toList(),
        ),
        if (moods.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PaletteColours.softCream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 16, color: PaletteColours.sageGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: ${moods.map((m) => m.displayName).join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PaletteColours.sageGreenDark,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BudgetStep extends StatelessWidget {
  const _BudgetStep({
    super.key,
    required this.budget,
    required this.isRenterMode,
    required this.onBudgetChanged,
    required this.onRenterChanged,
  });

  final BudgetBracket budget;
  final bool isRenterMode;
  final ValueChanged<BudgetBracket> onBudgetChanged;
  final ValueChanged<bool> onRenterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        ...BudgetBracket.values.map((bracket) {
          final isSelected = budget == bracket;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: isSelected
                  ? PaletteColours.sageGreenLight
                  : PaletteColours.cardBackground,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onBudgetChanged(bracket),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? PaletteColours.sageGreen
                          : PaletteColours.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        bracket.displayName,
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: PaletteColours.sageGreen,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: PaletteColours.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRenterMode
                  ? PaletteColours.sageGreen
                  : PaletteColours.divider,
            ),
          ),
          child: SwitchListTile(
            title: const Text('Renter mode'),
            subtitle: const Text(
              'Lock wall colour to landlord paint, '
              'focus on furniture & accessories',
            ),
            value: isRenterMode,
            onChanged: onRenterChanged,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
