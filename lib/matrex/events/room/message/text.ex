alias Matrex.Events.Room.Message
alias Message.Text, as: This
defmodule This do

  @behaviour Message.TypeBehaviour

  defstruct []

  def from_raw(_) do
    # Nothing more to do!
    {:ok, %This{}}
  end

end

defimpl Message.Type, for: This do

  def type(_), do: "m.text"

  def output(_), do: %{}

end
