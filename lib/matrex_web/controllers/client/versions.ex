defmodule MatrexWeb.Controllers.Client.Versions do
  use MatrexWeb, :controller

  def get(conn, _params) do
    json(conn, %{versions: ["r0.2.0"]})
  end
end
