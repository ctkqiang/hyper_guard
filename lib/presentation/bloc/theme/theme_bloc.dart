import 'package:bloc/bloc.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState(AppThemeMode.system)) {
    on<SetThemeMode>((event, emit) => emit(ThemeState(event.mode)));
  }
}
