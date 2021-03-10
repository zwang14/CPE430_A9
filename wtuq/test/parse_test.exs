defmodule ParseTest do
  use ExUnit.Case
  doctest Parse

  test "Parse correctly parses atomic data types" do
    assert Parse.parse([10]) == %NumC{num: 10}
    assert Parse.parse([:x]) == %IdC{id: :x}
    assert Parse.parse(["test"]) == %StrC{str: "test"}
  end

end
