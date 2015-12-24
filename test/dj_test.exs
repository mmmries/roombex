defmodule Roombex.DJ.Test do
  use ExUnit.Case, async: true
  alias Roombex.DJ

  test "it reports changes in its state" do
    {:ok, dj} = DJ.start_link([report_to: self(), tty: '/dev/ttyr0', listen_to: []])
    send dj, {:check_on, [:light_bumper]}
    send dj, {:data, <<12>>}
    assert_receive {:roomba_status, %{light_bumper_left_center: 1, light_bumper_right_center: 1}}
  end
end
