defmodule Roombex.DJ do
  require Logger
  use GenServer
  alias Roombex.State
  alias Roombex.State.Sensors

  # Client Interface
  def start_link(dj_opts, process_opts \\ []) do
    GenServer.start_link(__MODULE__, dj_opts, process_opts)
  end

  def command(pid \\ __MODULE__, binary), do: GenServer.cast(pid, {:command, binary})
  def sensors(pid \\ __MODULE__), do: GenServer.call(pid, :sensors)

  # GenServer Callbacks
  def init(opts) do
    # setup connection
    speed = Keyword.get(opts, :speed, 115_200)
    tty = Keyword.get(opts, :tty, '/dev/ttyAMA0')
    device = :serial.start([speed: speed, open: tty])
    # setup sensor listening
    listen_to = Keyword.get(opts, :listen_to, [:bumps_and_wheeldrops, :light_bumper])
    listen_interval = Keyword.get(opts, :listen_interval, 100)
    :timer.send_interval(listen_interval, {:check_on, listen_to})
    # who should receive status updates?
    report_to = Keyword.get(opts, :report_to, nil)
    # initialize connection
    send device, {:send, Roombex.start}
    :timer.sleep(50) # The SCI asks for a pause between commands that change the state
    send device, {:send, Roombex.safe}
    :timer.sleep(50)
    {:ok, %{serial: device, roomba: %Roombex.State{}, report_to: report_to}}
  end

  def handle_call(:sensors, _from, %{roomba: %State{sensors: sensors}}=state) do
    {:reply, sensors, state}
  end

  def handle_cast({:command, binary}, %{serial: device}=state) do
    send device, {:send, binary}
    {:noreply, state}
  end

  def handle_info({:data, data}, %{roomba: roomba}=state) do
    old_sensors = roomba.sensors
    roomba = Roombex.State.update(roomba, data)
    if ! Map.equal?(old_sensors, roomba.sensors) do
      report_sensor_change(roomba, state)
    end
    {:noreply, %{state | roomba: roomba}}
  end
  def handle_info({:check_on, sensor_packets}, %{serial: device, roomba: roomba}=state) do
    Enum.each(sensor_packets, &(send(device, {:send, Roombex.sensors(&1)})))
    new_roomba = Map.put(roomba, :expected_sensor_packets, roomba.expected_sensor_packets ++ sensor_packets)
    {:noreply, %{state | roomba: new_roomba}}
  end
  def handle_info(msg, state) do
    Logger.error "DJ ROOMBEX :: UNEXPECTED MESSAGE :: #{inspect msg}"
    {:noreply, state}
  end

  # Private Functions
  defp report_sensor_change(roomba, %{report_to: nil}), do: nil #no one to report to
  defp report_sensor_change(roomba, %{report_to: report_to}) do
    send report_to, {:roomba_status, roomba.sensors}
  end
end
