defmodule Strftime do
  alias Strftime.Format

  defmacro defformat(name, format) do
    parsed = Format.parse(format)
    {head, body} = Format.compile(parsed)

    quote do
      def unquote(name)(unquote(head)), do: unquote(body)
    end
  end

  defmacro defformatp(name, format) do
    parsed = Format.parse(format)
    {head, body} = Format.compile(parsed)

    quote do
      defp unquote(name)(unquote(head)), do: unquote(body)
    end
  end

  def interpret(format, data) do
    parsed = Format.parse(format)
    Format.interpret(parsed, data)
  end

  @common_formats [
    iso_date: "%Y-%m-%d",
    iso_time: "%H:%M:%S",
    iso_datetime: "%Y-%m-%dT%H:%M:%S%:z",
    iso_naive_datetime: "%Y-%m-%dT%H:%M:%S"
    # rfc822: "%a, %d %b %y %H:%M:%S %z",
    # rfc2822: "%a, %d %b %Y %H:%M:%S %z",
    # httpdate: "%a, %d %b %Y %H:%M:%S %Z",
  ]

  for {name, format} <- @common_formats do
    parsed = Format.parse(format)
    {head, body} = Format.compile(parsed)
    def unquote(name)(unquote(head)), do: unquote(body)
  end
end
