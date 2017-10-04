# distances are in millimeters
# heading is measured in radians
defmodule Roombex.WhereAmI do
  defstruct x: 0.0,
            y: 0.0,
            heading: 0.0,
            encoder_counts_left: 0,
            encoder_counts_right: 0

  @spec init() :: %__MODULE__{}
  def init() do
    %__MODULE__{}
  end

  @spec init(map()) :: %__MODULE__{}
  def init(%{encoder_counts_left: left, encoder_counts_right: right}) do
    %__MODULE__{encoder_counts_left: left, encoder_counts_right: right}
  end
end
