defmodule Matrex.Models.UserFilter do
  alias Matrex.Identifier
  alias __MODULE__

  defmodule Filter do
    @type t :: %Filter{
            limit: integer | nil,
            not_senders: [Identifier.user()],
            senders: [Identifier.user()],
            types: [String.t()]
          }

    defstruct([
      :limit,
      not_senders: [],
      senders: [],
      types: []
    ])
  end

  defmodule RoomFilter do
    defmodule EventFilter do
      @type t :: %EventFilter{
              limit: integer | nil,
              not_senders: [Identifier.user()],
              senders: [Identifier.user()],
              types: [String.t()],
              not_rooms: [Identifier.room()],
              rooms: [Identifier.room()],
              contains_url: boolean
            }

      defstruct([
        :limit,
        not_senders: [],
        senders: [],
        types: [],
        not_rooms: [],
        rooms: [],
        contains_url: false
      ])
    end

    @type t :: %RoomFilter{
            not_rooms: [Identifier.room()],
            rooms: [Identifier.room()],
            ephemeral: EventFilter.t() | nil,
            include_leave: boolean,
            state: EventFilter.t() | nil,
            timeline: EventFilter.t() | nil,
            account_data: EventFilter.t() | nil
          }

    defstruct([
      :ephemeral,
      :state,
      :timeline,
      :account_data,
      not_rooms: [],
      rooms: [],
      include_leave: false
    ])
  end

  @type t :: %UserFilter{
          event_fields: [String.t()],
          presence: Filter.t() | nil,
          account_data: Filter.t() | nil,
          room: RoomFilter.t() | nil
        }

  defstruct([
    :presence,
    :account_data,
    :room,
    event_fields: []
  ])
end
