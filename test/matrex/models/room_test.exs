defmodule Matrex.Models.RoomTest do

  use ExUnit.Case, async: true
  alias Matrex.Identifier
  alias Matrex.Events.Room.StateContent
  alias Matrex.Models.Room

  test "new room" do
    room_id = Identifier.generate(:room)
    actor_id = Identifier.generate(:user)
    {:ok, create} = StateContent.new("m.room.create", %{})
    args = %{"join_rule" => "invite"}
    {:ok, join_rules} = StateContent.new("m.room.join_rules", args)

    content = %{
      StateContent.key(create) => create,
      StateContent.key(join_rules) => join_rules
    }

    room = Room.new(room_id, content, actor_id)

    assert room_id == room.id
    assert [join_rules_event, member_event, create_event] = room.events

    key = {"m.room.create", ""}
    assert Map.has_key?(room.state, key)
    state_create_event = Map.fetch!(room.state, key)
    assert state_create_event == create_event
    assert actor_id == state_create_event.content.content["creator"]

    key = {"m.room.member", actor_id}
    assert Map.has_key?(room.state, key)
    state_member_event = Map.fetch!(room.state, key)
    assert state_member_event == member_event
    assert "join" == state_member_event.content.content["membership"]

    key = {"m.room.join_rules", ""}
    assert Map.has_key?(room.state, key)
    state_join_rules_event = Map.fetch!(room.state, key)
    assert state_join_rules_event == join_rules_event
    assert "invite" == state_join_rules_event.content.content["join_rule"]
 end


 test "join invite room" do
   room = create_room()
   user = Identifier.generate(:user)
   assert {:error, :forbidden} = Room.join(room, user)
 end


 test "join public room" do
   room = create_room("public")
   user = Identifier.generate(:user)
   assert {:ok, room} = Room.join(room, user)

   assert [member_event | _] = room.events

   key = {"m.room.member", user}
   assert Map.has_key?(room.state, key)
   state_member_event = Map.fetch!(room.state, key)
   assert state_member_event == member_event
   assert "join" == state_member_event.content.content["membership"]
 end


 defp create_room(join_rule \\ "invite") do
   room_id = Identifier.generate(:room)
   actor_id = Identifier.generate(:user)
   {:ok, create} = StateContent.new("m.room.create", %{})
   args = %{"join_rule" => join_rule}
   {:ok, join_rules} = StateContent.new("m.room.join_rules", args)

   content = %{
     StateContent.key(create) => create,
     StateContent.key(join_rules) => join_rules
   }

   Room.new(room_id, content, actor_id)
 end



end
