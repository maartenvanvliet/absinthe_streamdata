# Absinthe StreamData

## [![Hex pm](http://img.shields.io/hexpm/v/absinthe_streamdata.svg?style=flat)](https://hex.pm/packages/absinthe_streamdata) [![Hex Docs](https://img.shields.io/badge/hex-docs-9768d1.svg)](https://hexdocs.pm/absinthe_streamdata) [![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)![.github/workflows/elixir.yml](https://github.com/maartenvanvliet/subscriptions-transport-ws/workflows/.github/workflows/elixir.yml/badge.svg)

<!-- MDOC !-->

Build StreamData generator for valid Absinthe documents from an Absinthe schema.

It can take an entire schema, or single root queries/mutations and generate valid
documents from them. Supports variables and arguments.

By default supports all graphql scalar types but can be extended with
custom typemappers.

This gives you the chance to run random GraphQL documents against your schema and see whether
any of them returns errors you don't expect.

## Installation

The package can be installed by adding `absinthe_streamdata` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:absinthe_streamdata, "~> 0.1.0"}
  ]
end
```

## Example

```elixir
defmodule Absinthe.StreamDataTest do
  use MyApp.DataCase, async: false
  use ExUnitProperties

  defmodule TypeMapper do
    use Absinthe.StreamData.TypeMapper

    def from_type(%{name: "CustomScalar"}, schema, name, type_mapper) do
      StreamData.constant("bogus")
    end

    def from_type(type, schema, name, type_mapper) do
      Absinthe.StreamData.DefaultTypeMapper.from_type(type, schema, name, type_mapper)
    end
  end

  property "runs all docs" do
    schema = Your.Schema

    check all operation <- Absinthe.StreamData.operation_of(schema),
              field <- Absinthe.StreamData.field_of(schema, operation),
              doc <-
                Absinthe.StreamData.document_of(schema, operation, field),
              vars <- Absinthe.StreamData.variables_of(schema, doc, {TypeMapper, []}),
              runs <- Absinthe.StreamData.execution_of(schema, doc, variables: vars) do
      {:ok, blueprint} = runs

      assert blueprint.errors == []
    end
  end
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/absinthe_streamdata](https://hexdocs.pm/absinthe_streamdata).
