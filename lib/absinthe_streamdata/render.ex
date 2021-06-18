# defimpl Inspect, for: Absinthe.Language.Document do
#   defdelegate inspect(term, options),
#     to: A
# end

# defmodule A do
#   import Inspect.Algebra

#   # alias Absinthe.Language

#   @line_width 120

#   def inspect(term, %{pretty: true}) do
#     # IO.inspect(term.__struct__, label: "struct")

#     term
#     |> render()
#     |> concat(line())
#     |> format(@line_width)
#     |> to_string
#   end

#   def inspect(term, options) do
#     Inspect.Any.inspect(term, options)
#   end

#   defp render(bp)

#   defp render(%Absinthe.Language.Document{} = _op) do
#     # concat([
#     #   # string()
#     #   # arguments(field.arguments, type_definitions),
#     #   # ": ",
#     #   # render(field.type, type_definitions),
#     #   # directives(field.directives, type_definitions)
#     # ])
#     # IO.inspect(op)

#     # operation =
#     #   block(
#     #     glue(Atom.to_string(op.type), operation_name(op)),
#     #     render_list(op.selections)
#     #   )

#     concat([
#       "#Absinthe.Language.OperationDefinition<variables: ",
#       # op.provided_values || %{},
#       # "#{inspect(op.provided_values)}",
#       # ", document: \"",
#       # operation,
#       "\">"
#     ])
#   end
# end
