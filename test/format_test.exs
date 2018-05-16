defmodule Strftime.FormatTest do
  use ExUnit.Case, async: true

  alias Strftime.Format

  describe "parse/1" do
    test "simple format" do
      assert Format.parse("abc") == ["abc"]
    end

    test "iso date" do
      assert Format.parse("%Y-%m-%d") == [:year4, "-", :month, "-", :zeroed_day]
    end
  end

  describe "compile/1" do
    test "simple format" do
      assert Format.compile(["abc"]) == {{:%{}, [], []}, {:<<>>, [], ["abc"]}}
    end

    test "iso date" do
      format = [:year4, "-", :month, "-", :zeroed_day]
      {head, body} = Format.compile(format)
      assert Macro.to_string(head) == "%{day: day, month: month, year: year}"

      assert Macro.to_string(body) == """
             <<Strftime.Format.zeroed_int4(year)::binary()-size(4), \"-\", \
             Strftime.Format.zeroed_int(month)::binary()-size(2), \"-\", \
             Strftime.Format.zeroed_int(day)::binary()-size(2)>>\
             """
    end
  end
end
