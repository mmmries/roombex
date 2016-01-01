defmodule Roombex.DJ do
  require Logger
  use GenServer
  alias Roombex.State

  @baud_rate 115_200

  # Client Interface
  def start_link(dj_opts, process_opts \\ []) do
    GenServer.start_link(__MODULE__, dj_opts, process_opts)
  end

  def command(pid \\ __MODULE__, binary), do: GenServer.cast(pid, {:command, binary})
  def reset(pid \\ __MODULE__), do: GenServer.cast(pid, :reset)
  def sensors(pid \\ __MODULE__), do: GenServer.call(pid, :sensors)

  # GenServer Callbacks
  def init(opts) do
    # setup connection
    tty = Keyword.fetch!(opts, :tty)
    {:ok, serial} = Serial.start_link()
    Serial.set_speed(serial, @baud_rate)
    Serial.open(serial, tty)
    Serial.connect(serial)
    # who should receive status updates?
    report_to = Keyword.get(opts, :report_to, nil)
    send self(), :safe_mode
    {:ok, %{serial: serial, roomba: %State{}, report_to: report_to}}
  end

  def handle_call(:sensors, _from, %{roomba: %State{sensors: sensors}}=state) do
    {:reply, sensors, state}
  end

  def handle_cast({:command, binary}, %{serial: device}=state) do
    Serial.send_data(device, binary)
    {:noreply, state}
  end
  def handle_cast(:reset, %{serial: serial}=state) do
    Serial.set_speed(serial, 19_200) # sometimes the roomba gets set back to the wrong baud rate so we try a reset at the lower baud rate as well
    Serial.send_data(serial, Roombex.reset)
    Serial.set_speed(serial, @baud_rate)
    Serial.send_data(serial, Roombex.reset)
    send self(), :safe_mode
    :timer.sleep(10_000)
    {:noreply, state}
  end

  def handle_info({:elixir_serial, _pid, data}, %{roomba: roomba}=state) do
    old_sensors = roomba.sensors
    roomba = Roombex.State.update(roomba, data)
    if ! Map.equal?(old_sensors, roomba.sensors) do
      report_sensor_change(roomba, state)
    end
    {:noreply, %{state | roomba: roomba}}
  end
  def handle_info({:check_on, sensor_packets}, %{serial: device, roomba: roomba}=state) do
    Enum.each(sensor_packets, &(Serial.send_data(device, Roombex.sensors(&1))))
    # note: rather than handling the case of a faulty UART connection to the roomba, we just ignore old requests that weren't fulfilled
    new_roomba = Map.put(roomba, :expected_sensor_packets, sensor_packets)
    {:noreply, %{state | roomba: new_roomba}}
  end
  def handle_info(:safe_mode, %{serial: serial}=state) do
    Serial.send_data(serial, Roombex.start)
    :timer.sleep(50)
    Serial.send_data(serial, Roombex.safe)
    :timer.sleep(50)
    {:noreply, state}
  end
  def handle_info(msg, state) do
    Logger.error "DJ ROOMBEX :: UNEXPECTED MESSAGE :: #{inspect msg}"
    {:noreply, state}
  end

  # Private Functions
  defp report_sensor_change(_roomba, %{report_to: nil}), do: nil #no one to report to
  defp report_sensor_change(roomba, %{report_to: report_to}) do
    send report_to, {:roomba_status, roomba.sensors}
  end
end
