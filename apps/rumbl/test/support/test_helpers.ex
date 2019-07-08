defmodule Rumbl.TestHelpers do
  import Plug.Conn
  alias Rumbl.Repo

  def insert_user(attrs \\ %{}) do
    changes = Enum.into(attrs, %{
      name: "Some User",
      username: "user#{Base.encode16(:crypto.strong_rand_bytes(8))}",
      password: "supersecret"
    })

    %Rumbl.User{}
    |> Rumbl.User.registration_changeset(changes)
    |> Repo.insert!()
  end

  def insert_video(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:videos, attrs)
    |> Repo.insert!()
  end

  def login_as(conn, username) do
    user = insert_user(%{username: username})
    conn = assign(conn, :current_user, user)

    {:ok, conn, user}
  end

end
