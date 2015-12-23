defmodule Roombex.State.Sensors do
            # Physical bump sensors (0/1)
  defstruct bumper_left: 0,
            bumper_right: 0,
            # Current being expended or charged by the roomba (-32768 - 32767 mA)
            current: 0,
            # Simple 0/1 bump sensors for the light bumpers
            light_bumper_left: 0,
            light_bumper_left_front: 0,
            light_bumper_left_center: 0,
            light_bumper_right_center: 0,
            light_bumper_right_front: 0,
            light_bumper_right: 0,
            # signal strength for the light sensors in the bumper (normalized to 0.0-1.0)
            light_sensor_left: 0,
            light_sensor_left_front: 0,
            light_sensor_left_center: 0,
            light_sensor_right_center: 0,
            light_sensor_right_front: 0,
            light_sensor_right: 0,
            # wheel drop sensors (0/1)
            wheel_drop_left: 0,
            wheel_drop_right: 0
end

defmodule Roombex.State do
  defstruct sensors: %Roombex.State.Sensors{},
            expected_sensor_packets: [],
            unparsed_binary: <<>>,
            mode: :PASSIVE
  import Roombex.Sensor, only: [parse: 2]

  def update(%Roombex.State{sensors: sensors, expected_sensor_packets: [packet|expected]}=state, binary) do
    new_sensor_values = parse(packet, binary)
    sensors = Map.merge(sensors, new_sensor_values)
    %{state | sensors: sensors, expected_sensor_packets: expected}
  end
end
