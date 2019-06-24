defmodule Rumbl.AuthTest do
  use Rumbl.ConnCase
  alias Rumbl.Auth

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Rumbl.Router, :browser)
      |> get("/")

      {:ok, %{conn: conn}}
  end

  test "authenticate_user halts when no current_user exists", %{conn: conn} do
    conn = Auth.authenticate(conn, [])
    assert conn.halted
  end

  test "authenticate_user continues when no current_user exists", %{conn: conn} do
    conn =
      conn
      |> assign(:current_user, %Rumbl.User{})
      |> Auth.authenticate([])

    refute conn.halted
  end

  test "login puts the user in the session", %{conn: conn} do
    login_conn =
      conn
      |> Auth.login(%Rumbl.User{id: 123})
      |> send_resp(:ok, "")

    next_conn = get login_conn, "/"
    assert get_session(next_conn, :user_id) == 123
  end

  test "logout drops the session", %{conn: conn} do
    logout_conn =
      conn
      |> Auth.login(%Rumbl.User{id: 123})
      |> Auth.logout()
      |> send_resp(:ok, "")

    next_conn = get logout_conn, "/"
    refute get_session(next_conn, :user_id)
  end

  test "call places user from session into assigns", %{conn: conn} do
    user = insert_user()
    conn =
      conn
      |> Auth.login(user)
      |> Auth.call(Repo)

    assert conn.assigns.current_user.id == user.id
  end

  test "call with no session sets current_user assign to nil", %{conn: conn} do
    conn = Auth.call(conn, Repo)
    assert conn.assigns.current_user == nil
  end

  test "login with a valid username and pass", %{conn: conn} do
    user = insert_user(username: "username", password: "password123")
    {:ok, conn} = Auth.login_userpass(conn, user.username, user.password, repo: Repo)

    assert conn.assigns.current_user.id == user.id
  end

  test "login with a not found user", %{conn: conn} do
    assert {:error, :not_found, _conn} =
       Auth.login_userpass(conn, "username", "somepassword123", repo: Repo)
  end

  test "login with an invalid password", %{conn: conn} do
    user = insert_user(username: "username", password: "password123")

    assert {:error, :unauthorized, _conn} =
       Auth.login_userpass(conn, user.username, "invalidpassword", repo: Repo)
  end
end
