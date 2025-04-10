defmodule Oberon.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :title, :string

    field :state, Ecto.Enum,
      values: [
        :proposal,
        :cancelled,
        :declined,
        :in_planning,
        :in_progress,
        :paused,
        :completed
      ]

    field :price, :decimal
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs, user_scope) do
    project
    |> cast(attrs, [:title, :price])
    |> validate_required([:title, :price])
    |> put_change(:user_id, user_scope.user.id)
  end
end
