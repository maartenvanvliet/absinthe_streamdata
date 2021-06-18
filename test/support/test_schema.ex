defmodule Absinthe.StreamData.Fixtures.TestSchema do
  @moduledoc false
  use Absinthe.Schema

  enum :contact_type do
    value(:phone, as: "phone")
    value(:email, as: "email")
  end

  input_object :address do
    field(:number, :integer)
    field(:street, non_null(:string))
    field(:city, :string)
  end

  union :pet do
    types([:dog, :cat])
  end

  object :dog do
    field(:name, :string)
  end

  object :cat do
    field(:age, :integer)
  end

  input_object :contact_input do
    field(:contact_type, non_null(:contact_type))
    field(:string_value, non_null(:string))
    field(:integer_value, :string)
    field(:address, :address)
  end

  object :simple_nested do
    field(:tester, :string)
  end

  object :simple_list do
    field(:test_list, list_of(:string))
  end

  object :simple_object do
    field :boolean, :boolean do
      arg(:boolean, :boolean)

      resolve(fn _, args, _res ->
        {:ok, args[:boolean] || false}
      end)
    end

    field(:number, :integer)
    field(:test_list, list_of(:string))

    field(:contact_type, :contact_type)
    field(:nested_simple_object, :simple_nested)
    field(:pet, :pet)
  end

  mutation do
    field :default_scalar, :string do
      arg(:boolean, :boolean)
      arg(:float, :float)
      arg(:id, :id)
      arg(:integer, :integer)
      arg(:string, :string)

      resolve(fn _, args, _res ->
        {:ok, "#{inspect(args)}"}
      end)
    end

    field :list_args, :string do
      arg(:booleans, list_of(:boolean))
      arg(:strings, list_of(non_null(:string)))
      arg(:integers, non_null(list_of(non_null(:integer))))
      arg(:floats, non_null(list_of(:float)))

      resolve(fn _, args, _res ->
        {:ok, "#{inspect(args)}"}
      end)
    end

    field :enum_args, :string do
      arg(:contact_type, :contact_type)
      arg(:m_contact_type, :contact_type)
      arg(:list_contacts, non_null(list_of(non_null(:contact_type))))

      resolve(fn _, args, _res ->
        {:ok, "#{inspect(args)}"}
      end)
    end

    field :input_args, :string do
      arg(:input, :contact_input)

      resolve(fn _, args, _res ->
        {:ok, "#{inspect(args)}"}
      end)
    end
  end

  query do
    field(:version, :string)

    field(:name_from_context,
      type: :string,
      resolve: fn _, _, _res ->
        {:ok, "res.context.name"}
      end
    )

    field :name_from_var, :string do
      arg(:name, :string)
      arg(:num, :string)

      resolve(fn _, args, _res ->
        {:ok, "#{inspect(args)}"}
      end)
    end

    field :simple, :simple_object do
      arg(:boolean, :boolean)

      resolve(fn _, _args, _res ->
        {:ok, %{number: 1, nested_simple_object: %{name: "yaya"}}}
      end)
    end

    field :default_scalar, :string do
      arg(:boolean, :boolean)
      arg(:float, :float)
      arg(:id, :id)
      arg(:integer, :integer)
      arg(:string, :string)

      resolve(fn _, args, _res ->
        {:ok, "#{inspect(args)}"}
      end)
    end

    field :list_args, :string do
      arg(:booleans, list_of(:boolean))
      arg(:strings, list_of(non_null(:string)))
      arg(:integers, non_null(list_of(non_null(:integer))))
      arg(:floats, non_null(list_of(:float)))

      resolve(fn _, args, _res ->
        {:ok, "#{inspect(args)}"}
      end)
    end

    field :enum_args, :string do
      arg(:contact_type, :contact_type)
      arg(:m_contact_type, :contact_type)
      arg(:list_contacts, non_null(list_of(non_null(:contact_type))))

      resolve(fn _, args, _res ->
        {:ok, "#{inspect(args)}"}
      end)
    end

    field :input_args, :string do
      arg(:input, :contact_input)

      resolve(fn _, args, _res ->
        {:ok, "#{inspect(args)}"}
      end)
    end
  end
end
