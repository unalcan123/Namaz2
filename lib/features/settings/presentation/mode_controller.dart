import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppMode { phone, tv }

class ModeController extends StateNotifier<AppMode> {
  ModeController() : super(AppMode.phone);

  void setTvMode() => state = AppMode.tv;
  void setPhoneMode() => state = AppMode.phone;
  void toggleMode() => state = state == AppMode.phone ? AppMode.tv : AppMode.phone;
}

final modeProvider = StateNotifierProvider<ModeController, AppMode>((ref) {
  return ModeController();
});
