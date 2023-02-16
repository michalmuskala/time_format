defmodule TimeFormat.Interpreter do
  @moduledoc false

  alias TimeFormat.Interpreter, as: F

  expressions = [
    awday: quote(do: F.awday(year, month, day) :: 3 - bytes()),
    full_wday: quote(do: F.full_wday(year, month, day)),
    amonth: quote(do: F.amonth(month) :: 3 - bytes()),
    full_month: quote(do: F.full_month(month) :: 3 - bytes()),
    zday: quote(do: F.zeroed_int2(day) :: 2 - bytes()),
    sday: quote(do: F.spaced_int2(day) :: 2 - bytes()),
    # This has dynamic size, use the `size(..)` explicitly which is handled by expand_to_simple
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

  complex = [
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

  defmodule Utils do
    @moduledoc false

    def expand(string) when is_binary(string), do: [string]

    for {name, expression} <- expressions do
      def expand(unquote(name)), do: [unquote(Macro.escape(expression))]
    end

    for {name, expression} <- complex do
      def expand(unquote(name)) do
        Enum.flat_map(unquote(expression), &expand/1)
      end
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

    def collect_bindings(quoted) do
      quoted
      |> Macro.prewalk([], fn
        {micro, _, ctx} = var, acc when is_atom(ctx) and micro in [:microsecond, :precision] ->
          value = {Macro.var(:microsecond, ctx), Macro.var(:precision, ctx)}
          {var, [{:microsecond, value} | acc]}

        {name, _, ctx} = var, acc when is_atom(name) and is_atom(ctx) ->
          {var, [{name, var} | acc]}

        other, acc ->
          {other, acc}
      end)
      |> elem(1)
      |> Enum.uniq_by(fn {name, _} -> name end)
    end
  end

  defdelegate expand(expression), to: Utils

  defdelegate collect_bindings(expression), to: Utils

  def interpret(segments, %{calendar: Calendar.ISO} = data) do
    IO.iodata_to_binary(interpret_segment(segments, data))
  end

  defp interpret_segment([], _data) do
    []
  end

  defp interpret_segment([segment | rest], data) when is_binary(segment) do
    [segment | interpret_segment(rest, data)]
  end

  for name <- Keyword.keys(expressions) ++ Keyword.keys(complex) do
    expanded = Utils.expand_to_simple(name)
    bindings = Utils.collect_bindings(expanded)

    defp interpret_segment([unquote(name) | rest], %{unquote_splicing(bindings)} = data) do
      [unquote_splicing(expanded) | interpret_segment(rest, data)]
    end
  end

  ## Formatting helpers

  @doc false
  def zeroed_int2(int) when int >= 10, do: Integer.to_string(int)
  def zeroed_int2(int), do: <<?0, Integer.to_string(int)::1-bytes>>

  @doc false
  def zeroed_int3(int) when int >= 100, do: Integer.to_string(int)
  def zeroed_int3(int) when int >= 10, do: <<?0, Integer.to_string(int)::1-bytes>>
  def zeroed_int3(int), do: <<?0, ?0, Integer.to_string(int)::1-bytes>>

  @doc false
  def zeroed_int4(int) when int >= 1000, do: Integer.to_string(int)
  def zeroed_int4(int) when int >= 100, do: <<?0, Integer.to_string(int)::3-bytes>>
  def zeroed_int4(int) when int >= 10, do: <<?0, ?0, Integer.to_string(int)::2-bytes>>
  def zeroed_int4(int), do: <<?0, ?0, ?0, Integer.to_string(int)::1-bytes>>

  @doc false
  def zeroed_int6(int) when int >= 100_000, do: Integer.to_string(int)
  def zeroed_int6(int) when int >= 10000, do: <<?0, Integer.to_string(int)::5-bytes>>
  def zeroed_int6(int) when int >= 1000, do: <<?0, ?0, Integer.to_string(int)::4-bytes>>
  def zeroed_int6(int) when int >= 100, do: <<?0, ?0, ?0, Integer.to_string(int)::3-bytes>>
  def zeroed_int6(int) when int >= 10, do: <<?0, ?0, ?0, ?0, Integer.to_string(int)::2-bytes>>
  def zeroed_int6(int), do: <<?0, ?0, ?0, ?0, ?0, Integer.to_string(int)::1-bytes>>

  @doc false
  def spaced_int2(int) when int >= 10, do: Integer.to_string(int)
  def spaced_int2(int), do: <<?\s, Integer.to_string(int)::1-bytes>>

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

end
