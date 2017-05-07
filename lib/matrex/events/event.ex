defprotocol Matrex.Events.Event do

  alias __MODULE__

  @spec output(Event.t) :: map
  def output(event)

end
