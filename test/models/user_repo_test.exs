defmodule Rumbl.UserRepoTest do
  use Rumbl.ModelCase

  alias Rumbl.User

  @valid_attrs %{name: "a user", username: "something", password: "password123"}
  @invalid_attrs %{}

  test "converts unique_constraint on username to error" do
    user = insert_user(username: "Ari")
    attrs = Map.put(@valid_attrs, :username, user.username)
    changeset = User.changeset(%User{}, attrs)

    assert {:error, changeset} = Repo.insert(changeset)
    assert {:username, {"has already been taken", []}} in changeset.errors
  end

end
