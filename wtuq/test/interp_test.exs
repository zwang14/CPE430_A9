defmodule InterpTest do
  use ExUnit.Case
  doctest Interp

  test "interp returns basic structures" do
    base_env = Interp.new_env()
    assert Interp.interp(%NumC{num: 10}, base_env) == %NumV{num: 10}
    assert Interp.interp(%StrC{str: "test"}, base_env) == %StrV{str: "test"}
  end

  test "interp looks up idC correctly" do
    base_env = Interp.new_env()
    test_env = Interp.extend_env(base_env, :t, %NumV{num: 10})
    assert Interp.interp(%IdC{id: :t}, test_env) == %NumV{num: 10}
  end

  test "interp correctly applies PrimVs" do
    base_env = Interp.new_env()
    add = %AppC{fun: %IdC{id: :+}, args: [%NumC{num: 10}, %NumC{num: 1}]}
    multiply = %AppC{fun: %IdC{id: :*}, args: [%NumC{num: 10}, %NumC{num: 2}]}

    assert Interp.interp(add, base_env) == %NumV{num: 11}
    assert Interp.interp(multiply, base_env) == %NumV{num: 20}
  end

  test "interp correctly handles custom functions" do
    base_env = Interp.new_env()
    func = %LamC{args: [:x, :y], body: %AppC{fun: %IdC{id: :-}, args: [%IdC{id: :x}, %IdC{id: :y}]}}
    applyFunc = fn x, y -> %AppC{fun: func, args: [x, y]} end
    assert Interp.interp(applyFunc.(%NumC{num: 10}, %NumC{num: 5}), base_env) == %NumV{num: 5}

    more_complex = applyFunc.(applyFunc.(%NumC{num: 10}, %NumC{num: 5}), %NumC{num: 10})
    assert Interp.interp(more_complex, base_env) == %NumV{num: -5}
  end

  test "interp correctly handles closures" do
    base_env = Interp.new_env()
    clo_test = %LamC{args: [:x], body: 
            %LamC{args: [:y], body: %AppC{fun: %IdC{id: :+}, args: [%IdC{id: :x}, %IdC{id: :y}]}}}
    func = %LamC{args: [:f, :x], body: %AppC{fun: %IdC{id: :f}, args: [%IdC{id: :x}]}}
    applied_clo = %AppC{fun: clo_test, args: [%NumC{num: 10}]}
    apply_func = %AppC{fun: func, args: [applied_clo, %NumC{num: 2}]}
    assert Interp.interp(apply_func, base_env) == %NumV{num: 12}
  end

  test "interp handles ifC" do
    base_env = Interp.new_env()
    if_true = %IfC{test: %IdC{id: :true}, then: %NumC{num: 1},
                    el: %NumC{num: 0}}
    if_false = %IfC{test: %IdC{id: :false}, then: %NumC{num: 1},
                el: %NumC{num: 0}}
    assert Interp.interp(if_true, base_env) == %NumV{num: 1}
    assert Interp.interp(if_false, base_env) == %NumV{num: 0}
  end


end