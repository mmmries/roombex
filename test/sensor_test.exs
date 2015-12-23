defmodule Roombex.SensorTest do
  use ExUnit.Case, async: true
  alias Roombex.Sensor

  test "parsing light bumper signal packets" do
    assert 88 == Sensor.light_bumper_signal(<<0,88>>)
    assert 829 == Sensor.light_bumper_signal(<<3,61>>)
  end

  test "parsing light bumper signal packets as a ratio" do
    assert 829.0 / 4095.0 == Sensor.light_bumper_signal_ratio(<<3,61>>)
  end

  test "parsing current packets" do
    assert -117 == Sensor.current(<<255, 139>>)
  end

  test "parsing bumps and wheeldrops" do
    assert %{bumper_left: 0, bumper_right: 0, wheel_drop_left: 0, wheel_drop_right: 0} == Sensor.bumps_and_wheeldrops(<<0>>)
    assert %{bumper_right: 1} = Sensor.bumps_and_wheeldrops(<<1>>)
    assert %{bumper_left: 1} = Sensor.bumps_and_wheeldrops(<<2>>)
  end

  test "parsing light bumper" do
    assert %{left: 0, left_front: 0, left_center: 0, right_center: 0, right_front: 0, right: 0} == Sensor.light_bumper(<<0>>)
    assert %{left_center: 1, right_center: 1} = Sensor.light_bumper(<<12>>)
    assert %{left: 1} = Sensor.light_bumper(<<1>>)
    assert %{right: 1, right_front: 1} = Sensor.light_bumper(<<48>>)
  end
end
