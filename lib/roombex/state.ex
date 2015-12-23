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
  import Roombex.Sensor, only: [parse: 2, packet_size: 1]

  def update(%Roombex.State{sensors: sensors}=state, binary) do
    binary = state.unparsed_binary <> binary
    {parsed_sensor_values, unparsed_binary, unparsed_packets} = parse_expected_updates(binary, state.expected_sensor_packets)
    sensors = Map.merge(sensors, parsed_sensor_values)
    %{state | sensors: sensors, expected_sensor_packets: unparsed_packets, unparsed_binary: unparsed_binary}
  end

  defp parse_expected_updates(<<>>, expected_sensor_packets), do: {%{}, <<>>, expected_sensor_packets}
  defp parse_expected_updates(_rest, []), do: {%{}, <<>>, []}
  defp parse_expected_updates(binary, [next | rest]) do
    data_size = packet_size(next)
    if byte_size(binary) >= data_size do
      << sensor_data::binary-size(data_size), unparsed_binary::binary >> = binary
      sensor_updates = parse(next, sensor_data)
      { other_updates, unparsed_binary, expected_sensor_packets } = parse_expected_updates(unparsed_binary, rest)
      { Map.merge(sensor_updates, other_updates), unparsed_binary, expected_sensor_packets }
    else
      {%{}, binary, [next | rest]}
    end
  end
end
