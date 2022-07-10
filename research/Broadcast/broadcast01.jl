f(x) = 3x^2 + 5x + 2

function nobcst(f, x)
    f.(2 .* x.^2 .+ 6 .* x.^3 .- sqrt.(x))
end

function bcst(f, x)
    @. f(2 * x^2 + 6 * x^3 - sqrt(x))
end


n = 10^6
x = LinRange(0, 2, n)
    
@time y1 = nobcst(f, x)
@time y2 = bcst(f, x)
