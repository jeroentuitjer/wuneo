part of 'clock_cubit.dart';

class ClockState extends Equatable {
  final DateTime currentTime;

  const ClockState(this.currentTime);

  @override
  List<Object?> get props => [currentTime];
}
