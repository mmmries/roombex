defmodule Roombex do
  use Bitwise

  def baud(rate), do: [129, baud_code(rate)]
  def clean, do: [135]
  def control, do: [130]
  def drive(:straight), do: [137, 8, 0, 0, 0]
  def drive(:turn_clockwise), do: [137, 255, 255, 255, 255]
  def drive(:turn_counter_clockwise), do: [137, 0, 0, 0, 1]
  def drive(velocity_mm_per_sec, radius_mm) do
    [137] ++ velocity_bytes(velocity_mm_per_sec) ++ radius_bytes(radius_mm)
  end
  def full, do: [132]
  def max, do: [136]
  def power, do: [133]
  def safe, do: [131]
  def spot, do: [134]
  def start, do: [128]

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

  defp radius_bytes(mm) when mm >= -2000 and mm <= 2000 do
    << mm::16-signed-integer >> |> :erlang.binary_to_list
  end

  defp velocity_bytes(mm_per_sec) when mm_per_sec >= -500 and mm_per_sec <= 500 do
    << mm_per_sec::16-signed-integer >> |> :erlang.binary_to_list
  end
end
