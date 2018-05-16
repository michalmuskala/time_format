defmodule Strftime.Format do
  @formats [
    abbr_wday: ?a,
    full_wday: ?A,
    abbr_month: ?b,
    full_month: ?B,
    preferred: ?c,
    year2: ?C,
    zeroed_day: ?d,
    us_date: ?D,
    spaced_day: ?e,
    iso_date: ?F,
    fractional: ?f,
    iso_year2: ?g,
    iso_year4: ?G,
    hour24: ?H,
    hour12: ?I,
    year_day: ?j,
    month: ?m,
    minute: ?M,
    am_pm: ?p,
    clock12: ?r,
    clock24: ?R,
    second: ?S,
    iso_time: ?T,
    iso_weekday: ?u,
    usweek_week: ?U,
    week: ?V,
    us_weekday: ?w,
    isoweek_week: ?W,
    local_date: ?x,
    local_time: ?X,
    year2: ?y,
    year4: ?Y,
    offset: ?z,
    offset_ext: ":z",
    timezone: ?Z
  ]

  defmodule Utils do
    @moduledoc false

    alias Strftime.Format

    @expressions [
      abbr_wday: quote(do: Format.abbr_wday(year, month, day) :: binary() - size(3)),
      full_wday: quote(do: Format.full_wday(year, month, day)),
      abbr_month: quote(do: Format.abbr_month(month) :: binary() - size(3)),
      full_month: quote(do: Format.full_month(month) :: binary() - size(3)),
      # preferred: ?c,
      zeroed_day: quote(do: Format.zeroed_int2(day) :: binary() - size(2)),
      # us_date: ?D,
      spaced_day: quote(do: Format.spaced_int2(day) :: binary() - size(2)),
      # iso_date: ?F,
      fractional: quote(do: Format.microsecond(microsecond)),
      iso_year2: quote(do: Format.iso_year2(year, month, day) :: binary() - size(2)),
      iso_year4: quote(do: Format.iso_year4(year, month, day) :: binary() - size(2)),
      hour24: quote(do: Format.zeroed_int2(hour) :: binary() - size(2)),
      hour12: quote(do: Format.zeroed_int2(rem(hour, 12)) :: binary() - size(2)),
      # year_day: ?j,
      month: quote(do: Format.zeroed_int2(month) :: binary() - size(2)),
      minute: quote(do: Format.zeroed_int2(minute) :: binary() - size(2)),
      am_pm: quote(do: Format.am_pm(hour, minute) :: binary() - size(2)),
      # clock12: ?r,
      # clock24: ?R,
      second: quote(do: Format.zeroed_int2(second) :: binary() - size(2)),
      # iso_time: ?T,
      # iso_weekday: ?u,
      # usweek_week: ?U,
      # week: ?V,
      # us_weekday: ?w,
      # isoweek_week: ?W,
      # local_date: ?x,
      # local_time: ?X,
      year2: quote(do: Format.zeroed_int2(rem(year, 100)) :: binary() - size(2)),
      year4: quote(do: Format.zeroed_int4(year) :: binary() - size(4)),
      offset: quote(do: Format.offset(utc_offset, std_offset) :: binary() - size(5)),
      offset_ext: quote(do: Format.offset_ext(utc_offset, std_offset) :: binary() - size(6))
      # timezone: ?Z,
    ]

    def names, do: unquote(Keyword.keys(@expressions))

    def expand(string) when is_binary(string), do: string

    for {name, expression} <- @expressions do
      def expand(unquote(name)), do: unquote(Macro.escape(expression))
    end

    def collect_bindings(quoted) do
      quoted
      |> Macro.prewalk([calendar: Calendar.ISO], fn
        {name, _, ctx} = var, acc when is_atom(name) and is_atom(ctx) ->
          {var, [{name, var} | acc]}

        other, acc ->
          {other, acc}
      end)
      |> elem(1)
      |> Enum.uniq()
    end

    def expand_to_simple(name) do
      case expand(name) do
        {:::, _, [expr, _]} -> expr
        expr -> expr
      end
    end
  end

  def parse(string) when is_binary(string), do: do_parse(string)

  defp do_parse(<<?%, ?%, rest::bits>>), do: do_parse(rest, <<?%>>)
  defp do_parse(<<?%, ?n, rest::bits>>), do: do_parse(rest, <<?\n>>)
  defp do_parse(<<?%, ?t, rest::bits>>), do: do_parse(rest, <<?\t>>)

  for {name, char} <- @formats do
    defp do_parse(<<?%, unquote(char), rest::bits>>), do: [unquote(name) | do_parse(rest, "")]
  end

  defp do_parse(<<?%, c, _::bits>>), do: throw({:do_parse, {:badformat, c}})
  defp do_parse(<<c, rest::bits>>), do: do_parse(rest, <<c>>)
  defp do_parse(<<>>), do: []

  defp do_parse(<<?%, ?%, rest::bits>>, acc), do: do_parse(rest, <<acc::binary, ?%>>)
  defp do_parse(<<?%, ?n, rest::bits>>, acc), do: do_parse(rest, <<acc::binary, ?\n>>)
  defp do_parse(<<?%, ?t, rest::bits>>, acc), do: do_parse(rest, <<acc::binary, ?\t>>)

  for {name, char} <- @formats do
    defp do_parse(<<?%, unquote(char), rest::bits>>, acc),
      do: [acc, unquote(name) | do_parse(rest)]
  end

  defp do_parse(<<?%, c, _::bits>>, _acc), do: throw({:do_parse, {:badformat, c}})
  defp do_parse(<<c, rest::bits>>, acc), do: do_parse(rest, <<acc::binary, c>>)
  defp do_parse(<<>>, acc), do: [acc]

  def compile(segments) do
    expanded = Enum.map(segments, &Utils.expand/1)
    bindings = Utils.collect_bindings(expanded)
    head = quote(do: %{unquote_splicing(bindings)})
    body = quote(do: <<unquote_splicing(expanded)>>)
    {head, body}
  end

  def interpret(segments, data) do
    IO.iodata_to_binary(interpret_segment(segments, data))
  end

  defp interpret_segment([], _data) do
    []
  end

  defp interpret_segment([segment | rest], data) when is_binary(segment) do
    [segment | interpret_segment(rest, data)]
  end

  for name <- Utils.names() do
    expanded = Utils.expand_to_simple(name)
    bindings = Utils.collect_bindings(expanded)

    defp interpret_segment([unquote(name) | rest], %{unquote_splicing(bindings)} = data) do
      [unquote(expanded) | interpret_segment(rest, data)]
    end
  end

  ## Formatting helpers

  @doc false
  def zeroed_int2(int) when int < 10, do: <<?0, Integer.to_string(int)::binary-size(1)>>
  def zeroed_int2(int), do: Integer.to_string(int)

  @doc false
  def zeroed_int4(int) when int < 10, do: <<?0, ?0, ?0, Integer.to_string(int)::binary-size(1)>>
  def zeroed_int4(int) when int < 100, do: <<?0, ?0, Integer.to_string(int)::binary-size(2)>>
  def zeroed_int4(int) when int < 1000, do: <<?0, Integer.to_string(int)::binary-size(3)>>
  def zeroed_int4(int), do: Integer.to_string(int)

  @doc false
  def spaced_int2(int) when int < 10, do: <<?\s, Integer.to_string(int)::binary-size(1)>>
  def spaced_int2(int), do: Integer.to_string(int)

  @doc false
  def offset(utc, std) do
    total = utc + std

    if total < 0 do
      total = -total
      minute = total |> rem(3600) |> div(60)
      hour = div(total, 3600)
      <<?-, zeroed_int2(hour)::binary-size(2), zeroed_int2(minute)::binary-size(2)>>
    else
      minute = total |> rem(3600) |> div(60)
      hour = div(total, 3600)
      <<?+, zeroed_int2(hour)::binary-size(2), zeroed_int2(minute)::binary-size(2)>>
    end
  end

  @doc false
  def offset_ext(utc, std) do
    total = utc + std

    if total < 0 do
      total = -total
      minute = total |> rem(3600) |> div(60)
      hour = div(total, 3600)
      <<?-, zeroed_int2(hour)::binary-size(2), ":", zeroed_int2(minute)::binary-size(2)>>
    else
      minute = total |> rem(3600) |> div(60)
      hour = div(total, 3600)
      <<?+, zeroed_int2(hour)::binary-size(2), ":", zeroed_int2(minute)::binary-size(2)>>
    end
  end

  @doc false
  def abbr_wday(year, month, day) do
    wday_to_abbr(wday(year, month, day))
  end

  @doc false
  def full_wday(year, month, day) do
    wday_to_full(wday(year, month, day))
  end

  @doc false
  def iso_year2(year, month, day) do
    # TODO: port implementation
    {year, _} = :calendar.iso_week_number({year, month, day})
    zeroed_int2(rem(year, 100))
  end

  @doc false
  def iso_year4(year, month, day) do
    {year, _} = :calendar.iso_week_number({year, month, day})
    zeroed_int4(year)
  end

  @compile {:inline, wday: 3, wday_to_abbr: 1, wday_to_full: 1}

  defp wday(year, month, day) do
    Integer.mod(Calendar.ISO.date_to_iso_days(year, month, day) + 5, 7)
  end

  for {day, idx} <- Enum.with_index(~w[Mon Tue Wed Thu Fri Sat Sun]) do
    defp wday_to_abbr(unquote(idx)), do: unquote(day)
  end

  for {day, idx} <- Enum.with_index(~w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]) do
    defp wday_to_full(unquote(idx)), do: unquote(day)
  end

  @doc false
  for {month, idx} <- Enum.with_index(~w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]) do
    def abbr_month(unquote(idx + 1)), do: unquote(month)
  end

  @doc false
  @months ~w[January February March April May June July August September October November December]
  for {month, idx} <- Enum.with_index(@months) do
    def full_month(unquote(idx + 1)), do: unquote(month)
  end

  @doc false
  def microsecond({value, precision}) do
  end

  @doc false
  def am_pm(hour, minute) do
    if hour < 12 or (hour == 12 and minute == 0), do: "AM", else: "PM"
  end

  # %a	Abbreviated weekday name *	Thu
  # %A	Full weekday name * 	Thursday
  # %b	Abbreviated month name *	Aug
  # %B	Full month name *	August
  # %c	Date and time representation *	Thu Aug 23 14:55:02 2001
  # %C	Year divided by 100 and truncated to integer (00-99)	20
  # %d	Day of the month, zero-padded (01-31)	23
  # %D	Short MM/DD/YY date, equivalent to %m/%d/%y	08/23/01
  # %e	Day of the month, space-padded ( 1-31)	23
  # %F	Short YYYY-MM-DD date, equivalent to %Y-%m-%d	2001-08-23
  # %g	Week-based year, last two digits (00-99)	01
  # %G	Week-based year	2001
  # %h	Abbreviated month name * (same as %b)	Aug
  # %H	Hour in 24h format (00-23)	14
  # %I	Hour in 12h format (01-12)	02
  # %j	Day of the year (001-366)	235
  # %m	Month as a decimal number (01-12)	08
  # %M	Minute (00-59)	55
  # %n	New-line character ('\n')
  # %p	AM or PM designation	PM
  # %r	12-hour clock time *	02:55:02 pm
  # %R	24-hour HH:MM time, equivalent to %H:%M	14:55
  # %S	Second (00-61)	02
  # %t	Horizontal-tab character ('\t')
  # %T	ISO 8601 time format (HH:MM:SS), equivalent to %H:%M:%S	14:55:02
  # %u	ISO 8601 weekday as number with Monday as 1 (1-7)	4
  # %U	Week number with the first Sunday as the first day of week one (00-53)	33
  # %V	ISO 8601 week number (01-53)	34
  # %w	Weekday as a decimal number with Sunday as 0 (0-6)	4
  # %W	Week number with the first Monday as the first day of week one (00-53)	34
  # %x	Date representation *	08/23/01
  # %X	Time representation *	14:55:02
  # %y	Year, last two digits (00-99)	01
  # %Y	Year	2001
  # %z	ISO 8601 offset from UTC in timezone (1 minute=1, 1 hour=100)
  # If timezone cannot be determined, no characters	+100
  # %Z	Timezone name or abbreviation *
  # If timezone cannot be determined, no characters	CDT
  # %%	A % sign	%
end
