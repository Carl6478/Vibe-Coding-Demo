import 'package:flutter/material.dart';

import '../models/person.dart';

class PersonCard extends StatelessWidget {
  const PersonCard({
    required this.person,
    required this.isCheckedIn,
    required this.onTap,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
    super.key,
  });

  final Person person;
  final bool isCheckedIn;
  final VoidCallback onTap;
  final bool selectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final trailingWidgets = <Widget>[
      if (isCheckedIn)
        const Chip(
          label: Text('Checked In'),
          avatar: Icon(Icons.check_circle, size: 16),
        ),
      if (selectionMode)
        Checkbox(
          value: isSelected,
          onChanged: onSelectionChanged,
        ),
    ];

    return Card(
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          title: Text(person.fullName),
          subtitle: selectionMode && isSelected ? Text('ID: ${person.id}') : null,
          trailing: trailingWidgets.isEmpty
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: trailingWidgets,
                ),
        ),
      ),
    );
  }
}
