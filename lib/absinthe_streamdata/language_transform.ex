defmodule Absinthe.StreamData.LanguageTransform do
  @moduledoc """
  Module to walk and modify Absinthe AST
  """
  def walk(language, acc, post)

  def walk(nodes, acc, post) when is_list(nodes) do
    Enum.map_reduce(nodes, acc, &walk(&1, &2, post))
  end

  def walk(node, acc, post) do
    {node, acc} = maybe_walk_children(node, acc, post)

    post.(node, acc)
  end

  def maybe_walk_children(%Absinthe.Language.SelectionSet{} = node, acc, post) do
    node_with_children(node, [:selections], acc, post)
  end

  def maybe_walk_children(%Absinthe.Language.Field{} = node, acc, post) do
    node_with_children(node, [:selection_set, :arguments], acc, post)
  end

  def maybe_walk_children(%Absinthe.Language.InlineFragment{} = node, acc, post) do
    node_with_children(node, [:selection_set], acc, post)
  end

  def maybe_walk_children(node, acc, _post) do
    {node, acc}
  end

  defp node_with_children(node, children, acc, post) do
    walk_children(node, children, acc, post)
  end

  defp walk_children(node, children, acc, post) do
    Enum.reduce(children, {node, acc}, fn child_key, {node, acc} ->
      {children, acc} =
        node
        |> Map.fetch!(child_key)
        |> walk(acc, post)

      {Map.put(node, child_key, children), acc}
    end)
  end
end
