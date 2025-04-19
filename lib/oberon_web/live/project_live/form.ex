defmodule OberonWeb.ProjectLive.Form do
  use OberonWeb, :live_view

  alias Oberon.Projects
  alias Oberon.Projects.Project

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "File type not supported"
  defp error_to_string(:too_many_files), do: "Too many files"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns} route={:projects}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage project records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="project-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:price]} type="number" label="Price" step="any" />

        <label
          for={@uploads.attachments.ref}
          phx-drop-target={@uploads.attachments.ref}
          class="border-2 block border-dashed border-base-300 rounded-lg p-6 text-center transition-colors"
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

        <%= for entry <- @uploads.attachments.entries do %>
          <article class="card p-4 bg-base-200">
            <.live_img_preview entry={entry} class="w-32 h-32 object-cover rounded" />

            <div class="flex flex-col gap-2 flex-1">
              <p class="font-medium">{entry.client_name}</p>
              <%!-- entry.progress will update automatically for in-flight entries --%>
              <div class="w-full rounded-full h-2.5">
                <div class="bg-brand h-2.5 rounded-full" style={"width: #{entry.progress}%"}></div>
              </div>
              <p class="text-xs">{entry.progress}% uploaded</p>

              <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
              <button
                type="button"
                phx-click="cancel-upload"
                phx-value-ref={entry.ref}
                aria-label="cancel"
                class="absolute top-2 right-2 text-zinc-400 hover:text-zinc-200"
              >
                <.icon name="hero-x-mark-solid" class="h-5 w-5" />
              </button>

              <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
              <%= for err <- upload_errors(@uploads.attachments, entry) do %>
                <p class="text-rose-500 text-sm mt-1">{error_to_string(err)}</p>
              <% end %>
            </div>
          </article>
        <% end %>
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
     |> allow_upload(:attachments,
       accept: :any,
       max_file_size: 60_000_000,
       auto_upload: true,
       max_entries: 5
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
    project = %Project{user_id: socket.assigns.current_scope.user.id}

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

  def handle_event("save", %{"project" => project_params}, socket) do
    save_project(socket, socket.assigns.live_action, project_params)
  end

  defp upload_image(path, image, link_dir, dest_dir, entry) do
    file_name = Path.rootname(entry.client_name) <> ".webp"
    dest = Path.join(link_dir, file_name)

    File.cp!(
      path,
      Path.join(
        dest_dir,
        Path.rootname(entry.client_name) <> "-orig" <> Path.extname(entry.client_name)
      )
    )

    image =
      image
      |> Image.thumbnail!(Vix.Vips.Image.width(image))

    width = Vix.Vips.Image.width(image)
    image |> Image.write!(Path.join(dest_dir, file_name))

    {:ok,
     %{
       "value" => ~p"/uploads/" <> dest,
       "name" => entry.client_name,
       "type" => entry.client_type || "application/octet-stream",
       "dimensions" => {width, Vix.Vips.Image.height(image)},
       "placeholder" =>
         image
         |> Image.thumbnail!(64)
         |> Image.write!(:memory, suffix: ".webp")
     }}
  end

  defp upload_unknown_file(path, link_dir, dest_dir, entry) do
    dest = Path.join(link_dir, entry.client_name)
    dest_full = Path.join(dest_dir, entry.client_name)
    File.cp!(path, dest_full)

    {:ok,
     %{
       "value" => ~p"/uploads/" <> dest,
       "name" => entry.client_name,
       "type" => entry.client_type || "application/octet-stream"
     }}
  end

  defp upload_file(path, entry) do
    dest_dir = entry.uuid
    dest_dir_full = Path.join("priv/static/uploads", dest_dir)
    File.mkdir_p!(dest_dir_full)

    case Image.open(path) do
      {:ok, image} ->
        case Vix.Vips.Image.header_value(image, "vips-loader") do
          {:ok, "heifload"} ->
            upload_unknown_file(path, dest_dir, dest_dir_full, entry)

          _ ->
            upload_image(path, image, dest_dir, dest_dir_full, entry)
        end

      _ ->
        upload_unknown_file(path, dest_dir, dest_dir_full, entry)
    end
  end

  defp save_project(socket, :edit, project_params) do
    uploaded_files =
      consume_uploaded_entries(socket, :attachments, fn %{path: path}, entry ->
        upload_file(path, entry)
      end)

    case Projects.update_project(
           socket.assigns.current_scope,
           socket.assigns.project,
           project_params
           |> Map.put(
             "attachments",
             uploaded_files ++
               Enum.map(socket.assigns.project.attachments, &Ecto.embedded_dump(&1, :json))
           )
         ) do
      {:ok, project} ->
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
      consume_uploaded_entries(socket, :attachments, fn %{path: path}, entry ->
        upload_file(path, entry)
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
        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully")
         |> push_navigate(to: ~p"/projects/!#{project.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset |> IO.inspect()))}
    end
  end

  defp return_path(_scope, "index", _project), do: ~p"/projects"
  defp return_path(_scope, "show", project), do: ~p"/projects/!#{project}"
end
