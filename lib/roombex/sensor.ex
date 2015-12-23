defmodule Roombex.Sensor do
  alias Roombex.State.Sensors
  @light_sensors [:light_sensor_left, :light_sensor_left_front, :light_sensor_left_center, :light_sensor_right_center, :light_sensor_right_front, :light_sensor_right]
  @packet_sizes %{
    bumps_and_wheeldrops: 1,
    current: 2,
    light_bumper: 1,
  }

  def packet_size(packet) when packet in @light_sensors, do: 2
  def packet_size(packet), do: Map.get(@packet_sizes, packet)

  def parse(:bumps_and_wheeldrops, binary) do
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

  def parse(:current, binary) do
    << current::signed-size(16) >> = binary
    %{current: current}
  end

  def parse(:light_bumper, binary) do
    << _rest::size(2),
       right::unsigned-size(1),
       right_front::unsigned-size(1),
       right_center::unsigned-size(1),
       left_center::unsigned-size(1),
       left_front::unsigned-size(1),
       left::unsigned-size(1) >> = binary

    %{
      light_bumper_left: left,
      light_bumper_left_front: left_front,
      light_bumper_left_center: left_center,
      light_bumper_right_center: right_center,
      light_bumper_right_front: right_front,
      light_bumper_right: right,
    }
  end

  def parse(packet, binary) when packet in @light_sensors do
    << strength::unsigned-size(16) >> = binary
    Map.put(%{}, packet, strength / 4095.0)
  end
end
