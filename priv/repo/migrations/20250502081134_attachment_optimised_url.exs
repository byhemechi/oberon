defmodule Oberon.Repo.Migrations.AttachmentOptimisedUrl do
  use Ecto.Migration

  def change do
    alter table(:attachments) do
      add :optimised_url, :text
    end
  end
end
