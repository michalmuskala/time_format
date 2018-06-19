defmodule TimeFormat.Strftime do
  @moduledoc false

  alias TimeFormat.Interpreter

  @formats [
    awday: ?a,
    full_wday: ?A,
    amonth: ?b,
    full_month: ?B,
    preferred: ?c,
    year2: ?C,
    zday: ?d,
    us_date: ?D,
    sday: ?e,
    fractional: ?f,
    iso_date: ?F,
    iso_year2: ?g,
    iso_year4: ?G,
    amonth: ?h,
    hour24: ?H,
    hour12: ?I,
    year_day: ?j,
    spaced_hour24: ?k,
    spaced_hour12: ?l,
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
    vms_date: ?v,
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
    expanded = Enum.flat_map(segments, &Interpreter.expand/1)
    bindings = Interpreter.collect_bindings(expanded)
    head = quote(do: %{unquote_splicing(bindings), calendar: unquote(Calendar.ISO)})
    body = quote(do: <<unquote_splicing(expanded)>>)
    {head, body}
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
