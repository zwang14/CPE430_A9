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
