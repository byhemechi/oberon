defmodule Oberon.Projects.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "votes" do
    field :vote_type, Ecto.Enum, values: [:approve, :disapprove, :neutral, :veto]
    belongs_to :user, Oberon.Auth.User
    belongs_to :project, Oberon.Projects.Project

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vote, attrs, user_scope) do
    vote
    |> cast(attrs, [:vote_type])
    |> validate_required([:vote_type])
    |> put_change(:user_id, user_scope.user.id)
  end
end
