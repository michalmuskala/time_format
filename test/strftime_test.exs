defmodule StrftimeTest do
  use ExUnit.Case
  doctest Strftime

  describe "interpret/2" do
    import Strftime, only: [interpret: 2]
    @d ~D[2018-06-01]
    @n ~N[2018-06-01 15:45:00]
    @t ~T[15:45:00]
    @dt DateTime.from_naive(@n, "Etc/UTC") |> elem(1)

    test "%a is short weekday", do: assert(interpret("%a", @d) == "Fri")
    test "%A is full weekday", do: assert(interpret("%A", @d) == "Friday")
    test "%b is short month", do: assert(interpret("%b", @d) == "Jun")
    test "%B is full month", do: assert(interpret("%B", @d) == "June")

    test "%c is preferred date and time" do
      assert(interpret("%c", @n) == "Fri Jun  1 15:45:00 2018")
    end

    test "%C is year in century", do: assert(interpret("%C", @d) == "18")
    test "%d is day of month, zero padded", do: assert(interpret("%d", @d) == "01")

    test "%D is equivalent to %m/%d/%y." do
      assert(interpret("%D", @d) == interpret("%m/%d/%y", @d))
    end

    test "%e is day of month, space padded", do: assert(interpret("%e", @d) == " 1")

    test "%F is equivalent to %Y-%m-%d (the ISO 8601 date format)" do
      assert(interpret("%F", @d) == interpret("%Y-%m-%d", @d))
    end

    test "%G is the ISO 8601 week-based year" do
      assert(interpret("%G", @d) == "2018")
      assert(interpret("%G", ~D[2018-12-31]) == "2019")
    end

    test "%g is the ISO 8601 week-based year with two digits" do
      assert(interpret("%g", @d) == "18")
      assert(interpret("%g", ~D[2018-12-31]) == "19")
    end

    test "%h is %b i.e short month", do: assert(interpret("%h", @d) == "Jun")
    test "%H is hour in range 00-24", do: assert(interpret("%H", @t) == "15")
    test "%I is hour in range 01-12", do: assert(interpret("%I", @t) == "03")

    test "%j is the day of the year" do
      assert(interpret("%j", @d) == "152")
      assert(interpret("%j", ~D[2018-01-01]) == "001")
      assert(interpret("%j", ~D[2018-12-31]) == "365")
    end

    test "%k is hour in range 0-24, space padded", do: assert(interpret("%k", @t) == "15")
    test "%l is hour in range 1-12, space padded", do: assert(interpret("%l", @t) == " 3")

    test "%m is month as number", do: assert(interpret("%m", @d) == "06")
    test "%M is minute in range 00-59", do: assert(interpret("%M", @t) == "45")
    test "%n is a newline character", do: assert(interpret("%n", @d) == "\n")
    test "%p is AM or PM", do: assert(interpret("%p", @t) == "PM")
    test "%r is 12-hour clock time", do: assert(interpret("%r", @t) == "03:45:00 PM")
    test "%R is 24-hour HH:MM time", do: assert(interpret("%R", @t) == "15:45")

    test "%S is second in range 00-61" do
      assert(interpret("%S", @t) == "00")
      assert(interpret("%S", ~T[23:59:60]) == "60")
    end

    test "%t is a tab character", do: assert(interpret("%t", @t), "\t")

    test "%T is ISO 8601 time format, equivalent to %H:%M:%S" do
      assert(interpret("%T", @t) == interpret("%H:%M:%S", @t))
      assert(interpret("%T", @t) == "15:45:00")
    end

    test "%u is ISO 8601 weekday in range 1-7", do: assert(interpret("%u", @d) == "5")

    test "%U is week number where first Sunday starts week one" do
      assert(interpret("%U", @d) == "21")
      assert(interpret("%U", ~D[2015-12-31]) == "52")
      assert(interpret("%U", ~D[2017-01-01]) == "01")
      assert(interpret("%U", ~D[2018-01-01]) == "00")
      assert(interpret("%U", ~D[2018-12-31]) == "52")
    end

    test "%v is equivalent to %e-%b-%Y" do
      assert(interpret("%v", @d) == interpret("%v", @d))
      assert(interpret("%v", @d) == " 1-Jun-2018")
    end

    test "%V is ISO 8601 week number" do
      assert(interpret("%V", @d) == "22")
      assert(interpret("%V", ~D[2015-12-31]) == "53")
      assert(interpret("%V", ~D[2017-01-01]) == "52")
      assert(interpret("%V", ~D[2018-01-01]) == "01")
      assert(interpret("%V", ~D[2018-12-31]) == "01")
    end

    test "%w is weekday in range 0-6 starting Sunday", do: assert(interpret("%w", @d) == "5")

    test "%W is week number where first Monday starts week one" do
      assert(interpret("%W", @d) == "22")
      assert(interpret("%W", ~D[2015-12-31]) == "52")
      assert(interpret("%W", ~D[2017-01-01]) == "00")
      assert(interpret("%W", ~D[2018-01-01]) == "01")
      assert(interpret("%W", ~D[2018-12-31]) == "53")
    end

    test "%x is date equivalent to %m/%d/%y" do
      assert(interpret("%x", @d) == interpret("%m/%d/%y", @d))
      assert(interpret("%x", @d) == "06/01/18")
    end

    test "%X is time equivalent to %H:%M:%S" do
      assert(interpret("%X", @t) == interpret("%H:%M:%S", @t))
      assert(interpret("%X", @t) == "15:45:00")
    end

    test "%y is last two digits of year", do: assert(interpret("%y", @d) == "18")
    test "%Y is full year", do: assert(interpret("%Y", @d) == "2018")

    test "%z is the ISO 8601 offset from UTC", do: assert(interpret("%z", @dt) == "+0000")

    test "%Z is the time zone or abbreviation" do
      assert(interpret("%Z", @dt) == "UTC")
    end

    test "%+ is a full date time format, including time zone" do
      assert(interpret("%+", @dt) == "Fri Jun  1 15:45:00 UTC 2018")
    end

    test "%% is a % character", do: assert(interpret("%%", @d) == "%")
  end
end
