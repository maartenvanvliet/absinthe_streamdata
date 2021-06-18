defmodule Absinthe.StreamData.TypeMapper do
  @moduledoc """
  Behaviour for type mappers.

  ```elixir
  defmodule Test do
    use Absinthe.StreamData.TypeMapper

    def list_of(stream, name) do
      Absinthe.StreamData.DefaultTypeMapper.list_of(stream, name)
    end

    def optional(stream, name) do
      Absinthe.StreamData.DefaultTypeMapper.optional(stream, name)
    end

    def non_null(stream, name) do
      Absinthe.StreamData.DefaultTypeMapper.non_null(stream, name)
    end

    def from_type(type, schema, name, type_mapper) do
      Absinthe.StreamData.DefaultTypeMapper.from_type(type, schema, name, type_mapper)
    end
  end

  ```
  """
  @callback list_of(StreamData.t(), name :: binary) :: StreamData.t()
  @callback optional(StreamData.t(), name :: binary) :: StreamData.t()
  @callback non_null(StreamData.t(), name :: binary) :: StreamData.t()
  @callback from_type(
              type :: any,
              schema :: Absinthe.Schema.t(),
              name :: binary,
              type_mapper :: any
            ) ::
              StreamData.t()

  defmacro __using__(_) do
    quote do
      @behaviour Absinthe.StreamData.TypeMapper

      def list_of(stream, name) do
        Absinthe.StreamData.DefaultTypeMapper.list_of(stream, name)
      end

      def optional(stream, name) do
        Absinthe.StreamData.DefaultTypeMapper.optional(stream, name)
      end

      def non_null(stream, name) do
        Absinthe.StreamData.DefaultTypeMapper.non_null(stream, name)
      end

      def from_type(type, schema, name, type_mapper) do
        Absinthe.StreamData.DefaultTypeMapper.from_type(type, schema, name, type_mapper)
      end

      defoverridable list_of: 2, optional: 2, non_null: 2, from_type: 4
    end
  end
end
