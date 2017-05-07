defmodule Matrex.DB do

  alias __MODULE__, as: This
  alias Matrex.DB.Data
  alias Matrex.Models.{Account, Sessions}
  alias Matrex.Identifier
  alias Matrex.Events.Room, as: RoomEvent

  @doc "For debugging purposes"
  @spec dump :: Data.t
  def dump do
    Agent.get(This, fn data -> data end)
  end


  def start_link do
    Agent.start_link(fn -> %Data{} end, name: This)
  end


  @spec login(Identifier.user, String.t)
    :: {:ok, {Sessions.tokens, Identifier.user}} | {:error, atom}
  def login(user_id, password) do
    with {:ok, user_id} <- check_password(user_id, password) do
      {:ok, tokens} = new_session(user_id)
      {:ok, {tokens, user_id}}
    end
  end


  @spec logout(Sessions.token) :: :ok | {:error, atom}
  def logout(access_token) do
    Agent.get_and_update(This, fn data ->
      data
        |> Data.logout(access_token)
        |> wrap_result
    end)
  end


  @spec refresh_auth(Sessions.token)
    :: {:ok, Sessions.tokens} | {:error, atom}
  def refresh_auth(refresh_token) do
    Agent.get_and_update(This, fn data ->
      data
        |> Data.refresh_auth(refresh_token)
        |> wrap_result
    end)
  end


  @spec register(Identifier.user | nil, String.t)
    :: {:ok, {Sessions.tokens, Identifier.user}} | {:error, atom}
  def register(user_id_or_nil, password) do
    passhash = Account.hash_password(password)
    Agent.get_and_update(This, fn data ->
      data
        |> Data.register(user_id_or_nil, passhash)
        |> wrap_result
    end)
  end


  @spec create_room([RoomEvent.Content.t], Sessions.token)
    :: {:ok, Identifier.room} | {:error, atom}
  def create_room(contents, access_token) do
    Agent.get_and_update(This, fn data ->
      with {:ok, user, data} <- Data.auth(data, access_token) do
        Data.create_room(data, contents, user)
      end
        |> wrap_result
    end)
  end


  @spec join_room(Identifier.room, Sessions.token)
    :: {:ok, Identifier.room} | {:error, atom}
  def join_room(room_id, access_token) do
    Agent.get_and_update(This, fn data ->
      with {:ok, user, data} <- Data.auth(data, access_token) do
        Data.join_room(data, room_id, user)
      end
        |> wrap_result
    end)
  end


  @spec send_event(Identifier.room, String.t, RoomEvent.Content.t, Sessions.token)
    :: {:ok, Identifier.event} | {:error, atom}
  def send_event(room_id, _txn_id, content, access_token) do
    #TODO deal with txn_id
    Agent.get_and_update(This, fn data ->
      with {:ok, user, data} <- Data.auth(data, access_token) do
        Data.send_event(data, room_id, user, content)
      end
        |> wrap_result
    end)
  end


  # Internal Functions

  @spec check_password(Identifier.user, String.t)
    :: {:ok, Identifier.user} | {:error, atom}
  defp check_password(user_id, password) do
    account = Agent.get(This, fn data ->
      Data.fetch_account(data, user_id)
    end)

    case account do
      :error ->
        Account.dummy_check_password
        {:error, :forbidden}
      {:ok, account} ->
        with :ok <- Account.check_password(account, password)
        do
          {:ok, account.user_id}
        end
    end
  end

  @spec new_session(Identifier.user) :: {:ok, Sessions.tokens}
  defp new_session(user_id) do
    Agent.get_and_update(This, fn data ->
      Data.new_session(data, user_id)
        |> wrap_result
    end)
  end


  # Internal Functions

  defp wrap_result({:error, error, data}), do: {{:error, error}, data}

  defp wrap_result({:ok, data}), do: {:ok, data}

  defp wrap_result({:ok, res, data}), do: {{:ok, res}, data}


end
