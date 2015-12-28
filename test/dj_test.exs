defmodule Roombex.DJ.Test do
  use ExUnit.Case, async: true
  alias Roombex.DJ

  @test_tty '/dev/ttyr0'

  test "it reports changes in its state" do
    {:ok, dj} = DJ.start_link([report_to: self(), tty: @test_tty, listen_to: []])
    send dj, {:check_on, [:light_bumper]}
    send dj, {:data, <<12>>}
    assert_receive {:roomba_status, %{light_bumper_left_center: 1, light_bumper_right_center: 1}}
  end

  test "it reports its state when asked" do
    {:ok, dj} = DJ.start_link([tty: @test_tty])
    assert %Roombex.State.Sensors{light_bumper_left_center: 0} = DJ.sensors(dj)
  end
end
