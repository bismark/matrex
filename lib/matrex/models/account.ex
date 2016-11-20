defmodule Matrex.Models.Account do

  import Comeonin.Bcrypt

  alias __MODULE__, as: This


  @type user_id :: String.t

  @type t :: %This{
    username: user_id,
    passhash: String.t,
  }

  defstruct [
    :username,
    :passhash,
  ]

  @spec new(user_id, String.t) :: This.t
  def new(username, passhash) do
    %This{username: username, passhash: passhash}
  end


  @spec hash_password(String.t) :: String.t
  def hash_password(password) do
    hashpwsalt(password)
  end


  @spec check_password(This.t, String.t) :: :ok | {:error, term}
  def check_password(this, password) do
    case checkpw(password, this.passhash) do
      true -> :ok
      false -> {:error, :forbidden}
    end
  end


  @spec dummy_check_password :: :ok
  def dummy_check_password, do: dummy_checkpw()

end
