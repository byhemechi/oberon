defmodule Oberon.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Oberon.Projects` context.
  """

  @doc """
  Generate a project.
  """
  def project_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        price: 120.5,
        title: "some title",
        state: :proposal
      })

    {:ok, project} = Oberon.Projects.create_project(scope, attrs)
    project
  end
end
