### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 5084b8f0-65ac-4704-b1fc-2a9008132bd7
using Pkg, DrWatson

# ╔═╡ f71640c9-3918-475e-b32b-c85424bbcf5e
begin
	using GLM

	using StanSample
	
	# Graphics related
    using GLMakie
    using Makie
	using AlgebraOfGraphics

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ 17034ac2-d8da-40a4-a899-5c4e10877945
md"## See chapter 9 in Regression and Other Stories."

# ╔═╡ 262d5b57-4322-4e66-918f-edc0727e190e
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


# ╔═╡ 09298360-8bbe-4274-a0be-b7ad89f8f767
md" ### 9.1 Propagating uncertainty in inference using posterior simulations."

# ╔═╡ 2fb45a4e-33ad-461a-a973-54598c2154fb
hibbs = CSV.read(ros_datadir("ElectionsEconomy", "hibbs.csv"), DataFrame)

# ╔═╡ 440959ad-b440-4b56-b902-91410c158809
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

# ╔═╡ 3615736b-e80a-42b8-ad48-1b3c0d876bea
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

# ╔═╡ 2c6e3c52-3f32-4e68-b29e-444adbf5a019
let
	data = (N=nrow(hibbs), vote=hibbs.vote, growth=hibbs.growth)
	global m7_1s = SampleModel("hibbs", stan7_1)
	global rc7_1s = stan_sample(m7_1s; data)
	success(rc7_1s) && model_summary(m7_1s)
end

# ╔═╡ d16d75f4-0258-494e-985f-9c77141f4f82
post7_1s = success(rc7_1s) && read_samples(m7_1s, :dataframe)

# ╔═╡ 239e75f6-0c45-49c9-b31d-6c5c54bc4f6a
trankplot(post7_1s, "b")

# ╔═╡ ffdc6a1c-b1bb-428c-ba3a-74a3a1daa1bf
ms7_1s = model_summary(post7_1s, [:a, :b, :sigma])

# ╔═╡ a59a4aaa-a65e-4c77-adee-cb1b0bfda318
sims = Array(post7_1s)

# ╔═╡ 14ed6a4f-3ba5-408d-8e14-9ee67202c449
median(sims; dims=1)

# ╔═╡ f89d5f4b-2648-480b-99ee-0807eb5c07a5
let
	f = Figure()
	ax = Axis(f[1, 1]; title="Density :a", subtitle="+/- 1 std err = blue, +/- 2 std err = yellow")
	hist!(post7_1s.a; bins=15, color = :white, strokewidth = 1, strokecolor = :grey)
	#vlines!([ms7_1s[:a, :median] - ms7_1s[:a, :mad_sd], ms7_1s[:a, :median] + ms7_1s[:a, :mad_sd]]; linewidth=3)
	hlines!(ax, 400; xmin=0.40, xmax=0.62, linewidth=3)
	#vlines!([ms7_1s[:a, :median] - 2ms7_1s[:a, :mad_sd], ms7_1s[:a, :median] + 2ms7_1s[:a, :mad_sd]]; linewidth=3)
	hlines!(ax, 200; xmin=0.30, xmax=0.72, linewidth=3)

	ax = Axis(f[1, 2]; title="Density :b", subtitle="+/- 1 std err = blue, +/- 2 std err = yellow")
	hist!(post7_1s.b; bins=15, color = :white, strokewidth = 1, strokecolor = :grey)
	#vlines!([ms7_1s[:b, :median] - ms7_1s[:b, :mad_sd], ms7_1s[:b, :median] + ms7_1s[:b, :mad_sd]]; linewidth=3)
	hlines!(ax, 400; xmin=0.335, xmax=0.55, linewidth=3)
	#vlines!([ms7_1s[:b, :median] - 2ms7_1s[:b, :mad_sd], ms7_1s[:b, :median] + 2ms7_1s[:b, :mad_sd]]; linewidth=3)
	hlines!(ax, 200; xmin=0.23, xmax=0.66, linewidth=3)
	f
end

# ╔═╡ 81a07ee9-5b5f-4880-8c88-aa2d9c700d8d


