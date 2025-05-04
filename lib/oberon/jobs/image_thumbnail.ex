defmodule Oberon.Jobs.ImageThumbnail do
  alias Oberon.Repo
  alias Oberon.Projects.Attachment
  alias Oberon.Projects
  use Oban.Worker, unique: [keys: [:attachment_id]]

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

    status =
      case image do
        {:ok, image} ->
          width = Vix.Vips.Image.width(image)
          height = Vix.Vips.Image.height(image)

          placeholder =
            image
            |> Image.thumbnail!(64)
            |> Image.write!(:memory, suffix: ".webp")

          optimised_path = "optimised/#{Ecto.UUID.generate()}.webp"

          image
          |> Image.thumbnail!("1200x784")
          |> Image.stream!(suffix: ".webp", buffer_size: 5_242_880)
          |> ExAws.S3.upload(
            Application.fetch_env!(:oberon, :s3)[:bucket_name],
            optimised_path,
            content_type: "image/webp"
          )
          |> ExAws.request!()

          {status, _v} =
            attachment
            |> Attachment.changeset(%{
              "placeholder" => placeholder,
              "dimensions" => {width, height},
              "optimised_url" => "s3:/" <> optimised_path,
              "should_optimise" => false
            })
            |> Map.put(:action, :update)
            |> Repo.update()

          Phoenix.PubSub.broadcast(
            Oberon.PubSub,
            "projects",
            {:updated, Projects.get_project!(attachment.project_id)}
          )

          status

        _ ->
          :ok
      end

    File.rm_rf!(temp_dir)

    status
  end
end
