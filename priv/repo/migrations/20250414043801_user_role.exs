defmodule Oberon.Repo.Migrations.UserRole do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE role AS ENUM ('guest', 'horan', 'admin')",
            "DROP TYPE role"

    alter table(:users) do
      add :role, :role, default: "guest", null: false
    end
  end
end
