### A Pluto.jl notebook ###
# v0.19.36

using Markdown
using InteractiveUtils

# ╔═╡ a7e8b8f4-e5c6-4203-8b10-db83c49f14fd
using Pkg

# ╔═╡ 117bce29-5156-434a-9cfd-400e27703682
Pkg.activate(expanduser("~/.julia/dev/SR2StanPluto"))

# ╔═╡ 670da67b-fa90-41b9-99c1-e1aa403cb49e
begin
	# Specific to this notebook
    using GLM
	using Optim

	# Specific to ROSStanPluto
    using StanSample
	using StanOptimize	

	# Graphics related
    using CairoMakie

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ 3d06f09a-c972-474b-8e57-c396cefb5e22
let
	using Statistics
	Random.seed!(123)
	a = 46.2
	b = 3.0
	sigma = 4.0
	x = LinRange(1, 5, 200)
	ϵ = rand(Normal(0, sigma), length(x))
	y = a .+ b .* x .+ ϵ
	global obs = Matrix(hcat(x, y)')
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

# ╔═╡ 59b3a003-5a89-418f-96c5-7970bfbb2602
let
	Random.seed!(1)
	a = 46.2
	b = 3.0
	sigma = 4.0
	x = LinRange(0, 5, 200)
	ϵ = rand(Normal(0, sigma), length(x))
	y = a .+ b .* x .+ ϵ

	# DataFrame used to collect differen estimates, shown later on.
	
	global estimate_comparison = DataFrame()
	estimate_comparison.parameters = [:a, :b, :sigma]
	
	global sim = DataFrame(x = x, y = y, ϵ = ϵ, error = y .- (a .+ b .* x))
end

# ╔═╡ 2239ac13-f219-4307-b90b-bd88518793ee
stan8_1 = "
data {
	int<lower=1> N;    	// total number of observations
	vector[N] x;    	// Independent variable: growth
	vector[N] y;      	// Dependent variable: votes 
}
parameters {
	real b;              // Coefficient independent variable
	real a;              // Intercept
	real<lower=0> sigma; // dispersion parameter
}
model {
	vector[N] mu;

	// priors including constants
	a ~ normal(1, 5);
	b ~ normal(1, 5);
  	sigma ~ exponential(1);

	mu = a + b * x;

	// likelihood including constants
	y ~ normal(mu, sigma);
}";

# ╔═╡ 8afd6e0c-fdb1-45a3-b0a4-7080c9fd8b20
let
	data = (N = nrow(sim), x = sim.x, y = sim.y)
	global m8_1s = SampleModel("m8_1s", stan8_1)
	global rc8_1s = stan_sample(m8_1s; data)
	success(rc8_1s) && describe(m8_1s)
end

# ╔═╡ cf572844-7459-44a5-921c-0756d3bed89e
if success(rc8_1s)
	post8_1s = read_samples(m8_1s, :dataframe)
	ms8_1s = model_summary(post8_1s, [:a, :b, :sigma])
	estimate_comparison[!, :m8_1s] = [Vector(i) for i in eachrow(ms8_1s[:, [:median, :mad_sd]])]
	ms8_1s
end

# ╔═╡ b2e11cbd-2d58-45cc-a559-f35352872025
let
	â = ms8_1s[:a, :median]
	b̂ = ms8_1s[:b, :median]
	sim.residual = sim.y .- (â .+ b̂ .* sim.x)
	sim
end

# ╔═╡ 2393509b-bcae-4b6b-a552-ac5fba8fba3c
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="Regression line and simulated values", xlabel="x", ylabel="y")
	x_range = LinRange(minimum(sim.x), maximum(sim.x), 200)
	y_res = mean.(link(post8_1s, (r,x) -> r.a + x * r.b, x_range))
	scatter!(sim.x, sim.y; markersize=4)
	lines!(x_range, y_res; color=:darkred)

	ax = Axis(f[1, 2]; title="Residuals", xlabel="Observation", ylabel="Residual")
	scatter!(sim.residual; markersize=6)
	hlines!(ax, mean(sim.residual); color=:darkred)
	f
