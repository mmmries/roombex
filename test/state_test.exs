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

  test "receiving extra data is a no-op" do
    state = %State{expected_sensor_packets: [:current]}
    binary = <<0, 76>> <> "Roomba version 2015-11-02 build 112\r\n"
    assert %{expected_sensor_packets: [], sensors: %{current: 76}} = State.update(state, binary)
    assert %{expected_sensor_packets: []} = State.update(%State{}, "what is this data???")
  end

  test "it can be expect and receive multiple packets" do
    state = %State{expected_sensor_packets: [:light_sensor_left, :light_sensor_left_front, :light_sensor_left_center, :light_sensor_right_center, :light_sensor_right_front, :light_sensor_right]}
    state = State.update(state, <<0, 88, 0, 11, 0, 14, 0, 137>>)
    state = State.update(state, <<3, 61, 0, 174>>)

    assert %State{expected_sensor_packets: [], unparsed_binary: <<>>} = state
    assert state.sensors.light_sensor_left == 88 / 4095.0
  end
end
