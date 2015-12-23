defmodule Roombex.StateText do
  use ExUnit.Case, async: true
  alias Roombex.State

  test "it can receive sensor packets and update the state" do
    state = %State{expected_sensor_packets: [:current]}
    state = State.update(state, <<0,76>>)
    assert %{expected_sensor_packets: [], sensors: %{current: 76}} = state
  end
end
