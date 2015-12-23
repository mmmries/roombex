defmodule Roombex.SensorTest do
  use ExUnit.Case, async: true
  alias Roombex.Sensor
  alias Roombex.State.Sensors

  test "parsing light bumper signal packets" do
    assert %Sensors{light_sensor_left: 88.0 / 4095.0} = Sensor.parse(:light_sensor_left, <<0,88>>)
    assert %Sensors{light_sensor_right_center: 829 / 4095.0} = Sensor.parse(:light_sensor_right_center, <<3,61>>)
  end

  test "parsing current packets" do
    assert %Sensors{current: -117} == Sensor.parse(:current, <<255, 139>>)
  end

  test "parsing bumps and wheeldrops" do
    assert %Sensors{bumper_left: 0, bumper_right: 0, wheel_drop_left: 0, wheel_drop_right: 0} = Sensor.parse(:bumps_and_wheeldrops, <<0>>)
    assert %Sensors{bumper_right: 1} = Sensor.parse(:bumps_and_wheeldrops, <<1>>)
    assert %Sensors{bumper_left: 1} = Sensor.parse(:bumps_and_wheeldrops, <<2>>)
  end

  test "parsing light bumper" do
    assert %Sensors{light_bumper_left: 0,
                    light_bumper_left_front: 0,
                    light_bumper_left_center: 0,
                    light_bumper_right_center: 0,
                    light_bumper_right_front: 0,
                    light_bumper_right: 0} = Sensor.parse(:light_bumper, <<0>>)
    assert %Sensors{light_bumper_left_center: 1, light_bumper_right_center: 1} = Sensor.parse(:light_bumper, <<12>>)
    assert %Sensors{light_bumper_left: 1} = Sensor.parse(:light_bumper, <<1>>)
    assert %Sensors{light_bumper_right: 1, light_bumper_right_front: 1} = Sensor.parse(:light_bumper, <<48>>)
  end
end
