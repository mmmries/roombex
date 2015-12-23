defmodule Roombex.Sensor do
  @packet_sizes %{
    bumps_and_wheeldrops: 1,
    current: 2,
    light_bumper_signal: 2,
    light_bumper: 1,
  }

  def bumps_and_wheeldrops(binary) do
    << _rest::size(4),
       wheel_drop_left::unsigned-size(1),
       wheel_drop_right::unsigned-size(1),
       bumper_left::unsigned-size(1),
       bumper_right::unsigned-size(1), >> = binary
    %{
      wheel_drop_left: wheel_drop_left,
      wheel_drop_right: wheel_drop_right,
      bumper_left: bumper_left,
      bumper_right: bumper_right,
    }
  end

  def current(binary) do
    << current::signed-size(16) >> = binary
    current
  end

  def light_bumper(binary) do
    << _rest::size(2),
       right::unsigned-size(1),
       right_front::unsigned-size(1),
       right_center::unsigned-size(1),
       left_center::unsigned-size(1),
       left_front::unsigned-size(1),
       left::unsigned-size(1) >> = binary

    %{
      left: left,
      left_front: left_front,
      left_center: left_center,
      right_center: right_center,
      right_front: right_front,
      right: right,
    }
  end

  def light_bumper_signal(binary) do
    << strength::unsigned-size(16) >> = binary
    strength
  end

  def light_bumper_signal_ratio(binary) do
    light_bumper_signal(binary) / 4095.0
  end
end
