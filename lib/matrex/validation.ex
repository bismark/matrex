defmodule Matrex.Validation do

  @moduledoc """
  Basic validation

  Available options:

  - type: validates the type
    - :string
    - :integer
  - key: store in a different key
  - default: default value for optional
  - default_lazy: function to define a default
  - post: function to post process
  """

  def required(key, args, acc, options \\ []) do
    case fetch(key, args) do
      :error -> {:error, {:missing_arg, key}}
      {:ok, value} -> validate_value(key, value, acc, options)
    end
  end


  def optional(key, args, acc, options \\ []) do
    case fetch(key, args) do
      :error -> default(key, acc, options)
      {:ok, value} -> validate_value(key, value, acc, options)
    end
  end


  defp validate_value(key, value, acc, options) do
    with :ok <- validate_type(value, options),
         {:ok, value} <- cast(value, options),
         :ok <- validate_allowed(value, options),
         {:ok, value} <- postprocess(value, options)
    do
      key = get_key(key, options)
      {:ok, Map.put(acc, key, value)}
    else
      {:error, error} -> {:error, {error, key}}
    end
  end


  defp validate_type(value, options) do
    case Keyword.fetch(options, :type) do
      :error -> :ok
      {:ok, type} -> _validate_type(type, value)
    end
  end


  defp _validate_type(:string, value) when is_binary(value), do: :ok
  defp _validate_type(:integer, value) when is_integer(value), do: :ok
  defp _validate_type(:boolean, value) when is_boolean(value), do: :ok
  defp _validate_type(:map, value) when is_map(value), do: :ok
  defp _validate_type(:list, value) when is_list(value), do: :ok
  defp _validate_type(_, _), do: {:error, :bad_type}


  defp cast(value, options) do
    case Keyword.fetch(options, :as) do
      :error -> {:ok, value}
      {:ok, new_type} -> _cast(value, new_type)
    end
  end


  defp _cast(value, :atom) when is_binary(value) do
    try do
      String.to_existing_atom(value)
    rescue
      ArgumentError -> {:error, :bad_value}
    else
      v -> {:ok, v}
    end
  end


  defp validate_allowed(value, options) do
    case Keyword.fetch(options, :allowed) do
      :error -> :ok
      {:ok, allowed} -> case value in allowed do
        true -> :ok
        false -> {:error, :bad_value}
      end
    end
  end

  defp postprocess(value, options) do
    case Keyword.fetch(options, :post) do
      :error -> {:ok, value}
      {:ok, post} -> post.(value)
    end
  end


  defp get_key(key, options) do
    Keyword.get(options, :key, key)
  end


  defp default(key, acc, options) do
    case Keyword.fetch(options, :default) do
      :error -> default_lazy(key, acc, options)
      {:ok, default} ->
        key = get_key(key, options)
        {:ok, Map.put(acc, key, default)}
    end
  end


  defp default_lazy(key, acc, options) do
    case Keyword.fetch(options, :default_lazy) do
      :error -> {:ok, acc}
      {:ok, default} ->
        value = default.()
        key = get_key(key, options)
        {:ok, Map.put(acc, key, value)}
    end
  end


  defp fetch(key, args) do
    with :error <- Map.fetch(args, key) do
      if is_atom(key) do
        Map.fetch(args, Atom.to_string(key))
      else
        :error
      end
    end
  end


end
