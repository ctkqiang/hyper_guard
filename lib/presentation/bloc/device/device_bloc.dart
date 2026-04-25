import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../services/device_service.dart';
import 'device_event.dart';
import 'device_state.dart';

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final DeviceService _deviceService;

  DeviceBloc({DeviceService? deviceService})
    : _deviceService = deviceService ?? DeviceService(),
      super(const DeviceState()) {
    on<CheckDevice>(_onCheckDevice);
  }

  Future<void> _onCheckDevice(
    CheckDevice event,
    Emitter<DeviceState> emit,
  ) async {
    emit(state.copyWith(status: DeviceValidationStatus.checking));

    try {
      final isXiaomi = await _deviceService.isXiaomiDevice();
      final isHyperOS = await _deviceService.isHyperOS();

      if (!isXiaomi) {
        emit(
          state.copyWith(
            status: DeviceValidationStatus.incompatible,
            isXiaomi: false,
            isHyperOS: false,
            errorMessage: '此设备非小米/红米设备，HyperGuard 无法运行',
          ),
        );
        return;
      }

      if (!isHyperOS) {
        emit(
          state.copyWith(
            status: DeviceValidationStatus.incompatible,
            isXiaomi: true,
            isHyperOS: false,
            errorMessage: '请升级至 HyperOS 澎湃系统后使用 HyperGuard',
          ),
        );
        return;
      }

      final deviceInfo = await _deviceService.getDeviceInfo();

      emit(
        state.copyWith(
          status: DeviceValidationStatus.compatible,
          isXiaomi: true,
          isHyperOS: true,
          deviceInfo: deviceInfo,
        ),
      );
    } catch (e) {
      debugPrint('DeviceBloc error: $e');
      emit(
        state.copyWith(
          status: DeviceValidationStatus.error,
          errorMessage: '设备检测失败: $e',
        ),
      );
    }
  }
}
