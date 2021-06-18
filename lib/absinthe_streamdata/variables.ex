defmodule Absinthe.StreamData.Variables do
  @moduledoc false
  def parse_doc(doc, schema) do
    pipeline =
      schema
      |> Absinthe.Pipeline.for_document()
      |> Absinthe.Pipeline.upto(Absinthe.Phase.Document.Validation.UniqueVariableNames)

    Absinthe.Pipeline.run(doc, pipeline)
  end

  def variables_of(schema, doc, type_mapper \\ {Absinthe.StreamData.DefaultTypeMapper, []})

  def variables_of(schema, doc, type_mapper) when is_binary(doc) do
    {:ok, blueprint, _} = parse_doc(doc, schema)

    variables_of(schema, blueprint, type_mapper)
  end

  def variables_of(schema, %{operations: []} = doc, type_mapper) do
    pipeline =
      schema
      |> Absinthe.Pipeline.for_document()
      |> Absinthe.Pipeline.without(Absinthe.Phase.Parse)
      |> Absinthe.Pipeline.upto(Absinthe.Phase.Document.Validation.UniqueVariableNames)

    {:ok, blueprint, _} = Absinthe.Pipeline.run(doc, pipeline)
    variables_of(schema, blueprint, type_mapper)
  end

  def variables_of(schema, %Absinthe.Blueprint{} = doc, type_mapper) do
    operation = Absinthe.Blueprint.current_operation(doc)

    {required, optional} =
      operation.variable_definitions
      |> Enum.split_with(&match?(%{type: %Absinthe.Blueprint.TypeReference.NonNull{}}, &1))

    required =
      required
      |> Enum.map(fn def ->
        generator = to_generator(schema, def.name, def.type, type_mapper)

        {def.name, generator}
      end)
      |> Map.new()
      |> StreamData.fixed_map()

    optional =
      optional
      |> Enum.map(fn def ->
        generator = to_generator(schema, def.name, def.type, type_mapper)

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

  def to_generator(
        schema,
        name,
        %Absinthe.Blueprint.TypeReference.Name{} = type_ref,
        {type_mapper, opts}
      ) do
    type = Absinthe.Schema.lookup_type(schema, Absinthe.Type.unwrap(type_ref).name)

    type
    |> type_mapper.from_type(name, schema, {type_mapper, opts})
    |> type_mapper.optional(name)
  end

  def to_generator(
        schema,
        name,
        %Absinthe.Blueprint.TypeReference.NonNull{} = type_ref,
        {type_mapper, opts}
      ) do
    to_generator(schema, name, type_ref.of_type, {type_mapper, opts})
    |> type_mapper.non_null(name)
  end

  def to_generator(
        schema,
        name,
        %Absinthe.Blueprint.TypeReference.List{} = type_ref,
        {type_mapper, opts}
      ) do
    to_generator(schema, name, type_ref.of_type, {type_mapper, opts})
    |> type_mapper.list_of(name)
    |> type_mapper.optional(name)
  end

  def to_generator(schema, name, %Absinthe.Type.NonNull{} = type, {type_mapper, opts}) do
    to_generator(schema, name, type.of_type, {type_mapper, opts}) |> type_mapper.non_null(name)
  end

  def to_generator(schema, name, type, {type_mapper, opts}) when is_atom(type) do
    type = Absinthe.Schema.lookup_type(schema, type)

    type
    |> type_mapper.from_type(name, schema, {type_mapper, opts})
    |> type_mapper.optional(name)
  end
end
