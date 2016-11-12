defmodule Matrex.DB do

  alias __MODULE__, as: This
  alias Matrex.Models.{Account, Sessions}

  defstruct [
    accounts: %{},
    sessions: %Sessions{},
  ]

  def start_link do
    Agent.start_link(fn -> %This{} end, name: This)
  end


  @spec login(String.t, String.t)
    :: {:ok, {Sessions.token, Sessions.token}} | {:error, atom}
  def login(user, password) do
    with :ok <- check_password(user, password) do
      new_session(user)
    end
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
    :: {:ok, {Sessions.token, Sessions.token}} | {:error, atom}
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

  @spec new_session(String.t) :: {:ok, {Sessions.token, Sessions.token}}
  defp new_session(user) do
    Agent.get_and_update(This, fn this ->
      {:ok, tokens, sessions} = Sessions.new_session(this.sessions, user)
      {{:ok, tokens}, %This{this | sessions: sessions}}
    end)
  end


end
