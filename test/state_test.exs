defmodule Roombex.StateText do
  use ExUnit.Case, async: true
  alias Roombex.State

  test "it can receive sensor packets and update the state" do
    state = %State{expected_sensor_packets: [:current]}
    state = State.update(state, <<0,76>>)
    assert %{expected_sensor_packets: [], sensors: %{current: 76}} = state
  end

  test "it can receive packets split across multiple calls" do
    state = %State{expected_sensor_packets: [:light_sensor_left]}
    state = State.update(state, <<3>>)
    state = State.update(state, <<61>>)
    assert %{expected_sensor_packets: [], sensors: %{light_sensor_left: 829 / 4095.0}} = state
  end
end
