defmodule Absinthe.StreamData do
  @moduledoc """
  Documentation for `Absinthe.StreamData`.
  """

  require Logger

  def run(schema, doc, opts) do
    pipeline =
      schema
      |> Absinthe.Pipeline.for_document(opts)
      |> Absinthe.Pipeline.without(Absinthe.Phase.Parse)

    {:ok, blueprint, _} = Absinthe.Pipeline.run(doc, pipeline)
    {:ok, blueprint}
  end

  def execution_of(schema, doc, opts) do
    StreamData.constant(run(schema, doc, opts))
  end

  def variables_of(schema, doc, type_mapper \\ {Absinthe.StreamData.DefaultTypeMapper, []}) do
    Absinthe.StreamData.Variables.variables_of(schema, doc, type_mapper)
  end

  def operation_of(schema) do
    Absinthe.Schema.types(schema)
    |> Enum.filter(&(&1.identifier in [:query, :mutation]))
    |> Enum.map(& &1.identifier)
    |> StreamData.member_of()
  end

  def field_of(schema, operation_type) do
    operation_fields = find_type(schema, operation_type)

    operation_fields.fields
    |> Map.keys()
    |> Enum.reject(&(&1 in [:__schema, :__type, :__typename]))
    |> StreamData.member_of()
  end

  def document_of(schema, operation_type, name) do
    operation_fields = find_type(schema, operation_type)

    {_name, field} =
      Enum.find(operation_fields.fields, fn {op_name, _value} ->
        op_name == name
      end)

    input =
      struct_of(Absinthe.Language.Document, %{
        definitions:
          StreamData.list_of(
            StreamData.bind(
              StreamData.fixed_map(%{
                loc: nil,
                selection_set:
                  struct_of(
                    Absinthe.Language.SelectionSet,
                    %{
                      selections: root_operation(field, schema)
                    }
                  )
              }),
              fn operation_definition ->
                struct_of(
                  Absinthe.Language.OperationDefinition,
                  Map.merge(operation_definition, %{
                    name: StreamData.string(:printable),
                    operation: StreamData.constant(operation_type),
                    variable_definitions:
                      operation_definition.selection_set
                      |> extract_arguments()
                      |> build_variable_definitions(field.type, schema),
                    selection_set:
                      StreamData.constant(
                        operation_definition.selection_set
                        |> normalize_selection_set
                      )
                  })
                )
              end
            ),
            length: 1
          )
      })

    struct_of(Absinthe.Blueprint, %{input: input})
  end

  defp find_type(schema, type) when is_atom(schema) do
    Absinthe.Schema.types(schema) |> Enum.find(fn a -> a.identifier == type end)
  end

  defp root_operation(field, schema) do
    struct_of(
      Absinthe.Language.Field,
      %{
        loc: nil,
        name: StreamData.constant(field.name),
        arguments: build_arguments(field.args, schema),
        selection_set:
          schema
          |> find_type(Absinthe.Type.unwrap(field.type))
          |> build_selection_set(schema, 0)
      }
    )
    |> StreamData.list_of(length: 1)
  end

  defp build_arg_type(%Absinthe.Type.NonNull{of_type: type}, schema) do
    %Absinthe.Language.NonNullType{type: build_arg_type(type, schema)}
  end

  defp build_arg_type(%Absinthe.Type.List{of_type: type}, schema) do
    %Absinthe.Language.ListType{type: build_arg_type(type, schema)}
  end

  defp build_arg_type(%Absinthe.Language.NamedType{name: name}, schema) do
    build_arg_type(name, schema)
  end

  defp build_arg_type(name, schema) do
    %Absinthe.Language.NamedType{
      loc: nil,
      name: find_type(schema, name).name
    }
  end

  defp build_variable_definitions(arguments, _type, schema) do
    arguments
    |> Enum.map(fn {arg, type} ->
      %Absinthe.Language.VariableDefinition{
        loc: nil,
        type: build_arg_type(type, schema),
        variable: %Absinthe.Language.Variable{loc: nil, name: arg.value.name}
      }
    end)
    |> StreamData.constant()
  end

  # the AST is annotated with type information for arguments
  # this needs to be removed before it is a valid absinthe document again
  defp normalize_selection_set(selection_set) do
    {doc, _} =
      Absinthe.StreamData.LanguageTransform.walk(selection_set, nil, fn
        {%Absinthe.Language.Argument{} = node, _type}, _ ->
          {node, nil}

        node, _ ->
          {node, nil}
      end)

    doc
  end

  defp extract_arguments(selection_set) do
    {_, arguments} =
      Absinthe.StreamData.LanguageTransform.walk(selection_set, [], fn node, acc ->
        acc =
          case node do
            {%Absinthe.Language.Argument{} = node, type} ->
              [{node, type} | acc]

            _ ->
              acc
          end

        {node, acc}
      end)

    arguments
  end

  def struct_of(struct, data) do
    data |> StreamData.fixed_map() |> StreamData.map(&struct!(struct, &1))
  end

  defp build_selection_set(%{fields: _} = type, schema, depth) do
    struct_of(Absinthe.Language.SelectionSet, %{
      loc: StreamData.constant(nil),
      selections: build_selections(type, schema, depth)
    })
  end

  defp build_selection_set(_t, _schema, _) do
    StreamData.constant(nil)
  end

  # can do complexity analysis here to limit list length.
  # E.g. # field (recursive) * args * directives * # fields * constant
  defp complexity(%Absinthe.Type.Object{} = type, depth) do
    Enum.reduce(type.fields, 0, fn {_, field}, acc -> complexity(field, depth) + acc end)
  end

  defp complexity(type, _depth) do
    max(Enum.count(type.args), 1)
  end

  defp build_selections(%Absinthe.Type.Union{} = type, schema, depth) do
    type.types
    |> Enum.map(fn type ->
      type = find_type(schema, type)

      struct_of(Absinthe.Language.InlineFragment, %{
        type_condition:
          StreamData.constant(%Absinthe.Language.NamedType{loc: nil, name: type.name}),
        loc: StreamData.constant(nil),
        selection_set: build_selection_set(type, schema, depth + 1)
      })
    end)
    |> StreamData.one_of()
    |> StreamData.resize(Enum.count(type.types))
    |> StreamData.list_of(min_length: 1)
  end

  defp build_selections(type, schema, depth) do
    max_length = complexity(type, depth)

    type.fields
    |> Enum.map(fn {_n, field} ->
      struct_of(Absinthe.Language.Field, %{
        alias: StreamData.constant(nil),
        arguments: build_arguments(field.args, schema),
        directives: StreamData.constant([]),
        loc: StreamData.constant(nil),
        name: StreamData.constant(field.name),
        selection_set:
          find_type(schema, Absinthe.Type.unwrap(field.type))
          |> build_selection_set(schema, depth + 1)
      })
    end)
    |> StreamData.one_of()
    |> StreamData.resize(Enum.count(type.fields))
    |> StreamData.uniq_list_of(min_length: 1, max_length: max_length, max_tries: max_length * 10)
  end

  defp build_arguments(args, _schema) when args == %{} do
    StreamData.constant([])
  end

  defp build_arguments(args, _schema) do
    {required, optional} =
      args
      |> Enum.split_with(&match?(%{type: %Absinthe.Type.NonNull{}}, elem(&1, 1)))

    required =
      required
      |> Enum.map(fn {_, arg} ->
        build_argument(arg)
      end)
      |> StreamData.fixed_list()

    num_optional_args = Enum.count(optional)

    optional =
      if num_optional_args == 0 do
        StreamData.constant([])
      else
        optional
        |> Enum.map(fn {_, arg} ->
          build_argument(arg)
        end)
        |> StreamData.one_of()
        |> StreamData.uniq_list_of(
          uniq_fun: fn {arg, _} -> arg.name end,
          min_length: 0,
          max_tries: num_optional_args * 10,
          max_length: num_optional_args
        )
      end

    StreamData.bind(required, fn required ->
      StreamData.bind(optional, fn optional ->
        StreamData.constant(required ++ optional)
      end)
    end)
  end

  # it returns a tuple, with the first element the argument
  # and the second its type since we need that at a later stage
  def build_argument(arg) do
    StreamData.tuple({
      struct_of(Absinthe.Language.Argument, %{
        loc: nil,
        name: StreamData.constant(arg.name),
        value: struct_of(Absinthe.Language.Variable, %{loc: nil, name: var_name(arg.name)})
      }),
      StreamData.constant(arg.type)
    })
  end

  def var_name(name) do
    StreamData.map(
      {StreamData.unshrinkable(StreamData.positive_integer()),
       StreamData.string(:alphanumeric, min_length: 5)},
      fn {i, r} ->
        "var_#{name}_#{i}_#{r}"
      end
    )
  end
end
