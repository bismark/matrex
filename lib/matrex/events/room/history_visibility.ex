alias Matrex.Events.Room.HistoryVisibility, as: This
defmodule This do

  import Matrex.Validation

  @behaviour Matrex.Events.Room.StateContentBehaviour

  @allowed [:invited, :joined, :shared, :world_readable]

  @type t :: %This{
    history_visibility: :invited | :joined | :shared | :world_readable
  }

  defstruct [
    :history_visibility
  ]

  def new(visibility) when is_atom(visibility) do
    %This{history_visibility: visibility}
  end


  def new(args, _) do
    with options = [type: :string, as: :atom, allowed: @allowed],
         {:ok, %{history_visibility: v}} <- required(:history_visibility, args, %{}, options)
    do
      {:ok, new(v)}
    else
      {:error, _} -> :error
    end
  end


end

defimpl Matrex.Events.Room.Content, for: This do

  def type(_), do: "m.room.history_visibility"

  def is_state?(_), do: true

  def state_key(_), do: ""

  def output(this), do: this

end
