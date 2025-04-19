defmodule Oberon.Repo.Migrations.CreateAttachments do
  use Ecto.Migration

  def change do
    execute(
      "CREATE TYPE image_dimensions AS (width bigint, height bigint);",
      "DROP TYPE image_dimensions"
    )

    create table(:attachments) do
      add :name, :string, null: false
      add :value, :string, null: false
      add :type, :string, null: false
      add :placeholder, :bytea
      add :dimensions, :image_dimensions
      add :project_id, references(:projects, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:attachments, [:project_id])
  end
end
