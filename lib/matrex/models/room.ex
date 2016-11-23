defmodule Matrex.Models.Room do

  alias __MODULE__, as: This
  alias Matrex.Identifier
  alias Matrex.Events.Event
  alias Matrex.Events.Room, as: RoomEvent
  alias Matrex.Events.Room.Create

  @type t :: %This{
    id: Identifier.t,
    events: [Event.t]
  }

  @enforce_keys [:id]

  defstruct [
    :id,
    events: []
  ]


  def new(id, contents, actor) do
    events = Enum.map(contents, fn
       %Create{} = content ->
         content = Create.set_creator(content, actor)
         RoomEvent.create(id, actor, content)
       content ->
         RoomEvent.create(id, actor, content)
    end)

    %This{id: id, events: events}
  end

end
