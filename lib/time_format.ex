defmodule TimeFormat do
  import TimeFormat.Compiled

  def strftime(format, data) do
    parsed = TimeFormat.Strftime.parse(format)
    TimeFormat.Strftime.interpret(parsed, data)
  end

  @common_formats [
    iso_date: "%Y-%m-%d",
    iso_time: "%H:%M:%S",
    iso_datetime: "%Y-%m-%dT%H:%M:%S%:z",
    iso_naive_datetime: "%Y-%m-%dT%H:%M:%S",
    rfc822: "%a, %d %b %y %H:%M:%S %z",
    rfc2822: "%a, %d %b %Y %H:%M:%S %z",
    httpdate: "%a, %d %b %Y %H:%M:%S %Z"
  ]

  for {name, format} <- @common_formats do
    defstrftime(name, format)
  end
end
