import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/presentation/enum_presentation.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_overlays.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/recurrence.dart';
import 'package:kairo/features/tasks/presentation/widgets/property_pickers.dart';

/// Recurrence configuration.
///
/// Four presets cover almost everything; the custom option exposes an interval
/// and, for weekly rules, the weekdays. Anything more elaborate belongs in a
/// calendar app, not a task list.
class RecurrencePicker extends StatelessWidget {
  const RecurrencePicker({
    required this.value,
    required this.onChanged,
    this.dense = false,
    super.key,
  });

  final RecurrenceRule value;
  final ValueChanged<RecurrenceRule> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return AppSelectMenu<String>(
      selected: value.frequency.name,
      options: <MenuOption<String>>[
        for (final RecurrenceFrequency frequency in <RecurrenceFrequency>[
          RecurrenceFrequency.none,
          RecurrenceFrequency.daily,
          RecurrenceFrequency.weekly,
          RecurrenceFrequency.monthly,
        ])
          MenuOption<String>(
            value: frequency.name,
            label: frequency.label(context.l10n),
            icon: frequency == RecurrenceFrequency.none
                ? AppIcons.close
                : AppIcons.recurrence,
          ),
        MenuOption<String>(
          value: 'custom',
          label: context.l10n.recurrenceCustom,
          icon: AppIcons.settings,
        ),
      ],
      onSelected: (String choice) async {
        if (choice == 'custom') {
          final RecurrenceRule? custom = await _openCustom(context);
          if (custom != null) onChanged(custom);
          return;
        }
        final RecurrenceFrequency frequency = RecurrenceFrequency.values
            .firstWhere((RecurrenceFrequency f) => f.name == choice);
        onChanged(
          frequency == RecurrenceFrequency.none
              ? RecurrenceRule.none
              : RecurrenceRule(frequency: frequency),
        );
      },
      builder: (BuildContext context, VoidCallback open) => PropertyTrigger(
        onTap: open,
        dense: dense,
        icon: AppIcons.recurrence,
        isPlaceholder: !value.isEnabled,
        tooltip: context.l10n.fieldRecurrence,
        child: Text(describeRecurrence(context, value)),
      ),
    );
  }

  Future<RecurrenceRule?> _openCustom(BuildContext context) {
    return showAppDialog<RecurrenceRule>(
      context: context,
      maxWidth: 440,
      child: _CustomRecurrenceDialog(initial: value),
    );
  }
}

/// Human summary of a rule, e.g. "Every 2 weeks on Mon, Thu".
String describeRecurrence(BuildContext context, RecurrenceRule rule) {
  final l10n = context.l10n;
  if (!rule.isEnabled) return l10n.recurrenceNone;

  final String unit = switch (rule.frequency) {
    RecurrenceFrequency.daily => rule.interval == 1 ? 'day' : 'days',
    RecurrenceFrequency.weekly ||
    RecurrenceFrequency.custom => rule.interval == 1 ? 'week' : 'weeks',
    RecurrenceFrequency.monthly => rule.interval == 1 ? 'month' : 'months',
    RecurrenceFrequency.none => '',
  };

  final String base = rule.interval == 1
      ? rule.frequency.label(l10n)
      : l10n.recurrenceEveryN(rule.interval, unit);

  if (rule.weekdays.isEmpty) return base;
  const List<String> names = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final List<int> sorted = <int>[...rule.weekdays]..sort();
  return '$base · ${sorted.map((int d) => names[d - 1]).join(', ')}';
}

class _CustomRecurrenceDialog extends StatefulWidget {
  const _CustomRecurrenceDialog({required this.initial});

  final RecurrenceRule initial;

  @override
  State<_CustomRecurrenceDialog> createState() =>
      _CustomRecurrenceDialogState();
}

