defmodule Interp do
    @type exprC :: NumC.t() | IdC.t() | StrC.t() | AppC.t() | LamC.t() | IfC.t() 
    @type environment :: Map
    @type value :: NumV.t() | PrimV.t() | CloV.t() | BoolV.t() | StrV.t()

    defmodule NumC do
        defstruct val:
        @type t :: %NumC{num: float}
    end

    defmodule IdC do
        defstruct id:
        @type t :: %IdC{id: atom}
    end

    defmodule StrC do
        defstruct str:
        @type t :: %StrC{str: String.t()}
    end

    defmodule LamC do
        defstruct [:args, :body]
        @type t :: %LamC{args: list(:atom), body: Interp.exprC}
    end

    defmodule IfC do
        defstruct [:test, :then, :el]
        @type t :: %IfC{test: Interp.exprC, then: Interp.exprC, el: Interp.exprC}
    end

    defmodule AppC do
        defstruct [:fun, :args]
        @type t :: %AppC{fun: Interp.exprC, args: list(Interp.exprC)}
    end


    defmodule NumV do
        defstruct val:
        @type t :: %NumV{val: float}
    end

    defmodule BoolV do
        defstruct bool:
        @type t :: %BoolV{bool: boolean}
    end

    defmodule StringV do
        defstruct str:
        @type t :: %StringV{str: String.t}
    end

    defmodule PrimV do
        defstruct pfun:
        @type t :: %PrimV{pfun: (list(Interp.value) -> Interp.value)}
    end

    defmodule CloV do
        defstruct [:args, :body, :cloEnv]
        @type t :: %CloV{args: list(atom), body: Interp.exprC, cloEnv: Interp.environment}
    end

    defmodule Binding do
        defstruct [:id, :val]
        @type t :: %Binding{id: atom, val: Interp.value}
    end

    @doc """
    Evaluates ExprC and returns a Value
    """
    @spec interp(exprC, environment) :: value
    def interp(e, env) do
        case e do
        %NumC {num: num} ->
             %NumV{num: num}

        %StrC {str: str} ->
             %StrV{str: str}

        %IdC {id: id} ->
            lookup(id, env) 
            #TODO! add lookup function

        %LamC{args: args, body: body} ->
            %CloV{args: args, body: body, cloEnv: env}

        %IfC{test: test, then: then, el: el} ->
            case interp(test, env) do
                %BoolV{bool: true} -> 
                    interp(then, env)
                %BoolV{bool: false} -> 
                    interp(el, env)
                _ ->
                    raise "WTUQ if error test clause must be boolean"
            end
        %AppC{fun: fun, args: args} ->
            case interp(fun, env) do
                %PrimV{pfun: pfun} ->
                    #TODO map pfun
                %CloV{args: args, body: body, cloEnv: cloEnv} ->
                    if length(params) != length(args) do
                        raise "WTUQ incorrect number of argument"
                    end

                    #TODO
                _ ->
                    raise "WTUQ invalid function call"
        end
    end

    @doc """
        Basic wrapper for binomial mathematical expressions
    """
    @spec binom(Function) :: (list(Interp.value) -> Interp.value)
    def binom(func) do
        fn vals ->
            case vals do
                [%NumV{num: num1}, %NumV{num: num2}] ->
                    func.(num1, num2)
                _ ->
                    raise "WTUQ: Wrong arg types provided"
            end
        end
    end    
    add = fn num1, num2 -> %NumV{num: num1 + num2} end
    multiply = fn num1, num2 -> %NumV{num: num1 * num2} end
    sub = fn num1, num2 -> %NumV{num: num1 - num2} end
    lessThanEq = fn num1, num2 -> %BoolV{bool: num1 <= num2} end
    div = fn num1, num2 -> 
        case num2 do
            0 -> raise "WTUQ: Divide by 0 err"
            _ -> %NumV{num: num1 / num2}
        end
    end
    eq = fn values ->
        case values do 
            [%NumV{num: n1}, %NumV{num: n2}] -> %BoolV{bool: n1 == n2}
            [%StringV{str: str1}, %StringV{str2}] -> 
                %BoolV{bool: String.equivalent?(str1, str2)}
            [%BoolV{bool: b1}, %BoolV{bool: b2}] -> %BoolV{bool: b1 == b2}
            _ -> raise "WTUQ: Incorrect use of equal?"
        end
    end
    myError = fn values ->
        case values do
            [a] -> raise a
            _ -> raise "Inccorect use of error"
        end
    end

    newEnv = %{
        true: %BoolV{bool: true},
        false: %BoolV{bool: false},
        +: Interp.binom(add),
        *: Interp.binom(multiply),
        /: Interp.binom(div),
        -: Interp.binom(sub),
        <=: Interp.binop(lessThanEq),
        equal?: eq,
        error: myError
    }
    


end


