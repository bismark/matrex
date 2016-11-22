defmodule Matrex.Loops.Sync do
  require Logger

  @behaviour :cowboy_loop_handler

  alias Plug.Adapters.Cowboy.Conn, as: CowboyConn
  alias Plug.Conn
  alias __MODULE__, as: This

  import Phoenix.Controller, only: [json: 2]
  import Matrex.Validation
  import MatrexWeb.Errors

  def init({transport, :http}, req, opts) do
    conn =
      CowboyConn.conn(req, transport)
      |> Conn.fetch_query_params()

    try do
      handle(conn)
    catch
      # Lifted from Plug.Adapters.Cowboy.Handler
      :error, value ->
        stack = System.stacktrace()
        exception = Exception.normalize(:error, value, stack)
        reason = {{exception, stack}, {This, :handle, [conn, opts]}}
        shutdown(reason, req, stack)

      :throw, value ->
        stack = System.stacktrace()
        reason = {{{:nocatch, value}, stack}, {This, :handle, [conn, opts]}}
        shutdown(reason, req, stack)

      :exit, value ->
        stack = System.stacktrace()
        reason = {value, {This, :handle, [conn, opts]}}
        shutdown(reason, req, stack)
    end
  end

  def terminate(_reason, _req, _stack) do
    :ok
  end

  defp shutdown(reason, req, stack) do
    :cowboy_req.maybe_reply(stack, req)
    exit(reason)
  end

  defp handle(conn) do
    case parse_args(conn) do
      {:ok, %{timeout: _} = args} ->
        loop(conn, args)

      {:ok, args} ->
        respond(conn, args)

      {:error, error} ->
        conn
        |> json_error(error)
        |> Conn.halt()

        {:shutdown, req(conn), nil}
    end
  end

  defp loop(conn, args) do
    {:loop, req(conn), nil, args.timeout}
  end

  defp respond(conn, args) do
    conn
    |> json(%{})
    |> Conn.halt()

    {:shutdown, req(conn), nil}
  end

  defp parse_args(conn) do
    args = %{}
    params = conn.query_params

    with {:ok, args} <- optional(:filter, params, args, type: :string, post: &parse_filter/1),
         {:ok, args} <- optional(:since, params, args, type: :string),
         {:ok, args} <- optional(:full_state, params, args, type: :boolean),
         {:ok, args} <- optional(:set_presence, params, args, type: :string, allowed: ["offline"]),
         {:ok, args} <- optional(:timeout, params, args, type: :string, post: &parse_timeout/1) do
      {:ok, args}
    end
  end

  defp parse_filter("{" <> _ = filter) do
    case Poison.decode(filter) do
      {:error, _} -> {:error, :bad_value}
      {:ok, filter} -> {:ok, filter}
    end
  end

  defp parse_filter(filter), do: {:ok, filter}

  defp parse_timeout(timeout) do
    try do
      {:ok, String.to_integer(timeout)}
    catch
      ArgumentError ->
        {:error, :bad_type}
    end
  end

  defp req(conn) do
    {_, req} = conn.adapter
    req
  end
end
