import 'package:equatable/equatable.dart';

enum AppThemeMode { system, light, dark }

class ThemeState extends Equatable {
  final AppThemeMode mode;

  const ThemeState(this.mode);

  ThemeState copyWith({AppThemeMode? mode}) => ThemeState(mode ?? this.mode);

  @override
  List<Object?> get props => [mode];
}
