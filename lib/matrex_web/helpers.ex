defmodule MatrexWeb.Helpers do
  alias Matrex.Identifier

  @spec parse_room_id(String.t()) :: {:ok, Identifier.room()} | {:error, term}

  def parse_room_id(room_id) do
    case Identifier.parse(room_id, :room) do
      :error -> {:error, :forbidden}
      res -> res
    end
  end
end
