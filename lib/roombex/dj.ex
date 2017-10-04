defmodule Roombex.DJ do
  require Logger
  use GenServer
  alias Roombex.State
  alias Nerves.UART

  @baud_rate 115_200

  # Client Interface
  @spec start_link(keyword(), keyword()) :: GenServer.on_start
  def start_link(dj_opts, process_opts \\ []) do
    GenServer.start_link(__MODULE__, dj_opts, process_opts)
  end

  @spec command(GenServer.server, binary()) :: :ok
  def command(pid \\ __MODULE__, binary), do: GenServer.cast(pid, {:command, binary})

  @spec reset(GenServer.server) :: :ok
  def reset(pid \\ __MODULE__), do: GenServer.cast(pid, :reset)

  @spec sensors(GenServer.server) :: %Roombex.State.Sensors{}
  def sensors(pid \\ __MODULE__), do: GenServer.call(pid, :sensors)

  @impl GenServer
  def init(opts) do
    # setup connection
    tty = Keyword.fetch!(opts, :tty)
    {:ok, serial} = UART.start_link()
    :ok = UART.open(serial, tty, speed: @baud_rate, active: true)
    # who should receive status updates?
    report_to = Keyword.get(opts, :report_to, nil)
    send self(), :safe_mode
    :timer.send_interval(500, :broadcast_sensors)
    {:ok, %{serial: serial, roomba: %State{}, report_to: report_to}}
  end

  @impl GenServer
  def handle_call(:sensors, _from, %{roomba: %State{sensors: sensors}}=state) do
    {:reply, sensors, state}
  end

  @impl GenServer
  def handle_cast({:command, binary}, %{serial: device}=state) do
    UART.write(device, binary)
    {:noreply, state}
  end
  @impl GenServer
  def handle_cast(:reset, %{serial: serial}=state) do
    UART.configure(serial, speed: 19_200) # sometimes the roomba gets set back to the wrong baud rate so we try a reset at the lower baud rate as well
    UART.write(serial, Roombex.reset())
    UART.configure(serial, speed: @baud_rate)
    UART.write(serial, Roombex.reset())
    send self(), :safe_mode
    :timer.sleep(10_000)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:broadcast_sensors, %{roomba: roomba}=state) do
    report_sensor_change(roomba, state)
    {:noreply, state}
  end
  @impl GenServer
  def handle_info({:nerves_uart, _uart, data}, %{roomba: roomba}=state) do
    old_sensors = roomba.sensors
    roomba = Roombex.State.update(roomba, data)
    if ! Map.equal?(old_sensors, roomba.sensors) do
      report_sensor_change(roomba, state)
    end
    {:noreply, %{state | roomba: roomba}}
  end
  @impl GenServer
  def handle_info({:check_on, sensor_packets}, %{serial: device, roomba: roomba}=state) do
    Enum.each(sensor_packets, &(UART.write(device, Roombex.sensors(&1))))
    # note: rather than handling the case of a faulty UART connection to the roomba, we just ignore old requests that weren't fulfilled
    new_roomba = Map.put(roomba, :expected_sensor_packets, sensor_packets)
    {:noreply, %{state | roomba: new_roomba}}
  end
  @impl GenServer
  def handle_info(:safe_mode, %{serial: serial}=state) do
    UART.write(serial, Roombex.start)
    :timer.sleep(50)
    UART.write(serial, Roombex.safe)
    :timer.sleep(50)
    {:noreply, state}
  end
  @impl GenServer
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
