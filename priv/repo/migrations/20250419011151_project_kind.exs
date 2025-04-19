defmodule Oberon.Repo.Migrations.ProjectKind do
  use Ecto.Migration

  def change do
    execute(
      "CREATE TYPE project_kind AS ENUM ('purchase', 'project');",
      "DROP TYPE project_kind"
    )

    alter table(:projects) do
      add :kind, :project_kind, null: false, default: "project"
    end
  end
end
