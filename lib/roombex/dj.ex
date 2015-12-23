defmodule Roombex.DJ do
  require Logger
  use GenServer

  # Client Interface
  def start_link(tty_device, opts \\ []) do
    GenServer.start_link(__MODULE__, tty_device, opts)
  end

  def blink(pid \\ __MODULE__), do: GenServer.cast(pid, :blink)
  def command(pid \\ __MODULE__, binary), do: GenServer.cast(pid, {:command, binary})
  def shimmy(pid \\ __MODULE__), do: GenServer.cast(pid, :shimmy)

  # GenServer Callbacks
  def init(tty_device) do
    device = :serial.start([speed: 57_600, open: :erlang.bitstring_to_list(tty_device)])
    send device, {:send, Roombex.start}
    :timer.sleep(50) # The SCI asks for a pause between commands that change the state
    send device, {:send, Roombex.safe}
    :timer.sleep(50)
    {:ok, device}
  end

  def handle_cast({:command, binary}, device) do
    send device, {:send, binary}
    {:noreply, device}
  end

  def handle_cast(:blink, device) do
    Logger.debug "DJ Roombex :: I'm Blinking Here!"
    which_leds = [:dirt_detect, :max, :clean, :spot, :status_red, :status_green]
    send device, {:send, Roombex.leds(which_leds, 1.0, 1.0)}
    :timer.sleep(1000)
    send device, {:send, Roombex.leds([], 0.0, 0.0)}
    {:noreply, device}
  end

  def handle_cast(:shimmy, device) do
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
    {:noreply, device}
  end

  def handle_info({:data, data}, _device) do
    Logger.debug "DJ ROOMBEX :: RECEIVED :: #{data}"
  end
  def handle_info(msg, _device) do
    Logger.error "DJ ROOMBEX :: UNEXPECTED MESSAGE :: #{msg}"
  end
end
