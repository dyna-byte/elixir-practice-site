defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel

  def join("videos:" <> video_id, params, socket) do
    last_seen_id = params["last_seen_id"] || 0
    video_id = String.to_integer(video_id)
    video = Repo.get!(Rumbl.Video, video_id)

    annotations = Repo.all(
      from a in assoc(video, :annotations),
      where: a.id > ^last_seen_id,
      order_by: [asc: a.at, asc: a.id],
      limit: 200,
      preload: [:user]
    )

    resp = %{
      annotations: Phoenix.View.render_many(annotations, Rumbl.AnnotationView, "annotation.json")
    }

    {:ok, resp, assign(socket, :video_id, video_id)}
  end

  def handle_in(event, params, socket) do
    user = Rumbl.Repo.get!(Rumbl.User, socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  def handle_in("new_annotation", params, user, socket) do
    changeset =
      user
      |> build_assoc(:annotations, video_id: socket.assigns.video_id)
      |> Rumbl.Annotation.changeset(params)

    case Repo.insert(changeset) do
      {:ok, annotation} ->
        # broadcast!(socket, "new_annotation", %{
        #   id: annotation.id,
        #   user: Rumbl.UserView.render("user.json", %{user: user}),
        #   body: annotation.body,
        #   at: annotation.at
        # })
        broadcast_annotation(socket, annotation)
        Task.start_link(fn -> compute_additional_info(annotation, socket) end)

        {:reply, :ok, socket}
      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  defp broadcast_annotation(socket, annotaion) do
    annotaion = Repo.preload(annotaion, :user)
    ann = Phoenix.View.render(Rumbl.AnnotationView, "annotation.json", %{ annotation: annotaion})

    broadcast!(socket, "new_annotation", ann)
  end

  defp compute_additional_info(annotation, socket) do
    for result <- InfoSys.compute(annotation.body, limit: 1, timeout: 10_000) do
      IO.puts(inspect result)
      attrs = %{url: result.url, body: result.text, at: annotation.at}
      info_changeset =
        Repo.get_by!(Rumbl.User, username: result.backend)
        |> build_assoc(:annotations, video_id: annotation.video_id)
        |> Rumbl.Annotation.changeset(attrs)
      case Repo.insert(info_changeset) do
      {:ok, info_ann } -> broadcast_annotation(socket, info_ann)
      {:error, _ } -> :ignore
      end
    end
  end

end
