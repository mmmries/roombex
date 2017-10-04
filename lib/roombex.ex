defmodule Roombex do
  use Bitwise
  alias Roombex.Sensor

  @spec baud(non_neg_integer()) :: binary()
  def baud(rate), do: << 129, baud_code(rate) >>

  @spec clean() :: binary()
  def clean, do: << 135 >>

  @spec control() :: binary()
  def control, do: << 130 >>

  @spec drive(:straight | :stop | :turn_clockwise | :turn_counter_clockwise) :: binary()
  def drive(:straight), do: << 137, 8, 0, 0, 0 >>
  def drive(:stop), do: << 137 >> <> velocity_bytes(0) <> radius_bytes(0)
  def drive(:turn_clockwise), do: << 137, 255, 255, 255, 255 >>
  def drive(:turn_counter_clockwise), do: << 137, 0, 0, 0, 1 >>

  @spec drive(non_neg_integer(), non_neg_integer()) :: binary()
  def drive(velocity_mm_per_sec, radius_mm) do
    << 137 >> <> velocity_bytes(velocity_mm_per_sec) <> radius_bytes(radius_mm)
  end

  @spec force_seeking_dock() :: binary()
  def force_seeking_dock, do: << 143 >>

  @spec full() :: binary()
  def full, do: << 132 >>

  @spec leds([atom()], float(), float()) :: binary()
  def leds(leds, power_color, power_intensity) do
    << 139, leds_byte(leds, 0), float_to_byte(power_color), float_to_byte(power_intensity) >>
  end

  @spec max() :: binary()
  def max, do: << 136 >>

  @spec motors([atom()]) :: binary()
  def motors(which_motors), do: << 138, motors_byte(which_motors, 0) >>

  @spec play(non_neg_integer()) :: binary()
  def play(number) when number >= 0 and number <= 15 do
    << 141, number >>
  end

  @spec power() :: binary()
  def power, do: << 133 >>

  @spec reset() :: binary()
  def reset, do: << 7 >>

  @spec sensors(non_neg_integer() | atom()) :: binary()
  def sensors(packet_group) when packet_group in 0..255, do: << 142, packet_group >>
  def sensors(packet) when is_atom(packet) do
    packet_id = Sensor.packet_id(packet)
    << 142, packet_id >>
  end

  @spec safe() :: binary()
  def safe, do: << 131 >>

  @spec song(non_neg_integer(), list([...])) :: binary()
  def song(number, notes) when number >= 0 and number <= 15 and length(notes) <= 16 do
    << 140, number, length(notes) >> <> notes_bytes(notes, << >>)
  end

  @spec spot() :: binary()
  def spot, do: << 134 >>

  @spec start() :: binary()
  def start, do: << 128 >>

  defp baud_code(300), do: 0
  defp baud_code(600), do: 1
  defp baud_code(1_200), do: 2
  defp baud_code(2_400), do: 3
  defp baud_code(4_800), do: 4
  defp baud_code(9_600), do: 5
  defp baud_code(14_400), do: 6
  defp baud_code(19_200), do: 7
  defp baud_code(28_800), do: 8
  defp baud_code(38_400), do: 9
  defp baud_code(57_600), do: 10
  defp baud_code(115_200), do: 11

  defp float_to_byte(float) when float >= 0.0 and float <= 1.0 do
    Float.round( 255.0 * float ) |> trunc
  end

  defp leds_byte([], byte), do: byte
  defp leds_byte([:dirt_detect|tail], byte), do: leds_byte(tail, byte ||| 1)
  defp leds_byte([:spot|tail], byte), do: leds_byte(tail, byte ||| 2)
  defp leds_byte([:dock|tail], byte), do: leds_byte(tail, byte ||| 4)
  defp leds_byte([:warning|tail], byte), do: leds_byte(tail, byte ||| 8)

  defp notes_bytes([], bytes), do: bytes
  defp notes_bytes([ [note, duration] | tail ], bytes) when note >= 31 and note <= 127 and duration >= 0.0 and duration <= 3.99 do
    duration_byte = Float.round( 64.0 * duration ) |> trunc
    notes_bytes(tail, bytes <> <<note, duration_byte>>)
  end

  defp motors_byte([], byte), do: byte
  defp motors_byte([:main_brush|tail], byte), do: motors_byte(tail, byte ||| 4)
  defp motors_byte([:vacuum|tail], byte), do: motors_byte(tail, byte ||| 2)
  defp motors_byte([:side_brush|tail], byte), do: motors_byte(tail, byte ||| 1)

  defp radius_bytes(mm) when mm >= -2000 and mm <= 2000 do
    << mm::16-signed-integer >>
  end

  defp velocity_bytes(mm_per_sec) when mm_per_sec >= -500 and mm_per_sec <= 500 do
    << mm_per_sec::16-signed-integer >>
  end
end
