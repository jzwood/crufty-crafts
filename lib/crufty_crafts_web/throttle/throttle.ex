defmodule CruftyCraftsWeb.Throttle do
  @moduledoc """
  throttles api calls
  """
  require Logger

  defp throttle?() do
    !Application.get_env(:crufty_crafts, :sandbox?)
  end

  def rate_limit(secret) do
    if throttle?() and rate_limit?(secret, 1, 10) do
      {:error, :throttle}
    else
      :ok
    end
  end

  def rate_limit?(key, window, max) do
    hits =
      case CruftyCraftsWeb.ThrottleCallCache.lookup(key) do
        [{_, value, _}] -> value
        _miss -> []
      end

    now = Rivet.Utils.Time.epoch_time()
    cutoff = now - window

    hits =
      [now | hits]
      |> Enum.filter(&(&1 > cutoff))

    true = CruftyCraftsWeb.ThrottleCallCache.insert(key, hits, window * 2)

    length(hits) > max
  end
end
