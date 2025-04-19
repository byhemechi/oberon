defmodule Oberon.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias Oberon.Repo

  alias Oberon.Projects.Project
  alias Oberon.Auth.Scope

  @doc """
  Subscribes to scoped notifications about any project changes.

  The broadcasted messages match the pattern:

    * {:created, %Project{}}
    * {:updated, %Project{}}
    * {:deleted, %Project{}}

  """
  def subscribe_projects(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Oberon.PubSub, "user:#{key}:projects")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Oberon.PubSub, "user:#{key}:projects", message)
  end

  @doc """
  Returns the list of projects.

  ## Examples

      iex> list_projects(scope)
      [%Project{}, ...]

  """
  def list_projects(%Scope{user: nil}) do
    []
  end

  def list_projects(%Scope{}, state \\ :proposal) do
    Repo.all(from(project in Project, preload: [:user], where: project.state == ^state))
  end

  @doc """
  Gets a single project.

  Raises `Ecto.NoResultsError` if the Project does not exist.

  ## Examples

      iex> get_project!(123)
      %Project{}

      iex> get_project!(456)
      ** (Ecto.NoResultsError)

  """
  def get_project!(%Scope{}, id) do
    Repo.get_by!(Project |> preload([:user]), id: id)
  end

  @doc """
  Creates a project.

  ## Examples

      iex> create_project(%{field: value})
      {:ok, %Project{}}

      iex> create_project(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project(%Scope{} = scope, attrs \\ %{}) do
    with {:ok, project = %Project{}} <-
           %Project{}
           |> Project.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, project})
      {:ok, project}
    end
  end

  @doc """
  Updates a project.

  ## Examples

      iex> update_project(project, %{field: new_value})
      {:ok, %Project{}}

      iex> update_project(project, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_project(%Scope{} = scope, %Project{} = project, attrs) do
    true = project.user_id == scope.user.id

    with {:ok, project = %Project{}} <-
           project
           |> Project.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, project})
      {:ok, project}
    end
  end

  @doc """
  Deletes a project.

  ## Examples

      iex> delete_project(project)
      {:ok, %Project{}}

      iex> delete_project(project)
      {:error, %Ecto.Changeset{}}

  """
  def delete_project(%Scope{} = scope, %Project{} = project) do
    true = project.user_id == scope.user.id || scope.can_remove_proposals

    with {:ok, project = %Project{}} <-
           Repo.delete(project) do
      broadcast(scope, {:deleted, project})
      {:ok, project}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.

  ## Examples

      iex> change_project(project)
      %Ecto.Changeset{data: %Project{}}

  """
  def change_project(%Scope{} = scope, %Project{} = project, attrs \\ %{}) do
    true = project.user_id == scope.user.id

    Project.changeset(project, attrs, scope)
  end
end
