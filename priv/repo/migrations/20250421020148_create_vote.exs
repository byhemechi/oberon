defmodule Oberon.Repo.Migrations.CreateVote do
  use Ecto.Migration

  def change do
    execute(
      "CREATE TYPE vote_type AS ENUM ('approve', 'disapprove', 'neutral', 'veto');",
      "DROP TYPE vote_type"
    )

    create table(:votes) do
      add :vote_type, :vote_type, null: false, default: "neutral"
      add :project_id, references(:projects, on_delete: :nothing)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:votes, [:project_id])
    create index(:votes, [:user_id])
    create index(:votes, [:inserted_at])
    create unique_index(:votes, [:user_id, :project_id])
  end
end
