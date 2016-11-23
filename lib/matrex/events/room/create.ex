alias Matrex.Events.Room.Create, as: This
defmodule This do

  alias Matrex.Identifier

  @type t :: %This{
    creator: Identifier.user,
    federate: boolean,
    extra: map
  }

  defstruct [
    :creator,
    federate: true,
    extra: %{}
  ]

  def new(extra, federate? \\ true) do
    %This{federate: federate?, extra: extra}
  end

  def set_creator(this, creator) do
    %This{this | creator: creator}
  end

end

defimpl Matrex.Events.Room.Content, for: This do

  def type(_), do: "m.room.create"

  def is_state?(_), do: true

  def state_key(_), do: ""

  def output(this) do
    this.extra
      |> Map.put(:creator, this.creator)
      |> Map.put(:"m.federate", this.federate)
  end

end

