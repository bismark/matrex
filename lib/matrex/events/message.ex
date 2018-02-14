defmodule Matrex.Events.Message do
  alias __MODULE__, as: This
  alias Matrex.Identifier
  alias Matrex.Utils

  @type t :: %This{
          event_id: Identifier.event(),
          room_id: Identifier.room(),
          sender: Identifier.user(),
          origin_server_ts: integer,
          content: map,
          type: String.t()
        }

  @enforce_keys [:event_id, :room_id, :sender, :origin_server_ts, :content, :type]

  defstruct [
    :event_id,
    :room_id,
    :sender,
    :origin_server_ts,
    :content,
    :type
  ]

  def create(room_id, sender, content, type) do
    %This{
      event_id: Identifier.generate(:event),
      room_id: room_id,
      sender: sender,
      origin_server_ts: Utils.timestamp(),
      content: content,
      type: type
    }
  end

  defimpl Matrex.Events.Event, for: This do
    def output(this) do
      this
      |> Map.from_struct()
      |> Map.put(:age, Utils.age(this.origin_server_ts))
    end
  end
end
