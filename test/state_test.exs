defmodule Roombex.StateText do
  use ExUnit.Case, async: true
  alias Roombex.State

  test "it can receive sensor packets and update the state" do
    state = %State{expected_sensor_packets: [:current]}
    state = State.update(state, <<0,76>>)
    assert %{expected_sensor_packets: [], sensors: %{current: 76}} = state
  end

  test "it can receive packets split across multiple calls" do
    state = %State{expected_sensor_packets: [:light_bumper_left_signal]}
    state = State.update(state, <<3>>)
    state = State.update(state, <<61>>)
    assert %{expected_sensor_packets: [], sensors: %{light_bumper_left_signal: 829 / 4095.0}} = state
  end

  test "receiving extra data is a no-op" do
    state = %State{expected_sensor_packets: [:current]}
    binary = <<0, 76>> <> "Roomba version 2015-11-02 build 112\r\n"
    assert %{expected_sensor_packets: [], sensors: %{current: 76}} = State.update(state, binary)
    assert %{expected_sensor_packets: []} = State.update(%State{}, "what is this data???")
  end

  test "it can be expect and receive multiple packets" do
    state = %State{expected_sensor_packets: [:light_bumper_left_signal, :light_bumper_left_front_signal, :light_bumper_left_center_signal, :light_bumper_right_center_signal, :light_bumper_right_front_signal, :light_bumper_right_signal]}
    state = State.update(state, <<0, 88, 0, 11, 0, 14, 0, 137>>)
    state = State.update(state, <<3, 61, 0, 174>>)

    assert %State{expected_sensor_packets: [], unparsed_binary: <<>>} = state
    assert state.sensors.light_bumper_left_signal == 88 / 4095.0
  end

  test "it keeps track of its cartesian coordinates" do
    state = %State{}
    assert state.coordinates == {0,0}
    assert state.heading == 0
    state = State.update(%State{state | expected_sensor_packets: [:distance, :angle]}, << 0, 100, 0>>)
    assert state.coordinates == {0, 0}
    state = State.update(state, << 0 >>)
    assert state.coordinates == {100, 0}
    assert state.heading == 0
    state = State.update(%State{state | expected_sensor_packets: [:distance, :angle]}, << 0, 100, 0, 45 >>)
    assert state.coordinates == {171, 71}
    assert state.heading == 45
    state = State.update(%State{state | expected_sensor_packets: [:distance, :angle]}, << 0, 100, 0, 0 >>)
    assert state.coordinates == {242, 142}
    assert state.heading == 45
    state = State.update(%State{state | expected_sensor_packets: [:distance, :angle]}, << 255, 156, 255, 241 >>)
    assert state.coordinates == {155, 92}
    assert state.heading == 30
  end
end
