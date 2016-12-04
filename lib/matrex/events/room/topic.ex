alias Matrex.Events.Room.Topic, as: This
defmodule This do

  import Matrex.Validation

  @behaviour Matrex.Events.Room.StateContentBehaviour

  @type t :: %This{
    topic: String.t,
  }

  defstruct [
    :topic,
  ]

  def new(topic) when is_binary(topic), do: %This{topic: topic}


  def from_raw(args, _) do
    with {:ok, %{topic: topic}} <- required(:topic, args, %{}, type: :string),
    do: {:ok, new(topic)}
  end

end

defimpl Matrex.Events.Room.Content, for: This do

  def type(_), do: "m.room.topic"

  def is_state?(_), do: true

  def state_key(_), do: ""

  def output(this), do: this

end
