defmodule Projections do
  @moduledoc false

  def bounds([{x, y} | xys]) do
    [x_min: x_min, y_min: y_min, x_max: x_max, y_max: y_max] =
      xys
      |> Enum.reduce(
        [x_min: x, y_min: y, x_max: x, y_max: y],
        fn {x, y}, [x_min: x_min, y_min: y_min, x_max: x_max, y_max: y_max] ->
          [x_min: min(x_min, x), y_min: min(y_min, y), x_max: max(x_max, x), y_max: max(y_max, y)]
        end
      )

    max_width = x_max - x_min
    max_height = y_max - y_min
    scale = max(max_width, max_height)

    [x_min: x_min, y_min: y_min, scale: scale]
  end

  def normalize({x, y}, x_min: x_min, y_min: y_min, scale: scale) do
    x = (x - x_min) / scale
    y = (y - y_min) / scale
    {x, y}
  end

  def normalize_all(xys) do
    bounds = bounds(xys)

    xys
    |> Enum.map(&normalize(&1, bounds))
  end

  defp cot(a) do
    1 / :math.tan(a)
  end

  defp deg_to_rad(deg) do
    deg * :math.pi() / 180
  end

  def american_polyconic_projection(lat, long, lat0 \\ 0, long0 \\ 0)

  def american_polyconic_projection(0.0, long, lat0, long0) do
    x = long - long0
    y = -lat0
    {x, y}
  end

  def american_polyconic_projection(lat, long, lat0, long0) do
    x = cot(lat) * :math.sin((long - long0) * :math.sin(lat))
    y = lat - lat0 + cot(lat) * (1 - :math.cos((long - long0) * :math.sin(lat)))
    {x, y}
  end

  def cassini_projection(lat, long) do
    x = :math.asin(:math.cos(lat) * :math.sin(long))
    y = :math.atan2(:math.tan(lat), :math.cos(lat) * :math.cos(long))
    {x, y}
  end

  def azimuthal_equidistant_projection(lat, long) do
    r = 1
    theta = long
    rho = r * (:math.pi() / 2 - lat)
    x = rho * :math.sin(theta)
    y = -rho * :math.cos(theta)
    {x, y}
  end

  def hammer_retroazimuthal_projection(lat, long, lat0 \\ :math.pi() / 8, long0 \\ 0)

  def hammer_retroazimuthal_projection(lat, long, lat0, long0) do
    r = 1

    cos_z =
      :math.sin(lat0) * :math.sin(lat) +
        :math.cos(lat0) * :math.cos(lat) * :math.cos(long - long0)

    z = :math.acos(cos_z)
    z = if z == 0, do: 2 * :math.pi(), else: z
    k = z / :math.sin(z)
    x = r * k * :math.cos(lat0) * :math.sin(long - long0)

    y =
      -r * k *
        (:math.sin(lat0) * :math.cos(lat) -
           :math.cos(lat0) * :math.sin(lat) * :math.cos(long - long0))

    if long < -0.5 * :math.pi() or long > 0.5 * :math.pi() do
      {x, y}
    else
      {-x, -y}
    end
  end

  def american_polyconic_meridians() do
    for(
      long <- -180..180//10,
      lat <- -90..90//5,
      do: american_polyconic_projection(deg_to_rad(lat), deg_to_rad(long))
    )
    |> normalize_all()
  end

  def cassini_meridians() do
    for(
      long <- -180..180//5,
      lat <- -90..90//5,
      do: cassini_projection(deg_to_rad(lat), deg_to_rad(long))
    )
    |> normalize_all()
  end

  def azimuthal_equidistant_meridians() do
    for(
      long <- -180..180//5,
      lat <- -90..90//5,
      do: azimuthal_equidistant_projection(deg_to_rad(lat), deg_to_rad(long))
    )
    |> normalize_all()
  end

  def hammer_retroazimuthal_meridians() do
    for long <- -180..180//5,
        lat <- -90..90//5,
        do: hammer_retroazimuthal_projection(deg_to_rad(lat), deg_to_rad(long))
  end
end
