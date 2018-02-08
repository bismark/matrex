defmodule Matrex.Models.Account do
  import Comeonin.Pbkdf2

  alias __MODULE__, as: This
  alias Matrex.Identifier

  @type t :: %This{
          user_id: Identifier.user(),
          passhash: String.t()
        }

  defstruct [
    :user_id,
    :passhash
  ]

  @spec new(Identifier.user(), String.t()) :: This.t()
  def new(user_id, passhash) do
    %This{user_id: user_id, passhash: passhash}
  end

  @spec hash_password(String.t()) :: String.t()
  def hash_password(password) do
    hashpwsalt(password)
  end

  @spec check_password(This.t(), String.t()) :: :ok | {:error, term}
  def check_password(this, password) do
    case checkpw(password, this.passhash) do
      true -> :ok
      false -> {:error, :forbidden}
    end
  end

  @spec dummy_check_password :: :ok
  def dummy_check_password do
    dummy_checkpw()
    :ok
  end
end
