defmodule Mainframe.ClientLoginController do

  use Matrex.Web, :controller

  def post(conn, %{"type" => "m.login.password"} = params) do
    password = Map.fetch!(params, "password")
    user = Map.fetch!(params, "user")


  end

end
