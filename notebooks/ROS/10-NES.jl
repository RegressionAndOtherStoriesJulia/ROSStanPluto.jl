### A Pluto.jl notebook ###
# v0.19.36

using Markdown
using InteractiveUtils

# ╔═╡ 2194fb02-a53d-45a5-8d07-b480ae8eb20e
using Pkg

# ╔═╡ 7682365a-bb24-4fb2-a679-4c37dc6c178e
Pkg.activate(expanduser("~/.julia/dev/SR2StanPluto"))

# ╔═╡ e7199343-953b-4979-8b0e-2c6e876b4815
begin
	using GLM

	using CairoMakie

	using StanSample
	using RegressionAndOtherStories
end

# ╔═╡ 0d93db8a-7dd6-4be5-9675-f26081e25f5d
html"""
<style>
	main {
		margin: 0 auto;
		max-width: 2000px;
    	padding-left: max(160px, 5%);
    	padding-right: max(160px, 10%);
	}
</style>
"""

# ╔═╡ d1280ea4-8e72-4d4c-8da7-6d491fbe3a32
ros_path()

# ╔═╡ 2a0065d1-ff80-4a66-8f4d-3c65f9cf0143
nes = CSV.read("/Users/rob/.julia/dev/RegressionAndOtherStories/data/NES/nes.csv", DataFrame)

# ╔═╡ 0b78387a-0a24-4e6e-8eb4-35bf2c449faa
pwd()

# ╔═╡ dfeb5204-0312-477b-b41e-f7e6cfa66060
ros_datadir("NES", "nes.csv")

# ╔═╡ cc0354a3-3dbc-4502-a914-69589df239a8
begin
	lr = DataFrame(year=nes.year, income=Float64.(nes.income), rvote=nes.rvote, dvote=nes.dvote)
	lr = filter(x -> !(x.year < 1992 || x.year > 1992), lr)
	lr = filter(x -> !(x.dvote == 1 && x.rvote == 1), lr)
	lr = filter(x -> !(x.rvote == "NA" || x.dvote == "NA"), lr)
	lr.rvote = Meta.parse.(String.(lr.rvote))
	lr.dvote = Meta.parse.(String.(lr.dvote))
	lr = filter(x -> !(x.dvote == 0 && x.rvote == 0), lr)
	lrd = filter(x -> !(x.rvote == 1 && x.dvote == 0), lr)
	lrr = filter(x -> !(x.dvote == 1 && x.rvote == 0), lr)
	lr
end

# ╔═╡ 0f5e2801-51e3-42d3-ba85-07e412fa59c8
lr[3, :rvote] == "NA"

# ╔═╡ 83e8ba59-4b7f-47f1-8a2b-27b4d914f754
unique(lr.income)

# ╔═╡ 01a99ec9-c988-4f67-9ad8-7529e9edb512
unique(lr.year)

# ╔═╡ 95446053-615b-48eb-8f9f-d744e1b38fa7
genlm = glm(@formula(rvote ~ 1 + income), lr, Binomial(2.0), LogitLink())

# ╔═╡ ea620ba2-af94-4033-883a-a5088eb73c47
coef(genlm)

# ╔═╡ 8bcb015b-c960-4bfe-ba26-6587caf51db4
let
	fig = Figure(;size=default_figure_resolution)
	xlabel = "Income"
	ylabel = "Presidential vote"
	let
		ax = Axis(fig[1, 1]; xlabel, ylabel)
		scatter!(jitter.(Float64.(lrd.income), 0.1), jitter.(Float64.(lrd.rvote), 0.1), markersize=3,
			color=:darkblue)
		scatter!(jitter.(Float64.(lrr.income), 0.1), jitter.(Float64.(lrr.rvote), 0.1), markersize=3,
			color=:darkred)
	end
	fig
end


# ╔═╡ bfce1b38-d1bc-4f20-a616-6e2e2f9bf932
logit(x) = log(x/(1-x))

# ╔═╡ 5c952e72-bcae-4ffb-9e75-ceba3fac7e4e
invlogit(x) = exp(x) / (1 + exp(x))

# ╔═╡ 58ddf53b-2c9f-4ce0-aab8-fd34105faa25
invlogit2(x) = 1 / (1 + exp(-x))

# ╔═╡ a1a15848-303b-430f-97d3-efb20397e405
let
	fig = Figure(;size=default_figure_resolution)
	xlabel = "x"
	ylabel = "invlogit(x)"
	x = -10:0.1:10
	ax = Axis(fig[1, 1]; xlabel, ylabel)
	lines!(x, [invlogit(x[i]) for i in 1:length(x)])
	lines!(x, [invlogit2(x[i]) for i in 1:length(x)], linestyle=:dash)
	fig
end

