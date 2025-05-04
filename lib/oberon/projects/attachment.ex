defmodule Oberon.Projects.Attachment.Dimensions do
  use Ecto.Type

  def type, do: :supertype

  def cast({x, y}) when is_integer(x) and is_integer(y) do
    {:ok, {x, y}}
  end

  def cast([x, y]) when is_integer(x) and is_integer(y) do
    {:ok, {x, y}}
  end

  def cast(%{"x" => x, "y" => y}) when is_integer(x) and is_integer(y) do
    {:ok, {x, y}}
  end

  def cast(%{"width" => x, "height" => y}) when is_integer(x) and is_integer(y) do
    {:ok, {x, y}}
  end

  def cast(_), do: :error

  def dump({x, y}) when is_integer(x) and is_integer(y) do
    {:ok, {x, y}}
  end

  def dump(_), do: :error

  def load({x, y}) when is_integer(x) and is_integer(y) do
    {:ok, {x, y}}
  end
end

defmodule Oberon.Projects.Attachment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "attachments" do
    field :name, :string
    field :value, :string
    field :optimised_url, :string
    field :type, :string
    field :placeholder, :string
    belongs_to :project, Oberon.Projects.Project
    field :dimensions, __MODULE__.Dimensions

    timestamps(type: :utc_datetime)
  end

  def global_link(%__MODULE__{optimised_url: p, value: v}), do: global_link(p || v)

  def global_link("s3:" <> object) do
    {:ok, url} =
      ExAws.Config.new(:s3)
      |> ExAws.S3.presigned_url(:get, Application.fetch_env!(:oberon, :s3)[:bucket_name], object)

    url
  end

  def global_link(v), do: v

  @doc false
  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:name, :value, :optimised_url, :type, :placeholder, :dimensions])
    |> validate_required([:name, :value, :type])
  end
end
