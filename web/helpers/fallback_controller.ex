defmodule Matrex.FallbackController do
  use Matrex.Web, :controller

  def call(conn, {:ok, res}) do
    json(conn, res)
  end

  def call(conn, {:error, error}) do
    json_error(conn, error)
  end
end
