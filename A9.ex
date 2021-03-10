import Map
defmodule NumC do
    defstruct num: nil
    @type t :: %NumC{num: float}
end

defmodule IdC do
    defstruct id: nil
    @type t :: %IdC{id: atom}
end

defmodule StrC do
    defstruct str: nil
    @type t :: %StrC{str: String.t()}
end

defmodule LamC do
    defstruct args: [], body: nil
    @type t :: %LamC{args: list(:atom), body: Interp.exprC}
end

defmodule IfC do
    defstruct test: nil, then: nil, el: nil
    @type t :: %IfC{test: Interp.exprC, then: Interp.exprC, el: Interp.exprC}
end

defmodule AppC do
    defstruct [:fun, :args]
    @type t :: %AppC{fun: Interp.exprC, args: list(Interp.exprC)}
end


defmodule NumV do
    defstruct num:
    @type t :: %NumV{num: float}
end

defmodule BoolV do
    defstruct bool:
    @type t :: %BoolV{bool: boolean}
end

defmodule StrV do
    defstruct str:
    @type t :: %StrV{str: String.t}
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

defmodule Utils do

    @doc """
        Basic wrapper for binomial mathematical expressions
    """
    @spec binop(Function) :: (list(Interp.value) -> Interp.value)
    def binop(func) do
        fn vals ->
            case vals do
                [%NumV{num: num1}, %NumV{num: num2}] ->
                    func.(num1, num2)
                _ ->
                    raise "WTUQ: Wrong arg types provided"
            end
        end
    end
end

defmodule Interp do
    @type exprC :: NumC.t() | IdC.t() | StrC.t() | AppC.t() | LamC.t() | IfC.t() 
    @type environment :: Map
    @type value :: NumV.t() | PrimV.t() | CloV.t() | BoolV.t() | StrV.t()

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
            lookUp(id, env) 

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
                    pfun.(Enum.map(args, fn exp -> interp(exp, env) end))
                %CloV{args: params, body: body, cloEnv: cloEnv} ->
                    argVals = Enum.map(args, fn exp -> interp(exp, env) end)
                    interp(body, extend_env_multiple(cloEnv, params, argVals))
                _ ->
                    raise "WTUQ invalid function call"
            end
        end
    end

    @doc """
        Looks up a symbol in the environment
    """
    @spec lookUp(Interp.environment, Atom) :: Interp.value
    def lookUp(env, sym) do
        case Map.get(env, sym, nil) do
            nil -> raise "WTUQ: Unbound symbol" <> Atom.to_string(sym)
            a -> a
        end
    end

    @doc """
        Returns new env with the given key, value association
    """
    @spec extend_env(Interp.environment, Atom, Interp.value) :: Interp.environment
    def extend_env(env, sym, val) do
        env |> put(sym, val)
    end

    @doc """
        Returns a new env with the given keys bound to the given values
    """
    @spec extend_env_multiple(Interp.environment, List, List) :: Interp.environment
    def extend_env_multiple(env, syms, vals) do
        case [syms, vals] do
            [[], []] -> env
            [[sym | sRest], [val | vRest]] ->
                extend_env_multiple(extend_env(env, sym, val), sRest, vRest)
            _ -> raise "WTUQ: Incorrect number of arguments provided"
        end
    end
    # Wrapper for addition    
    add = fn num1, num2 -> %NumV{num: num1 + num2} end
        
    # Wrapper for multiplication
    multiply = fn num1, num2 -> %NumV{num: num1 * num2} end

    # Wrapper for subtraction
    sub = fn num1, num2 -> %NumV{num: num1 - num2} end

    # Wrapper for <=
    lessThanEq = fn num1, num2 -> %BoolV{bool: num1 <= num2} end

    # Wrapper for division, w/ check for divide by 0 err
    div = fn num1, num2 -> 
        case num2 do
            0 -> raise "WTUQ: Divide by 0 err"
            _ -> %NumV{num: num1 / num2}
        end
    end

    # Wrapper for equals?
    eq = fn values ->
        case values do 
            [%NumV{num: n1}, %NumV{num: n2}] -> %BoolV{bool: n1 == n2}
            [%StrV{str: str1}, %StrV{str: str2}] -> 
                %BoolV{bool: String.equivalent?(str1, str2)}
            [%BoolV{bool: b1}, %BoolV{bool: b2}] -> %BoolV{bool: b1 == b2}
            _ -> raise "WTUQ: Incorrect use of equal?"
        end
    end

    # Wrapper for an error function
    myError = fn values ->
        case values do
            [a] -> raise a
            _ -> raise "Inccorect use of error"
        end
    end
    # Base environment
    newEnv = %{
        true: %BoolV{bool: true},
        false: %BoolV{bool: false},
        +: %PrimV{pfun: Utils.binop(add)},
        *: %PrimV{pfun: Utils.binop(multiply)},
        /: %PrimV{pfun: Utils.binop(div)},
        -: %PrimV{pfun: Utils.binop(sub)},
        <=: %PrimV{pfun: Utils.binop(lessThanEq)},
        equal?: %PrimV{pfun: eq},
        error: %PrimV{pfun: myError}
    }
end