import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ai/witt_ai.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

void main() => Bootstrap.run(
  ProviderScope(
    overrides: [
      aiRouterProvider.overrideWithValue(
        AiRouter(
          supabaseUrl: dotenv.env['SUPABASE_URL'] ?? '',
          supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        ),
      ),
    ],
    child: const WittApp(),
  ),
);
