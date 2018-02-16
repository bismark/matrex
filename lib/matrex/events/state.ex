defmodule Matrex.Events.State do
  alias __MODULE__, as: This
  alias Matrex.Identifier
  alias Matrex.Utils

  @type key :: {String.t(), String.t()}

  @type t :: %This{
          event_id: Identifier.event(),
          room_id: Identifier.room(),
          sender: Identifier.user(),
          origin_server_ts: integer,
          content: map,
          prev_state: nil | This.t(),
          state_key: any,
          type: String.t()
        }

  @enforce_keys [:event_id, :room_id, :sender, :origin_server_ts, :content, :state_key, :type]

  defstruct([
    :event_id,
    :room_id,
    :sender,
    :origin_server_ts,
    :content,
    :prev_state,
    :state_key,
    :type
  ])

  def create(room_id, sender, content, type, state_key \\ "") do
    %This{
      event_id: Identifier.generate(:event),
      room_id: room_id,
      sender: sender,
      origin_server_ts: Utils.timestamp(),
      content: content,
      type: type,
      state_key: state_key
    }
  end

  def set_content(this, key, value) do
    content = Map.put(this.content, key, value)
    %This{this | content: content}
  end

  def key(this) do
    {this.type, this.state_key}
  end

  defimpl Matrex.Events.Event, for: This do
    def output(this) do
      this
      |> Map.from_struct()
      |> Map.put(:age, Utils.age(this.origin_server_ts))
      |> Utils.map_move(:prev_state, :prev_content)
      |> Map.update!(:prev_content, & &1.content)
    end
  end
end
