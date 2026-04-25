import 'package:equatable/equatable.dart';

enum DeviceValidationStatus {
  initial,
  checking,
  compatible,
  incompatible,
  error,
}

class DeviceState extends Equatable {
  final DeviceValidationStatus status;
  final bool isXiaomi;
  final bool isHyperOS;
  final Map<String, dynamic> deviceInfo;
  final String? errorMessage;

  const DeviceState({
    this.status = DeviceValidationStatus.initial,
    this.isXiaomi = false,
    this.isHyperOS = false,
    this.deviceInfo = const {},
    this.errorMessage,
  });

  DeviceState copyWith({
    DeviceValidationStatus? status,
    bool? isXiaomi,
    bool? isHyperOS,
    Map<String, dynamic>? deviceInfo,
    String? errorMessage,
  }) {
    return DeviceState(
      status: status ?? this.status,
      isXiaomi: isXiaomi ?? this.isXiaomi,
      isHyperOS: isHyperOS ?? this.isHyperOS,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    isXiaomi,
    isHyperOS,
    deviceInfo,
    errorMessage,
  ];
}
