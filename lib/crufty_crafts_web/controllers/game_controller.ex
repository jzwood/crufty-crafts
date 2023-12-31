defmodule CruftyCraftsWeb.GameController do
  use CruftyCraftsWeb, :controller
  alias CruftyCrafts.GameManager

  # HOST
  def host(conn, %{"handle" => handle, "map" => map}) do
    case GameManager.host(handle: handle, map: map) do
      {:ok, data} -> success(conn, data)
      {:error, msg} -> failure(conn, msg)
      _ -> failure(conn)
    end
  end

  def host(conn, %{"handle" => handle}) do
    case GameManager.host(handle: handle) do
      {:ok, data} -> success(conn, data)
      {:error, msg} -> failure(conn, msg)
      _ -> failure(conn)
    end
  end

  def host(conn, _), do: failure(conn, "invalid host args")

  # JOIN
  def join(conn, %{"game_id" => game_id, "handle" => handle}) do
    case GameManager.join(game_id: game_id, handle: handle) do
      {:ok, data} -> success(conn, data)
      {:error, msg} -> failure(conn, msg)
      _ -> failure(conn)
    end
  end

  def join(conn, _), do: failure(conn, "invalid join args")

  # KICK
  def kick(conn, %{"game_id" => game_id, "secret" => secret, "handle" => handle}) do
    case GameManager.kick(game_id: game_id, secret: secret, handle: handle) do
      {:ok, game} -> success(conn, game)
      {:error, msg} -> failure(conn, msg)
      _ -> failure(conn)
    end
  end

  def kick(conn, _), do: failure(conn, "invalid kick args")

  defp parse_angle(angle: angle) do
    case Float.parse(angle) do
      {angle, ""} -> {:ok, angle}
      {angle, "rad"} -> {:ok, angle}
      {angle, "deg"} -> {:ok, Projections.deg_to_rad(angle)}
      :error -> :error
      err -> err
    end
  end

  # rotate
  def rotate(conn, %{"game_id" => game_id, "secret" => secret, "angle" => angle}) do
    with :ok <- CruftyCraftsWeb.Throttle.rate_limit(secret),
         {:ok, angle} <- parse_angle(angle: angle),
         {:ok, game} <- GameManager.rotate(game_id: game_id, secret: secret, angle: angle) do
      success(conn, game)
    else
      {:error, msg} -> failure(conn, msg)
      _ -> failure(conn)
    end
  end

  def rotate(conn, _), do: failure(conn, "invalid move args")

  # shoot missile
  def shoot(conn, %{"game_id" => game_id, "secret" => secret}) do
    with :ok <- CruftyCraftsWeb.Throttle.rate_limit(secret),
         {:ok, game} <- GameManager.shoot(game_id: game_id, secret: secret) do
      success(conn, game)
    else
      {:error, msg} -> failure(conn, msg)
      _ -> failure(conn)
    end
  end

  def shoot(conn, _), do: failure(conn, "invalid move args")

  # INFO
  def info(conn, %{"game_id" => game_id, "secret" => secret}) do
    with :ok <- CruftyCraftsWeb.Throttle.rate_limit(secret),
         {:ok, game} <- GameManager.info(game_id: game_id, secret: secret) do
      success(conn, game)
    else
      {:error, msg} -> failure(conn, msg)
      _ -> failure(conn)
    end
  end

  def info(conn, _), do: failure(conn, "invalid info args")

  # RESTART
  def reset(conn, %{"game_id" => game_id, "secret" => secret}) do
    with :ok <- CruftyCraftsWeb.Throttle.rate_limit(secret),
         {:ok, game} <- GameManager.reset(game_id: game_id, secret: secret) do
      success(conn, game)
    else
      {:error, msg} -> failure(conn, msg)
      _ -> failure(conn)
    end
  end

  def reset(conn, _), do: failure(conn, "invalid reset args")

  # KILL
  def kill(conn, %{"game_id" => game_id}) do
    case GameManager.kill(game_id: game_id) do
      :ok ->
        GameManager.update_liveview_list()
        success(conn, :ok)

      _ ->
        failure(conn)
    end
  end

  def kill(conn, _), do: failure(conn)

  defp success(conn, result) do
    json(conn, %{success: true, reason: nil, result: result})
  end

  defp failure(conn, reason \\ "something went wrong") do
    json(conn, %{success: false, reason: reason, result: nil})
  end
end
