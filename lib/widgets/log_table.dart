import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/checkin.dart';

class LogTable extends StatelessWidget {
  const LogTable({
    required this.checkins,
    super.key,
  });

  final List<CheckIn> checkins;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, HH:mm');

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 500) {
          return ListView.builder(
            itemCount: checkins.length,
            itemBuilder: (_, index) {
              final item = checkins[index];
              return Card(
                child: ListTile(
                  title: Text(item.fullName),
                  subtitle: Text(item.notes.isEmpty ? '-' : item.notes),
                  trailing: Text(
                    formatter.format(item.checkedInAt.toLocal()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              );
            },
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Time')),
              DataColumn(label: Text('Notes')),
            ],
            rows: checkins
                .map(
                  (item) => DataRow(
                    cells: [
                      DataCell(Text(item.fullName)),
                      DataCell(
                        Text(formatter.format(item.checkedInAt.toLocal())),
                      ),
                      DataCell(Text(item.notes)),
                    ],
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
