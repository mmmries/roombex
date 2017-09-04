defmodule Roombex.SensorTest do
  use ExUnit.Case, async: true
  alias Roombex.Sensor

  test "parsing light bumper signal packets" do
    expected = 88.0 / 4095.0
    assert %{light_bumper_left_signal: ^expected} = Sensor.parse(:light_bumper_left_signal, <<0,88>>)
    expected = 829 / 4095.0
    assert %{light_bumper_right_center_signal: ^expected} = Sensor.parse(:light_bumper_right_center_signal, <<3,61>>)
  end

  test "cliff_left_signal" do
    expected = 537 / 4095.0
    assert %{cliff_left_signal: ^expected} = Sensor.parse(:cliff_left_signal, << 2, 25 >>)
  end

  test "cliff_right_front_signal" do
    expected = 1049 / 4095.0
    assert %{cliff_right_front_signal: ^expected} = Sensor.parse(:cliff_right_front_signal, << 4, 25 >>)
  end

  test "parsing current packets" do
    assert %{current: -117} == Sensor.parse(:current, <<255, 139>>)
  end

  test "parsing bumps and wheeldrops" do
    assert %{bumper_left: 0, bumper_right: 0, wheel_drop_left: 0, wheel_drop_right: 0} = Sensor.parse(:bumps_and_wheeldrops, <<0>>)
    assert %{bumper_right: 1} = Sensor.parse(:bumps_and_wheeldrops, <<1>>)
    assert %{bumper_left: 1} = Sensor.parse(:bumps_and_wheeldrops, <<2>>)
  end

  test "parsing overcurrents" do
    assert %{overcurrent_left_wheel: 1, overcurrent_side_brush: 1} = Sensor.parse(:overcurrents, << 0b00010001 >>)
  end

  test "parsing buttons" do
    assert %{button_spot: 1, button_hour: 1} = Sensor.parse(:buttons, << 0b00010010 >>)
  end

  test "parsing charging_state" do
    assert %{charging_state: :trickle_charging} = Sensor.parse(:charging_state, <<3>>)
  end

  test "parsing charger_available" do
    assert %{charger_available_dock: 1, charger_available_internal: 0} = Sensor.parse(:charger_available, << 0b00000010 >>)
  end

  test "parsing open_interface_mode" do
    assert %{open_interface_mode: :off} = Sensor.parse(:open_interface_mode, <<0>>)
    assert %{open_interface_mode: :passive} = Sensor.parse(:open_interface_mode, <<1>>)
    assert %{open_interface_mode: :safe} = Sensor.parse(:open_interface_mode, <<2>>)
    assert %{open_interface_mode: :full} = Sensor.parse(:open_interface_mode, <<3>>)
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
    assert Sensor.packet_size(:light_bumper_left_signal) == 2
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
