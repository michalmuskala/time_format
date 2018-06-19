defmodule TimeFormatTest do
  use ExUnit.Case
  doctest TimeFormat

  describe "strftime/2" do
    import TimeFormat, only: [strftime: 2]
    @d ~D[2018-06-01]
    @n ~N[2018-06-01 15:45:00]
    @t ~T[15:45:00]
    @dt DateTime.from_naive!(@n, "Etc/UTC")

    test "%a is short weekday", do: assert(strftime("%a", @d) == "Fri")
    test "%A is full weekday", do: assert(strftime("%A", @d) == "Friday")
    test "%b is short month", do: assert(strftime("%b", @d) == "Jun")
    test "%B is full month", do: assert(strftime("%B", @d) == "June")

    test "%c is preferred date and time" do
      assert(strftime("%c", @n) == "Fri Jun  1 15:45:00 2018")
    end

    test "%C is year in century", do: assert(strftime("%C", @d) == "18")
    test "%d is day of month, zero padded", do: assert(strftime("%d", @d) == "01")

    test "%D is equivalent to %m/%d/%y." do
      assert(strftime("%D", @d) == strftime("%m/%d/%y", @d))
    end

    test "%e is day of month, space padded", do: assert(strftime("%e", @d) == " 1")

    test "%F is equivalent to %Y-%m-%d (the ISO 8601 date format)" do
      assert(strftime("%F", @d) == strftime("%Y-%m-%d", @d))
    end

    test "%G is the ISO 8601 week-based year" do
      assert(strftime("%G", @d) == "2018")
      assert(strftime("%G", ~D[2018-12-31]) == "2019")
    end

    test "%g is the ISO 8601 week-based year with two digits" do
      assert(strftime("%g", @d) == "18")
      assert(strftime("%g", ~D[2018-12-31]) == "19")
    end

    test "%h is %b i.e short month", do: assert(strftime("%h", @d) == "Jun")
    test "%H is hour in range 00-24", do: assert(strftime("%H", @t) == "15")
    test "%I is hour in range 01-12", do: assert(strftime("%I", @t) == "03")

    test "%j is the day of the year" do
      assert(strftime("%j", @d) == "152")
      assert(strftime("%j", ~D[2018-01-01]) == "001")
      assert(strftime("%j", ~D[2018-12-31]) == "365")
    end

    test "%k is hour in range 0-24, space padded", do: assert(strftime("%k", @t) == "15")
    test "%l is hour in range 1-12, space padded", do: assert(strftime("%l", @t) == " 3")

    test "%m is month as number", do: assert(strftime("%m", @d) == "06")
    test "%M is minute in range 00-59", do: assert(strftime("%M", @t) == "45")
    test "%n is a newline character", do: assert(strftime("%n", @d) == "\n")
    test "%p is AM or PM", do: assert(strftime("%p", @t) == "PM")
    test "%r is 12-hour clock time", do: assert(strftime("%r", @t) == "03:45:00 PM")
    test "%R is 24-hour HH:MM time", do: assert(strftime("%R", @t) == "15:45")

    test "%S is second in range 00-61" do
      assert(strftime("%S", @t) == "00")
      assert(strftime("%S", ~T[23:59:60]) == "60")
    end

    test "%t is a tab character", do: assert(strftime("%t", @t), "\t")

    test "%T is ISO 8601 time format, equivalent to %H:%M:%S" do
      assert(strftime("%T", @t) == strftime("%H:%M:%S", @t))
      assert(strftime("%T", @t) == "15:45:00")
    end

    test "%u is ISO 8601 weekday in range 1-7", do: assert(strftime("%u", @d) == "5")

    test "%U is week number where first Sunday starts week one" do
      assert(strftime("%U", @d) == "21")
      assert(strftime("%U", ~D[2015-12-31]) == "52")
      assert(strftime("%U", ~D[2017-01-01]) == "01")
      assert(strftime("%U", ~D[2018-01-01]) == "00")
      assert(strftime("%U", ~D[2018-12-31]) == "52")
    end

    test "%v is equivalent to %e-%b-%Y" do
      assert(strftime("%v", @d) == strftime("%v", @d))
      assert(strftime("%v", @d) == " 1-Jun-2018")
    end

    test "%V is ISO 8601 week number" do
      assert(strftime("%V", @d) == "22")
      assert(strftime("%V", ~D[2015-12-31]) == "53")
      assert(strftime("%V", ~D[2017-01-01]) == "52")
      assert(strftime("%V", ~D[2018-01-01]) == "01")
      assert(strftime("%V", ~D[2018-12-31]) == "01")
    end

    test "%w is weekday in range 0-6 starting Sunday", do: assert(strftime("%w", @d) == "5")

    test "%W is week number where first Monday starts week one" do
      assert(strftime("%W", @d) == "22")
      assert(strftime("%W", ~D[2015-12-31]) == "52")
      assert(strftime("%W", ~D[2017-01-01]) == "00")
      assert(strftime("%W", ~D[2018-01-01]) == "01")
      assert(strftime("%W", ~D[2018-12-31]) == "53")
    end

    test "%x is date equivalent to %m/%d/%y" do
      assert(strftime("%x", @d) == strftime("%m/%d/%y", @d))
      assert(strftime("%x", @d) == "06/01/18")
    end

    test "%X is time equivalent to %H:%M:%S" do
      assert(strftime("%X", @t) == strftime("%H:%M:%S", @t))
      assert(strftime("%X", @t) == "15:45:00")
    end

    test "%y is last two digits of year", do: assert(strftime("%y", @d) == "18")
    test "%Y is full year", do: assert(strftime("%Y", @d) == "2018")

    test "%z is the ISO 8601 offset from UTC", do: assert(strftime("%z", @dt) == "+0000")

    test "%Z is the time zone or abbreviation" do
      assert(strftime("%Z", @dt) == "UTC")
    end

    test "%+ is a full date time format, including time zone" do
      assert(strftime("%+", @dt) == "Fri Jun  1 15:45:00 UTC 2018")
    end

    test "%% is a % character", do: assert(strftime("%%", @d) == "%")
  end
end