# ╔═╡ f1169732-1df1-43ee-b296-1432ebbf21bc
logit(0.5)

# ╔═╡ 8f06aa47-5096-46e0-beaa-15e1f8108d92
invlogit(0)

# ╔═╡ bb5e41ef-ffff-413f-9b6b-2f81c08af9c1
invlogit2(0)

# ╔═╡ 9357e8a1-8dc8-4021-b5fb-0d097f8c2628
stan01 = "
data {
  int<lower=0> N;
  vector[N] x;
  array[N] int<lower=0, upper=1> y;
}
parameters {
  real alpha;
  real beta;
}
model {
  y ~ bernoulli_logit(alpha + beta * x);
}";

# ╔═╡ cb17ed07-c288-40ac-94b9-6a4695c578c3
begin
	data = (N=nrow(lr), x=lr.income, y=lr.rvote)
	sm = SampleModel("presvote", stan01)
	rc = stan_sample(sm; data)
	if success(rc)
		df = read_samples(sm, :dataframe)
		ms = model_summary(df, [:alpha, :beta])
	end
end

# ╔═╡ 59a49bde-c43f-4f92-b9ca-128e96b24afb
let
	fig = Figure(;size=default_figure_resolution)
	xlabel = "Income"
	ylabel = "Presidential vote"
	x = -5:0.1:10
	x1 = 0.5:0.1:5.5
	let
		ax = Axis(fig[1, 1]; xlabel, ylabel)
		scatter!(jitter.(Float64.(lrd.income), 0.1), jitter.(Float64.(lrd.rvote), 0.05), markersize=3,
			color=:darkblue)
		scatter!(jitter.(Float64.(lrr.income), 0.1), jitter.(Float64.(lrr.rvote), 0.05), markersize=3,
			linestyle=:solid, color=:darkred)

		ylims!(0, 1)
		for i in 1:400:4000
			lines!(x, [invlogit(df.alpha[i] + df.beta[i] * x[j]) for j in 1:length(x)], color=:lightgrey)
		end			
		lines!(x, [invlogit(mean(df.alpha) + mean(df.beta) * x[j]) for j in 1:length(x)], color=:darkblue)
		lines!(x1, [invlogit(mean(df.alpha) + mean(df.beta) * x1[j]) for j in 1:length(x1)], linewidth=4, 
			color=:darkblue)
		lines!(x1, [invlogit(coef(genlm)[1] + coef(genlm)[2] * x1[j]) for j in 1:length(x1)], linewidth=4, 
			color=:darkred)
	end
	fig
end


# ╔═╡ 383ea358-6050-4c26-8c71-19db042f74f2
invlogit(0.082)

# ╔═╡ Cell order:
# ╠═2194fb02-a53d-45a5-8d07-b480ae8eb20e
# ╠═7682365a-bb24-4fb2-a679-4c37dc6c178e
# ╠═e7199343-953b-4979-8b0e-2c6e876b4815
# ╠═0d93db8a-7dd6-4be5-9675-f26081e25f5d
# ╠═d1280ea4-8e72-4d4c-8da7-6d491fbe3a32
# ╠═2a0065d1-ff80-4a66-8f4d-3c65f9cf0143
# ╠═0b78387a-0a24-4e6e-8eb4-35bf2c449faa
# ╠═dfeb5204-0312-477b-b41e-f7e6cfa66060
# ╠═cc0354a3-3dbc-4502-a914-69589df239a8
# ╠═0f5e2801-51e3-42d3-ba85-07e412fa59c8
# ╠═83e8ba59-4b7f-47f1-8a2b-27b4d914f754
# ╠═01a99ec9-c988-4f67-9ad8-7529e9edb512
# ╠═95446053-615b-48eb-8f9f-d744e1b38fa7
# ╠═ea620ba2-af94-4033-883a-a5088eb73c47
# ╠═8bcb015b-c960-4bfe-ba26-6587caf51db4
# ╠═bfce1b38-d1bc-4f20-a616-6e2e2f9bf932
# ╠═5c952e72-bcae-4ffb-9e75-ceba3fac7e4e
# ╠═58ddf53b-2c9f-4ce0-aab8-fd34105faa25
# ╠═a1a15848-303b-430f-97d3-efb20397e405
# ╠═f1169732-1df1-43ee-b296-1432ebbf21bc
# ╠═8f06aa47-5096-46e0-beaa-15e1f8108d92
# ╠═bb5e41ef-ffff-413f-9b6b-2f81c08af9c1
# ╠═9357e8a1-8dc8-4021-b5fb-0d097f8c2628
# ╠═cb17ed07-c288-40ac-94b9-6a4695c578c3
# ╠═59a49bde-c43f-4f92-b9ca-128e96b24afb
# ╠═383ea358-6050-4c26-8c71-19db042f74f2
