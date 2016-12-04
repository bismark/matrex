alias Matrex.Events.Room
alias Room.Message, as: This
defmodule This do

  import Matrex.Validation

  @behaviour Room.ContentBehaviour

  @type t :: %This{
    body: String.t,
    type: This.Type.t,
  }

  defstruct [
    :body,
    :type,
  ]

  @message_types %{
    "m.text" => This.Text,
    #"m.emote" => This.Emote,
    #"m.notice" => This.Notice,
    #"m.image" => This.Image,
    #"m.file" => This.File,
    #"m.location" => This.Location,
    #"m.video" => This.Video,
    #"m.audio" => This.Audio,
  }




  def from_raw(args) do
    acc = %{}
    with {:ok, acc} <- required(:msgtype, args, acc, type: :string),
         {:ok, acc} <- required(:body, args, acc, type: :string),
         {:ok, type} <- parse_type(acc.msgtype, args),
    do: {:ok, %This{body: acc.body, type: type}}
  end


  defp parse_type(type, args) do
    factory = case Map.fetch(@message_types, type) do
      :error -> This.UnknownType.factory(type)
      {:ok, type} -> &type.from_raw/1
    end

    factory.(args)
  end


end


defmodule This.TypeBehaviour do
  @callback from_raw(args :: map) :: {:ok, struct} | {:error, atom}
end


defprotocol This.Type do

  @spec type(Type.t) :: String.t
  def type(type)

  @spec output(Type.t) :: map
  def output(content)

end


defimpl Room.Content, for: This do

  def type(_), do: "m.room.message"

  def is_state?(_), do: false

  def state_key(_), do: nil

  def output(this) do
    this.type
      |> This.Type.output
      |> Map.put(:type, This.Type.type(this.type))
      |> Map.put(:body, this.body)
  end

end

