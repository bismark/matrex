defmodule Matrex.UserID do

  @localpart_regex ~r|^[a-z0-9_.=\-]+$|
  @max_length 255

  def valid_localpart?(username) do
    Regex.match?(@localpart_regex, username)
  end

  def fquid(username, hostname) do
    "@#{username}:#{hostname}"
  end

  def valid_fquid?(username, hostname) do
    String.length(fquid(username, hostname)) < @max_length
  end

  def parse(user) do
    case user do
      "@" <> user ->
        [part|_] = String.split(user, ":", parts: 2, trim: true)
        {:ok, part}
      _ -> :error
    end
  end


end
