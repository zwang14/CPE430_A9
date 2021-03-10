defmodule Parse do
    @doc """
    Parses concrete syntax into an AST 
    """
    @spec parse(List) :: Interp.exprC
    def parse(exprs) do
        case exprs do
            [single] -> returnAtomic(single)
        end
    end
    
    @doc """
    Determines what type a wtuq atomic variable is
    """
    def returnAtomic(x) when is_number(x) do %NumC{num: x} end
    def returnAtomic(x) when is_atom(x) do %IdC{id: x} end
    def returnAtomic(x) when is_bitstring(x) do %StrC{str: x} end
end