end

# ╔═╡ e4beb669-2a0f-4461-a2bf-fbd2691af3f6
RSS = sum(sim.residual .^ 2)

# ╔═╡ e4c3b43a-0284-415f-a266-1be1a8750be9
let
	â = ms8_1s[:a, :mean]
	b̂ = ms8_1s[:b, :mean]

	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="RSS as a function of a", xlabel="a", ylabel="RSS")
	a_range = LinRange(43, 48, 100)
	r = [sum((sim.y .- (k .+ b̂ .* sim.x)) .^ 2) for k in a_range]
	lines!(a_range, r)
	annotations!("$((â = â, b̂ = b̂))", position=(44.5, 4500), fontsize=15)
	ax = Axis(f[1, 2]; title="RSS as a function of b", xlabel="b", ylabel="RSS")
	b_range = LinRange(2.1, 4.4, 100)
	r = [sum((sim.y .- (â .+ k .* sim.x)) .^ 2) for k in b_range]
	lines!(b_range, r)
	annotations!("$((â = â, b̂ = b̂))", position=(2.58, 4800), fontsize=15)
	f
end

# ╔═╡ 10b2181b-e48d-44e8-8a8f-d45330def40d
md" ###### Least squares"

# ╔═╡ 39471f16-b364-41f4-bd57-42c4c5ac4e3f
let
	global lsq = [0.0 missing; 0.0 missing; 0.0 missing]
	df = DataFrame(ones = ones(nrow(sim)), x = sim.x)
	X = Array(df)
	Xt = transpose(X)
	â, b̂ = (Xt * X)^-1 * Xt * sim.y
	lsq[1, 1] = â
	lsq[2, 1] = b̂
	â, b̂
end

# ╔═╡ 10e19c62-edfe-456f-892a-03d17c6036ab
let
	b̂ = sum((sim.x .- mean(sim.x)) .* sim.y) / sum(((sim.x .- mean(sim.x)) .^ 2))
	â = mean(sim.y) - b̂ * mean(sim.x)
	(â = â, b̂ = b̂)
end

# ╔═╡ 86be6ea3-e6ed-4616-893f-bc75ea799113
let
	σ̂ = sqrt(sum(sim.residual .^ 2)/(nrow(sim) - 2))
	lsq[3, 1] = σ̂
	estimate_comparison[!, :least_squares] = [Vector(i) for i in eachrow(lsq)]
	σ̂
end

# ╔═╡ 0f8587a5-fc88-4931-8e32-7d68dfcfc6e7
md" ###### Maximum likelihood"

# ╔═╡ e8ab3389-de0b-4f54-b12d-5baac6820079
function loglik(x)
	ll = 0.0
	ll += log(pdf(Normal(50, 20), x[1]))
	ll += log(pdf(Normal(2, 10), x[2]))
	ll += log(pdf(Exponential(1), x[3]))
	for i in 1:nrow(sim)
		ll += sum(logpdf.(Normal(x[1] .+ x[2] .* sim.x[i], x[3]), sim.y[i]))
	end
	-ll
end

# ╔═╡ 80b5d36e-281c-4915-9929-c3b088924358
pdf(Exponential(1), 2.0)

# ╔═╡ 302c8e0d-9db2-485b-b9fc-437327d1be45
begin
	lower = [0.0, 0.0, 0.0]
	upper = [250.0, 50.0, 10.0]
	x0 = [170.0, 10.0, 2.0]
end

# ╔═╡ 957b21a4-583c-472e-8a09-cf34a6d71cc0
res = optimize(loglik, lower, upper, x0)

# ╔═╡ ed8009b1-a3ba-4ea6-b408-ba358e6062d0
let
	mle = Optim.minimizer(res)
	lsq[:, 1] = mle
	estimate_comparison[!, :mle] = [Vector(i) for i in eachrow(lsq)]
	mle
end

# ╔═╡ 1fb54c4a-8148-44f2-a50e-da1d57ea78e3
md" ###### MLE estimate (using StanOptimize and 4 chains)"

