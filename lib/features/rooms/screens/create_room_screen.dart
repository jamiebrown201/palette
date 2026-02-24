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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
                    const Icon(Icons.explore, size: 48, color: PaletteColours.sageGreen),
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
    // Normalise to 0-360
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Room'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && _nameController.text.trim().isEmpty) return;
          if (_currentStep < 4) {
            setState(() => _currentStep++);
          } else {
            _saveRoom();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 4;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: Text(isLast ? 'Create Room' : 'Continue'),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          // Step 0: Name
          Step(
            title: const Text('Room name'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter room name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetNames.map((name) {
                    return ActionChip(
                      label: Text(name),
                      onPressed: () => _nameController.text = name,
                    );
                  }).toList(),
                ),
              ],
            ),
            isActive: _currentStep >= 0,
          ),

          // Step 1: Compass direction
          Step(
            title: const Text('Light direction'),
            subtitle: const Text('Which way does the main window face?'),
            content: Column(
              children: [
                RadioGroup<CompassDirection>(
                  groupValue: _direction,
                  onChanged: (v) => setState(() => _direction = v),
                  child: Column(
                    children: CompassDirection.values.map((dir) {
                      return RadioListTile<CompassDirection>(
                        title: Text(dir.displayName),
                        value: dir,
                      );
                    }).toList(),
                  ),
                ),
                TextButton.icon(
                  onPressed: _detectWithCompass,
                  icon: const Icon(Icons.explore, size: 16),
                  label: const Text('Detect with compass'),
                ),
                TextButton(
                  onPressed: () => setState(() => _direction = null),
                  child: const Text("I'm not sure"),
                ),
              ],
            ),
            isActive: _currentStep >= 1,
          ),

          // Step 2: Usage time
          Step(
            title: const Text('When do you use this room most?'),
            content: RadioGroup<UsageTime>(
              groupValue: _usageTime,
              onChanged: (v) {
                if (v != null) setState(() => _usageTime = v);
              },
              child: Column(
                children: UsageTime.values.map((time) {
                  return RadioListTile<UsageTime>(
                    title: Text(time.displayName),
                    value: time,
                  );
                }).toList(),
              ),
            ),
            isActive: _currentStep >= 2,
          ),

          // Step 3: Mood
          Step(
            title: const Text('How should this room feel?'),
            subtitle: const Text('Choose up to 3'),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RoomMood.values.map((mood) {
                final isSelected = _moods.contains(mood);
                return FilterChip(
                  label: Text(mood.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected && _moods.length < 3) {
                        _moods.add(mood);
                      } else {
                        _moods.remove(mood);
                      }
                    });
                  },
                  selectedColor: PaletteColours.sageGreenLight,
                );
              }).toList(),
            ),
            isActive: _currentStep >= 3,
          ),

          // Step 4: Budget & renter mode
          Step(
            title: const Text('Budget & ownership'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                RadioGroup<BudgetBracket>(
                  groupValue: _budget,
                  onChanged: (v) {
                    if (v != null) setState(() => _budget = v);
                  },
                  child: Column(
                    children: BudgetBracket.values.map((bracket) {
                      return RadioListTile<BudgetBracket>(
                        title: Text(bracket.displayName),
                        value: bracket,
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Renter mode'),
                  subtitle: const Text(
                    'Lock wall colour to landlord paint, '
                    'focus on furniture & accessories',
                  ),
                  value: _isRenterMode,
                  onChanged: (v) => setState(() => _isRenterMode = v),
                ),
              ],
            ),
            isActive: _currentStep >= 4,
          ),
        ],
      ),
    );
  }
}
