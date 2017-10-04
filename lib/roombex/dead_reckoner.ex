defmodule Roombex.DeadReckoner do
  alias Roombex.WhereAmI
  @axle_length 235.0
  @max_encoder_count 65535
  @near_upper_bound @max_encoder_count - 5000
  @near_lower_bound 5000

  @spec update(%WhereAmI{}, %{encoder_counts_left: non_neg_integer(), encoder_counts_right: non_neg_integer()}) :: %WhereAmI{}
  def update(%WhereAmI{}=whereami, %{encoder_counts_left: left, encoder_counts_right: right}) do
    left_diff = encoder_diff(whereami.encoder_counts_left, left)
    right_diff = encoder_diff(whereami.encoder_counts_right, right)
    updated_whereami(whereami, {left, right}, {left_diff, right_diff})
  end

  defp updated_whereami(whereami, {count_left, count_right}, {count_diff, count_diff}) do
    distance = encoder_counts_to_distance(count_diff)
    x_delta = distance * :math.cos(whereami.heading)
    y_delta = distance * :math.sin(whereami.heading)
    %{whereami | x: whereami.x + x_delta, y: whereami.y + y_delta, encoder_counts_left: count_left, encoder_counts_right: count_right}
  end
  defp updated_whereami(whereami, {count_left, count_right}, {diff_left, diff_right}) do
    {x_delta, y_delta, heading_delta} = deltas(whereami.heading, diff_left, diff_right)

    %WhereAmI{
      x: whereami.x + x_delta,
      y: whereami.y + y_delta,
      heading: clamp_heading(whereami.heading + heading_delta),
      encoder_counts_left: count_left,
      encoder_counts_right: count_right,
    }
  end

  defp clamp_heading(heading) do
    cond do
      heading < -1 * :math.pi ->
        heading + (2 * :math.pi)
      heading > :math.pi ->
        heading - (2 * :math.pi)
      true ->
        heading
    end
  end

  # lovingly borrowed from http://www.seattlerobotics.org/encoder/200010/dead_reckoning_article.html
  defp deltas(heading, diff_left, diff_right) do
    cos_current = :math.cos(heading)
    sin_current = :math.sin(heading)
    dist_left = encoder_counts_to_distance(diff_left)
    dist_right = encoder_counts_to_distance(diff_right)
    right_minus_left = dist_right - dist_left
    expr1 = @axle_length * (dist_right + dist_left) / 2.0 / (right_minus_left)
    x_delta = expr1 * (:math.sin(right_minus_left / @axle_length + heading) - sin_current)
    y_delta = -1 * expr1 * (:math.cos(right_minus_left / @axle_length + heading) - cos_current)
    heading_delta = right_minus_left / @axle_length
    {x_delta, y_delta, heading_delta}
  end

  defp encoder_counts_to_distance(count) do
    count * :math.pi * 72.0 / 508.8
  end

  defp encoder_diff(previous, new) when previous < @near_lower_bound and new > @near_upper_bound do
    previous - (@max_encoder_count - new)
  end
  defp encoder_diff(previous, new) when previous > @near_upper_bound and new < @near_lower_bound do
    (@max_encoder_count + new) - previous
  end
  defp encoder_diff(previous, new) do
    new - previous
  end
end
