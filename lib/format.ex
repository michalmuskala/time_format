defmodule Strftime.Format do
  @formats [
    awday: ?a,
    full_wday: ?A,
    amonth: ?b,
    full_month: ?B,
    preferred: ?c,
    year2: ?C,
    zday: ?d,
    sday: ?e,
    us_date: ?D,
    iso_date: ?F,
    vms_date: ?v,
    fractional: ?f,
    iso_year2: ?g,
    iso_year4: ?G,
    hour24: ?H,
    amonth: ?h,
    spaced_hour24: ?k,
    hour12: ?I,
    spaced_hour12: ?l,
    year_day: ?j,
    zmonth: ?m,
    minute: ?M,
    am_pm: ?p,
    am_pm_lower: ?P,
    clock12: ?r,
    clock24: ?R,
    second: ?S,
    iso_time: ?T,
    iso_weekday: ?u,
    week_sun: ?U,
    iso_week: ?V,
    weekday_sun: ?w,
    week_mon: ?W,
    local_date: ?x,
    local_time: ?X,
    year2: ?y,
    year4: ?Y,
    offset: ?z,
    offset_ext: ":z",
    timezone: ?Z,
    full: ?+
  ]

  defmodule Utils do
    @moduledoc false

    alias Strftime.Format, as: F

    @expressions [
      awday: quote(do: F.awday(year, month, day) :: 3 - bytes()),
      full_wday: quote(do: F.full_wday(year, month, day)),
      amonth: quote(do: F.amonth(month) :: 3 - bytes()),
      full_month: quote(do: F.full_month(month) :: 3 - bytes()),
      zday: quote(do: F.zeroed_int2(day) :: 2 - bytes()),
      sday: quote(do: F.spaced_int2(day) :: 2 - bytes()),
      fractional: quote(do: F.zeroed_int6(microsecond) :: size(precision) - bytes()),
      iso_year2: quote(do: F.iso_year2(year, month, day) :: 2 - bytes()),
      iso_year4: quote(do: F.iso_year4(year, month, day) :: 2 - bytes()),
      hour24: quote(do: F.zeroed_int2(hour) :: 2 - bytes()),
      spaced_hour24: quote(do: F.spaced_int2(hour) :: 2 - bytes()),
      hour12: quote(do: F.zeroed_int2(rem(hour, 12)) :: 2 - bytes()),
      spaced_hour12: quote(do: F.spaced_int2(rem(hour, 12)) :: 2 - bytes()),
      year_day: quote(do: F.year_day(year, month, day) :: 3 - bytes()),
      zmonth: quote(do: F.zeroed_int2(month) :: 2 - bytes()),
      minute: quote(do: F.zeroed_int2(minute) :: 2 - bytes()),
      am_pm: quote(do: F.am_pm(hour, minute) :: 2 - bytes()),
      am_pm_lower: quote(do: F.am_pm_lower(hour, minute) :: 2 - bytes()),
      second: quote(do: F.zeroed_int2(second) :: 2 - bytes()),
      iso_weekday: quote(do: F.iso_wday(year, month, day) :: 1 - bytes()),
      week_sun: quote(do: F.week_sun(year, month, day) :: 2 - bytes()),
      iso_week: quote(do: F.iso_week(year, month, day) :: 2 - bytes()),
      weekday_sun: quote(do: F.wday_sun(year, month, day) :: 1 - bytes()),
      week_mon: quote(do: F.week_mon(year, month, day) :: 2 - bytes()),
      year2: quote(do: F.zeroed_int2(rem(year, 100)) :: 2 - bytes()),
      year4: quote(do: F.zeroed_int4(year) :: 4 - bytes()),
      offset: quote(do: F.offset(utc_offset, std_offset) :: 5 - bytes()),
      offset_ext: quote(do: F.offset_ext(utc_offset, std_offset) :: 6 - bytes()),
      timezone: quote(do: F.timezone(zone_abbr) :: 3 - bytes())
    ]

    @complex [
      us_date: [:zmonth, "/", :zday, "/", :year2],
      iso_date: [:year4, "-", :zmonth, "-", :zday],
      iso_time: [:hour24, ":", :minute, ":", :second],
      clock12: [:hour12, ":", :minute, ":", :second, " ", :am_pm],
      clock24: [:hour24, ":", :minute],
      preferred: [:awday, " ", :amonth, " ", :sday, " ", :iso_time, " ", :year4],
      vms_date: [:sday, "-", :amonth, "-", :year4],
      local_date: [:zmonth, "/", :zday, "/", :year2],
      local_time: [:hour24, ":", :minute, ":", :second],
      full: [:awday, " ", :amonth, " ", :sday, " ", :iso_time, " ", :timezone, " ", :year4]
    ]

    def names, do: unquote(Keyword.keys(@expressions) ++ Keyword.keys(@complex))

    def expand(string) when is_binary(string), do: [string]

    for {name, expression} <- @expressions do
      def expand(unquote(name)), do: [unquote(Macro.escape(expression))]
    end

    for {name, expression} <- @complex do
      def expand(unquote(name)) do
        Enum.flat_map(unquote(expression), &expand/1)
      end
    end

    def collect_bindings(quoted) do
      quoted
      |> Macro.prewalk([calendar: Calendar.ISO], fn
        {micro, _, ctx} = var, acc when is_atom(ctx) and micro in [:microsecond, :precision] ->
          value = quote(do: {microsecond, precision})
          {var, [{:microsecond, value} | acc]}

        {name, _, ctx} = var, acc when is_atom(name) and is_atom(ctx) ->
          {var, [{name, var} | acc]}

        other, acc ->
          {other, acc}
      end)
      |> elem(1)
      |> Enum.uniq()
    end

    def expand_to_simple(name) do
      Enum.map(expand(name), fn
        {:::, _, [expr, {:-, _, [{:size, _, [size]}, _]}]} ->
          quote(do: binary_part(unquote(expr), 0, unquote(size)))

        {:::, _, [expr, _]} ->
          expr

        expr ->
          expr
      end)
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
    expanded = Enum.flat_map(segments, &Utils.expand/1)
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
      [unquote_splicing(expanded) | interpret_segment(rest, data)]
    end
  end

  ## Formatting helpers

  @doc false
  def zeroed_int2(int) when int < 10, do: <<?0, Integer.to_string(int)::1-bytes>>
  def zeroed_int2(int), do: Integer.to_string(int)

  @doc false
  def zeroed_int3(int) when int < 10, do: <<?0, ?0, Integer.to_string(int)::1-bytes>>
  def zeroed_int3(int) when int < 100, do: <<?0, Integer.to_string(int)::1-bytes>>
  def zeroed_int3(int), do: Integer.to_string(int)

  @doc false
  def zeroed_int4(int) when int < 10, do: <<?0, ?0, ?0, Integer.to_string(int)::1-bytes>>
  def zeroed_int4(int) when int < 100, do: <<?0, ?0, Integer.to_string(int)::2-bytes>>
  def zeroed_int4(int) when int < 1000, do: <<?0, Integer.to_string(int)::3-bytes>>
  def zeroed_int4(int), do: Integer.to_string(int)

  @doc false
  def zeroed_int6(int) when int < 10, do: <<?0, ?0, ?0, ?0, ?0, Integer.to_string(int)::1-bytes>>
  def zeroed_int6(int) when int < 100, do: <<?0, ?0, ?0, ?0, Integer.to_string(int)::2-bytes>>
  def zeroed_int6(int) when int < 1000, do: <<?0, ?0, ?0, Integer.to_string(int)::3-bytes>>
  def zeroed_int6(int) when int < 10000, do: <<?0, ?0, Integer.to_string(int)::4-bytes>>
  def zeroed_int6(int) when int < 100_000, do: <<?0, Integer.to_string(int)::5-bytes>>
  def zeroed_int6(int), do: Integer.to_string(int)

  @doc false
  def spaced_int2(int) when int < 10, do: <<?\s, Integer.to_string(int)::1-bytes>>
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
  def awday(year, month, day) do
    wday_to_abbr(wday(year, month, day))
  end

  @doc false
  def full_wday(year, month, day) do
    wday_to_full(wday(year, month, day))
  end

  @doc false
  def iso_wday(year, month, day) do
    Integer.to_string(Calendar.ISO.day_of_week(year, month, day))
  end

  @doc false
  def wday_sun(year, month, day) do
    case Calendar.ISO.day_of_week(year, month, day) do
      7 -> "0"
      n -> Integer.to_string(n)
    end
  end

  @doc false
  def iso_week(year, month, day) do
    {_, week} = :calendar.iso_week_number({year, month, day})
    zeroed_int2(week)
  end

  @doc false
  def week_sun(year, month, day) do
    week_number(year, month, day, &day_of_first_sunday/1)
    |> zeroed_int2()
  end

  @doc false
  def week_mon(year, month, day) do
    week_number(year, month, day, &day_of_first_monday/1)
    |> zeroed_int2()
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

  @doc false
  def year_day(year, month, day) do
    zeroed_int3(year_day_number(year, month, day))
  end

  @doc false
  def timezone(zone_abbr), do: zone_abbr

  @compile {:inline, wday: 3, wday_to_abbr: 1, wday_to_full: 1}

  defp wday(year, month, day) do
    Integer.mod(:calendar.date_to_gregorian_days(year, month, day) + 5, 7)
  end

  defp year_day_number(year, month, day) do
    1 + :calendar.date_to_gregorian_days(year, month, day) -
      :calendar.date_to_gregorian_days(year, 1, 1)
  end

  defp week_number(year, month, day, day_of_week_one_fun) do
    days_from_week_one = year_day_number(year, month, day) - day_of_week_one_fun.(year)

    case days_from_week_one do
      days when days < 0 -> 0
      days -> div(days, 7) + 1
    end
  end

  defp day_of_first_monday(year) do
    first_wday = Calendar.ISO.day_of_week(year, 1, 1)
    Integer.mod(1 - first_wday, 7) + 1
  end

  defp day_of_first_sunday(year) do
    7 - Calendar.ISO.day_of_week(year, 1, 1) + 1
  end

  for {day, idx} <- Enum.with_index(~w[Mon Tue Wed Thu Fri Sat Sun]) do
    defp wday_to_abbr(unquote(idx)), do: unquote(day)
  end

  for {day, idx} <- Enum.with_index(~w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]) do
    defp wday_to_full(unquote(idx)), do: unquote(day)
  end

  @doc false
  for {month, idx} <- Enum.with_index(~w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]) do
    def amonth(unquote(idx + 1)), do: unquote(month)
  end

  @doc false
  @months ~w[January February March April May June July August September October November December]
  for {month, idx} <- Enum.with_index(@months) do
    def full_month(unquote(idx + 1)), do: unquote(month)
  end

  @doc false
  def am_pm(hour, minute) do
    if hour < 12 or (hour == 12 and minute == 0), do: "AM", else: "PM"
  end

  @doc false
  def am_pm_lower(hour, minute) do
    if hour < 12 or (hour == 12 and minute == 0), do: "am", else: "pm"
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
