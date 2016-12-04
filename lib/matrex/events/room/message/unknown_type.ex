alias Matrex.Events.Room.Message
alias Message.UnknownType, as: This
defmodule This do

  @type t :: %This{
    type: String.t,
    content: map,
  }

  defstruct [
    :type,
    :content,
  ]

  def factory(type) do
    fn (content) ->
      {:ok, %This{type: type, content: content}}
    end
  end

end

defimpl Message.Type, for: This do

  def type(this), do: this.type

  def output(this), do: this.content

end
