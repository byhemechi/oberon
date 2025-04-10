defmodule OberonWeb.ProjectLive.Show do
  use OberonWeb, :live_view

  alias Oberon.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Project {@project.id}
        <:subtitle>This is a project record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/projects"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/projects/#{@project}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit project
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Title">{@project.title}</:item>
        <:item title="Price">{@project.price}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    Projects.subscribe_projects(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Show Project")
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
