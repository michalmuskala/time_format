# TimeFormat

Library for formatting Elixir calendar structs using the classic `strftime` syntax.

This library is in development.

## Usage

Because most of the time the actual format string is entirely static, the library optimises
for that case providing two modes of operation:

  * interpretation - using the `TimeFormat.interpret` function, behaving like a classical
    TimeFormat interface accepting a format string and data to format.

    ```elixir
    iex> TimeFormat.interpret("%m-%d-%Y", ~D[2017-05-21])
    "05-21-2017"
    ```

  * compilation - using the `TimeFormat.Compiled.defstrftime` and
    `TimeFormat.Compiled.defstrftimep` macros offering to compile a particular format
    into a formatting function accepting just data for best performance.

    ```elixir
    defmodule MyFormat do
      import TimeFormat.Compiled
      defstrftime :us_date, "%m-%d-%Y"
    end

    iex> MyFormat.us_date(~D[2017-05-21])
    "05-21-2017"
    ```

## TODO

* [ ] - complete all the formats in `TimeFormat.Format.Utils`
* [ ] - consider what to do with modifiers in formats like "upcase" - do we really need it?
* [ ] - add support for "mnemonic" formatters from timex: https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Default.html
* [ ] - explore replacing timex and calendar formatting with this library

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `time_format` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:time_format, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/time_format](https://hexdocs.pm/time_format).