# ╔═╡ 6da20da7-28f0-4930-8165-419ba7df337a
let
	growth_range = LinRange(minimum(hibbs.growth), maximum(hibbs.growth), 200)
	votes = mean.(link(post7_1s, (r,x) -> r.a + x * r.b, growth_range))

	xlabel = "Average growth personal income [%]"
	ylabel = "Incumbent's party vote share"

	fig = Figure()

	ax = Axis(fig[1, 1]; title="Plot the mcmc draws for :a and :b", xlabel=":a", ylabel=":b")
	scatter!(post7_1s.a, post7_1s.b; markersize=4)

	xlabel = "Average growth personal income [%]"
	ylabel="Incumbent's party vote share"
	ax = Axis(fig[1, 2]; title="Regression line based on 4000 posterior samples", 
		subtitle = "(grey lines are based on first 200 draws of :a and :b)",
		xlabel, ylabel)
	for i in 1:100
		lines!(growth_range, post7_1s.a[i] .+ post7_1s.b[i] .* growth_range, color = :lightgrey)
	end
	scatter!(hibbs.growth, hibbs.vote)
	lines!(growth_range, votes, color = :red)
	fig
end

# ╔═╡ ae84cab6-c439-49b2-9028-9c2fed142833
md" ### 9.2 Prediction and uncertainty."

# ╔═╡ 28ad5de7-c040-4e82-abc0-c4bbd50f2207
let
	x = LinRange(-2, 2, 5)
	y = [50, 44, 50, 47, 56]
	global sexratio = DataFrame(x = x, y = y)
end

# ╔═╡ f0f4e685-8cfd-4c8d-b93a-a4b04c3ef2c4
stan9_1 = "
data {
	int<lower=1> N; // total number of observations
	vector[N] x;    // Independent variable: growth
	vector[N] y;    // Dependent variable: votes 
}
parameters {
	real b;              // Coefficient independent variable
	real a;              // Intercept
	real<lower=0> sigma; // dispersion parameter
}
model {
	vector[N] mu;

	// priors including constants
	a ~ normal(50, 5);
	b ~ normal(0, 5);
  	sigma ~ uniform(0, 10);

	mu = a + b * x;

	// likelihood including constants
	y ~ normal(mu, sigma);
}";

# ╔═╡ 716cd60e-d66b-4fd0-9143-9d77e0cfd3b4
let
	data = (N = nrow(sexratio), x = sexratio.x, y = sexratio.y)
	global m9_1s = SampleModel("m9_1s", stan9_1)
	global rc9_1s = stan_sample(m9_1s; data)
	success(rc9_1s) && model_summary(m9_1s)
end

# ╔═╡ 7951b61f-b423-4ac4-a728-70c8bb6c60c8
if success(rc9_1s)
	post9_1s = read_samples(m9_1s, :dataframe)
	sm9_1s = model_summary(post9_1s, [:a, :b, :sigma])
end

# ╔═╡ e1bec0a3-1319-4fb2-be67-e6a91b57dae7
let
	x_range = LinRange(minimum(sexratio.x), maximum(sexratio.x), 200)
	y = mean.(link(post9_1s, (r,x) -> r.a + x * r.b, x_range))

	xlabel = "x"
	ylabel = "y"

	fig = Figure()

	ax = Axis(fig[1, 1]; title="Posterior simulation under default prior", xlabel="Intercept, a", ylabel="Slope, b")
	scatter!(post9_1s.a, post9_1s.b; markersize=4)

	ax = Axis(fig[1, 2]; title="Bayes regression (4000 posterior samples)", 
		subtitle = "(grey lines are based on first 100 draws of a and b)",
		xlabel, ylabel)
	for i in 1:100
		lines!(x_range, post9_1s.a[i] .+ post9_1s.b[i] .* x_range, color = :lightgrey)
	end
	scatter!(sexratio.x, sexratio.y)
	lines!(x_range, y, color = :red)
	fig
end

# ╔═╡ dffa112b-0741-4c7e-9067-70879f6b8d56
stan9_2 = "
data {
	int<lower=1> N; // total number of observations
	vector[N] x;    // Independent variable: growth
	vector[N] y;    // Dependent variable: votes 
}
parameters {
	real b;              // Coefficient independent variable
	real a;              // Intercept
	real<lower=0> sigma; // dispersion parameter
}
model {
	vector[N] mu;

	// priors including constants
	a ~ normal(48.8, 0.2);
	b ~ normal(0, 0.2);
  	sigma ~ uniform(0, 10);

	mu = a + b * x;

	// likelihood including constants
	y ~ normal(mu, sigma);
}";

