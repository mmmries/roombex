defmodule Roombex.DJ do
  require Logger
  use GenServer

  # Client Interface
  def start_link(dj_opts, process_opts \\ []) do
    GenServer.start_link(__MODULE__, dj_opts, process_opts)
  end

  def blink(pid \\ __MODULE__), do: GenServer.cast(pid, :blink)
  def command(pid \\ __MODULE__, binary), do: GenServer.cast(pid, {:command, binary})
  def shimmy(pid \\ __MODULE__), do: GenServer.cast(pid, :shimmy)

  # GenServer Callbacks
  def init(opts) do
    # setup connection
    speed = Keyword.get(opts, :speed, 115_200)
    tty = Keyword.get(opts, :tty, '/dev/ttyAMA0')
    device = :serial.start([speed: speed, open: tty])
    # setup sensor listening
    listen_to = Keyword.get(opts, :listen_to, [:bumps_and_wheeldrops, :light_bumper])
    :timer.send_interval(30, {:check_on, listen_to})
    # initializer connection
    send device, {:send, Roombex.start}
    :timer.sleep(50) # The SCI asks for a pause between commands that change the state
    send device, {:send, Roombex.safe}
    :timer.sleep(50)
    {:ok, %{serial: device, roomba: %Roombex.State{}}}
  end

  def handle_cast({:command, binary}, %{serial: device}=state) do
    send device, {:send, binary}
    {:noreply, state}
  end

  def handle_cast(:blink, %{serial: device}=state) do
    Logger.debug "DJ Roombex :: I'm Blinking Here!"
    which_leds = [:dirt_detect, :max, :clean, :spot, :status_red, :status_green]
    send device, {:send, Roombex.leds(which_leds, 1.0, 1.0)}
    :timer.sleep(1000)
    send device, {:send, Roombex.leds([], 0.0, 0.0)}
    {:noreply, state}
  end

  def handle_cast(:shimmy, %{serial: device}=state) do
    Logger.debug "DJ Roombex :: Shimmy Time!"
    send device, {:send, Roombex.drive(:turn_clockwise)}
    :timer.sleep(100)
    send device, {:send, Roombex.drive(:turn_counter_clockwise)}
    :timer.sleep(100)
    send device, {:send, Roombex.drive(:turn_clockwise)}
    :timer.sleep(100)
    send device, {:send, Roombex.drive(:turn_counter_clockwise)}
    :timer.sleep(100)
    send device, {:send, Roombex.drive(:turn_clockwise)}
    :timer.sleep(100)
    send device, {:send, Roombex.drive(:turn_counter_clockwise)}
    :timer.sleep(100)
    send device, {:send, Roombex.drive(:stop)}
    {:noreply, state}
  end

  def handle_info({:data, data}, %{roomba: roomba}=state) do
    Logger.debug "DJ ROOMBEX :: RECEIVED :: #{data}"
    old_sensors = roomba.sensors
    roomba = Roombex.State.update(roomba, data)
    if ! Map.equal?(old_sensors, roomba.sensors) do
      Logger.debug "#{inspect roomba.sensors}"
    end
    {:noreply, %{state | roomba: roomba}}
  end
  def handle_info({:listen_to, sensor_packets}, %{serial: device, roomba: roomba}=state) do
    Enum.each(sensor_packets, &(send(device, {:send, Roombex.sensor(&1)})))
    new_roomba = Map.put(roomba, :expected_sensor_packets, roomba.expected_sensor_packets ++ sensor_packets)
    {:noreply, %{state | roomba: new_roomba}}
  end
  def handle_info(msg, state) do
    Logger.error "DJ ROOMBEX :: UNEXPECTED MESSAGE :: #{msg}"
    {:noreply, state}
  end
end
