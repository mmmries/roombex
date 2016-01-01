defmodule Roombex.SensorTest do
  use ExUnit.Case, async: true
  alias Roombex.Sensor

  test "parsing light bumper signal packets" do
    assert %{light_sensor_left: 88.0 / 4095.0} = Sensor.parse(:light_sensor_left, <<0,88>>)
    assert %{light_sensor_right_center: 829 / 4095.0} = Sensor.parse(:light_sensor_right_center, <<3,61>>)
  end

  test "cliff_left_signal" do
    assert %{cliff_left_signal: 537 / 4095.0} = Sensor.parse(:cliff_left_signal, << 2, 25 >>)
  end

  test "cliff_right_front_signal" do
    assert %{cliff_right_front_signal: 1049 / 4095.0} = Sensor.parse(:cliff_right_front_signal, << 4, 25 >>)
  end

  test "parsing current packets" do
    assert %{current: -117} == Sensor.parse(:current, <<255, 139>>)
  end

  test "parsing bumps and wheeldrops" do
    assert %{bumper_left: 0, bumper_right: 0, wheel_drop_left: 0, wheel_drop_right: 0} = Sensor.parse(:bumps_and_wheeldrops, <<0>>)
    assert %{bumper_right: 1} = Sensor.parse(:bumps_and_wheeldrops, <<1>>)
    assert %{bumper_left: 1} = Sensor.parse(:bumps_and_wheeldrops, <<2>>)
  end

  test "parsing light bumper" do
    assert %{light_bumper_left: 0,
             light_bumper_left_front: 0,
             light_bumper_left_center: 0,
             light_bumper_right_center: 0,
             light_bumper_right_front: 0,
             light_bumper_right: 0} = Sensor.parse(:light_bumper, <<0>>)
    assert %{light_bumper_left_center: 1, light_bumper_right_center: 1} = Sensor.parse(:light_bumper, <<12>>)
    assert %{light_bumper_left: 1} = Sensor.parse(:light_bumper, <<1>>)
    assert %{light_bumper_right: 1, light_bumper_right_front: 1} = Sensor.parse(:light_bumper, <<48>>)
  end

  test "parsing virtual wall" do
    assert %{virtual_wall: 1} = Sensor.parse(:virtual_wall, << 1 >>)
  end

  test "it knows the size of sensor packets" do
    assert Sensor.packet_size(:light_bumper) == 1
    assert Sensor.packet_size(:light_sensor_left) == 2
    assert Sensor.packet_size(:cliff_left_front_signal) == 2
    assert Sensor.packet_size(:cliff_right_signal) == 2
    assert Sensor.packet_size(:virtual_wall) == 1
  end

  test "packet_size throws an error for unknown packets" do
    assert_raise KeyError, fn() ->
      Sensor.packet_size(:wat)
    end
  end
end
