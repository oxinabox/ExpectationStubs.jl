module ExpectionTestingMocks
using DataStructures
using MacroTools
export @stub, @expect, Stub, SortedDict


struct SyntaxError <: Exception
end

struct ExpectationNotSetError <: Exception
    name
    sig
    argvals
end

struct ExpectationAlreadySetError <:Exception
    name
    sig
    argvals
end

struct Stub{name}
    expectations::SortedDict
end
Stub(name)=Stub{name}(SortedDict())


macro stub(name)
    quote
        $(esc(name))=Stub($(QuoteNode(name)))
    end
end

"""
    DoNotCare

A type that is equal to all things.
For internal use.
Will interact weirdly with hash based dicts
"""
immutable DoNotCare
end
Base.isequal(::DoNotCare,::Any)=true
Base.isequal(::DoNotCare, ::DoNotCare)=true
Base.isequal(::Any, ::DoNotCare)=true
Base.:(==)(::Any, ::DoNotCare)=true
Base.:(==)(::DoNotCare,::Any)=true
Base.:(==)(::DoNotCare, ::DoNotCare)=true

"""
    split_vals_and_sig(argsexpr)

Takes an expression from a function definition's args
eg `:([a::Int, ::Integer])`
and breaks it down into the values, and the types.
When value is not given it subsitutes `DoNotCare()`,
when type is not given it subsitutes `typeof(val)`
Returns a tuple of each, with all things in expression/symbol form.
"""
function split_vals_and_sig(argsexpr)
    vals=Any[]
    sig=Expr(:tuple)
    for term in argsexpr
        if @capture(term, v_::s_)
            push!(vals, v)
            push!(sig.args, s)
        elseif @capture(term, ::s_)
            push!(vals, DoNotCare())
            push!(sig.args, s)
        elseif @capture(term, v_)
            push!(vals, v)
            push!(sig.args, :(typeof($v)))
        else
            throw(SyntaxError)()
        end
    end
    Tuple(vals), sig
end

"""
    format_sig(sig)

takes a signature of symbols/exprs eg (:Any, :Int)
and return a tuple full function signature, and corresponding tuple of args
eg `:(a::Any, b::Int), (:a,:b)`
"""
function format_sig(sig)
    full_sig = Expr(:tuple)
    args = Expr(:tuple)

    for (ii, term) in enumerate(sig.args)
        var = Symbol(:x, ii)
        push!(args.args, var)
        push!(full_sig.args, :($var::$term))
    end

    full_sig, args
end

macro expect(defn)
    @capture(defn, name_(args__)=ret_) || throw(SyntaxError())
    argvals, sig = split_vals_and_sig(args)
    formatted_sig, formatted_args = format_sig(sig)
    quote
        if !method_exists($(esc(name)), ($(esc(sig))))
            function (stub::Stub{$(QuoteNode(name))})($(esc.((formatted_sig).args)...))
                sigkey = $(esc(sig))
                argkey = $(esc(formatted_args))
                if !haskey(stub.expectations, argkey)
                    throw(ExpectationNotSetError($(QuoteNode(name)), sigkey, argkey))
                end
                stub.expectations[argkey]
            end
        end


        if haskey($(esc(name)).expectations, $(argvals))
            throw(ExpectationAlreadySetError($(esc(name)), $(esc(sig)), $(esc(argvals))))
        end
        $(esc(name)).expectations[$(argvals)] = $(esc(ret))
    end |> unblock |>  MacroTools.striplines


end

end #Module
