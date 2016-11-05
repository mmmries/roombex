defmodule Roombex.DeadReckonerTest do
  use ExUnit.Case, async: true
  import Roombex.DeadReckoner
  alias Roombex.WhereAmI

  test "initial idling" do
    whereami = WhereAmI.init
      |> update(%{encoder_counts_left: 0, encoder_counts_right: 0})
    assert_in_delta whereami.heading, 0.0, 0.01
    assert_in_delta whereami.x,       0.0, 0.1
    assert_in_delta whereami.y,       0.0, 0.1
  end

  test "moving forward" do
    whereami = WhereAmI.init
      |> update(%{encoder_counts_left: 509, encoder_counts_right: 509})
    assert_in_delta whereami.heading, 0.0, 0.01
    assert_in_delta whereami.x,     226.2, 0.1
    assert_in_delta whereami.y,       0.0, 0.1
  end

  test "moving forward through a 90° turn to the right" do
    radius_left  = 1235.0
    radius_right = 1000.0
    distance_left_wheel  = (1/4) * 2 * :math.pi * radius_left
    distance_right_wheel = (1/4) * 2 * :math.pi * radius_right
    left = distance_to_encoder_counts(distance_left_wheel)
    right = distance_to_encoder_counts(distance_right_wheel)
    whereami = WhereAmI.init
    |> update(%{encoder_counts_left: left, encoder_counts_right: right})
    assert_in_delta whereami.heading, -0.5 * :math.pi, 0.01
    assert_in_delta whereami.x,                1117.5, 1.0
    assert_in_delta whereami.y,               -1117.5, 1.0
  end

  test "moving forward through a 90° turn to the left" do
    radius_left  = 1882.5
    radius_right = 2117.5
    distance_left_wheel  = (1/4) * 2 * :math.pi * radius_left
    distance_right_wheel = (1/4) * 2 * :math.pi * radius_right
    left = distance_to_encoder_counts(distance_left_wheel)
    right = distance_to_encoder_counts(distance_right_wheel)
    whereami = WhereAmI.init
    |> update(%{encoder_counts_left: left, encoder_counts_right: right})
    assert_in_delta whereami.heading,  0.5 * :math.pi, 0.01
    assert_in_delta whereami.x,                2000.0, 1.0
    assert_in_delta whereami.y,                2000.0, 1.0
  end

  test "moving through a 180° turn to the right starting above the origin" do
    radius_left = 2117.5
    radius_right = 1882.5
    distance_left_wheel  = (1/2) * 2 * :math.pi * radius_left
    distance_right_wheel = (1/2) * 2 * :math.pi * radius_right
    left = distance_to_encoder_counts(distance_left_wheel)
    right = distance_to_encoder_counts(distance_right_wheel)
    whereami = %WhereAmI{x: 0.0, y: 2000.0}
    |> update(%{encoder_counts_left: left, encoder_counts_right: right})
    assert_in_delta whereami.heading, -:math.pi, 0.01
    assert_in_delta whereami.x,             0.0, 3.0
    assert_in_delta whereami.y,         -2000.0, 3.0
  end

  test "moving through a 180° turn to the right starting to the right of the origin facing down" do
    radius_left = 2117.5
    radius_right = 1882.5
    distance_left_wheel  = (1/2) * 2 * :math.pi * radius_left
    distance_right_wheel = (1/2) * 2 * :math.pi * radius_right
    left = distance_to_encoder_counts(distance_left_wheel)
    right = distance_to_encoder_counts(distance_right_wheel)
    whereami = %WhereAmI{x: 4000.0, y: 0.0, heading: -0.5 * :math.pi}
    |> update(%{encoder_counts_left: left, encoder_counts_right: right})
    assert_in_delta whereami.heading, 0.5 * :math.pi, 0.01
    assert_in_delta whereami.x,                  0.0, 3.0
    assert_in_delta whereami.y,                  0.0, 3.0
  end

  test "moving through a turn via many small updates" do
    radius_left  = 1235.0
    radius_right = 1000.0
    distance_left_wheel  = (1/4) * 2 * :math.pi * radius_left
    distance_right_wheel = (1/4) * 2 * :math.pi * radius_right
    left_total = distance_to_encoder_counts(distance_left_wheel)
    right_total = distance_to_encoder_counts(distance_right_wheel)
    whereami = Enum.reduce(Range.new(0,1000), WhereAmI.init, fn(iteration, whereami) ->
      left  = left_total  * (iteration / 1000.0)
      right = right_total * (iteration / 1000.0)
      update(whereami, %{encoder_counts_left: left, encoder_counts_right: right})
    end)
    assert_in_delta whereami.heading, -0.5 * :math.pi, 0.01
    assert_in_delta whereami.x,                1117.5, 1.0
    assert_in_delta whereami.y,               -1117.5, 1.0
  end

  test "turning in place" do
    radius = 117.5 # half the distance between the wheels
    distance = (1/4) * 2 * :math.pi * radius
    left = 65535 - distance_to_encoder_counts(distance) # backwards 1/4 turn
    right = distance_to_encoder_counts(distance) # forwards 1/4 turn
    whereami = WhereAmI.init |> update(%{encoder_counts_left: left, encoder_counts_right: right})
    assert_in_delta whereami.heading, 0.5 * :math.pi, 0.01
    assert_in_delta whereami.x,                  0.0, 1.0
    assert_in_delta whereami.y,                  0.0, 1.0
  end

  test "moving backward" do
    counts = distance_to_encoder_counts(750.0)
    whereami = %WhereAmI{encoder_counts_left: 100, encoder_counts_right: 200, x: 250.0}
    |> update(%{encoder_counts_left: 100 - counts, encoder_counts_right: 200 - counts})
    assert_in_delta whereami.heading, 0.0, 0.01
    assert_in_delta whereami.x,    -500.0, 0.1
    assert_in_delta whereami.y,       0.0, 0.1
  end

  test "encoder counts rolling over past the maximum" do
    counts = distance_to_encoder_counts(750.0)
    new_count = counts - (65535 - 65500)
    whereami = %WhereAmI{encoder_counts_left: 65500, encoder_counts_right: 65500, x: -250.0}
    |> update(%{encoder_counts_left: new_count, encoder_counts_right: new_count})
    assert_in_delta whereami.heading, 0.0, 0.01
    assert_in_delta whereami.x,     500.0, 0.1
    assert_in_delta whereami.y,       0.0, 0.1
  end

  defp distance_to_encoder_counts(distance_in_mm) do
    (distance_in_mm * 508.8 / :math.pi / 72.0)
    |> Float.floor
    |> trunc
  end
end
