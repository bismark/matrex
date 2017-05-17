defmodule Matrex.Events.Room.MessageContent do

  import Matrex.Validation

  alias __MODULE__, as: This

  @type t :: %This{
    content: map,
    type: String.t,
  }

  defstruct [
    :content,
    :type,
  ]

  @spec new(String.t, map) :: {:ok, This.t} | {:error, term}

  def new(type, content) do
    with {:ok, parsed} <- parse_content(type, content),
         content = Map.merge(content, parsed),
    do: {:ok, %This{type: type, content: content}}
  end


  @spec parse_content(String.t, map) :: {:ok, map} | {:error, term}

  defp parse_content("m.room.message", content) do
    acc = %{}
    with {:ok, acc} <- required("body", content, acc, type: :string),
         {:ok, acc} <- required("msgtype", content, acc, type: :string),
    do: {:ok, acc}
  end

  defp parse_content(_, content), do: content

end

