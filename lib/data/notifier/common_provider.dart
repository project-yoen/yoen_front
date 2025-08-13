import 'package:flutter_riverpod/flutter_riverpod.dart';

final dialogOpenProvider = StateProvider<bool>((ref) => false);

final overviewTabIndexProvider = StateProvider<int>((ref) => 0);
