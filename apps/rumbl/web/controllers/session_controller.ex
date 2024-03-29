defmodule Rumbl.SessionController do
  use Rumbl.Web, :controller

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"session" => %{ "username" => user, "password" => pass}}) do
    case Rumbl.Auth.login_userpass(conn, user, pass, repo: Repo) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome Back!")
        |> redirect(to: page_path(conn, :index))
      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid username/password combination")
        |> render("new.html")

    end
  end

  def delete(conn, _opts) do
    conn
    |> Rumbl.Auth.logout()
    |> redirect(to: page_path(conn, :index))
  end
end
