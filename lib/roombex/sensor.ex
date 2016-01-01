defmodule Roombex.Sensor do
  @packets %{
    bumps_and_wheeldrops: %{id: 7, bytes: 1, type: :custom},
    wall: %{id: 8, bytes: 1, type: :one_byte_unsigned},
    cliff_left: %{id: 9, bytes: 1, type: :one_byte_unsigned},
    cliff_left_front: %{id: 10, bytes: 1, type: :one_byte_unsigned},
    cliff_right_front: %{id: 11, bytes: 1, type: :one_byte_unsigned},
    cliff_right: %{id: 12, bytes: 1, type: :one_byte_unsigned},
    virtual_wall: %{id: 13, bytes: 1, type: :one_byte_unsigned},
    overcurrents: %{id: 14, bytes: 1, type: :custom},
    dirt_detect: %{id: 15, bytes: 1, type: :one_byte_unsigned},
    ir_opcode: %{id: 17, bytes: 1, type: :one_byte_unsiged},
    buttons: %{id: 18, bytes: 1, type: :custom},
    distance: %{id: 19, bytes: 2, type: :two_byte_signed},
    angle: %{id: 20, bytes: 2, type: :two_byte_signed},
    charging_state: %{id: 21, bytes: 1, type: :custom},
    voltage: %{id: 22, bytes: 2, type: :two_byte_unsigned},
    current: %{id: 23, bytes: 2, type: :two_byte_signed},
    temperature: %{id: 24, bytes: 2, type: :one_byte_signed},
    battery_charge: %{id: 25, bytes: 2, type: :two_byte_unsigned},
    battery_capacity: %{id: 26, bytes: 2, type: :two_byte_unsigned},
    wall_signal: %{id: 27, bytes: 2, type: :ten_bit_unsigned},
    cliff_left_signal: %{id: 28, bytes: 2, type: :twelve_bit_unsigned},
    cliff_left_front_signal: %{id: 29, bytes: 2, type: :twelve_bit_unsigned},
    cliff_right_front_signal: %{id: 30, bytes: 2, type: :twelve_bit_unsigned},
    cliff_right_signal: %{id: 31, bytes: 2, type: :twelve_bit_unsigned},
    charger_available: %{id: 34, bytes: 1, type: :custom},
    open_interface_mode: %{id: 35, bytes: 1, type: :custom},
    song_number: %{id: 37, bytes: 1, type: :one_byte_unsigned},
    song_playing?: %{id: 38, bytes: 1, type: :one_byte_unsigned},
    velocity: %{id: 39, bytes: 2, type: :two_byte_unsigned}, #mm/sec
    radius: %{id: 40, bytes: 2, type: :two_byte_signed}, #mm
    velocity_right: %{id: 41, bytes: 2, type: :two_byte_signed}, #mm/sec
    velocity_left: %{id: 42, bytes: 2, type: :two_byte_signed}, #mm/sec
    encoder_counts_left: %{id: 43, bytes: 2, type: :two_byte_unsigned},
    encoder_counts_right: %{id: 44, bytes: 2, type: :two_byte_unsigned},
    light_bumper: %{id: 45, bytes: 1, type: :custom},
    light_bumper_left_signal: %{id: 46, bytes: 2, type: :twelve_bit_unsigned},
    light_bumper_left_front_signal: %{id: 47, bytes: 2, type: :twelve_bit_unsigned},
    light_bumper_left_center_signal: %{id: 48, bytes: 2, type: :twelve_bit_unsigned},
    light_bumper_right_center_signal: %{id: 49, bytes: 2, type: :twelve_bit_unsigned},
    light_bumper_right_front_signal: %{id: 50, bytes: 2, type: :twelve_bit_unsigned},
    light_bumper_right_signal: %{id: 51, bytes: 2, type: :twelve_bit_unsigned},
    ir_opcode_left: %{id: 52, bytes: 1, type: :one_byte_unsigned},
    ir_opcode_right: %{id: 53, bytes: 1, type: :one_byte_unsigned},
    left_motor_current: %{id: 54, bytes: 2, type: :two_byte_signed_packets},
    right_motor_current: %{id: 55, bytes: 2, type: :two_byte_signed_packets},
    main_brush_current: %{id: 56, bytes: 2, type: :two_byte_signed_packets},
    side_brush_current: %{id: 57, bytes: 2, type: :two_byte_signed_packets},
    stasis: %{id: 58, bytes: 1, type: :one_byte_unsigned},
  }

  @packet_groups %{
    all: %{id: 100},
    battery: %{id: 3},
    light_bumper_signals: %{id: 106},
  }

  def packet_size(packet) when is_atom(packet), do: Map.fetch!(@packets, packet)[:bytes]

  def packet_id(packet) when is_atom(packet) do
    case Map.get(@packets, packet) do
      %{id: id} -> id
      nil -> Map.fetch!(@packet_groups, packet)[:id]
    end
  end

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

  def parse(:buttons, binary) do
    << clock::size(1),
       schedule::size(1),
       day::size(1),
       hour::size(1),
       minute::size(1),
       dock::size(1),
       spot::size(1),
       clean::size(1) >> = binary
    %{
      button_clock: clock,
      button_schedule: schedule,
      button_day: day,
      button_hour: hour,
      button_minute: minute,
      button_dock: dock,
      button_spot: spot,
      button_clean: clean,
    }
  end

  def parse(:charging_state, binary) do
    << number::unsigned-size(8) >> = binary
    atom = case number do
      0 -> :not_charging
      1 -> :recondition_charging
      2 -> :full_charging
      3 -> :trickle_charging
      4 -> :waiting
      5 -> :charging_fault_condition
    end
    %{charging_state: atom}
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

  def parse(packet, binary) do
    type = Map.fetch!(@packets, packet)[:type]
    parse_by_type(packet, binary, type)
  end

  defp parse_by_type(packet, binary, :one_byte_unsigned) do
    << number::unsigned-size(8) >> = binary
    Map.put(%{}, packet, number)
  end

  defp parse_by_type(packet, binary, :one_byte_signed) do
    << number::signed-size(8) >> = binary
    Map.put(%{}, packet, number)
  end

  defp parse_by_type(packet, binary, :two_byte_unsigned) do
    << number::unsigned-size(16) >> = binary
    Map.put(%{}, packet, number)
  end

  defp parse_by_type(packet, binary, :two_byte_signed) do
    << number::signed-size(16) >> = binary
    Map.put(%{}, packet, number)
  end

  defp parse_by_type(packet, binary, :twelve_bit_unsigned) do
    << number::unsigned-size(16) >> = binary
    Map.put(%{}, packet, number / 4095.0)
  end

  defp parse_by_type(packet, binary, :ten_bit_unsigned) do
    << number::unsigned-size(16) >> = binary
    Map.put(%{}, packet, number / 1023.0)
  end
end
