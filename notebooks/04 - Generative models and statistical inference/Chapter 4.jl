### A Pluto.jl notebook ###
# v0.19.8

using Markdown
using InteractiveUtils

# ╔═╡ 8442b25c-8331-4b77-82d7-c0a1089478f2
using Pkg, DrWatson

# ╔═╡ 7d2229ba-483a-417b-9ef7-2bf81fd71944
begin
	# Specific to this notebook
    using GLM

	# Specific to ROSStanPluto
    using StanSample
	
	# Graphics related
    using GLMakie
    using Makie

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ 6d0bb5ac-efc0-445a-aded-ec69fee95019
md"### Chapter 4 in Regression and Other Stories."

# ╔═╡ c0658351-3395-46a4-b711-98fd5988893f
md" ###### Widen the notebook."

# ╔═╡ 659d2b04-a03e-4faa-b818-1ae53b219f85

html"""
<style>
	main {
		margin: 0 auto;
		max-width: 2000px;
    	padding-left: max(160px, 10%);
    	padding-right: max(160px, 10%);
	}
</style>
"""

# ╔═╡ 169b41f7-7825-4abf-ae2b-e076e634b58c
md"###### A typical set of Julia packages to include in notebooks."

# ╔═╡ 9ead40d7-e641-4c93-bacd-bfe164b77417
md" #### 4.1 Sampling distributions and generative models."

# ╔═╡ 072d2912-363e-4d66-9f6f-241518b0349e
begin
	Random.seed!(1)
	a = 1.0
	b = 2.0
	x = LinRange(-2, 2, 100)
	y = a .+ b .* x .+ rand(Normal(0.0, 0.2), 100)
end;

# ╔═╡ ac86e192-f1f1-4722-85a6-89d95a8f7265
let
	f = Figure()
	ax = Axis(f[1, 1]; title="Linear regression")
	scatter!(x, y)
	lines!(x, a .+ b .* x; color=:darkred)
	annotations!("yᵢ = 1.0 + 2.0 * xᵢ + ϵᵢ", position=(0, -2), textsize=20)
	current_figure()
end

# ╔═╡ 7301c69b-815c-4b77-83e6-ea561a1364a5
stan4_1 = "
data {
	int N;
	vector[N] x;
	vector[N] y;
}
parameters {
	real a;
	real b;
	real<lower=0> sigma;
}
model {
	vector[N] mu;
	a ~ normal(0.0, 1.5);
	b ~ normal(1.0, 1.5);
	sigma ~ exponential(1);
	mu = a + b * x;
	y ~ normal(mu, sigma);
}";

# ╔═╡ 4b8268e2-9665-402e-b60d-e1465f39e417
begin
	data = (N = length(x), x = x, y = y)
	m4_1s = SampleModel("m4.1s", stan4_1)
	rc4_1s = stan_sample(m4_1s; data)
end;

# ╔═╡ 13723997-3932-4aaa-b718-7fb336be72ac
if success(rc4_1s)
	ms4_1s = model_summary(m4_1s, [:a, :b, :sigma])
end

# ╔═╡ acafb529-bda5-4814-a56d-5445894a2f19
if success(rc4_1s)
	post4_1s = read_samples(m4_1s, :dataframe)
end

# ╔═╡ 4fd36f4b-28d1-47f2-a803-f8727e078484
let
	f = Figure()
	ax = Axis(f[1, 1]; title="Sampling distribution of a")
	density!(post4_1s.a)
	ax = Axis(f[1, 2]; title="Sampling distribution of b")
	density!(post4_1s.b)
	ax = Axis(f[1, 3]; title="Sampling distribution of sigma")
	density!(post4_1s.sigma)
	current_figure()
end

# ╔═╡ bb7a65ba-0003-4d5c-abe1-19e6f6820f06
let
	f = Figure()
	ax = Axis(f[1, 1]; title="Linear regression")
	scatter!(x, y)
	lines!(x, ms4_1s[:a, "mean"] .+ ms4_1s[:b, "mean"] .* x; color=:darkred)
	mean_a = round(ms4_1s[:a, "mean"]; digits=2)
	mean_b = round(ms4_1s[:b, "mean"]; digits=2)
	mean_σ = round(ms4_1s[:sigma, "mean"]; digits=2)
	annotations!("y = $(mean_a) + $(mean_b) * x + $(mean_σ)", position=(0, -2), textsize=20)
	current_figure()
end

# ╔═╡ 8342a3bd-1ffb-470b-be32-d3d8db1eedc2
md" #### 4.2 Estimates, standard errors, and confidence intervals."

