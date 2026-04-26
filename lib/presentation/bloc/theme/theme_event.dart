import 'package:equatable/equatable.dart';
import 'theme_state.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class SetThemeMode extends ThemeEvent {
  final AppThemeMode mode;
  const SetThemeMode(this.mode);

  @override
  List<Object?> get props => [mode];
}
