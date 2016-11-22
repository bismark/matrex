defmodule Matrex.Utils do

  def map_move(map, old_key, new_key) do
    case Map.fetch(map, old_key) do
      :error -> map
      {:ok, value} ->
        map
          |> Map.delete(old_key)
          |> Map.put(new_key, value)
    end
  end

end
