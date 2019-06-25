defmodule Rumbl.UserTest do
  use Rumbl.ModelCase, async: true

  alias Rumbl.User

  @valid_attrs %{name: "a user", username: "something", password: "password123"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset does not accept long usernames" do
    attrs = Map.put(@valid_attrs, :username, String.duplicate("a", 30))
    assert {:username, "should be at most 20 character(s)"}
      in errors_on(%User{}, attrs)
  end

  test "registration_changeset with valid attributes hashes password" do
    attrs = [password: "123456"] |> Enum.into(@valid_attrs)
    changeset = User.registration_changeset(%User{}, attrs)

    %{password: pass, password_hash: hash} = changeset.changes

    assert changeset.valid?
    assert hash
    assert Comeonin.Bcrypt.checkpw(pass, hash)
  end
end
