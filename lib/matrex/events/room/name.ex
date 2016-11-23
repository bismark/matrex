alias Matrex.Events.Room.Name, as: This
defmodule This do

  import Matrex.Validation

  @behaviour Matrex.Events.Room.StateContentBehaviour

  @type t :: %This{
    name: String.t,
  }

  defstruct [
    :name,
  ]

  def new(name) when is_binary(name), do: %This{name: name}


  def new(args, _) do
    with {:ok, %{name: name}} <- required(:name, args, %{}, type: :string)
    do
      {:ok, new(name)}
    else
      {:error,_} ->
        :error
    end
  end

end

defimpl Matrex.Events.Room.Content, for: This do

  def type(_), do: "m.room.name"

  def is_state?(_), do: true

  def state_key(_), do: ""

  def output(this), do: this

end
