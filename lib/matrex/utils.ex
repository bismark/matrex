defmodule Matrex.Utils do


  def timestamp, do: :os.system_time(:millisecond)

  def age(since), do: timestamp() - since


  def map_move(map, old_key, new_key) do
    case Map.fetch(map, old_key) do
      :error -> map
      {:ok, value} ->
        map
          |> Map.delete(old_key)
          |> Map.put(new_key, value)
    end
  end


  def has_struct?(enum, struct) do
    Enum.any?(enum, fn
       %{__struct__: ^struct} -> true
       _ -> false
    end)
  end


end
