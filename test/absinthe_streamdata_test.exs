defmodule Absinthe.StreamDataTest do
  use ExUnit.Case
  use ExUnitProperties

  doctest Absinthe.StreamData

  # defstruct :variables
  @no_var_query """
  query testA{
    version
  }
  """

  @scalar_query """
  query testB($boolean: Boolean
  $float: Float
  $integer: Int
  $id: ID
  $string: String){
    defaultScalar(boolean: $boolean
    float: $float
    id: $id
    integer: $integer
    string: $string)
  }
  """

  @list_query """
  query testC($booleans: [Boolean] $strings: [String!], $integers: [Int!]!, $floats: [Float]!){
    list_args(booleans: $booleans strings: $strings, integers: $integers, floats: $floats)
  }
  """

  @enum_query """
  query testD($contact: ContactType $m_contact: ContactType! $list: [ContactType!]!){
    enum_args(contactType: $contact mContactType: $m_contact listContacts: $list)
  }
  """

  @input_query """
  query testE($input: ContactInput){
    input_args(input: $input)
  }
  """

  @queries [
    @no_var_query,
    @scalar_query,
    @list_query,
    @enum_query,
    @input_query
  ]

  for query <- @queries do
    @query query
    property "#{query}" do
      check all(
              vars <-
                Absinthe.StreamData.variables_of(Absinthe.StreamData.Fixtures.TestSchema, @query),
              max_runs: 5
            ) do
        {:ok, _} = Absinthe.run(@query, Absinthe.StreamData.Fixtures.TestSchema, variables: vars)
      end
    end
  end

  property "runs all docs" do
    schema = Absinthe.StreamData.Fixtures.TestSchema

    check all(
            operation <- Absinthe.StreamData.operation_of(schema),
            field <- Absinthe.StreamData.field_of(schema, operation),
            doc <-
              Absinthe.StreamData.document_of(schema, operation, field),
            vars <- Absinthe.StreamData.variables_of(schema, doc),
            runs <- Absinthe.StreamData.execution_of(schema, doc, variables: vars),
            max_runs: 100
          ) do
      {:ok, blueprint} = runs

      assert blueprint.errors == []
      assert blueprint.result[:errors] == nil
    end
  end
end