# ╔═╡ 6e5e2cc2-dc9f-411c-b21b-e7cf1b0947a3
let
	data = (N=nrow(sim), y=sim.y, x=sim.x)
	o8_1s = OptimizeModel("m8_1s", stan8_1)
	rc8_1s = stan_optimize(o8_1s; data)
	result = success(rc8_1s) && read_optimize(o8_1s)
	global o8_1_df = DataFrame()
	for p in ["a", "b", "sigma"]
		o8_1_df[!, p] = result[1][p]
	end
	o8_1_df
end

# ╔═╡ b92c2a39-02ff-4af2-9f64-d7d60277634b
md" ###### Compare the four results."

# ╔═╡ 200b3b06-2341-4648-a908-fdfac308bf36
let
	lsq[:, 1] = mean(Array(o8_1_df); dims=1)
	estimate_comparison[!, :o8_1s] = [Vector(i) for i in eachrow(lsq)]
	estimate_comparison
end

# ╔═╡ 71e0c365-79dd-40ad-b9ee-c3d9f84a757c
loglik([45.6, 3.25, 4.4])

# ╔═╡ 6034ad40-242d-4b6b-8f9f-1941572ed079
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1])
	lines!(30:0.1:60, [-loglik([a, 3.25, 4.4]) for a in 30:0.1:60])
	ax = Axis(f[1, 2])
	lines!(0:0.1:5, [-loglik([46.5, b, 4.4]) for b in 0:0.1:5])
	f
end

# ╔═╡ d0b9e895-d5cb-4593-8b96-474f9b7cf635
loglik([45, 3, 4.4])

# ╔═╡ 0f0348e5-86b6-4b18-b997-d742b2a64636
distr8_1 = fit_mle(MvNormal, obs)

# ╔═╡ 8f3f5bb6-0813-401a-a99c-491f62ded4ec
mean(rand(distr8_1, 1000); dims=2)

# ╔═╡ 815acfd8-18e7-4c3e-a4df-e2fdb8a7ad78
loglikelihood(distr8_1, [3, 55])

# ╔═╡ 2a3715b5-27c0-47c3-bcde-2375d512c428
let
	a = collect(LinRange(30, 80, 50))
	b = collect(LinRange(0, 8, 50))
	global z = [loglikelihood(distr8_1, [b, a]) for a in a, b in b]
	m, i = findmax(z)
	maxz = [a[i[1]], b[i[1]], z[i]]
	println(maxz)
	wireframe(a, b, z, axis=(type=Axis3,))
end

# ╔═╡ 2e060389-0b27-4182-a871-a6bd889e746f
my_μ = [ms8_1s["a", "mean"], ms8_1s["b", "mean"]]

# ╔═╡ e6e8becb-30ed-48a8-9ac2-3470e4798778
my_Σ = cov([post8_1s.a post8_1s.b])

# ╔═╡ f5a8786b-1d88-4070-9ea1-abf2c4506523
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="(â, b̂) and covariance matrix derivative")
	lines!(getellipsepoints(my_μ, my_Σ)..., label="95% confidence interval of derivative", color=:black)
	lines!(getellipsepoints(my_μ, my_Σ, 0.5)..., label="50% confidence interval of derivative", color=:darkred)
	scatter!(post8_1s.a, post8_1s.b; markersize=4)
	axislegend(position=:rt)
	f
end

# ╔═╡ 09b4223c-ef55-4255-bd9b-91683ce3c3cb
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="(â, b̂) and covariance matrix derivative")
	poly!(Point2f.(zip(getellipsepoints(my_μ, my_Σ)...)); color=(:yellow, 0.5))
	poly!(Point2f.(zip(getellipsepoints(my_μ, my_Σ, 0.50)...)); color=(:lightgrey, 0.5))
	lines!(getellipsepoints(my_μ, my_Σ)..., label="95% confidence interval of derivative", color=:black)
	lines!(getellipsepoints(my_μ, my_Σ, 0.5)..., label="50% confidence interval of derivative", color=:darkred)
	scatter!(post8_1s.a, post8_1s.b; markersize=4)
	axislegend(position=:rt)
	f
