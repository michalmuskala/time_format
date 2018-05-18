defmodule Strftime.FormatTest do
  use ExUnit.Case, async: true

  alias Strftime.Format

  describe "parse/1" do
    test "simple format" do
      assert Format.parse("abc") == ["abc"]
    end

    test "iso date" do
      assert Format.parse("%Y-%m-%d") == [:year4, "-", :zmonth, "-", :zday]
    end
  end

  describe "compile/1" do
    test "simple format" do
      assert Format.compile(["abc"]) ==
               {{:%{}, [], [calendar: Calendar.ISO]}, {:<<>>, [], ["abc"]}}
    end

    test "iso date" do
      format = [:year4, "-", :zmonth, "-", :zday]
      {head, body} = Format.compile(format)

      assert Macro.to_string(head) ==
               "%{day: day, month: month, year: year, calendar: Calendar.ISO}"

      assert Macro.to_string(body) == """
             <<F.zeroed_int4(year)::4-bytes(), \"-\", F.zeroed_int2(month)::2-bytes(), \"-\", F.zeroed_int2(day)::2-bytes()>>\
             """
    end

    test "fractional" do
      format = [:fractional]
      {head, body} = Format.compile(format)

      assert Macro.to_string(head) ==
               "%{microsecond: {microsecond, precision}, calendar: Calendar.ISO}"

      assert Macro.to_string(body) == """
             <<F.zeroed_int6(microsecond)::size(precision)-bytes()>>\
             """
    end
  end
end
