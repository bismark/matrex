defmodule Matrex.Router do
  use Matrex.Web, :router

  alias Matrex.Controllers.Client
  alias Matrex.Plugs.RequireAccessToken
  alias Matrex.Plugs.RequireAccessToken

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug RequireAccessToken
  end

  scope "/_matrix/client", Client do
    pipe_through :api

    get "/versions", Versions, :get

    scope "/r0", R0 do
      get "/login", Login, :get
      post "/login", Login, :post
      post "/tokenrefresh", TokenRefresh, :post

      post "/register", Register, :post
    end

    scope "/r0", R0 do
      pipe_through :auth
      post "/logout", Logout, :post

      post "/createRoom", CreateRoom, :post

      scope "/rooms", Rooms do
        post "/:room_id/join", Join, :post
        put "/:room_id/send/:event_type/:txn_id", Send, :put
      end
    end
  end

end
