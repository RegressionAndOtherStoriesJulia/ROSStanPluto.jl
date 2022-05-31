### A Pluto.jl notebook ###
# v0.19.5

using Markdown
using InteractiveUtils

# ╔═╡ 5084b8f0-65ac-4704-b1fc-2a9008132bd7
using Pkg, DrWatson

# ╔═╡ ee654cbd-61d2-48a7-a1b7-ed05d45517e5
begin
	# Specific to this notebook
    using Random, GLM

	# Specific to ROSStanPluto
    using StanSample
	
	# Graphics related
    using GLMakie
    using Makie

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ 0391fc17-09b7-47d7-b799-6dc6de13e82b
md"## Simple causal: causal.jl"

# ╔═╡ eb7ea04a-da52-4e69-ac3e-87dc7f014652
md"##### See Chapter 1.3, Figures 1.5, 1.6 & 1.8 in Regression and Other Stories."

# ╔═╡ 669ddd0f-8192-4436-8405-6270be8642db
md" ##### Widen the cells."

# ╔═╡ 6d979419-40f4-425f-89d2-ee7d499aa743
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

# ╔═╡ 4755dab0-d228-41d3-934a-56f2863a5652
md"###### Included Julia packages."

# ╔═╡ a80b9f49-5949-494c-80e1-153b6973db62
stan1_2 = "
data {
	int N;
	vector[N] x;
	vector[N] x_binary;
	vector[N] y;
}
parameters {
	vector[2] a;
	vector[2] b;
	vector[2] sigma;
}
model {
	// Priors
	a ~ normal(10, 10);
	b ~ normal(10, 10);
	sigma ~ exponential(1);
	// Likelihood
	y ~ normal(a[1] + b[1] * x, sigma[1]);
	y ~ normal(a[2] + b[2] * x_binary, sigma[2]);
}
";

# ╔═╡ 5fdc1b11-ce9b-4f67-8e2e-5ab22cd75b70
md"
!!! note

Aki Vehtari did not include a seed number in his code.
"

# ╔═╡ e079cc5a-a5cf-48d4-b954-1a652872aeb5
begin
	Random.seed!(123)
	n = 50
	x = rand(Uniform(1, 5), n)
	x_binary = [x[i] < 3 ? 0 : 1 for i in 1:n]
	y = [rand(Normal(10 + 3x[i], 3), 1)[1] for i in 1:n]
end;

# ╔═╡ 7001ad1f-419b-448e-bacf-f79995d533ee
begin
	data1_2 = (N = n, x = x, x_binary = x_binary, y = y)
	m1_2s = SampleModel("m1.2s", stan1_2);
	rc1_2 = stan_sample(m1_2s; data=data1_2)
end;

# ╔═╡ 20dea214-9997-4a6e-8d15-7a2bc42d33b6
if success(rc1_2)
	post1_2s = read_samples(m1_2s, :dataframe)
	mod_sum = model_summary(post1_2s, Symbol.(names(post1_2s)))
end

# ╔═╡ be8ef59e-ba27-4432-8eed-99834498c5f3
let
	x1 = 1.0:0.01:5.0
	f = Figure()
	medians = mod_sum[:, :median]
	ax = Axis(f[1, 1], title = "Regression with continuous treatment",
		xlabel = "Treatment", ylabel = "Outcome")
	sca1 = scatter!(x, y)
	annotations!("Slope of fitted line = $(round(medians[3], digits=2))",
		position = (2.8, 10), textsize=15)
	lin1 = lines!(x1, medians[1] .+ medians[3] * x1)

	x2 = 0.0:0.01:1.0
	ax = Axis(f[2, 1], title="Regression with binary treatment",
		xlabel = "Treatment", ylabel = "Outcome")
	sca1 = scatter!(x_binary, y)
	lin1 = lines!(x2, medians[2] .+ medians[4] * x2)
	annotations!("Slope of fitted line = $(round(medians[4], digits=2))", 
		position = (0.4, 12), textsize=15)
	f
end

# ╔═╡ 9b74c1e7-0a76-4c38-afdc-0a2f3959614c
stan1_3 = "
data {
	int N;
	vector[N] x;
	vector[N] y;
}
parameters {
	vector[2] a;
	real b;
	real b_exp;
	vector[2] sigma;
}
model {
	// Priors
	a ~ normal(10, 5);
	b ~ normal(0, 5);
	b_exp ~ normal(5, 5);
	sigma ~ exponential(1);
	// Likelihood
	vector[N] mu;
	for ( i in 1:N )
		mu[i] = a[2] + b_exp * exp(-x[i]);
	y ~ normal(mu, sigma[2]);
	y ~ normal(a[1] + b * x, sigma[1]);
}
";

# ╔═╡ d780afbc-1e3f-41dd-b021-c7d85c319510
begin
	#Random.seed!(1533)
	n1 = 50
	x1 = rand(Uniform(1, 5), n1)
	y1 = [rand(Normal(5 + 30exp(-x1[i]), 2), 1)[1] for i in 1:n]
	data1_3 = (N = n1, x = x1, y = y1)
	m1_3s = SampleModel("m1.3s", stan1_3);
	rc1_3 = stan_sample(m1_3s; data=data1_3)
