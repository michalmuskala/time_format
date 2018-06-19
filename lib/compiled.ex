defmodule TimeFormat.Compiled do
  @moduledoc """
  Support for compiling format strings into functions.
  """

  alias TimeFormat.Strftime

  @doc """
  Defines a function named `name` converting a value to string according to `format`.

  For supported formats, see `TimeFormat.strftime/2`.
  """
  defmacro defstrftime(name, format) do
    quote bind_quoted: [name: name, format: format] do
      parsed = Strftime.parse(format)
      {head, body} = Strftime.compile(parsed)

      def unquote(name)(unquote(head)), do: unquote(body)
    end
  end

  @doc """
  Defines a private function named `name` converting a value to string according to `format`.

  For supported formats, see `TimeFormat.strftime/2`.
  """
  defmacro defstrftimep(name, format) do
    quote bind_quoted: [name: name, format: format] do
      parsed = Strftime.parse(format)
      {head, body} = Strftime.compile(parsed)

      defp unquote(name)(unquote(head)), do: unquote(body)
    end
  end
end
