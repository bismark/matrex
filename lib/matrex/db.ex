defmodule Matrex.DB do

  alias __MODULE__, as: This
  alias Matrex.Models.{Account, Sessions}

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


  @spec login(String.t, String.t)
    :: {:ok, Sessions.tokens} | {:error, atom}
  def login(user, password) do
    with :ok <- check_password(user, password) do
      new_session(user)
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


  @spec authenticate(Sessions.token) :: {:ok, String.t} | {:error, atom}
  def authenticate(access_token) do
    Agent.get_and_update(This, fn this ->
      case Sessions.get_user(this.sessions, access_token) do
        {:error, error, sessions} ->
          {{:error, error}, %This{this | sessions: sessions}}
        {:ok, user, sessions} ->
          {{:ok, user}, %This{this | sessions: sessions}}
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

  @spec check_password(String.t, String.t) :: :ok | {:error, atom}
  defp check_password(user, password) do
    case Agent.get(This, &(Map.fetch(&1.accounts, user))) do
      :error ->
        Account.dummy_check_password
        {:error, :forbidden}
      {:ok, account} ->
        Account.check_password(account, password)
    end
  end

  @spec new_session(String.t) :: {:ok, Sessions.tokens}
  defp new_session(user) do
    Agent.get_and_update(This, fn this ->
      {:ok, tokens, this} = _new_session(this, user)
      {{:ok, tokens}, this}
    end)
  end


  @spec _register(map)
    :: {:ok, Sessions.tokens, Account.user_id} | {:error, atom}
  defp _register(%{username: _} = args) do
    Agent.get_and_update(This, fn this ->
      case Map.has_key?(this, args.username) do
        true -> {:error, :user_in_use}
        false ->
          {:ok, this} = _new_account(this, args.username, args.password)
          {:ok, tokens, this} = _new_session(this, args.username)
          {{:ok, tokens, args.username}, this}
      end
    end)
  end

  defp _register(args) do
    Agent.get_and_update(This, fn this ->
      {:ok, user_id, this} = generate_user_id(this)
      {:ok, this} = _new_account(this, user_id, args.password)
      {:ok, tokens, this} = _new_session(this, user_id)
      {{:ok, tokens, user_id}, this}
    end)
  end


  defp generate_user_id(this) do
    id = _generate_user_id(this.next_generated_user_id, this.accounts)
    {:ok, id, %This{this | next_generated_user_id: id + 1}}
  end


  defp _generate_user_id(id, accounts) do
    if Map.has_key?(accounts, id) do
      _generate_user_id(id + 1 , accounts)
    else
      id
    end
  end


  defp _new_session(this, user) do
    {:ok, tokens, sessions} = Sessions.new_session(this.sessions, user)
    {:ok, tokens, %This{this | sessions: sessions}}
  end

  defp _new_account(this, username, passhash) do
    user = Account.new(username, passhash)
    accounts = Map.put(this.accounts, user.username, user)
    {:ok, %This{this | accounts: accounts}}
  end




end
