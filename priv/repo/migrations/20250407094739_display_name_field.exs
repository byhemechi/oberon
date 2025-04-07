defmodule Oberon.Repo.Migrations.UsernameField do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :display_name, :text, default: "User Name", null: false
    end
  end
end
