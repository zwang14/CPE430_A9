import Map

defmodule Serialize do
    @doc """
        Serialize function for Value types (after interp)
    """
    @spec serialize(Interp.value) :: String.t()
    def serialize(v) do
        case v do
        
        %NumV {num: num} ->
            cond do
                is_float(num) ->
                    Float.to_string(num)
                is_integer(num) ->
                    Integer.to_string(num)
            end
        
        %BoolV {bool: boolVal} ->
            cond do
                boolVal ->
                    "true"
                !boolVal ->
                    "false"
            end

        %StrV {str: str} ->
            str

        %PrimV{pfun: _pfun} ->
            "#primop"

        %CloV{args: _args, body: _body, cloEnv: _cloEnv} ->
            "#procedure"

        end
    end
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
            lookUp(env, id) 

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

    # Base environment
    def new_env() do
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
                [%StrV{str: str1}, %StrV{str: str2}] -> 
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

        %{
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
end
