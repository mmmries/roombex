defmodule Roombex.State.Sensors do
            # Angle moved through since last check (-32768 - 32767 degrees)
  defstruct angle: 0,
            # Physical bump sensors (0/1)
            bumper_left: 0,
            bumper_right: 0,
            # Battery State (0 - 65535 mAh)
            battery_charge: 0,
            battery_capacity: 0,
            # Buttons (0/1)
            button_clean: 0,
            button_clock: 0,
            button_day: 0,
            button_dock: 0,
            button_hour: 0,
            button_minute: 0,
            button_schedule: 0,
            button_spot: 0,
            # Chargers Available (0/1)
            charger_available_dock: 0,
            charger_available_internal: 0,
            # Charging State (atom)
            charging_state: :not_charging,
            # Cliff sensors (0/1)
            cliff_left: 0,
            cliff_left_front: 0,
            cliff_right_front: 0,
            cliff_right: 0,
            # Cliff signals (0.0 - 1.0)
            cliff_left_signal: 0.0,
            cliff_left_front_signal: 0.0,
            cliff_right_front_signal: 0.0,
            cliff_right_signal: 0.0,
            # Current being expended or charged (-32768 - 32767 mA)
            current: 0,
            current_left_motor: 0,
            current_main_brush: 0,
            current_right_motor: 0,
            current_side_brush: 0,
            # Dirt detect sensors (0-255)
            dirt_detect: 0,
            # Distance, millimeters moved since last check (-32768 - 32767 mm)
            distance: 0,
            # Encoders: number of encoder clicks, rolls over (0 - 65535)
            encoder_counts_left: 0,
            encoder_counts_right: 0,
            # IR Opcodes (0-255)
            ir_opcode: 0,
            ir_opcode_left: 0,
            ir_opcode_right: 0,
            # Simple 0/1 bump sensors for the light bumpers
            light_bumper_left: 0,
            light_bumper_left_front: 0,
            light_bumper_left_center: 0,
            light_bumper_right_center: 0,
            light_bumper_right_front: 0,
            light_bumper_right: 0,
            # signal strength for the light sensors in the bumper (normalized to 0.0-1.0)
            light_bumper_left_signal: 0,
            light_bumper_left_front_signal: 0,
            light_bumper_left_center_signal: 0,
            light_bumper_right_center_signal: 0,
            light_bumper_right_front_signal: 0,
            light_bumper_right_signal: 0,
            # Open Interface Mode (atom :off, :passive, :safe, :full)
            open_interface_mode: :off,
            # Overcurrents (0/1)
            overcurrent_left_wheel: 0,
            overcurrent_right_wheel: 0,
            overcurrent_main_brush: 0,
            overcurrent_side_brush: 0,
            # Song Number (0 - 15)
            song_number: 0,
            # Song Playing? (0 / 1)
            song_playing?: 0,
            # Stasis - making forward progress? (0 / 1)
            stasis: 0,
            # Temperature (-128 - 127 degrees Celsius)
            temperature: 0,
            # Wheel Velocities (-500 - 500 mm/sec)
            velocity_left: 0,
            velocity_right: 0,
            # Virtual wall (0/1)
            virtual_wall: 0,
            # Voltage (0 - 65535 mV)
            voltage: 0,
            # Wall sensor (0/1)
            wall: 0,
            # Wall Signal (0.0-1.0)
            wall_signal: 0.0,
            # wheel drop sensors (0/1)
            wheel_drop_left: 0,
            wheel_drop_right: 0
end

defmodule Roombex.State do
  # coordinates is an inferred value
  # by watching the distance and angle sensors we try to infer our current cartesian coordinates
  defstruct coordinates: {0, 0},
            delta_sensors: %{},
            expected_sensor_packets: [],
            heading: 0,
            mode: :PASSIVE,
            sensors: %Roombex.State.Sensors{},
            unparsed_binary: <<>>
  import Roombex.Sensor, only: [parse: 2, packet_size: 1]

  def update(%Roombex.State{sensors: sensors}=state, binary) do
    binary = state.unparsed_binary <> binary
    {parsed_sensor_values, unparsed_binary, unparsed_packets} = parse_expected_updates(binary, state.expected_sensor_packets)
    delta_sensors = Map.merge(state.delta_sensors, parsed_sensor_values)
    {new_coordinates, new_heading, delta_sensors} = infer_coordinates_and_heading(state, delta_sensors)
    sensors = Map.merge(sensors, parsed_sensor_values)
    %{state | coordinates: new_coordinates, delta_sensors: delta_sensors, heading: new_heading, sensors: sensors, expected_sensor_packets: unparsed_packets, unparsed_binary: unparsed_binary}
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

  def infer_coordinates_and_heading(%{heading: heading, coordinates: {x, y}}, %{angle: angle, distance: distance}=delta_sensors) do
    heading = heading + angle
    radians = heading * (:math.pi / 180.0)
    dx = (distance * :math.cos(radians)) |> Float.round |> trunc
    dy = (distance * :math.sin(radians)) |> Float.round |> trunc
    {{x + dx, y + dy}, heading, Map.drop(delta_sensors, [:angle, :distance])}
  end
  def infer_coordinates_and_heading(%{heading: heading, coordinates: coords}, delta_sensors) do
    {coords, heading, delta_sensors}
  end
end
