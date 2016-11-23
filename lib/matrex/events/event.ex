defprotocol Matrex.Events.Event do

  @spec output(Event.t) :: map
  def output(event)

end
