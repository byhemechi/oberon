defmodule OberonWeb.ProjectLive.Show do
  use OberonWeb, :live_view

  alias Oberon.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns} route={:projects} container={false}>
      <div class="max-w-screen-lg mx-auto p-4 px-6 pb-0">
        <.header>
          {@project.title}
          <:subtitle>This is a project record from your database.</:subtitle>
          <:actions>
            <.button navigate={~p"/projects"}>
              <.icon name="hero-arrow-left" />
            </.button>
            <.button
              :if={@current_scope.can_edit_proposals || @current_scope.user.id == @project.user_id}
              variant="primary"
              navigate={~p"/projects/!#{@project}/edit?return_to=show"}
            >
              <.icon name="hero-pencil-square" />

              {gettext("Edit %{state}",
                state:
                  case @project do
                    %{state: :proposal} -> gettext("proposal")
                    %{kind: :project} -> gettext("project")
                    %{kind: :purchase} -> gettext("purchase")
                    _ -> gettext("project")
                  end
              )}
            </.button>
          </:actions>
        </.header>
      </div>
      <div
        :if={length(@project.attachments) > 0}
        class={[
          "grid auto-rows-[calc(var(--spacing)_*_48)]",
          "grid-flow-col-dense gap-2 my-4 lg:px-0",
          "overflow-auto snap-x snap-mandatory",
          "p-4 lg:px-[calc(50dvw_-_var(--breakpoint-lg)_/_2_+_var(--spacing)_*_4)]"
        ]}
      >
        <%= for attachment <- @project.attachments do %>
          <%= case attachment do %>
            <% %{type: "link"} -> %>
              <a href={attachment.value} class="upload w-46 gap-2 items-center justify-center">
                <div class="card-title">
                  <.icon name="hero-link" />{attachment.name}
                </div>
              </a>
            <% %{placeholder: placeholder} when is_binary(placeholder) -> %>
              <a
                class="upload overflow-clip row-span-2 relative"
                href={attachment.value}
                style={
                  case attachment.dimensions do
                    {x, y} ->
                      "aspect-ratio: #{x} / #{y}; width: calc(var(--spacing) * 98 * #{x} / #{y}); height: calc(var(--spacing) * 98)"

                    _ ->
                      nil
                  end
                }
              >
                <figure>
                  <lazy-img>
                    <img
                      alt={attachment.name}
                      src={ "data:image/webp;base64,#{Base.encode64(placeholder)}"}
                      role="presentation"
                      data-role="placeholder"
                      class="size-full absolute inset-0 blur"
                    />
                    <img alt={attachment.name} src={attachment.value} class="size-full relative" />
                  </lazy-img>
                </figure>
              </a>
            <% _ -> %>
              <a
                href={attachment.value}
                download={Path.basename(attachment.value)}
                class="upload w-46 gap-2 items-center justify-center"
              >
                <.icon name="hero-arrow-down-tray" />
                <div class="card-title">
                  {attachment.name}
                </div>
              </a>
          <% end %>
        <% end %>
      </div>

      <div class="max-w-screen-lg mx-auto px-6">
        <.list>
          <:item title="Title">{@project.title}</:item>
          <:item title="Price">{gettext("$%{price}", price: @project.price)}</:item>
          <:item title="Created by">{@project.user.display_name}</:item>
        </.list>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    Projects.subscribe_projects(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Show Project")
     |> assign(:route, :projects)
     |> assign(:project, Projects.get_project!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %Oberon.Projects.Project{id: id} = project},
        %{assigns: %{project: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :project, project)}
  end

  def handle_info(
        {:deleted, %Oberon.Projects.Project{id: id}},
        %{assigns: %{project: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current project was deleted.")
     |> push_navigate(to: ~p"/projects")}
  end
end
