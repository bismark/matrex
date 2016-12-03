alias Matrex.Events.Room.Member, as: This
defmodule This do

  alias Matrex.Identifier

  @allowed [:invite, :join, :leave, :ban]

  @type t :: %This{
    state_key: Identifier.user,
    membership: :atom,
  }

  defstruct [
    :state_key,
    :membership
  ]

  def new(user, membership) do
    %This{state_key: user, membership: membership}
  end

end

defimpl Matrex.Events.Room.Content, for: This do

  def type(_), do: "m.room.member"

  def is_state?(_), do: true

  def state_key(this), do: this.state_key

  def output(this), do: this

end


