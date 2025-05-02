defmodule Oberon.Jobs.ImageThumbnail do
  alias Oberon.Repo
  alias Oberon.Projects.Attachment
  alias Oberon.Projects
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"attachment_id" => attachment_id} = _args, id: job_id}) do
    attachment = Projects.get_attachment!(attachment_id)
    temp_dir = System.tmp_dir!() |> Path.join("thumbnail-#{job_id}")
    File.mkdir_p(temp_dir)
    temp_file = Path.join(temp_dir, attachment.value |> Path.basename())
    handle = File.stream!(temp_file)

    Req.get!(Attachment.global_link(attachment), into: handle)

    image =
      Image.open(temp_file)

    case image do
      {:ok, image} ->
        placeholder =
          image
          |> Image.thumbnail!(64)
          |> Image.write!(:memory, suffix: ".webp")

        dimensions = {Vix.Vips.Image.width(image), Vix.Vips.Image.height(image)}

        {status, _v} =
          attachment
          |> Attachment.changeset(%{"placeholder" => placeholder, "dimensions" => dimensions})
          |> Map.put(:action, :update)
          |> Repo.update()

        status

      _ ->
        :ok
    end
  end
end
