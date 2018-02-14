defmodule Matrex.Validation.MessageContent do
  import Matrex.Validation

  @spec parse_content(String.t(), map) :: {:ok, map} | {:error, term}

  def parse_content("m.room.message", content) do
    acc = %{}

    with {:ok, acc} <- required("body", content, acc, type: :string),
         {:ok, acc} <- required("msgtype", content, acc, type: :string),
         do: {:ok, acc}
  end

  def parse_content(_, content), do: content
end