class _CustomRecurrenceDialogState extends State<_CustomRecurrenceDialog> {
  late RecurrenceFrequency _frequency = widget.initial.isEnabled
      ? widget.initial.frequency
      : RecurrenceFrequency.weekly;
  late int _interval = widget.initial.interval;
  late final Set<int> _weekdays = <int>{...widget.initial.weekdays};
  late DateTime? _until = widget.initial.until;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppDialogShell(
      title: context.l10n.recurrenceCustom,
      subtitle: 'Repeat this task on a schedule.',
      icon: AppIcons.recurrence,
      actions: <Widget>[
        AppButton(
          label: context.l10n.actionCancel,
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          label: context.l10n.actionApply,
          onPressed: () => Navigator.of(context).pop(
            RecurrenceRule(
              frequency:
                  _frequency == RecurrenceFrequency.weekly &&
                      _weekdays.isNotEmpty
                  ? RecurrenceFrequency.weekly
                  : _frequency,
              interval: _interval,
              weekdays: _weekdays.toList()..sort(),
              until: _until,
            ),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('Every', style: context.textStyles.bodyMedium),
              const SizedBox(width: Spacing.md),
              SizedBox(
                width: 70,
                child: DropdownButtonFormField<int>(
                  initialValue: _interval,
                  isDense: true,
                  items: <DropdownMenuItem<int>>[
                    for (int i = 1; i <= 12; i++)
                      DropdownMenuItem<int>(value: i, child: Text('$i')),
                  ],
                  onChanged: (int? value) =>
                      setState(() => _interval = value ?? 1),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: DropdownButtonFormField<RecurrenceFrequency>(
                  initialValue: _frequency,
                  isDense: true,
                  items: <DropdownMenuItem<RecurrenceFrequency>>[
                    for (final RecurrenceFrequency frequency
                        in <RecurrenceFrequency>[
                          RecurrenceFrequency.daily,
                          RecurrenceFrequency.weekly,
                          RecurrenceFrequency.monthly,
                        ])
                      DropdownMenuItem<RecurrenceFrequency>(
                        value: frequency,
                        child: Text(switch (frequency) {
                          RecurrenceFrequency.daily =>
                            _interval == 1 ? 'day' : 'days',
                          RecurrenceFrequency.weekly =>
                            _interval == 1 ? 'week' : 'weeks',
                          RecurrenceFrequency.monthly =>
                            _interval == 1 ? 'month' : 'months',
                          _ => '',
                        }),
                      ),
                  ],
                  onChanged: (RecurrenceFrequency? value) => setState(
                    () => _frequency = value ?? RecurrenceFrequency.weekly,
                  ),
                ),
              ),
            ],
          ),
          if (_frequency == RecurrenceFrequency.weekly) ...<Widget>[
            const SizedBox(height: Spacing.xl),
            Text('On these days', style: context.textStyles.labelMedium),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              children: <Widget>[
                for (int day = 1; day <= 7; day++)
                  AppFilterChip(
                    label: const <String>[
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ][day - 1],
                    selected: _weekdays.contains(day),
                    onTap: () => setState(() {
                      if (!_weekdays.remove(day)) _weekdays.add(day);
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: Spacing.xl),
          Row(
            children: <Widget>[
              Text('Ends', style: context.textStyles.labelMedium),
              const SizedBox(width: Spacing.md),
              DatePickerField(
                value: _until,
                label: 'Never',
                onChanged: (DateTime? value) => setState(() => _until = value),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: colors.brandSoft,
              borderRadius: Radii.brSm,
            ),
            child: Row(
              children: <Widget>[
                Icon(AppIcons.recurrence, size: 14, color: colors.brand),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    describeRecurrence(
                      context,
                      RecurrenceRule(
                        frequency: _frequency,
                        interval: _interval,
                        weekdays: _weekdays.toList()..sort(),
                      ),
                    ),
                    style: context.textStyles.labelMedium?.copyWith(
                      color: colors.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact read-only badge shown on task rows for repeating tasks.
class RecurrenceBadge extends StatelessWidget {
  const RecurrenceBadge({required this.rule, super.key});

  final RecurrenceRule rule;

  @override
  Widget build(BuildContext context) {
    if (!rule.isEnabled) return const SizedBox.shrink();
    return Tooltip(
      message: describeRecurrence(context, rule),
      child: Icon(
        AppIcons.recurrence,
        size: 13,
        color: context.colors.inkFaint,
      ),
    );
  }
}
