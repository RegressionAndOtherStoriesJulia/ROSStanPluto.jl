### A Pluto.jl notebook ###
# v0.19.8

using Markdown
using InteractiveUtils

# ╔═╡ c14a1548-e1a8-11ec-1929-b7d3e09b5073
using Pkg

# ╔═╡ 6fd3283b-4e12-4b39-96ac-958dfbdb7d4f
begin
	using Optim
	
	using StanSample
	using StanOptimize

	using CairoMakie
	
	using RegressionAndOtherStories
end

# ╔═╡ 4e858c0e-af1b-44fa-9e9b-663ade98ab1b
stan_a7 = "
parameters {
	real x;
}
model {
	target += 15 + 10*x - 2*x^2;
}
";

# ╔═╡ 40d7fb2c-581c-496f-a967-1fac1f73b1d5
begin
	a7 = OptimizeModel("A.7", stan_a7)
	a7o = stan_optimize(a7)
	optim, cnames = read_optimize(a7)
	optim
end

# ╔═╡ 287fa913-1eaa-4828-bf5c-8ad6655b60c7
cnames

# ╔═╡ a9df804b-4883-45e0-b854-919ad7c4f18f
x̄ = optim["x"]

# ╔═╡ b7cca360-b1f1-48b6-95b8-ba938e6ab363
ȳ = optim["lp__"]

# ╔═╡ fc1123df-6e28-41f3-ac5b-8eab96038b80
function fun(x)
	return 15 + 10 * x - 2 * x^2
end

# ╔═╡ 8425aace-93a2-4685-88e8-5313a27d3b2c
md" #### Using Julia's Optim.jl package"

# ╔═╡ 06c8b4f9-89cb-4b4b-9be0-1a5454d1404e
begin
	f1(x::Vector) = -(15 .+ 10 .* x[1] .- 2 .* x[1].^2)
	res = optimize(f1, [5.0])
end

# ╔═╡ 369bc376-3fb7-46ab-886d-261d7eb2f624
Optim.minimizer(res)

# ╔═╡ 884a3c1f-e1b3-4110-b4ca-8194f5d7b17d
begin
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="Apendix A.7 optimization")
	x = collect(LinRange(-2.0, 5.0, 100))
	lines!(x, [fun(v) for v in x])
	vlines!(ax, [optim["x"][1]]; color=:red)
	hlines!(ax, [optim["lp__"][1]]; color=:grey, xmin=[0.50], xmax=[0.8])
	annotations!("x̄ = $(optim["x"])", position=(-2,24), fontsize=15)
	annotations!("fun(x̄) = $(optim["lp__"])", position=(-2, 22), fontsize=15)
	f
end

# ╔═╡ Cell order:
# ╠═c14a1548-e1a8-11ec-1929-b7d3e09b5073
# ╠═6fd3283b-4e12-4b39-96ac-958dfbdb7d4f
# ╠═4e858c0e-af1b-44fa-9e9b-663ade98ab1b
# ╠═40d7fb2c-581c-496f-a967-1fac1f73b1d5
# ╠═287fa913-1eaa-4828-bf5c-8ad6655b60c7
# ╠═a9df804b-4883-45e0-b854-919ad7c4f18f
# ╠═b7cca360-b1f1-48b6-95b8-ba938e6ab363
# ╠═fc1123df-6e28-41f3-ac5b-8eab96038b80
# ╟─8425aace-93a2-4685-88e8-5313a27d3b2c
# ╠═06c8b4f9-89cb-4b4b-9be0-1a5454d1404e
# ╠═369bc376-3fb7-46ab-886d-261d7eb2f624
# ╠═884a3c1f-e1b3-4110-b4ca-8194f5d7b17d
