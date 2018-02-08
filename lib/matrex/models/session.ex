defmodule Matrex.Models.Session do
  alias __MODULE__, as: This
  alias Matrex.Identifier

  @type t :: %This{
          user: Identifier.user(),
          expires: integer
        }

  defstruct [
    :user,
    :expires
  ]

  @expiration 60 * 60

  def new(user) do
    expires = :erlang.monotonic_time(:second) + @expiration
    %This{user: user, expires: expires}
  end

  def expired?(this) do
    :erlang.monotonic_time(:second) > this.expires
  end
end
