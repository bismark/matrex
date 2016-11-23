defmodule Matrex.DB do

  alias __MODULE__, as: This
  alias Matrex.Models.{Account, Sessions}
  alias Matrex.Identifier

  @type t :: %This{
    accounts: %{Account.user_id => Account.t},
    sessions: Sessions.t,
    next_generated_user_id: integer,
  }

  defstruct [
    accounts: %{},
    sessions: %Sessions{},
    next_generated_user_id: 1,
  ]


  @doc "For debugging purposes"
  @spec dump :: This.t
  def dump do
    Agent.get(This, fn this -> this end)
  end


  def start_link do
    Agent.start_link(fn -> %This{} end, name: This)
  end


  @spec login(Identifier.t | String.t, String.t)
    :: {:ok, Sessions.tokens, Identifier.t} | {:error, atom}
  def login(user_id, password) do
    with {:ok, user_id} <- check_password(user_id, password) do
      {:ok, tokens} = new_session(user_id)
      {:ok, tokens, user_id}
    end
  end


  @spec logout(Sessions.token) :: :ok | {:error, atom}
  def logout(access_token) do
    Agent.get_and_update(This, fn this ->
      case Sessions.remove_session(this.sessions, access_token) do
        {:error, sessions} ->
          {{:error, :unknown_token}, %This{this | sessions: sessions}}
        {:ok, sessions} ->
          {:ok, %This{this | sessions: sessions}}
      end
    end)
  end


  @spec refresh_auth(Sessions.token)
    :: {:ok, Sessions.tokens} | {:error, atom}
  def refresh_auth(refresh_token) do
    Agent.get_and_update(This, fn this ->
      case Sessions.refresh_session(this.sessions, refresh_token) do
        {:error, error, sessions} ->
          {{:error, error}, %This{this | sessions: sessions}}
        {:ok, tokens, sessions} ->
          {{:ok, tokens}, %This{this | sessions: sessions}}
      end
    end)
  end


  @spec register(map)
    :: {:ok, Sessions.tokens, Account.user_id} | {:error, atom}
  def register(args) do
    args = Map.update!(args, :password, &Account.hash_password/1)
    _register(args)
  end

  # Internal Functions

  @spec check_password(Identifier.t | String.t, String.t)
    :: {:ok, Identifier.t} | {:error, atom}
  defp check_password(user_id, password) do
    account = Agent.get(This, fn this ->
      username = case user_id do
        %Identifier{localpart: localpart} -> localpart
        username -> username
      end
      Map.fetch(this.accounts, username)
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

  @spec new_session(Identifier.t) :: {:ok, Sessions.tokens}
  defp new_session(user_id) do
    Agent.get_and_update(This, fn this ->
      {:ok, tokens, this} = new_session(this, user_id)
      {{:ok, tokens}, this}
    end)
  end


  @spec _register(map)
    :: {:ok, Sessions.tokens, Account.user_id} | {:error, atom}
  defp _register(%{user_id: _} = args) do
    Agent.get_and_update(This, fn this ->
      case Map.has_key?(this, args.user_id.localpart) do
        true -> {:error, :user_in_use}
        false ->
          {:ok, this} = new_account(this, args.user_id, args.password)
          {:ok, tokens, this} = new_session(this, args.user_id)
          {{:ok, tokens, args.user_id}, this}
      end
    end)
  end

  defp _register(args) do
    Agent.get_and_update(This, fn this ->
      {:ok, user_id, this} = generate_user_id(this)
      {:ok, this} = new_account(this, user_id, args.password)
      {:ok, tokens, this} = new_session(this, user_id)
      {{:ok, tokens, user_id}, this}
    end)
  end


  # Internal This Functions


  @spec generate_user_id(This.t) :: {:ok, Identifier.t, This.t}
  defp generate_user_id(this) do
    id = generate_user_id(this.next_generated_user_id, this.accounts)
    {:ok, id, %This{this | next_generated_user_id: id + 1}}
  end


  @spec generate_user_id(integer, map) :: Identifier.t
  defp generate_user_id(id, accounts) do
    if Map.has_key?(accounts, id) do
      generate_user_id(id + 1 , accounts)
    else
      Identifier.new(:user, id, Matrex.hostname)
    end
  end


  @spec new_session(This.t, Identifier.t)
    :: {:ok, Sessions.tokens, This.t}
  defp new_session(this, user) do
    {:ok, tokens, sessions} = Sessions.new_session(this.sessions, user)
    {:ok, tokens, %This{this | sessions: sessions}}
  end


  @spec new_account(This.t, Identifier.t, String.t) :: {:ok, This.t}
  defp new_account(this, user_id, passhash) do
    user = Account.new(user_id, passhash)
    accounts = Map.put(this.accounts, user.user_id.localpart, user)
    {:ok, %This{this | accounts: accounts}}
  end

end
