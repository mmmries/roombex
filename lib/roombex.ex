defmodule Roombex do
  use Bitwise

  def baud(rate), do: << 129, baud_code(rate) >>
  def clean, do: << 135 >>
  def control, do: << 130 >>
  def drive(:straight), do: << 137, 8, 0, 0, 0 >>
  def drive(:stop), do: << 137 >> <> velocity_bytes(0) <> radius_bytes(0)
  def drive(:turn_clockwise), do: << 137, 255, 255, 255, 255 >>
  def drive(:turn_counter_clockwise), do: << 137, 0, 0, 0, 1 >>
  def drive(velocity_mm_per_sec, radius_mm) do
    << 137 >> <> velocity_bytes(velocity_mm_per_sec) <> radius_bytes(radius_mm)
  end
  def force_seeking_dock, do: << 143 >>
  def full, do: << 132 >>
  def leds(leds, power_color, power_intensity) do
    << 139, leds_byte(leds, 0), float_to_byte(power_color), float_to_byte(power_intensity) >>
  end
  def max, do: << 136 >>
  def motors(which_motors), do: << 138, motors_byte(which_motors, 0) >>
  def play(number) when number >= 0 and number <= 15 do
    << 141, number >>
  end
  def power, do: << 133 >>
  def sensors(:all), do: << 142, 100 >>
  def sensors(:bumps_and_wheeldrops), do: << 142, 7 >>
  def sensors(:light_bumper), do: << 142, 45 >>
  def sensors(:light_sensors), do: << 142, 106 >>
  def sensors(:motor_currents), do: << 142, 107 >>
  def sensors(packet_group) when packet_group in 0..255, do: << 142, packet_group >>
  def safe, do: << 131 >>
  def song(number, notes) when number >= 0 and number <= 15 and length(notes) <= 16 do
    << 140, number, length(notes) >> <> notes_bytes(notes, << >>)
  end
  def spot, do: << 134 >>
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
  defp leds_byte([:max|tail], byte), do: leds_byte(tail, byte ||| 2)
  defp leds_byte([:clean|tail], byte), do: leds_byte(tail, byte ||| 4)
  defp leds_byte([:spot|tail], byte), do: leds_byte(tail, byte ||| 8)
  defp leds_byte([:status_red|tail], byte), do: leds_byte(tail, byte ||| 16)
  defp leds_byte([:status_green|tail], byte), do: leds_byte(tail, byte ||| 32)

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
