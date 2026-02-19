import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

void main() => Bootstrap.run(const ProviderScope(child: WittApp()));
