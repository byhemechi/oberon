defmodule Oberon.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :title, :string

    field :kind, Ecto.Enum,
      values: [
        :purchase,
        :project
      ],
      default: :project

    field :state, Ecto.Enum,
      values: [
        :proposal,
        :cancelled,
        :declined,
        :in_planning,
        :in_progress,
        :paused,
        :completed
      ],
      default: :proposal

    field :price, :decimal
    belongs_to :user, Oberon.Auth.User

    has_many :attachments, Oberon.Projects.Attachment
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs, user_scope) do
    project
    |> cast(attrs, [:title, :price, :state])
    |> cast_assoc(:attachments)
    |> validate_required([:title, :price, :state])
    |> put_change(:user_id, user_scope.user.id)
  end
end
