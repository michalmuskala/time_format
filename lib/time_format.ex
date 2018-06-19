defmodule TimeFormat do
  @moduledoc """
  Functions for formatting `Date`, `Time`, `DateTime` and `NaiveDateTime` structs.

  All functions support only values in the `Calendar.ISO` calendar.
  """

  import TimeFormat.Compiled

  @doc """
  Formats `data` according to the `format` string.

  ## Format string

    TODO

  """
  def strftime(format, data) do
    parsed = TimeFormat.Strftime.parse(format)
    TimeFormat.Interpreter.interpret(parsed, data)
  end

  @common_formats [
    iso8601_date: {
      "%Y-%m-%d",
      """
      Formats value as an iso8601 date string.

      Accepts `Date`, `DateTime`, and `NaiveDateTime` structs.
      """
    },
    iso8601_time: {
      "%H:%M:%S",
      """
      Formats value as an iso8601 time string.

      Accepts `Time`, `DateTime`, and `NaiveDateTime` structs.
      """
    },
    iso8601_datetime: {
      "%Y-%m-%dT%H:%M:%S%:z",
      """
      Formats value as an iso8601 datetime string with offset.

      Accepts `DateTime` structs.
      """
    },
    iso8601_naive_datetime: {
      "%Y-%m-%dT%H:%M:%S",
      """
      Formats value as an is8601 datetime string without an offset.

      Accepts `NaiveDateTime` and `DateTime` structs.
      """
    },
    rfc822: {
      "%a, %d %b %y %H:%M:%S %z",
      """
      Formats value as an rfc822 string.

      Accepts `DateTime` structs.
      """
    },
    rfc2822: {
      "%a, %d %b %Y %H:%M:%S %z",
      """
      Formats value as an rfc2822 string.

      Accepts `DateTime` structs.
      """
    },
    httpdate: {
      "%a, %d %b %Y %H:%M:%S %Z",
      """
      Formats values as an httpdate string.

      Accepts `DateTime` structs.
      """
    }
  ]

  for {name, {format, doc}} <- @common_formats do
    @doc doc
    defstrftime(name, format)
  end
end
