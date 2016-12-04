alias Matrex.Events.Room.UnknownContent, as: This
defmodule This do

 @type t :: %This{
   content: map,
   type: String.t,
 }

 defstruct [
   :content,
   :type
 ]


 def factory(type) do
   fn (content) ->
     {:ok, %This{type: type, content: content}}
   end
 end


end

defimpl Matrex.Events.Room.Content, for: This do

  def type(%This{type: type}), do: type

  def is_state?(_), do: false

  def state_key(_), do: nil

  def output(this), do: this.content

end

