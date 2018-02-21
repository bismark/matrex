defmodule MatrexWeb.Router do
  use MatrexWeb, :router

  alias MatrexWeb.Controllers.Client
  alias MatrexWeb.Plugs.RequireAccessToken

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :auth do
    plug(RequireAccessToken)
  end

  scope "/_matrix/client", Client do
    pipe_through(:api)

    get("/versions", Versions, :get)

    scope "/r0", R0 do
      get("/login", Login, :get)
      post("/login", Login, :post)
      post("/tokenrefresh", TokenRefresh, :post)

      post("/register", Register, :post)
    end

    scope "/r0", R0 do
      pipe_through(:auth)
      post("/logout", Logout, :post)

      post("/createRoom", CreateRoom, :post)

      scope "/rooms/:room_id", Rooms do
        post("/join", Join, :post)
        put("/send/:event_type/:txn_id", Send, :put)

        get("/state", State, :get_all)
        get("/state/:event_type", State, :get)
        get("/state/:event_type/:state_key", State, :get)
        put("/state/:state_event_type", State, :put)
        put("/state/:state_event_type/:state_key", State, :put)

        get("/members", Members, :get)
        get("/joined_members", Members, :get_joined)
      end

      scope "/user/:user_id", User do
        post("/filter", Filter, :post)
        post("/filter/:filter_id", Filter, :get)
      end
    end
  end
end
