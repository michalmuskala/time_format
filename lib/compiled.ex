defmodule TimeFormat.Compiled do
  alias TimeFormat.Strftime

  defmacro defstrftime(name, format) do
    quote bind_quoted: [name: name, format: format] do
      parsed = Strftime.parse(format)
      {head, body} = Strftime.compile(parsed)

      def unquote(name)(unquote(head)), do: unquote(body)
    end
  end

  defmacro defstrftimep(name, format) do
    quote bind_quoted: [name: name, format: format] do
      parsed = Strftime.parse(format)
      {head, body} = Strftime.compile(parsed)

      defp unquote(name)(unquote(head)), do: unquote(body)
    end
  end
end
