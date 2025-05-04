defmodule Oberon.Jobs.ThumbnailScan do
  alias Oberon.Repo
  alias Oberon.Projects.Attachment
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    import Ecto.Query, only: [from: 2]

    attachments =
      from(a in Attachment,
        where:
          a.should_optimise == true and
            a.type |> like("image/%")
      )
      |> Repo.all()

    for %Attachment{id: id} <- attachments do
      Oberon.Jobs.ImageThumbnail.new(%{"attachment_id" => id}) |> Oban.insert()
    end

    :ok
  end
end
