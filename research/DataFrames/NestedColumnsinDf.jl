df = DataFrame(
    x₁ = 1:5, 
    f = [[2], [1, 3], [4.0], [1,2,3.0], [missing]],
    g = [
            (city="Atlanta", state="GA"),
            (city="DC", state="DC"),
            (city="San Diego", state="CA"),
            (city="Denver", state="CO"),
            (city="Palo Alto", state="CA")
        ],
    h = [i for i in eachrow(randn(5,2))],
    i = [[1 2;3 4], [2], [3], [4], [5]]

)

df[:, 1:3] |> display
println()
df[:, 4:end] |> display
println()
@show df[df.x₁ .== df.x₁[1], :i]
println()
df[1, :i] |> display

function matrix(df::DataFrame, var::Union{Symbol, String})
    colsyms = Symbol.(names(df))
    sym = Symbol(var)
    res = Float64[]

    if sym in colsyms
        d = df[:, sym]
        res = zeros(length(d), length(d[1]))
        indx = 1
        for r in eachrow(d)
            res[indx, :] = d[indx]
            indx += 1
        end
    end
    res
end

m = matrix(df, :h)
m |> display

function new_dataframe(df::DataFrame, sym::Union{Symbol, String})
    n = string.(names(st))
    syms = string(sym)
    sel = String[]
    for (i, s) in enumerate(n)
        if length(s) > length(syms) && syms == n[i][1:length(syms)] &&
            n[i][length(syms)+1] in ['[', '.', '_']
            append!(sel, [n[i]])
        end
    end
    length(sel) == 0 && error("$syms not in $n")
    tmp = st |> TableOperations.select(sel...) |> Tables.columntable
    Tables.matrix(tmp)
end
