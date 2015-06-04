defmodule Roombex do
  def baud(rate), do: [129, baud_code(rate)]
  def clean, do: [135]
  def control, do: [130]
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
end
