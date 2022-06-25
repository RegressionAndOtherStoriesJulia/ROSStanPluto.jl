### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ a7e8b8f4-e5c6-4203-8b10-db83c49f14fd
using Pkg, DrWatson

# ╔═╡ 670da67b-fa90-41b9-99c1-e1aa403cb49e
begin
	# Specific to this notebook
    using GLM

	# Specific to ROSStanPluto
    using StanSample
	
	# Graphics related
    using GLMakie
    using Makie
    using AlgebraOfGraphics

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ 53cabf93-4721-4a94-8cf2-0027d6956c3d
md"#### See chapter 8 in Regression and Other Stories."

# ╔═╡ 80654ee5-415a-4d0f-a3e9-7aba64dbdaed
md" ##### Widen the notebook."

# ╔═╡ 8dec7b41-6a63-40c4-8e85-2e57b10f418c
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

# ╔═╡ 9553193f-f338-470c-892c-2745ccac23a9
md"##### A typical set of Julia packages to include in notebooks."

# ╔═╡ 5c1dee90-d13a-4069-83b2-b6939ae98862
md"### 8.1 Least squares, maximum likelihood, and Bayesian inference."

# ╔═╡ 1cf3a8f4-12f9-46a6-8f1c-23747cce5096
hibbs = CSV.read(ros_datadir("ElectionsEconomy", "hibbs.csv"), DataFrame)

# ╔═╡ dcb3688e-c31a-4c00-a86a-bd643a19a3ee
let
	fig = Figure()
	hibbs.label = string.(hibbs.year)
	xlabel = "Average growth personal income [%]"
	ylabel = "Incumbent's party vote share"
	let
		title = "Forecasting the election from the economy"
		plt = data(hibbs) * 
			mapping(:label => verbatim, (:growth, :vote) => Point) *
			visual(Annotations, textsize=15)
		axis = (; title, xlabel, ylabel)
		draw!(fig[1, 1], plt; axis)
	end
	let
		title = "Data and linear fit"
		cols = mapping(:growth, :vote)
		scat = visual(Scatter) + linear()
		plt = data(hibbs) * cols * scat
		axis = (; title, xlabel, ylabel)
		draw!(fig[1, 2], plt; axis)
		annotations!("vote = 46.2 + 3.0 * growth"; position=(0, 41))
	end
	fig
end

# ╔═╡ 6ccecf93-3950-4eeb-87e2-bd0781ca0e53
stan7_1 = "
data {
	int<lower=1> N;      // total number of observations
	vector[N] growth;    // Independent variable: growth
	vector[N] vote;      // Dependent variable: votes 
}
parameters {
	real b;              // Coefficient independent variable
	real a;              // Intercept
	real<lower=0> sigma; // dispersion parameter
}
model {
	vector[N] mu;

	// priors including constants
	a ~ normal(50, 20);
	b ~ normal(2, 10);
  	sigma ~ exponential(1);

	mu = a + b * growth;

	// likelihood including constants
	vote ~ normal(mu, sigma);
}";

# ╔═╡ 21571106-9c07-4c5e-bd32-c80cc41f4245
let
	data = (N=nrow(hibbs), vote=hibbs.vote, growth=hibbs.growth)
	global m7_1s = SampleModel("hibbs", stan7_1)
	global rc7_1s = stan_sample(m7_1s; data)
	success(rc7_1s) && model_summary(m7_1s)
end

# ╔═╡ b2277131-d48b-4f95-9a85-081652be2541
post7_1s = success(rc7_1s) && read_samples(m7_1s, :dataframe)

# ╔═╡ 39989206-bced-4049-92af-90f5cfd2abdd
trankplot(post7_1s, "b")

# ╔═╡ e05648e2-c133-42b8-a9fe-304e3b1eb4de
ms7_1s = model_summary(post7_1s, [:a, :b, :sigma])

# ╔═╡ 18016f61-dea9-4c73-a274-d37ab9d1ff27
let
	growth_range = LinRange(minimum(hibbs.growth), maximum(hibbs.growth), 200)
	votes = mean.(link(post7_1s, (r,x) -> r.a + x * r.b, growth_range))

	xlabel = "Average growth personal income [%]"
	ylabel = "Incumbent's party vote share"

	fig = Figure()

	let
		title = "Data and (glm) linear fit"
		cols = mapping(:growth, :vote)
		scat = visual(Scatter) + linear()
		plt = data(hibbs) * cols * scat
		axis = (; title, xlabel, ylabel)
		draw!(fig[1, 1], plt; axis)
		annotations!("vote = 46.2 + 3.0 * growth"; position=(0, 41))
	end

	
	xlabel = "Average growth personal income [%]"
	ylabel="Incumbent's party vote share"
	ax = Axis(fig[1, 2]; title="Regression line based on 4000 posterior samples", 
		subtitle = "(grey lines are based on first 200 draws of :a and :b)",
		xlabel, ylabel)
	for i in 1:200
		lines!(growth_range, post7_1s.a[i] .+ post7_1s.b[i] .* growth_range, color = :lightgrey)
	end
	scatter!(hibbs.growth, hibbs.vote)
	lines!(growth_range, votes, color = :red)
	fig
end

# ╔═╡ Cell order:
# ╟─53cabf93-4721-4a94-8cf2-0027d6956c3d
# ╟─80654ee5-415a-4d0f-a3e9-7aba64dbdaed
# ╠═8dec7b41-6a63-40c4-8e85-2e57b10f418c
# ╠═a7e8b8f4-e5c6-4203-8b10-db83c49f14fd
# ╟─9553193f-f338-470c-892c-2745ccac23a9
# ╠═670da67b-fa90-41b9-99c1-e1aa403cb49e
# ╟─5c1dee90-d13a-4069-83b2-b6939ae98862
# ╠═1cf3a8f4-12f9-46a6-8f1c-23747cce5096
# ╠═dcb3688e-c31a-4c00-a86a-bd643a19a3ee
# ╠═6ccecf93-3950-4eeb-87e2-bd0781ca0e53
# ╠═21571106-9c07-4c5e-bd32-c80cc41f4245
# ╠═b2277131-d48b-4f95-9a85-081652be2541
# ╠═39989206-bced-4049-92af-90f5cfd2abdd
# ╠═e05648e2-c133-42b8-a9fe-304e3b1eb4de
# ╠═18016f61-dea9-4c73-a274-d37ab9d1ff27