# ╔═╡ 75963690-51cd-496c-b802-6095247de0b8
let
	data = (N = nrow(sexratio), x = sexratio.x, y = sexratio.y)
	global m9_2s = SampleModel("m9_2s", stan9_2)
	global rc9_2s = stan_sample(m9_2s; data)
	success(rc9_2s) && model_summary(m9_2s)
end

# ╔═╡ 028b5b0a-ba9f-40c0-b504-242e2aaa6d5d
if success(rc9_2s)
	post9_2s = read_samples(m9_2s, :dataframe)
	sm9_2s = model_summary(post9_2s, [:a, :b, :sigma])
end

# ╔═╡ 8df488d8-a241-48e8-bd1c-2ab73e6e0f63
let
	x_range = LinRange(minimum(sexratio.x), maximum(sexratio.x), 200)
	y = mean.(link(post9_2s, (r,x) -> r.a + x * r.b, x_range))

	xlabel = "x"
	ylabel = "y"

	fig = Figure()

	ax = Axis(fig[1, 1]; title="Posterior simulation under informative prior", xlabel="Intercept, a", ylabel="Slope, b")
	ylims!(ax, -8, 8)
	scatter!(post9_2s.a, post9_2s.b; markersize=4)

	ax = Axis(fig[1, 2]; title="Bayes regression (4000 posterior samples)", 
		subtitle = "(grey lines are based on first 100 draws of :a and :b)",
		xlabel, ylabel)
	for i in 1:100
		lines!(x_range, post9_2s.a[i] .+ post9_2s.b[i] .* x_range, color = :lightgrey)
	end
	scatter!(sexratio.x, sexratio.y)
	lines!(x_range, y, color = :red)
	fig
end

# ╔═╡ 391692d1-03ce-498b-83d6-66bb8f56bdac
md" ### 9.3 Prior information and Bayesian synthesis."

# ╔═╡ 32d7fdff-2e2e-485d-bab5-09d2358a446e
md"##### Prior based on a previously-fitted model using economic and political condition."

# ╔═╡ 62ee06b2-6ef9-4fb7-b194-f701250465ee
begin
	theta_hat_prior = 0.524
	se_prior = 0.041
end;

# ╔═╡ e8419e76-e251-429d-8e1f-9784dffcb78a
md"##### Survey of 400 people, of whom 190 say they will vote for the Democratic candidate."

# ╔═╡ 0acb8885-4178-4679-bf06-8fb6ff60e161
begin
	n = 400
	y = 190
end;

# ╔═╡ d8b54dc0-d091-467b-8025-2981c6342dad
md"##### Data estimate."

# ╔═╡ 6c6d2896-daef-4984-b028-04100643b9f9
theta_hat_data = y/n

# ╔═╡ 0d97580b-924d-4638-b228-0a7c4b67549f
se_data = √((y/n)*(1-y/n)/n)

# ╔═╡ a6797e8d-5d39-4bf6-981b-ed070cc28586
md"##### Bayes estimate."

# ╔═╡ aa58187a-739e-4b03-8ebe-19faef7473a1
theta_hat_bayes = (theta_hat_prior/se_prior^2 +
	theta_hat_data/se_data^2) /(1/se_prior^2 + 1/se_data^2)

# ╔═╡ 0a9b23e6-4022-433b-955c-7c84bd020bf1
se_bayes = sqrt(1/(1/se_prior^2 + 1/se_data^2))

# ╔═╡ 46a4817a-1587-4b26-98d0-b1da5e9f4673
let
	x = 0.3:0.001:0.7
	f = Figure()
	ax = Axis(f[1, 1], title="Prior, likelihood & posterior")
	prior = lines!(f[1, 1], x, pdf.(Normal(theta_hat_prior, se_prior), x), color=:gray)
	data = lines!(x, pdf.(Normal(theta_hat_data, se_data), x),color=:darkred)
	bayes = lines!(x, pdf.(Normal(theta_hat_bayes, se_bayes), x), color=:darkblue)
	Legend(f[1, 2], [prior, data, bayes], ["Prior", "Data", "Bayesian"])

	current_figure()
