defmodule Matrex.Events.Room do

  alias __MODULE__, as: This
  alias Matrex.Identifier
  alias Matrex.Utils
  alias This.StateContent
  alias This.MessageContent

  @type content :: StateContent.t | MessageContent.t

  @type t :: %This{
    event_id: Identifier.event,
    room_id: Identifier.room,
    sender: Identifier.user,
    origin_server_ts: integer,
    content: content,
  }

  defstruct [
    :event_id,
    :room_id,
    :sender,
    :origin_server_ts,
    :content,
  ]

  @spec create(Identifier.room, Identifier.user, content) :: This.t
  def create(room_id, sender, content) do
    %This{
      event_id: Identifier.generate(:event),
      room_id: room_id,
      sender: sender,
      origin_server_ts: Utils.timestamp,
      content: content,
    }
  end


  defimpl Matrex.Events.Event, for: This do

    def output(this) do
      this
        |> Map.from_struct
        |> Map.put(:type, this.content.type)
        |> Map.put(:content, this.content)
        |> Map.put(:age, Utils.age(this.origin_server_ts))
        |> add_extra(this.content)
    end


    defp add_extra(acc, %StateContent{} = content) do
      acc = Map.put(acc, :state_key, content.state_key)
      if content.prev_content do
        Map.put(acc, :prev_content, content.prev_content)
      else
        acc
      end
    end

    defp add_extra(acc, _), do: acc


  end

end


