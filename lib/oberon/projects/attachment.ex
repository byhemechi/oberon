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
    field :type, :string
    field :placeholder, :string
    field :project_id, :id
    field :dimensions, __MODULE__.Dimensions

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:name, :value, :type, :placeholder, :dimensions])
    |> validate_required([:name, :value, :type])
  end
end
