defmodule OberonWeb.ProjectLive.Form do
  alias Oberon.Repo
  alias Oberon.Projects.Attachment
  use OberonWeb, :live_view

  alias Oberon.Projects
  alias Oberon.Projects.Project

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "File type not supported"
  defp error_to_string(:too_many_files), do: "Too many files"
  defp error_to_string(:external_client_failure), do: "External error"

  def presign_upload(entry, socket) do
    config = ExAws.Config.new(:s3)
    bucket = Application.fetch_env!(:oberon, :s3)[:bucket_name]
    key = "/attachments/#{entry.uuid}/#{entry.client_name}"

    {:ok, url} =
      ExAws.S3.presigned_url(config, :put, bucket, key,
        expires_in: 3600,
        query_params: [{"Content-Type", entry.client_type}]
      )

    {:ok, %{uploader: "S3", key: key, url: url}, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns} route={:projects}>
      <.header>
        {@page_title}
      </.header>

      <.form
        for={@form}
        id="project-form"
        phx-change="validate"
        phx-submit="save"
        class="flex flex-col gap-2"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:price]} type="number" label="Price" step="any" />

        <label
          for={@uploads.attachments.ref}
          phx-drop-target={@uploads.attachments.ref}
          class="border-2 block border-dashed border-base-content/20 rounded-lg p-6 text-center transition-colors"
        >
          <div class="flex flex-col items-center justify-center gap-4">
            <.icon name="hero-photo-solid" class="h-12 w-12 text-zinc-400" />
            <div class="text-sm text-base-content">
              <p>Drag and drop your image here</p>
              <p>or</p>
              <.live_file_input upload={@uploads.attachments} class="btn py-2" />
            </div>
          </div>
        </label>

        <div class={[
          "flex gap-2 flex-wrap"
        ]}>
          <%= for attachment <- @project.attachments ++ @uploads.attachments.entries do %>
            <%= case attachment do %>
              <% %Attachment{name: name} -> %>
                <div class="upload size-36 group" id={"attachment-#{attachment.id}"}>
                  <.icon name="hero-document" />
                  <div class="card-title max-w-32 text-center overflow-ellipsis overflow-hidden">
                    {name}
                  </div>
                  <button
                    class={[
                      "btn btn-circle btn-sm",
                      "absolute -top-3 -right-3 btn-secondary z-40",
                      "scale-0 group-hover:scale-100 transition"
                    ]}
                    type="button"
                    phx-click={
                      JS.push("delete-attachment") |> JS.hide(to: "#attachment-#{attachment.id}")
                    }
                    value={attachment.id}
                  >
                    <.icon name="hero-x-mark" />
                  </button>
                </div>
              <% %Phoenix.LiveView.UploadEntry{valid?: valid?, done?: done?, } -> %>
                <div
                  class={[
                    "upload size-36 group p-4",
                    !valid? && "ring-error ring-3"
                  ]}
                  id={"upload-#{attachment.ref}"}
                >
                  <div class="card-body items-center">
                    <.icon :if={!done?} name="hero-arrow-up-tray" />
                    <.icon :if={done?} name="hero-check" class="text-success" />
                    <div class="card-title text-base max-w-32 text-center overflow-ellipsis overflow-hidden">
                      {attachment.client_name}
                    </div>
                    <div
                      :if={valid? && !done?}
                      class="w-full rounded-full h-1 bg-base-content/1 0  overflow-hidden"
                    >
                      <div
                        class="bg-primary  h-full rounded-full transition-size"
                        style={"width: #{attachment.progress}%"}
                      >
                      </div>
                    </div>
                    <%= for err <- upload_errors(@uploads.attachments, attachment) do %>
                      <p class="text-error text-sm mt-1">{error_to_string(err)}</p>
                    <% end %>
                  </div>
                  <button
                    class={[
                      "btn btn-circle btn-sm",
                      "absolute -top-3 -right-3 btn-error z-40",
                      "scale-0 group-hover:scale-100 transition"
                    ]}
                    type="button"
                    phx-click={JS.push("cancel-upload") |> JS.hide(to: "#upload-#{attachment.ref}")}
                    phx-value-ref={attachment.ref}
                  >
                    <.icon name="hero-x-mark" />
                  </button>
                </div>
            <% end %>
          <% end %>
        </div>

        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Project</.button>
          <.button navigate={return_path(@current_scope, @return_to, @project)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:to_delete, [])
     |> allow_upload(:attachments,
       accept: :any,
       max_file_size: 60_000_000,
       auto_upload: true,
       max_entries: 5,
       external: &presign_upload/2
     )
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    project = Projects.get_project!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Project")
    |> assign(:project, project)
    |> assign(:form, to_form(Projects.change_project(socket.assigns.current_scope, project)))
  end

  defp apply_action(socket, :new, _params) do
    project = %Project{user_id: socket.assigns.current_scope.user.id, attachments: []}

    socket
    |> assign(:page_title, "New Project")
    |> assign(:project, project)
    |> assign(:form, to_form(Projects.change_project(socket.assigns.current_scope, project)))
  end

  @impl true
  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset =
      Projects.change_project(
        socket.assigns.current_scope,
        socket.assigns.project,
        project_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachments, ref)}
  end

  def handle_event("delete-attachment", %{"value" => id}, socket) do
    {id, _} = Integer.parse(id)

    {:noreply, socket |> assign(to_delete: [id | socket.assigns.to_delete])}
  end

  def handle_event("save", %{"project" => project_params}, socket) do
    save_project(socket, socket.assigns.live_action, project_params)
  end

  defp upload_file(key, entry) do
    {:ok,
     %{
       "value" => "s3:" <> key,
       "name" => entry.client_name,
       "type" =>
         if !is_nil(entry.client_type) && String.length(entry.client_type) > 0 do
           entry.client_type
         else
           "application/octet-stream"
         end
     }}
  end

  defp save_project(socket, :edit, project_params) do
    uploaded_files =
      consume_uploaded_entries(socket, :attachments, fn %{key: key}, entry ->
        upload_file(key, entry)
      end)

    case Repo.transaction(fn ->
           project = socket.assigns.project

           project =
             project
             |> Map.put(
               :attachments,
               project.attachments
               |> Enum.filter(&(!Enum.member?(socket.assigns.to_delete, &1.id)))
             )

           {:ok, project} =
             Projects.update_project(
               socket.assigns.current_scope,
               socket.assigns.project,
               project_params
               |> Map.put(
                 "attachments",
                 Enum.map(project.attachments, &Ecto.embedded_dump(&1, :json)) ++
                   uploaded_files
               )
             )

           project
         end) do
      {:ok, project} ->
        Oberon.Jobs.GenerateProjectThumbnails.new(%{"project_id" => project.id})
        |> Oban.insert()

        {:noreply,
         socket
         |> put_flash(:info, "Project updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, project)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_project(socket, :new, project_params) do
    uploaded_files =
      consume_uploaded_entries(socket, :attachments, fn %{key: key}, entry ->
        upload_file(key, entry)
      end)

    case Projects.create_project(
           socket.assigns.current_scope,
           project_params
           |> Map.put(
             "attachments",
             uploaded_files
           )
         ) do
      {:ok, project} ->
        Oberon.Jobs.GenerateProjectThumbnails.new(%{"project_id" => project.id})
        |> Oban.insert()

        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully")
         |> push_navigate(to: ~p"/projects/!#{project.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _project), do: ~p"/projects"
  defp return_path(_scope, "show", project), do: ~p"/projects/!#{project}"
end