end;

# ╔═╡ 69e721e2-41cb-4cf3-ae09-e34b64bba55e
if success(rc1_3)
	df1_3s = read_samples(m1_3s, :dataframe)
end

# ╔═╡ e0a7d4aa-9236-40a6-867e-2eb9cac304fe
â₁, â₂, b̂, b̂ₑₓₚ, σ̂₁, σ̂₂ = median(Array(df1_3s); dims=1)

# ╔═╡ 1b81bb06-d52e-4153-b428-db9fc3d89b73
let
	x1 = 1.0:0.1:5.9
	f = Figure()
	ax = Axis(f[1, 1], title = "Linear regression",
		xlabel = "Treatments", ylabel = "Outcomes")
	scatter!(x1, y1)
	lines!(x1, â₁ .+ b̂ .* x1)

	ax = Axis(f[2, 1], title = "Non-linear regression",
		xlabel = "Treatments", ylabel = "Outcomes")
	scatter!(x1, y1)
	lines!(x1, â₂ .+ b̂ₑₓₚ .* exp.(-x1))
	f
end

# ╔═╡ d2c54e59-99dc-45a8-b7f9-602e63b74a29
begin
	Random.seed!(12573)
	n2 = 100
	z = repeat([0, 1]; outer=50)
	df1_8 = DataFrame()
	df1_8.xx = [(z[i] == 0 ? rand(Normal(0, 1.2), 1).^2 : rand(Normal(0, 0.8), 1).^2)[1] for i in 1:n2]
	df1_8.z = z
	df1_8.yy = [rand(Normal(20 .+ 5df1_8.xx[i] .+ 10df1_8.z[i], 3), 1)[1] for i in 1:n2]
	df1_8
end

# ╔═╡ fa40d0f3-3c0a-4e28-80d2-a2d42a75d500
lm1_8 = lm(@formula(yy ~ xx + z), df1_8)

# ╔═╡ 92b603e2-0fdd-441e-977e-58abff496f9d
lm1_8_0 = lm(@formula(yy ~ xx), df1_8[df1_8.z .== 0, :])

# ╔═╡ 0ece515b-5b52-4165-ac3b-dca290753c38
lm1_8_1 = lm(@formula(yy ~ xx), df1_8[df1_8.z .== 1, :])

# ╔═╡ c1ad9a76-7427-4bb5-88b2-a46467b18523
let
	â₁, b̂₁ = coef(lm1_8_0)
	â₂, b̂₂ = coef(lm1_8_1)
	x = range(0, maximum(df1_8.xx), length=40)
	
	f = Figure()
	ax = Axis(f[1, 1]; title="Figure 1.8")
	scatter!(df1_8.xx[df1_8.z .== 0], df1_8.yy[df1_8.z .== 0])
	scatter!(df1_8.xx[df1_8.z .== 1], df1_8.yy[df1_8.z .== 1])
	lines!(x, â₁ .+ b̂₁ * x, label = "Control")
	lines!(x, â₂ .+ b̂₂ * x, label = "Treated")
	axislegend(; position=(:right, :bottom))
	current_figure()
end

# ╔═╡ Cell order:
# ╠═0391fc17-09b7-47d7-b799-6dc6de13e82b
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╠═669ddd0f-8192-4436-8405-6270be8642db
# ╠═6d979419-40f4-425f-89d2-ee7d499aa743
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═ee654cbd-61d2-48a7-a1b7-ed05d45517e5
# ╠═a80b9f49-5949-494c-80e1-153b6973db62
# ╟─5fdc1b11-ce9b-4f67-8e2e-5ab22cd75b70
# ╠═e079cc5a-a5cf-48d4-b954-1a652872aeb5
# ╠═7001ad1f-419b-448e-bacf-f79995d533ee
# ╠═20dea214-9997-4a6e-8d15-7a2bc42d33b6
# ╠═be8ef59e-ba27-4432-8eed-99834498c5f3
# ╠═9b74c1e7-0a76-4c38-afdc-0a2f3959614c
# ╠═d780afbc-1e3f-41dd-b021-c7d85c319510
# ╠═69e721e2-41cb-4cf3-ae09-e34b64bba55e
# ╠═e0a7d4aa-9236-40a6-867e-2eb9cac304fe
# ╠═1b81bb06-d52e-4153-b428-db9fc3d89b73
# ╠═d2c54e59-99dc-45a8-b7f9-602e63b74a29
# ╠═fa40d0f3-3c0a-4e28-80d2-a2d42a75d500
# ╠═92b603e2-0fdd-441e-977e-58abff496f9d
# ╠═0ece515b-5b52-4165-ac3b-dca290753c38
# ╠═c1ad9a76-7427-4bb5-88b2-a46467b18523
