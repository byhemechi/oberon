defmodule Oberon.Repo.Migrations.AttachmentShouldOptimiseFlag do
  use Ecto.Migration

  def change do
    alter table(:attachments) do
      add :should_optimise, :boolean, null: false, default: false
    end

    create index(:attachments, [:should_optimise])
  end
end
