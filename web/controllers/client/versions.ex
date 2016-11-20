defmodule Matrex.Controllers.Client.Versions do

  use Matrex.Web, :controller

  def get(conn, _params) do
    json(conn, %{versions: ["r0.2.0"]})
  end

end
