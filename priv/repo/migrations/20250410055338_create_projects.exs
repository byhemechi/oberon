defmodule Oberon.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    execute(
      "CREATE TYPE project_state AS ENUM ('proposal', 'cancelled', 'declined', 'in_planning', 'in_progress', 'paused', 'completed');",
      "DROP TYPE project_state"
    )

    create table(:projects) do
      add :title, :string, null: false
      add :state, :project_state, null: false, default: "proposal"
      add :price, :numeric
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:projects, [:user_id])
    create index(:projects, [:state])
  end
end
