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

  @spec check_sensors(GenServer.server, [atom()], non_neg_integer()) :: %Roombex.State.Sensors{}
  def check_sensors(pid \\ __MODULE__, sensor_packets, timeout \\ 100), do: GenServer.call(pid, {:check_sensors, sensor_packets}, timeout)

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
    send self(), :safe_mode
    {:ok, %{serial: serial, roomba: %State{}}}
  end

  @impl GenServer
  def handle_call(:sensors, _from, %{roomba: %State{sensors: sensors}}=state) do
    {:reply, sensors, state}
  end
  @impl GenServer
  def handle_call({:check_sensors, sensor_packets}, from, %{roomba: roomba}=state) do
    Enum.each(sensor_packets, &(UART.write(state.serial, Roombex.sensors(&1))))
    new_roomba = Map.put(roomba, :expected_sensor_packets, sensor_packets)
    state = state |> Map.put(:roomba, new_roomba) |> Map.put(:sensor_client, from)
    {:noreply, state}
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
  def handle_info({:nerves_uart, _uart, data}, %{roomba: roomba, sensor_client: client}=state) do
    roomba = Roombex.State.update(roomba, data)
    if roomba.expected_sensor_packets == [] do
      GenServer.reply(client, roomba.sensors)
    end
    {:noreply, %{state | roomba: roomba}}
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
end
