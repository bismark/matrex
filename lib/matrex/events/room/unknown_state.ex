alias Matrex.Events.Room.UnknownState, as: This
defmodule This do

 @type t :: %This{
   content: map,
   state_key: String.t,
   type: String.t,
 }

 defstruct [
   :content,
   :state_key,
   :type
 ]


 def factory(type) do
   fn (content, state_key) ->
     {:ok, %This{type: type, content: content, state_key: state_key}}
   end
 end


end

defimpl Matrex.Events.Room.Content, for: This do

  def type(%This{type: type}), do: type

  def is_state?(_), do: true

  def state_key(%This{state_key: state_key}), do: state_key

  def output(this), do: this.content

end
