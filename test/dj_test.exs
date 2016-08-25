# using a pty for testing no longer works on OSX
defmodule Roombex.DJ.Test do
  use ExUnit.Case
  alias Roombex.DJ

  @test_tty '/dev/ttyp0'

  @tag :pending
  test "it reports changes in its state" do
    {:ok, dj} = DJ.start_link([report_to: self(), tty: @test_tty, listen_to: []])
    send dj, {:check_on, [:light_bumper]}
    send dj, {:elixir_serial, self(), <<12>>}
    :timer.sleep(10)
    assert_receive {:roomba_status, %{light_bumper_left_center: 1, light_bumper_right_center: 1}}
  end

  @tag :pending
  test "it reports its state when asked" do
    {:ok, dj} = DJ.start_link([tty: @test_tty])
    assert %Roombex.State.Sensors{light_bumper_left_center: 0} = DJ.sensors(dj)
  end

  @tag :pending
  test "it can reset the roomba" do
    {:ok, dj} = DJ.start_link(tty: @test_tty)
    DJ.reset(dj)
    :timer.sleep(10) #Just a smoke test for now to exercise the codepath
  end
end
