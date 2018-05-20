defmodule StrftimeTest do
  use ExUnit.Case
  doctest Strftime

  describe "interpret/2" do
    import Strftime, only: [interpret: 2]
    @d ~D[2018-06-01]
    @n ~N[2018-06-01 15:45:00]
    @t ~T[15:45:00]

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
  end
end
