alias Matrex.Events.Room.JoinRules, as: This
defmodule This do

  import Matrex.Validation

  @behaviour Matrex.Events.Room.StateContentBehaviour

  @allowed [:public, :invite]

  @type t :: %This{
    join_rule: :public | :invite
  }

  defstruct [
    :join_rule
  ]

  def new(join_rule) when is_atom(join_rule) do
    %This{join_rule: join_rule}
  end


  def from_raw(args, _) do
    with options = [type: :string, as: :atom, allowed: @allowed],
         {:ok, %{join_rule: rule}} <- required(:join_rule, args, %{}, options),
     do: {:ok, new(rule)}
  end

end

defimpl Matrex.Events.Room.Content, for: This do

  def type(_), do: "m.room.join_rules"

  def is_state?(_), do: true

  def state_key(_), do: ""

  def output(this), do: this

end
