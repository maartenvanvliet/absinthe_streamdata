defmodule Absinthe.StreamData.DefaultTypeMapper do
  @moduledoc """
  Default type mapper from Absinthe types to StreamData.

  """
  @behaviour Absinthe.StreamData.TypeMapper

  def list_of(gen, _name) do
    StreamData.list_of(gen)
  end

  # 1 and 3 are frequencies picked after trying out a few different ones
  def optional(gen, _name) do
    StreamData.frequency([
      {1, StreamData.constant(nil)},
      {3, gen}
    ])
  end

  def non_null(gen, _name) do
    StreamData.filter(gen, &(!is_nil(&1)))
  end

  def from_type(%{identifier: :integer}, _name, _schema, _type_mapper) do
    StreamData.integer()
  end

  def from_type(%{identifier: :string}, _name, _schema, _type_mapper) do
    StreamData.string(:alphanumeric)
  end

  def from_type(%{identifier: :id}, _name, _schema, _type_mapper) do
    StreamData.one_of([StreamData.binary(), StreamData.integer()])
  end

  def from_type(%{identifier: :float}, _name, _schema, _type_mapper) do
    StreamData.float()
  end

  def from_type(%{identifier: :boolean}, _name, _schema, _type_mapper) do
    StreamData.boolean()
  end

  def from_type(%Absinthe.Type.Enum{} = type, _name, _schema, _type_mapper) do
    StreamData.member_of(Map.keys(type.values_by_name))
  end

  def from_type(%Absinthe.Type.InputObject{} = type, name, schema, type_mapper) do
    {required, optional} =
      type.fields
      |> Enum.split_with(&match?({_, %{type: %Absinthe.Type.NonNull{}}}, &1))

    required =
      required
      |> Enum.map(fn {_field_name, def} ->
        generator =
          Absinthe.StreamData.Variables.to_generator(schema, name, def.type, type_mapper)

        {def.name, generator}
      end)
      |> Map.new()
      |> StreamData.fixed_map()

    optional =
      optional
      |> Enum.map(fn {_field_name, def} ->
        generator =
          Absinthe.StreamData.Variables.to_generator(schema, name, def.type, type_mapper)

        {def.name, generator}
      end)
      |> Map.new()
      |> StreamData.optional_map()

    StreamData.bind(required, fn required ->
      StreamData.bind(optional, fn optional ->
        StreamData.constant(Map.merge(required, optional))
      end)
    end)
  end

  def from_type(type, name, _schema, _type_mapper) do
    raise RuntimeError, "No mapping defined for type #{type.name} on variable named #{name}"
  end
end
