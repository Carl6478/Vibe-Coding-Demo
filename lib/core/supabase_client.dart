import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
    final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

    final isUrlInvalid =
        url.isEmpty ||
        url == 'https://your-project-id.supabase.co' ||
        !url.startsWith('https://');
    final isAnonKeyInvalid = anonKey.isEmpty || anonKey == 'your-anon-key';

    if (isUrlInvalid || isAnonKeyInvalid) {
      throw StateError(
        'Supabase is not configured. Update SUPABASE_URL and SUPABASE_ANON_KEY in .env.',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
