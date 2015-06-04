defmodule RoombexTest do
  use ExUnit.Case

  test "start command" do
    assert Roombex.start == [128]
  end

  test "baud command" do
    assert Roombex.baud(2_400) == [129,3]
  end

  test "control command" do
    assert Roombex.control == [130]
  end

  test "safe command" do
    assert Roombex.safe == [131]
  end

  test "full command" do
    assert Roombex.full == [132]
  end

  test "power command" do
    assert Roombex.power == [133]
  end

  test "spot command" do
    assert Roombex.spot == [134]
  end

  test "clean command" do
    assert Roombex.clean == [135]
  end

  test "max command" do
    assert Roombex.max == [136]
  end
end
