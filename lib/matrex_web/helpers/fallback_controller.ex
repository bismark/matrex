defmodule MatrexWeb.FallbackController do
  use MatrexWeb, :controller

  def call(conn, {:ok, res}) do
    json(conn, res)
  end

  def call(conn, {:error, error}) do
    json_error(conn, error)
  end
end
