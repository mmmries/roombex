defmodule RoombexTest do
  use ExUnit.Case

  test "start command" do
    assert Roombex.start == << 128 >>
  end

  test "baud command" do
    assert Roombex.baud(2_400) == << 129,3 >>
  end

  test "control command" do
    assert Roombex.control == << 130 >>
  end

  test "safe command" do
    assert Roombex.safe == << 131 >>
  end

  test "full command" do
    assert Roombex.full == << 132 >>
  end

  test "power command" do
    assert Roombex.power == << 133 >>
  end

  test "spot command" do
    assert Roombex.spot == << 134 >>
  end

  test "clean command" do
    assert Roombex.clean == << 135 >>
  end

  test "max command" do
    assert Roombex.max == << 136 >>
  end

  test "drive command" do
    assert Roombex.drive(-200, 500) == << 137, 255, 56, 1, 244 >>
  end

  test "drive command special cases" do
    assert Roombex.drive(:straight) == << 137, 8, 0, 0, 0 >>
    assert Roombex.drive(:turn_clockwise) == << 137, 255, 255, 255, 255 >>
    assert Roombex.drive(:turn_counter_clockwise) == << 137, 0, 0, 0, 1 >>
  end

  test "motors command" do
    assert Roombex.motors([:main_brush, :side_brush]) == << 138, 5 >>
    assert Roombex.motors([:side_brush]) == << 138, 1 >>
  end

  test "leds command" do
    assert Roombex.leds([:dirt_detect, :spot, :status_red], 0.0, 0.5) == << 139, 25, 0, 128 >>
  end

  test "song command" do
    song = [[31, 0.5], [95, 0.75], [65, 0.25]]
    assert Roombex.song(4, song) == << 140, 4, 3, 31, 32, 95, 48, 65, 16 >>
  end

  test "play command" do
    assert Roombex.play(4) == << 141, 4 >>
  end

  test "sensors command" do
    assert Roombex.sensors(:all) == << 142 , 0 >>
    assert Roombex.sensors(:sensors) == << 142 , 1 >>
    assert Roombex.sensors(:interface) == << 142 , 2 >>
    assert Roombex.sensors(:electronics) == << 142 , 3 >>
  end

  test "force seeking dock" do
    assert Roombex.force_seeking_dock == << 143 >>
  end
end
