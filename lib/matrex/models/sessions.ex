defmodule Matrex.Models.Sessions do

  alias __MODULE__, as: This
  alias Matrex.Models.Session
  alias Matrex.Models.Account


  @type token :: String.t
  @type tokens :: {token, token}

  @type t :: %This{
    access_tokens: %{token => Session.t},
    refresh_tokens: %{token => Account.user_id}
  }

  defstruct [
    access_tokens: %{},
    refresh_tokens: %{},
  ]


  @token_length 64


  @spec new_session(This.t, Account.user_id) :: {:ok, tokens, This.t}
  def new_session(this, user) do
    access_token = create_token
    refresh_token = create_token

    access_tokens = Map.put(
      this.access_tokens, 
      access_token,
      Session.new(user)
    )

    refresh_tokens = Map.put(
      this.refresh_tokens,
      refresh_token,
      user
    )

    this = %This{this |
      access_tokens: access_tokens,
      refresh_tokens: refresh_tokens,
    }

    {:ok, {access_token, refresh_token}, this}
  end


  @spec get_user(This.t, token)
    :: {:ok, Account.user_id, This.t} | {:error, atom, This.t}
  def get_user(this, access_token) do
    with {:ok, session} <- get_session(this, access_token),
         :ok <- check_session(session)
    do
      {:ok, session.user, this}
    else
      {:error, :forbidden} ->
        this = invalidate_session(this, access_token)
        {:error, :forbidden, this}
    end
  end


  @spec refresh_session(This.t, token)
    :: {:ok, tokens, This.t} | {:error, atom, This.t}
  def refresh_session(this, refresh_token) do
    with {:ok, user, this} <- pop_refresh_user(this, refresh_token) do
      new_session(this, user)
    end
  end


  @spec remove_session(This.t, token) :: {:ok, This.t}  | {:error, This.t}
  def remove_session(this, access_token) do
    case Map.pop(this.access_tokens, access_token) do
      {nil, access_tokens} ->
        {:error, %This{this | access_tokens: access_tokens}}
      {_, access_tokens} ->
        {:ok, %This{this | access_tokens: access_tokens}}
    end
  end


  # Internal Functions

  @spec create_token :: token
  defp create_token do
    Base.url_encode64(:crypto.strong_rand_bytes(@token_length))
  end


  @spec get_session(This.t, token) :: {:ok, Session.t} | {:error, atom}
  defp get_session(this, access_token) do
    case Map.get(this.access_tokens, access_token) do
      nil -> {:error, :forbidden}
      session -> {:ok, session}
    end
  end


  @spec check_session(Session.t) :: :ok | {:error, atom}
  defp check_session(session) do
    case Session.expired?(session) do
      true -> {:error, :forbidden}
      false -> :ok
    end
  end


  @spec invalidate_session(This.t, token) :: This.t
  defp invalidate_session(this, access_token) do
    access_tokens = Map.delete(this.access_tokens, access_token)
    %This{this | access_tokens: access_tokens}
  end


  @spec pop_refresh_user(This.t, token)
    :: {:ok, String.t, %This{}} | {:error, atom, %This{}}
  defp pop_refresh_user(this, refresh_token) do
    case Map.pop(this.refresh_tokens, refresh_token) do
      {nil, _} -> {:error, :forbidden, this}
      {user, refresh_tokens} ->
        {:ok, user, %This{this | refresh_tokens: refresh_tokens}}
    end
  end


end
