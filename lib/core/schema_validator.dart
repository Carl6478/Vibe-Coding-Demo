import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class AppSchemaValidator {
  static Future<void> validate() async {
    await _validatePeopleTable();
    await _validateCheckinsTable();
  }

  static Future<void> _validatePeopleTable() async {
    await _validateSelect(table: 'people', columns: 'id,first_name,last_name');
  }

  static Future<void> _validateCheckinsTable() async {
    await _validateSelect(
      table: 'checkins',
      columns: 'id,person_id,first_name,last_name,checked_in_at,notes',
    );
  }

  static Future<void> _validateSelect({
    required String table,
    required String columns,
  }) async {
    try {
      await SupabaseService.client.from(table).select(columns).limit(1);
    } on PostgrestException catch (error) {
      throw StateError(_buildSchemaError(table: table, error: error));
    }
  }

  static String _buildSchemaError({
    required String table,
    required PostgrestException error,
  }) {
    final code = error.code ?? '';
    final message = error.message.trim();
    final hint = error.hint?.trim();
    final buffer = StringBuffer(
      'Supabase schema is not ready for the reception app.\n\n'
      'Expected table: public.$table\n'
      'Received: $message',
    );

    if (hint != null && hint.isNotEmpty) {
      buffer.write('\nHint: $hint');
    }

    if (code == 'PGRST205') {
      buffer.write(
        '\n\nRun the SQL in README.md or '
        'supabase/migrations/20260516_create_reception_tables.sql, then hot restart.',
      );
    } else if (code == '42703') {
      buffer.write(
        '\n\nThe table exists, but its columns do not match the app.'
        '\nRun the SQL in README.md or '
        'supabase/migrations/20260516_create_reception_tables.sql, then hot restart.',
      );
    } else {
      buffer.write('\n\nPostgREST code: $code');
    }

    return buffer.toString();
  }
}
