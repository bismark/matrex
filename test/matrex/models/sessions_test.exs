defmodule Matrex.Models.SessionsTest do

  use ExUnit.Case, async: true

  alias Matrex.Models.Sessions
  alias Matrex.Models.Session


  test "new session" do
    username = "foo"
    assert {:ok, tokens, sessions} = Sessions.new_session(%Sessions{}, username)
    assert {access_token, refresh_token} = tokens

    # Ensure sessions stored correctly
    assert %Session{user: ^username} = Map.fetch!(sessions.access_tokens, access_token)
    assert username == Map.fetch!(sessions.refresh_tokens, refresh_token)
  end


  test "get user" do
    username = "foo"
    assert {:ok, {access_token, _}, sessions} = Sessions.new_session(%Sessions{}, username)

    # Ensure bad token return error
    assert {:error, :unknown_token, ^sessions} = Sessions.get_user(sessions, "badtoken")

    # Ensure lookup works correctly
    assert {:ok, ^username, ^sessions} = Sessions.get_user(sessions, access_token)

    # Ensure expired session is invalidated
    sessions = expire_session(sessions, access_token)
    assert {:error, :unknown_token, sessions_2} = Sessions.get_user(sessions, access_token)
    assert not Map.has_key?(sessions_2.access_tokens, access_token)
  end


  test "refresh_session" do
    username = "foo"
    assert {:ok, tokens, sessions} = Sessions.new_session(%Sessions{}, username)
    assert {access_token, refresh_token} = tokens

    # Assert refreshed session
    assert {:ok, tokens, sessions} = Sessions.refresh_session(sessions, refresh_token)
    assert {access_token_2, refresh_token_2} = tokens
    assert access_token != access_token_2
    assert refresh_token != refresh_token_2

    # Ensure lookup works correctly
    assert {:ok, ^username, ^sessions} = Sessions.get_user(sessions, access_token_2)

    # Previous refresh token is invalidated
    assert {:error, :unknown_token, ^sessions} = Sessions.refresh_session(sessions, refresh_token)

    # One more time for safety
    assert {:ok, _, _} = Sessions.refresh_session(sessions, refresh_token_2)
  end


  defp expire_session(sessions, access_token) do
    session = sessions.access_tokens
      |> Map.fetch!(access_token)
      |> struct(expires: :erlang.monotonic_time(:second) - 1)

    access_tokens = Map.put(sessions.access_tokens, access_token, session)
    %Sessions{sessions | access_tokens: access_tokens}
  end

end
