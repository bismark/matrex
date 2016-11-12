defmodule Matrex.Router do
  use Matrex.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/_matrix/client", Matrex do
    pipe_through :api

    get "/versions", ClientVersionsController, :get

    scope "/ro", Matrex do
      post "/login", ClientLoginController, :post

    end
  end

end