end

# ╔═╡ 883e8535-0b1e-491c-91ff-4cc21025de50
let
	f = Figure()
	ax = Axis(f[1, 1], title="Prior, likelihood & posterior (using `density()`)")
	density!(rand(Normal(theta_hat_prior, se_prior), Int(1e6)), lab="prior")
	density!(rand(Normal(theta_hat_data, se_data), Int(1e6)), lab="likelihood")
	density!(rand(Normal(theta_hat_bayes, se_bayes), Int(1e6)), lab="bayes")
	current_figure()
end

# ╔═╡ c9572931-3dda-403d-8a67-355c352927d8
md" ### 9.4 Example of Bayesian inference: beauty and sex ratio."

# ╔═╡ Cell order:
# ╟─17034ac2-d8da-40a4-a899-5c4e10877945
# ╠═262d5b57-4322-4e66-918f-edc0727e190e
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═f71640c9-3918-475e-b32b-c85424bbcf5e
# ╟─09298360-8bbe-4274-a0be-b7ad89f8f767
# ╠═2fb45a4e-33ad-461a-a973-54598c2154fb
# ╠═440959ad-b440-4b56-b902-91410c158809
# ╠═3615736b-e80a-42b8-ad48-1b3c0d876bea
# ╠═2c6e3c52-3f32-4e68-b29e-444adbf5a019
# ╠═d16d75f4-0258-494e-985f-9c77141f4f82
# ╠═239e75f6-0c45-49c9-b31d-6c5c54bc4f6a
# ╠═ffdc6a1c-b1bb-428c-ba3a-74a3a1daa1bf
# ╠═a59a4aaa-a65e-4c77-adee-cb1b0bfda318
# ╠═14ed6a4f-3ba5-408d-8e14-9ee67202c449
# ╠═f89d5f4b-2648-480b-99ee-0807eb5c07a5
# ╠═81a07ee9-5b5f-4880-8c88-aa2d9c700d8d
# ╠═6da20da7-28f0-4930-8165-419ba7df337a
# ╟─ae84cab6-c439-49b2-9028-9c2fed142833
# ╠═28ad5de7-c040-4e82-abc0-c4bbd50f2207
# ╠═f0f4e685-8cfd-4c8d-b93a-a4b04c3ef2c4
# ╠═716cd60e-d66b-4fd0-9143-9d77e0cfd3b4
# ╠═7951b61f-b423-4ac4-a728-70c8bb6c60c8
# ╠═e1bec0a3-1319-4fb2-be67-e6a91b57dae7
# ╠═dffa112b-0741-4c7e-9067-70879f6b8d56
# ╠═75963690-51cd-496c-b802-6095247de0b8
# ╠═028b5b0a-ba9f-40c0-b504-242e2aaa6d5d
# ╠═8df488d8-a241-48e8-bd1c-2ab73e6e0f63
# ╟─391692d1-03ce-498b-83d6-66bb8f56bdac
# ╟─32d7fdff-2e2e-485d-bab5-09d2358a446e
# ╠═62ee06b2-6ef9-4fb7-b194-f701250465ee
# ╟─e8419e76-e251-429d-8e1f-9784dffcb78a
# ╠═0acb8885-4178-4679-bf06-8fb6ff60e161
# ╟─d8b54dc0-d091-467b-8025-2981c6342dad
# ╠═6c6d2896-daef-4984-b028-04100643b9f9
# ╠═0d97580b-924d-4638-b228-0a7c4b67549f
# ╟─a6797e8d-5d39-4bf6-981b-ed070cc28586
# ╠═aa58187a-739e-4b03-8ebe-19faef7473a1
# ╠═0a9b23e6-4022-433b-955c-7c84bd020bf1
# ╠═46a4817a-1587-4b26-98d0-b1da5e9f4673
# ╠═883e8535-0b1e-491c-91ff-4cc21025de50
# ╟─c9572931-3dda-403d-8a67-355c352927d8
