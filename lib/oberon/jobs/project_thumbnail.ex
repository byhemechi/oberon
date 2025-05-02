defmodule Oberon.Jobs.GenerateProjectThumbnails do
  alias Oberon.Repo
  alias Oberon.Projects.Attachment
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"project_id" => project_id}}) do
    import Ecto.Query, only: [from: 2]

    attachments = from(a in Attachment, where: a.project_id == ^project_id) |> Repo.all()

    for %Attachment{type: "image/" <> _, placeholder: nil, id: id} <- attachments do
      Oberon.Jobs.ImageThumbnail.new(%{"attachment_id" => id}) |> Oban.insert()
    end

    :ok
  end
end
