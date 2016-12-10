defmodule Matrex.Identifier do

  alias __MODULE__, as: This

  @valid_chars [
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l",
    "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x",
    "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
    "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V",
    "W", "X", "Y", "Z", "1", "2", "3", "4", "5", "6", "7", "8",
    "9", "0",
  ]

  @id_length 18

  @type user :: %This{
    type: :user,
    localpart: String.t,
    hostname: String.t,
  }
  @type room :: %This{
    type: :room,
    localpart: String.t,
    hostname: String.t,
  }
  @type event :: %This{
    type: :event,
    localpart: String.t,
    hostname: String.t,
  }
  @type room_alias :: %This{
    type: :room_alias,
    localpart: String.t,
    hostname: String.t,
  }
  @type t :: %This{
    type: atom,
    localpart: String.t,
    hostname: String.t,
  }

  defstruct [
    :type,
    :localpart,
    :hostname,
  ]

  @user_localpart_regex ~r|^[a-z0-9_.=\-]+$|
  @user_sigil "@"
  @room_sigil "!"
  @event_sigil "$"
  @room_alias_sigil "#"
  @max_length 255


  def new(type, localpart, hostname \\ nil) do
    hostname = case hostname do
      nil -> Matrex.hostname
      _ -> hostname
    end
    %This{type: type, localpart: localpart, hostname: hostname}
  end


  def generate(type) do
    localpart = @valid_chars |> Enum.take_random(@id_length) |> Enum.join
    %This{type: type, localpart: localpart, hostname: Matrex.hostname}
  end


  def valid?(%This{} = this) do
    valid_localpart?(this) &&
    String.length(fqid(this)) < @max_length
  end


  def fqid(%This{} = this) do
    "#{sigil(this)}#{this.localpart}:#{this.hostname}"
  end


  @spec parse(String.t, atom) :: {:ok, This.t} | :error
  def parse(id, expected) do
    with {:ok, ^expected, id} <- type_from_sigil(id),
         [localpart, hostname] <- String.split(id, ":", parts: 2, trim: true)
    do
      {:ok, new(expected, localpart, hostname)}
    else
      _ -> :error
    end
  end


  @spec parse(String.t) :: {:ok, This.t} | :error
  def parse(id) do
    with {:ok, type, id} <- type_from_sigil(id)
    do
      [localpart|hostname] = String.split(id, ":", parts: 2, trim: true)
      {:ok, new(type, localpart, hostname)}
    end
  end


  defp valid_localpart?(%This{type: :user, localpart: localpart}) do
    Regex.match?(@user_localpart_regex, localpart)
  end

  defp valid_localpart?(_), do: true


  @spec type_from_sigil(String.t) :: {:ok, atom, String.t} | :error
  defp type_from_sigil(@user_sigil <> rest), do: {:ok, :user, rest}
  defp type_from_sigil(@room_sigil <> rest), do: {:ok, :room, rest}
  defp type_from_sigil(@event_sigil <> rest), do: {:ok, :event, rest}
  defp type_from_sigil(@room_alias_sigil <> rest), do: {:ok, :room_alias, rest}
  defp type_from_sigil(_), do: :error


  defp sigil(%This{type: :user}), do: @user_sigil
  defp sigil(%This{type: :room}), do: @room_sigil
  defp sigil(%This{type: :event}), do: @event_sigil
  defp sigil(%This{type: :room_alias}), do: @room_alias_sigil

end

alias Matrex.Identifier, as: This

defimpl Poison.Encoder, for: This do

  def encode(id, options) do
    Poison.Encoder.BitString.encode(This.fqid(id), options)
  end

end

defimpl Inspect, for: This do
  def inspect(this, _), do: This.fqid(this)
end
