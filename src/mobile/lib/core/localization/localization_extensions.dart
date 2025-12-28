import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/localization/app_localization_cubit.dart';

extension LocalizedLabelsExt on BuildContext {
  String? tr(String key) => read<AppLocalizationCubit>().tr(key) ?? key;
  
  /// Translate with a fallback value if key is not found in translations
  String trWithFallback(String key, String fallback) {
    final translated = read<AppLocalizationCubit>().tr(key);
    return translated ?? fallback;
  }
}
