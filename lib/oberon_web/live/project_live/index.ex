defmodule OberonWeb.ProjectLive.Index do
  use OberonWeb, :live_view

  alias Oberon.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <.header>
        Listing Projects
        <:actions>
          <.button
            :if={@current_scope.can_create_proposals}
            variant="primary"
            navigate={~p"/projects/new"}
          >
            <.icon name="hero-plus" /> New Project
          </.button>
        </:actions>
      </.header>

      <.table
        id="projects"
        rows={@streams.projects}
        row_click={fn {_id, project} -> JS.navigate(~p"/projects/!#{project}") end}
      >
        <:col :let={{_id, project}} label="Title">{project.title}</:col>
        <:col :let={{_id, project}} label="Kind">
          {project.kind}
        </:col>
        <:col :let={{_id, project}} label="Price">{project.price}</:col>
        <:col :let={{_id, project}} label="Created By">{project.user.display_name}</:col>
        <:action :let={{_id, project}}>
          <div class="sr-only">
            <.link navigate={~p"/projects/!#{project}"}>Show</.link>
          </div>
          <.link navigate={~p"/projects/!#{project}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, project}}>
          <.link
            class={!@current_scope.can_remove_proposals && "hidden"}
            phx-click={JS.push("delete", value: %{id: project.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
            title="delete"
            data-action="delete"
          >
            <.icon name="hero-trash" />
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Projects.subscribe_projects(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Listing Projects")
     |> assign(:route, :projects)
     |> stream(:projects, Projects.list_projects(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    project = Projects.get_project!(id)
    {:ok, _} = Projects.delete_project(socket.assigns.current_scope, project)

    {:noreply, stream_delete(socket, :projects, project)}
  end

  @impl true
  def handle_info({type, %Oberon.Projects.Project{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply,
     stream(socket, :projects, Projects.list_projects(socket.assigns.current_scope), reset: true)}
  end
end