# ╔═╡ edb83342-1518-4938-afca-b9981bfe6c48
let
	f = Figure()
	ax = Axis(f[1, 1]; title="Sampling distribution of b (revisited)")
	b̂ = ms4_1s[:b, "mean"]
	σ̂ = ms4_1s[:b, "std"]
	x = LinRange(b̂ - 4σ̂ , b̂ + 4σ̂, 100)
	y = pdf.(Normal(b̂, σ̂), x)
	ylims!(ax, [0, maximum(y) + 1.0])
	ax.xticks = b̂ - 3σ̂ : σ̂ : b̂ + 3σ̂
	ax.xtickformat = xs -> ["$(i) s.e." for i in -3:3]
	lines!(x, y)
	vlines!(ax, [b̂]; ymax=[maximum(y)/(maximum(y) + 1.0)], color=:grey)
	vlines!(ax, [b̂-σ̂, b̂+σ̂];
		ymax=[pdf.(Normal(b̂, σ̂), b̂-σ̂)/(maximum(y) + 1.0), pdf.(Normal(b̂, σ̂), b̂+σ̂)/(maximum(y) + 1.0)],
		color=:grey)
	annotations!("b ±  1 s.e.", position=(b̂-0.008, 7.5), textsize=20)
	x1 = range(b̂ - σ̂ , b̂ + σ̂; length=60)
	band!(x1, fill(0, length(x1)), pdf.(Normal(b̂, σ̂), x1); color = (:blue, 0.25))
	f
end

# ╔═╡ 47c24a34-c8fb-4909-8de6-f46c36fbda56
let
	n = 100
	b = 2.0

	f = Figure()
	ax = Axis(f[1,1]; title="Simulation of confidence intervals", xlabel="Simulation",
		ylabel="Assumed 50% and 95% confidence intervals")

	x = 1:n
	y = [rand(Uniform(b - 2.1 , b + 2.1), 1)[1] for i in 1:n]

	# Assumed s.e. = 1.0
	lowerrors = fill(0.66, n)
	higherrors = fill(2, n)
	
	errorbars!(x, y, lowerrors, color = :red) # same low and high error
	errorbars!(x, y, higherrors, color = :grey) # same low and high error
	
	scatter!(x, y, markersize = 3, color = :black)
	hlines!(ax, [2])
	
	f
end

# ╔═╡ 0890feea-2432-4472-b36e-54a36b2c02f9
let
	n = 1000
	yes = 700
	no = n - yes
	est = yes/n
	se = sqrt(est * (1 - est)/n)
	
	(estimate = est, se = se, int_95 = est .+ quantile.(Normal(0, 1), [0.025, 0.975]) * se)
end

# ╔═╡ 3d2b0416-8510-463d-9ed0-a598085d9918
let
	y = [35, 34, 38, 35, 37]
	n = length(y)
	est = mean(y)
	se = std(y)/sqrt(n)
	int_50 = est .+ quantile.(TDist(n-1), [0.25, 0.75]) * se
	int_95 =  est .+ quantile.(TDist(n-1), [0.025, 0.975]) * se
	
	(estimate = est, se = se, int_50 = int_50, int_95 = int_95)
end

# ╔═╡ Cell order:
# ╟─6d0bb5ac-efc0-445a-aded-ec69fee95019
# ╟─c0658351-3395-46a4-b711-98fd5988893f
# ╠═659d2b04-a03e-4faa-b818-1ae53b219f85
# ╠═8442b25c-8331-4b77-82d7-c0a1089478f2
# ╟─169b41f7-7825-4abf-ae2b-e076e634b58c
# ╠═7d2229ba-483a-417b-9ef7-2bf81fd71944
# ╟─9ead40d7-e641-4c93-bacd-bfe164b77417
# ╠═072d2912-363e-4d66-9f6f-241518b0349e
# ╠═ac86e192-f1f1-4722-85a6-89d95a8f7265
# ╠═7301c69b-815c-4b77-83e6-ea561a1364a5
# ╠═4b8268e2-9665-402e-b60d-e1465f39e417
# ╠═13723997-3932-4aaa-b718-7fb336be72ac
# ╠═acafb529-bda5-4814-a56d-5445894a2f19
# ╠═4fd36f4b-28d1-47f2-a803-f8727e078484
# ╠═bb7a65ba-0003-4d5c-abe1-19e6f6820f06
# ╟─8342a3bd-1ffb-470b-be32-d3d8db1eedc2
# ╠═edb83342-1518-4938-afca-b9981bfe6c48
# ╠═47c24a34-c8fb-4909-8de6-f46c36fbda56
# ╠═0890feea-2432-4472-b36e-54a36b2c02f9
# ╠═3d2b0416-8510-463d-9ed0-a598085d9918