end

# ╔═╡ 261db479-f8cf-42b3-86d8-547facbe32e9
md" ### 8.2 Influence of individual points in a fitted regression."

# ╔═╡ ff062913-8600-476a-a87d-3ea953364240
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="Regression line and influence of 20 selected observations", xlabel="x", ylabel="y")
	x_range = LinRange(minimum(sim.x), maximum(sim.x), 200)
	y_res = mean.(link(post8_1s, (r,x) -> r.a + x * r.b, x_range))
	select_obs = 1:10:200
	scatter!(sim.x[select_obs], sim.y[select_obs]; markersize=4)
	lines!(x_range, y_res; color=:darkred)
	for ind in select_obs
		ymin = min(sim.y[ind], y_res[ind])
		ymax = max(sim.y[ind], y_res[ind])
		lines!([sim.x[ind], sim.x[ind]], [ymin, ymax]; color=:lightgrey)
	end
	f
end

# ╔═╡ 6ef207a8-ed88-41a9-b5fe-e3b2f9437362
md" ### 8.3 Least squares slope as a weighted average of slopes of pairs."

# ╔═╡ 9c342d3b-eed4-4665-9211-6543030be4db
let
	s1 = sum([(sim.x[i]-sim.x[j]) * (sim.y[i]-sim.y[j]) for i in 1:length(sim.x), j in 1:length(sim.y)])
	s2 = sum([(sim.x[i]-sim.x[j])^2 for i in 1:length(sim.x), j in 1:length(sim.y)])
	(weighted_slopes = round(s1/s2; digits=5), least_squares=estimate_comparison[2, :least_squares])
end

# ╔═╡ b300c3e8-db6b-4369-bace-ba8ef1e5cb35
md" ### 8.4 Comparing two fitting functions: `glm` and `stan_sample`."

# ╔═╡ e01b2475-ef68-48a8-9e80-7b17a5e2848d
stan8_2 = "
data {
	int<lower=1> N;    	// total number of observations
	vector[N] x;    	// Independent variable: growth
	vector[N] y;      	// Dependent variable: votes 
}
parameters {
	real b;              // Coefficient independent variable
	real a;              // Intercept
	real<lower=0> sigma; // dispersion parameter
}
model {
	vector[N] mu;

	// priors including constants
	a ~ normal(0, 50);
	b ~ normal(0, 50);
  	sigma ~ uniform(0, 50);

	mu = a + b * x;

	// likelihood including constants
	y ~ normal(mu, sigma);
}";

# ╔═╡ 2c931278-db26-4ed6-9ddf-06b901fccf26
let
	x = LinRange(1, 10, 10)
	y = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
	global fake = DataFrame(x = x, y = y)
	data = (N = nrow(fake), x = fake.x, y = fake.y)
	global m8_2s = SampleModel("m8_2s", stan8_2)
	global rc8_2s = stan_sample(m8_2s; data)
	success(rc8_2s) && describe(m8_2s)
end

# ╔═╡ ebea0c5b-fa4d-4bad-8966-ef25b084ebf5
if success(rc8_2s)
	post8_2s = read_samples(m8_2s, :dataframe)
	ms8_2s = model_summary(post8_2s, [:a, :b, :sigma])
end

# ╔═╡ 2eddfc5f-75dd-44c8-8032-925288fe6fb9
quantile(post8_2s.b, [0.025, 0.975])

# ╔═╡ 77f16b11-a425-4214-b59a-f7e2aa21af78
quantile(post8_2s.b, [0.05, 0.95])

# ╔═╡ 3ad4cc33-75f0-4068-a848-59f6cd1e928c
fake_lm = lm(@formula(y ~ x), fake)

