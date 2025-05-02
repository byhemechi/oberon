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

  @doc """
  Generate a attachment.
  """
  def attachment_fixture(attrs \\ %{}) do
    {:ok, attachment} =
      attrs
      |> Enum.into(%{
        name: "some name",
        placeholder: "some placeholder",
        type: "some type",
        value: "some value"
      })
      |> Oberon.Projects.create_attachment()

    attachment
  end

  @doc """
  Generate a vote.
  """
  def vote_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        vote_type: :approve
      })

    {:ok, vote} = Oberon.Projects.create_vote(scope, attrs)
    vote
  end
end
