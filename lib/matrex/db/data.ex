defmodule Matrex.DB.Data do

  alias __MODULE__, as: This
  alias Matrex.Models.{Account, Sessions, Rooms}
  alias Matrex.Identifier

  @type t :: %This{
    accounts: %{Identifier.user => Account.t},
    sessions: Sessions.t,
    rooms: Rooms.t,
    next_generated_user_id: integer,
  }

  defstruct [
    accounts: %{},
    sessions: %Sessions{},
    rooms: Rooms.new,
    next_generated_user_id: 1,
  ]


  ### Rooms ###

  @spec create_room(This.t, map, Identifier.user)
    :: {:ok, Identifier.room, This.t} | {:error, atom, This.t}

  def create_room(this, contents, user) do
    {room_id, rooms} = Rooms.create(this.rooms, contents, user)
    {:ok, room_id, %This{this | rooms: rooms}}
  end


  @spec join_room(This.t, Identifier.room, Identifier.user)
    :: {:ok, Identifier.room, This.t} | {:error, atom, This.t}

  def join_room(this, room_id, user) do
    case Rooms.join_room(this.rooms, room_id, user) do
      {:error, error} ->
        {:error, error, this}
      {:ok, rooms} ->
        {:ok, room_id, %This{this | rooms: rooms}}
    end
  end


  @spec send_event(This.t, Identifier.room, Identifier.user, struct)
    :: {:ok, Identifier.event, This.t} | {:error, atom, This.t}

  def send_event(this, room_id, user, content) do
    case Rooms.send_event(this.rooms, room_id, user, content) do
      {:error, error} ->
        {:error, error, this}
      {:ok, event_id, rooms} ->
        {:ok, event_id, %This{this | rooms: rooms}}
    end
  end


  ### Auth ###

  @spec logout(This.t, Sessions.token)
    :: {:ok, This.t} | {:error, atom, This.t}

  def logout(this, access_token) do
    case Sessions.remove_session(this.sessions, access_token) do
      {:error, sessions} ->
        {:error, :unknown_token, %This{this | sessions: sessions}}
      {:ok, sessions} ->
        {:ok, %This{this | sessions: sessions}}
    end
  end


  @spec refresh_auth(This.t, Sessions.token)
    :: {:ok, Sessions.tokens, This.t} | {:error, atom, This.t}

  def refresh_auth(this, refresh_token) do
    case Sessions.refresh_session(this.sessions, refresh_token) do
      {:error, error, sessions} ->
        {:error, error, %This{this | sessions: sessions}}
      {:ok, tokens, sessions} ->
        {:ok, tokens, %This{this | sessions: sessions}}
    end
  end


  @spec auth(This.t, Sessions.token)
    :: {:ok, Identifier.t, This.t} | {:error, atom, This.t}

  def auth(this, access_token) do
    case Sessions.get_user(this.sessions, access_token) do
      {:error, error, sessions} ->
        {:error, error, %This{this | sessions: sessions}}
      {:ok, user, sessions} ->
        {:ok, user, %This{this | sessions: sessions}}
    end
  end


  @spec new_session(This.t, Identifier.user)
    :: {:ok, Sessions.tokens, This.t}

  def new_session(this, user_id) do
    {:ok, tokens, sessions} = Sessions.new_session(this.sessions, user_id)
    {:ok, tokens, %This{this | sessions: sessions}}
  end


  ### Accounts ###

  @spec register(This.t, Identifier.user | nil, String.t)
    :: {:ok, {Sessions.t, Identifier.user}, This.t} | {:error, atom, This.t}

  def register(this, nil, passhash) do
    {:ok, user_id, this} = generate_user_id(this)
    {:ok, this} = new_account(this, user_id, passhash)
    {:ok, tokens, this} = new_session(this, user_id)
    {:ok, {tokens, user_id}, this}
  end

  def register(this, user_id, passhash) do
    case Map.has_key?(this.accounts, user_id) do
      true -> {:error, :user_in_use, this}
      false ->
        {:ok, this} = new_account(this, user_id, passhash)
        {:ok, tokens, this} = new_session(this, user_id)
        {:ok, {tokens, user_id}, this}
    end
  end


  @spec fetch_account(This.t, Identifier.user)
    :: {:ok, Account.t} | {:error}

  def fetch_account(this, user_id) do
    Map.fetch(this.accounts, user_id)
  end



  ### Internal Functions ###

  @spec generate_user_id(This.t) :: {:ok, Identifier.user, This.t}

  defp generate_user_id(this) do
    {id, user_id} = generate_user_id(this.next_generated_user_id, this.accounts)
    {:ok, user_id, %This{this | next_generated_user_id: id + 1}}
  end


  @spec generate_user_id(integer, map) :: {integer, Identifier.user}

  defp generate_user_id(id, accounts) do
    user_id = Identifier.new(:user, Integer.to_string(id), Matrex.hostname)
    if Map.has_key?(accounts, user_id) do
      generate_user_id(id + 1 , accounts)
    else
      {id, user_id}
    end
  end


  @spec new_account(This.t, Identifier.user, String.t) :: {:ok, This.t}

  defp new_account(this, user_id, passhash) do
    user = Account.new(user_id, passhash)
    accounts = Map.put(this.accounts, user.user_id, user)
    {:ok, %This{this | accounts: accounts}}
  end


end