# ╔═╡ Cell order:
# ╟─53cabf93-4721-4a94-8cf2-0027d6956c3d
# ╟─80654ee5-415a-4d0f-a3e9-7aba64dbdaed
# ╠═8dec7b41-6a63-40c4-8e85-2e57b10f418c
# ╠═a7e8b8f4-e5c6-4203-8b10-db83c49f14fd
# ╠═117bce29-5156-434a-9cfd-400e27703682
# ╟─9553193f-f338-470c-892c-2745ccac23a9
# ╠═670da67b-fa90-41b9-99c1-e1aa403cb49e
# ╟─5c1dee90-d13a-4069-83b2-b6939ae98862
# ╠═59b3a003-5a89-418f-96c5-7970bfbb2602
# ╠═2239ac13-f219-4307-b90b-bd88518793ee
# ╠═8afd6e0c-fdb1-45a3-b0a4-7080c9fd8b20
# ╠═cf572844-7459-44a5-921c-0756d3bed89e
# ╠═b2e11cbd-2d58-45cc-a559-f35352872025
# ╠═2393509b-bcae-4b6b-a552-ac5fba8fba3c
# ╠═e4beb669-2a0f-4461-a2bf-fbd2691af3f6
# ╠═e4c3b43a-0284-415f-a266-1be1a8750be9
# ╟─10b2181b-e48d-44e8-8a8f-d45330def40d
# ╠═39471f16-b364-41f4-bd57-42c4c5ac4e3f
# ╠═10e19c62-edfe-456f-892a-03d17c6036ab
# ╠═86be6ea3-e6ed-4616-893f-bc75ea799113
# ╟─0f8587a5-fc88-4931-8e32-7d68dfcfc6e7
# ╠═e8ab3389-de0b-4f54-b12d-5baac6820079
# ╠═80b5d36e-281c-4915-9929-c3b088924358
# ╠═302c8e0d-9db2-485b-b9fc-437327d1be45
# ╠═957b21a4-583c-472e-8a09-cf34a6d71cc0
# ╠═ed8009b1-a3ba-4ea6-b408-ba358e6062d0
# ╟─1fb54c4a-8148-44f2-a50e-da1d57ea78e3
# ╠═6e5e2cc2-dc9f-411c-b21b-e7cf1b0947a3
# ╟─b92c2a39-02ff-4af2-9f64-d7d60277634b
# ╠═200b3b06-2341-4648-a908-fdfac308bf36
# ╠═71e0c365-79dd-40ad-b9ee-c3d9f84a757c
# ╠═6034ad40-242d-4b6b-8f9f-1941572ed079
# ╠═d0b9e895-d5cb-4593-8b96-474f9b7cf635
# ╠═3d06f09a-c972-474b-8e57-c396cefb5e22
# ╠═0f0348e5-86b6-4b18-b997-d742b2a64636
# ╠═8f3f5bb6-0813-401a-a99c-491f62ded4ec
# ╠═815acfd8-18e7-4c3e-a4df-e2fdb8a7ad78
# ╠═2a3715b5-27c0-47c3-bcde-2375d512c428
# ╠═2e060389-0b27-4182-a871-a6bd889e746f
# ╠═e6e8becb-30ed-48a8-9ac2-3470e4798778
# ╠═f5a8786b-1d88-4070-9ea1-abf2c4506523
# ╠═09b4223c-ef55-4255-bd9b-91683ce3c3cb
# ╟─261db479-f8cf-42b3-86d8-547facbe32e9
# ╠═ff062913-8600-476a-a87d-3ea953364240
# ╟─6ef207a8-ed88-41a9-b5fe-e3b2f9437362
# ╠═9c342d3b-eed4-4665-9211-6543030be4db
# ╟─b300c3e8-db6b-4369-bace-ba8ef1e5cb35
# ╠═e01b2475-ef68-48a8-9e80-7b17a5e2848d
# ╠═2c931278-db26-4ed6-9ddf-06b901fccf26
# ╠═ebea0c5b-fa4d-4bad-8966-ef25b084ebf5
# ╠═2eddfc5f-75dd-44c8-8032-925288fe6fb9
# ╠═77f16b11-a425-4214-b59a-f7e2aa21af78
# ╠═3ad4cc33-75f0-4068-a848-59f6cd1e928c
