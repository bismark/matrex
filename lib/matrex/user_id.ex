defmodule Matrex.UserID do

  alias __MODULE__, as: This

  @type t :: %This{
    localpart: String.t,
    hostname: String.t,
  }

  defstruct [
    :localpart,
    :hostname,
  ]

  @localpart_regex ~r|^[a-z0-9_.=\-]+$|
  @max_length 255

  def new(localpart, hostname) do
    %This{localpart: localpart, hostname: hostname}
  end

  def valid?(%This{} = this) do
    Regex.match?(@localpart_regex, this.localpart) &&
    (String.length(fquid(username, hostname)) < @max_length)
  end

  def fquid(%This{} = this) do
    "@#{this.localpart}:#{this.hostname}"
  end


  def parse(user) do
    case user do
      "@" <> user ->
        [localpart|hostname] = String.split(user, ":", parts: 2, trim: true)
        {:ok, new(localpart, hostname)}
      _ -> :error
    end
  end


end
