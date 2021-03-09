defmodule Interp do
    @type exprC :: NumC.t() | IdC.t() | StrC.t() | AppC.t() | LamC.t() | IfC.t() 
    @type environment :: list(Binding.t())
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
end
