defmodule Rumbl.Channels.VideoChannelTest do
  use Rumbl.ChannelCase

  import Rumbl.TestHelpers

  setup do
    user = insert_user(name: "Arijoon")
    video = insert_video(user, title: "Test video")
    token = Phoenix.Token.sign(@endpoint, "user socket", user.id)
    {:ok, socket} = connect(Rumbl.UserSocket, %{"token" => token})

    {:ok, socket: socket, user: user, video: video}
  end

  test "join replies with video annotations", %{socket: socket, video: vid} do
    for body <- ~w(one two) do
      vid
      |> build_assoc(:annotations, %{body: body})
      |> Repo.insert!()
    end

    {:ok, reply, socket} = subscribe_and_join(socket, "videos:#{vid.id}", %{})

    assert socket.assigns.video_id == vid.id
    assert %{annotations: [%{body: "one"}, %{body: "two"}]} = reply
  end

  test "inserting new annotaions", %{socket: socket, video: vid} do
    {:ok, _, socket} = subscribe_and_join(socket, "videos:#{vid.id}", %{})
    ref = push socket, "new_annotation", %{body: "the body", at: 0}

    assert_reply ref, :ok, %{}
    assert_broadcast("new_annotation", %{})
  end

  test "new annotations trigger infosys", %{socket: socket, video: vid} do
    insert_user(username: "wolfram")
    {:ok, _, socket} = subscribe_and_join(socket, "videos:#{vid.id}", %{})
    ref = push socket, "new_annotation", %{body: "1+1", at: 123}

    assert_reply ref, :ok, _
    assert_broadcast("new_annotation", %{body: "1+1", at: 123})
    assert_broadcast("new_annotation", %{body: "2", at: 123})
  end
end
