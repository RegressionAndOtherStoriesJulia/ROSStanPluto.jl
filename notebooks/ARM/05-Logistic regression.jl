### A Pluto.jl notebook ###
# v0.19.36

using Markdown
using InteractiveUtils

# ╔═╡ 5084b8f0-65ac-4704-b1fc-2a9008132bd7
using Pkg

# ╔═╡ d7753cf6-7452-421a-a3ec-76e07646f808
Pkg.activate(expanduser("~/.julia/dev/SR2StanPluto"))

# ╔═╡ 550371ad-d411-4e66-9d63-7329322c6ea1
begin
    # Specific to this notebook
    using GLM
    using Statistics
	using ParetoSmoothedImportanceSampling

    # Specific to ROSStanPluto
    using StanSample
    
    # Graphics related
    using CairoMakie
    using AlgebraOfGraphics
    
    # Include basic packages
    using RegressionAndOtherStories
end

# ╔═╡ eb7ea04a-da52-4e69-ac3e-87dc7f014652
md"## 05-Logistic regression."

# ╔═╡ cf39df58-3371-4535-88e4-f3f6c0404500
md" ###### Widen the cells."

# ╔═╡ 0616ece8-ccf8-4281-bfed-9c1192edf88e
html"""
<style>
    main {
        margin: 0 auto;
        max-width: 2000px;
        padding-left: max(160px, 10%);
        padding-right: max(160px, 15%);
    }
</style>
"""

# ╔═╡ 4755dab0-d228-41d3-934a-56f2863a5652
md"###### A typical set of Julia packages to include in notebooks."

# ╔═╡ 0391fc17-09b7-47d7-b799-6dc6de13e82b
md"### 5.1  Logistic regression with one predictor."

# ╔═╡ ff959f21-c153-45b5-b0f5-10dd33e361ef
nes = CSV.read(arm_datadir("nes", "nes.csv"), DataFrame)

# ╔═╡ ebdcdfaa-4f80-4143-b322-9b4869ed63e0
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

# ╔═╡ 14d10efd-9877-439d-bdb7-d6ca4bfa31f1
lr[3, :rvote] == "NA"

# ╔═╡ 9716541d-b8a0-40f8-864e-998307a6538c
unique(lr.income)

# ╔═╡ 9d96ce6f-e39a-48a9-a8cc-519f236e6e94
unique(lr.year)

# ╔═╡ c5cf5bb3-c592-446f-89ea-47de31b50d6d
nes_lm = glm(@formula(rvote ~ 1 + income), lr, Binomial(2.0), LogitLink())

# ╔═╡ 057d0272-6bd5-4157-842d-f3f9527d937f
coef(nes_lm)

# ╔═╡ 0566ccb6-abd6-4236-8d8c-53d2cb0dd106
deviance(nes_lm)

# ╔═╡ 8938b5a8-88a7-400e-bf1f-e238d6215d1a
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

# ╔═╡ 241ecb94-3e40-4956-9a4c-da9dd2f011c2
logit(x) = log(x/(1-x))

# ╔═╡ 482f1759-d9d5-40ac-9eac-664ad600180f
invlogit(x) = exp(x) / (1 + exp(x))

# ╔═╡ ea229fa3-a0bd-421f-928f-6e52f5cf8fab
invlogit2(x) = 1 / (1 + exp(-x))

# ╔═╡ 1cc0814b-ba60-48bf-9257-520adf279484
let
	fig = Figure(; size=default_figure_resolution)
	xlabel = "x"
	ylabel = "invlogit(x)"
	x = -10:0.1:10
	ax = Axis(fig[1, 1]; xlabel, ylabel)
	lines!(x, [invlogit(x[i]) for i in 1:length(x)])
	lines!(x, [invlogit2(x[i]) for i in 1:length(x)], linestyle=:dash)
	fig
end

# ╔═╡ cd0b637d-a08a-467d-8b01-04681ca3d63d
logit(0.5)

# ╔═╡ 3f08cc02-f0c2-4462-b123-860c919adc08
invlogit(0)

# ╔═╡ a90b80ce-2109-4c97-a726-cf5f269f1cb6
invlogit2(0)

# ╔═╡ f426c57d-174c-4c90-a525-ea6e7007f3cf
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

# ╔═╡ c778d877-5e1a-4830-a038-969c1589fff5
let
	data = (N=nrow(lr), x=lr.income, y=lr.rvote)
	global nes_sm = SampleModel("presvote", stan01)
	nes_rc = stan_sample(nes_sm; data)
	if success(nes_rc)
		global nes_df = read_samples(nes_sm, :dataframe)
		global nes_ms = model_summary(nes_df, [:alpha, :beta])
	end
	success(nes_rc) && describe(nes_sm, [:lp__, :alpha, :beta])
end

# ╔═╡ 6377f893-f9a4-49a3-a778-9d3f4138b008
let
	fig = Figure(;size=default_figure_resolution)
	xlabel = "Income"
	ylabel = "Presidential vote"
	let
		x = -5:0.1:10
		x1 = 0.5:0.1:5.5
		ax = Axis(fig[1, 1]; xlabel, ylabel)
		scatter!(jitter.(Float64.(lrd.income), 0.1), jitter.(Float64.(lrd.rvote), 0.05), markersize=3,
			color=:darkblue)
		scatter!(jitter.(Float64.(lrr.income), 0.1), jitter.(Float64.(lrr.rvote), 0.05), markersize=3,
			linestyle=:solid, color=:darkred)

		ylims!(0, 1)
		for i in 1:400:4000
			lines!(x, [invlogit(nes_df.alpha[i] + nes_df.beta[i] * x[j]) for j in 1:length(x)], color=:lightgrey)
		end			
		lines!(x, [invlogit(mean(nes_df.alpha) + mean(nes_df.beta) * x[j]) for j in 1:length(x)], color=:darkblue)
		lines!(x1, [invlogit(mean(nes_df.alpha) + mean(nes_df.beta) * x1[j]) for j in 1:length(x1)], linewidth=4, 
			color=:darkblue)
		lines!(x1, [invlogit(coef(nes_lm)[1] + coef(nes_lm)[2] * x1[j]) for j in 1:length(x1)], linewidth=4, 
			color=:darkred)

		x = 0.5:0.1:5.5
		x1 = 1:0.1:5
		ax = Axis(fig[1, 2]; xlabel, ylabel, xticks=(1:2:5, ["poor", "medium", "rich"]))
		scatter!(jitter.(Float64.(lrd.income), 0.1), jitter.(Float64.(lrd.rvote), 0.05), markersize=3,
			color=:darkblue)
		scatter!(jitter.(Float64.(lrr.income), 0.1), jitter.(Float64.(lrr.rvote), 0.05), markersize=3,
			linestyle=:solid, color=:darkred)

		ylims!(0, 1)
		for i in 1:400:4000
			lines!(x, [invlogit(nes_df.alpha[i] + nes_df.beta[i] * x[j]) for j in 1:length(x)], color=:lightgrey)
		end			
		lines!(x, [invlogit(mean(nes_df.alpha) + mean(nes_df.beta) * x[j]) for j in 1:length(x)], color=:darkblue)
		lines!(x1, [invlogit(mean(nes_df.alpha) + mean(nes_df.beta) * x1[j]) for j in 1:length(x1)], linewidth=4, 
			color=:darkblue)
		lines!(x1, [invlogit(coef(nes_lm)[1] + coef(nes_lm)[2] * x1[j]) for j in 1:length(x1)], linewidth=4, 
			color=:darkred)

	end
	fig
end

# ╔═╡ 85438f53-668d-4a1d-9767-7791102c3ee4
md" ### 5.2 Interpreting the logistic regression coefficients."

# ╔═╡ f24bd557-f10c-4873-ae59-6e418e996ce6
round(invlogit(-1.4 + 0.33*3); digits=2)

# ╔═╡ 36d9e0e7-355a-4e37-bdab-dc30c5b1f177
[round(-1.4 + 0.33 * i; digits=2) for i in 1:5]

# ╔═╡ 0d5894dc-5576-4962-986b-d776e2145abd
[round(invlogit(-1.4 + 0.33*i); digits=2) for i in 1:5]

# ╔═╡ 432d993f-e2c7-49c8-854f-ca80bef7f0fd
nes_ms

# ╔═╡ 15e3b592-e7de-4e13-b8aa-a6a6d71e5e5b
round.([nes_ms[:beta, :mean] - 2nes_ms[:beta, :std], nes_ms[:beta, :mean] + 2nes_ms[:beta, :std]]; digits=2)

# ╔═╡ 21fe1b1a-e9f4-49af-91e6-fafa33121526
"Predicted probability of supporting Bush Pr(ỹ₅)=$(round(invlogit(-1.4 + 0.33 * 5); digits=2))"

# ╔═╡ 365e0470-7697-4720-a397-dd6b829dde92
"Predicted probability of supporting Bush Pr(ỹ₁)=$(round(invlogit(-1.4 + 0.33 * 1); digits=2))"

# ╔═╡ 26d71001-8a17-4c66-9b61-622d90f5036c
function select_year(df::DataFrame, yr::Int)
	lr = DataFrame(year=df.year, income=Float64.(df.income), rvote=df.rvote, dvote=df.dvote)
	lr = filter(x -> !(x.year < yr || x.year > yr), lr)
	lr = filter(x -> !(x.dvote == 1 && x.rvote == 1), lr)
	lr = filter(x -> !(x.rvote == "NA" || x.dvote == "NA"), lr)
	lr.rvote = Meta.parse.(String.(lr.rvote))
	lr.dvote = Meta.parse.(String.(lr.dvote))
	lr = filter(x -> !(x.dvote == 0 && x.rvote == 0), lr)
	lrd = filter(x -> !(x.rvote == 1 && x.dvote == 0), lr)
	lrr = filter(x -> !(x.dvote == 1 && x.rvote == 0), lr)
	return lr
end

# ╔═╡ 3b5a3e9f-a47f-4b60-af52-c17ead4a3c29
let
	years = 1952:4:2000
	b_mean = Float64[]
	b_std = Float64[]
	tmpdir = joinpath(pwd(), "tmp")
	for yr in years
		lr = select_year(nes, yr)
		data = (N=nrow(lr), x=lr.income, y=lr.rvote)
		sm = SampleModel("presvote", stan01, tmpdir)
		rc = stan_sample(sm; data)
		if success(rc)
			df = read_samples(sm, :dataframe)
			ms = model_summary(df, [:alpha, :beta])
		end
		append!(b_mean, ms[:beta, :mean])
		append!(b_std, ms[:beta, :std])
	end
	f = Figure(;size = default_figure_resolution)
	ax = Axis(f[1, 1]; title="...", xticks=(1952:4:2000, ["$i" for i in 1952:4:2000]))
	scatter!(years, b_mean; color=:darkred)
	for (ind, yr) in enumerate(years)
		lines!([yr, yr], [b_mean[ind]-b_std[ind], b_mean[ind]+b_std[ind]]; color=:gray)
	end
	hlines!(0.0; linestyle=:dot)
	f
end

# ╔═╡ 36f02b83-26ef-4b0d-b1ac-d41f574ae430
md" ### 5.3 Latent-data formulation."

# ╔═╡ d2df1e48-632e-46b6-a798-590879044f5f
md" ### 5.4 Building a logistic regression model: wells in Bangladesh."

# ╔═╡ 8b7b6c0a-021c-4ec3-8556-70f81132c30a
wells = CSV.read(arm_datadir("wells", "wells.csv"), DataFrame)

# ╔═╡ 6c6837c6-7eba-4ffb-ba77-e3d893a23dbb
wells_01_lm = glm(@formula(switch ~ 1 + dist), wells, Binomial(2.0), LogitLink())

# ╔═╡ a0b0577c-b60d-450c-90a0-b7d414a2c1e1
deviance(wells_01_lm)

# ╔═╡ c2a7909b-dfc1-4ae1-9a3e-cadfc7c866ed
wells_01_stan = "
data {
  int<lower=0> N;
  array[N] int<lower=0, upper=1> switched;
  vector[N] dist;
}
transformed data {
  matrix[N, 1] x = [dist']';
}
parameters {
  real alpha;
  vector[1] beta;
}
model {
  switched ~ bernoulli_logit_glm(x, alpha, beta);
}";

# ╔═╡ 9bfa94e8-1bae-4379-a9af-a14a0a851edf
let
	data = (N=nrow(wells), dist=wells.dist, switched=wells.switch)
	global wells_01_sm = SampleModel("wells_01", wells_01_stan)
	wells_01_rc = stan_sample(wells_01_sm; data)
	if success(wells_01_rc)
		global wells_01_df = read_samples(wells_01_sm, :dataframe)
		global wells_01_ms = model_summary(wells_01_df, [:alpha, Symbol("beta.1")])
	end
	success(wells_01_rc) && read_summary(wells_01_sm)
end

# ╔═╡ a749aee0-e3f5-47e9-8f06-3763888f8729
wells_01_ndf = read_samples(wells_01_sm, :nesteddataframe)

# ╔═╡ e3d0f216-57b0-4553-8ff1-0b94ab9d6855
# ╠═╡ disabled = true
#=╠═╡
beta = collect(Iterators.flatten(wells_01_ndf.beta))
  ╠═╡ =#

# ╔═╡ fa7758e4-8f59-4e37-99a1-264218aefc66
alpha = collect(Iterators.flatten(wells_01_ndf.alpha))

# ╔═╡ c12f66b7-bbf5-4f5d-bf02-98ddcceec483
md" ### Appendix A: Comparing models."

# ╔═╡ e02787f9-c8a8-4d6a-bba4-2e2c1238db75
wells_a_stan = "
data {
	int<lower=0> N;                   // Number of data ponts
	int<lower=0> P;                   // Number of predictors (including intercept)
	matrix[N, P] X;                   // Predictors
	array[N] int<lower=0, upper=1> y; //Binary outcome
}
parameters {
	vector[P] beta;
}
model {
	beta ~ normal(0, 1);
	y ~ bernoulli_logit(X * beta);
}
generated quantities {
	vector[N] log_lik;
	for (n in 1:N) {
		log_lik[n] = bernoulli_logit_lpmf(y[n] | X[n] * beta);
	}
}";

# ╔═╡ a63d3ef8-be51-421f-820f-203b6096e09a
let
	df = DataFrame(intercept=repeat([1], nrow(wells)), dist100=wells.dist100, arsenic=wells.arsenic)
	X = Array(df)
	data = (X=X, y=wells.switch, N=size(X, 1), P=size(X, 2))
	global wells_a_sm = SampleModel("appendix_a", wells_a_stan)
	wells_a_rc = stan_sample(wells_a_sm; data)
	if success(wells_a_rc)
		global wells_a_ndf = read_samples(wells_a_sm, :nesteddataframe)
	end
	success(wells_a_rc) && read_summary(wells_a_sm)
end

# ╔═╡ 88d4a195-9d7a-4335-8742-84f03b7e53eb
wells_a_ndf

# ╔═╡ eabc2a95-9ad6-4a8f-9df3-050612893b1f
let
	global beta = zeros(nrow(wells_a_ndf), length(wells_a_ndf.beta[1]))
	for i in 1:nrow(wells_a_ndf)
		beta[i, :] = wells_a_ndf.beta[i]
	end
	beta
end

# ╔═╡ 50b08d0f-a9fe-44f0-bb13-dd187fe8d121
let
	global log_lik = zeros(nrow(wells_a_ndf), length(wells_a_ndf.log_lik[1]))
	for i in 1:nrow(wells_a_ndf)
		log_lik[i, :] = wells_a_ndf.log_lik[i]
	end
	log_lik
end

# ╔═╡ 15a4591f-a7a8-4e2a-8cbc-dfe0d0add687
size(log_lik)

# ╔═╡ d0532199-1ef4-4f42-9535-d9df253ce35d
waic(log_lik)

# ╔═╡ c4d1ee58-cf18-4518-bb6f-c2397a3a1830
begin
	loo, loos, pk = psisloo(log_lik)
	loo
end

# ╔═╡ ccdebb27-95ab-4664-b9f3-51c8bef63cc5
loos

# ╔═╡ 60466c98-8794-4790-92f1-6076c150364c
sum(loos)

# ╔═╡ ed04eef5-1f20-472f-8f0a-690b0d7749f1
pk

# ╔═╡ d21a88f3-5665-4a76-91ac-80408a9abe49
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="PSIS diagnostic plot")
	scatter!(pk)
	hlines!([0.5, 0.7]; color=[:darkred, :darkblue])
	f
end

# ╔═╡ 958df2bd-86d2-4dee-8425-87b880547ed7
function pk_qualify(pk::Vector{Float64})
    pk_good = sum(pk .<= 0.5)
    pk_ok = length(pk[pk .<= 0.7]) - pk_good
    pk_bad = length(pk[pk .<= 1]) - pk_good - pk_ok
    (good=pk_good, ok=pk_ok, bad=pk_bad, very_bad=sum(pk .> 1))
end

# ╔═╡ b282b31c-ff82-4dd6-b3c8-fe6dc88745a8
pk_qualify(pk)

# ╔═╡ 924b5c4f-7eda-4c0b-b036-301ffeeb4317
let
	df = DataFrame(intercept=repeat([1], nrow(wells)), dist100=wells.dist100, arsenic=log.(wells.arsenic))
	X = Array(df)
	data = (X=X, y=wells.switch, N=size(X, 1), P=size(X, 2))
	global wells_la_sm = SampleModel("appendix_a", wells_a_stan)
	wells_la_rc = stan_sample(wells_la_sm; data)
	if success(wells_la_rc)
		global wells_la_ndf = read_samples(wells_la_sm, :nesteddataframe)
	end
	success(wells_la_rc) && read_summary(wells_la_sm)
end

# ╔═╡ ea459aea-0280-40a9-8fb3-4a0803c63be8
let
	log_lik = zeros(nrow(wells_la_ndf), length(wells_a_ndf.log_lik[1]))
	for i in 1:nrow(wells_la_ndf)
		log_lik[i, :] = wells_la_ndf.log_lik[i]
	end
	waic(log_lik)
end

# ╔═╡ Cell order:
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╟─cf39df58-3371-4535-88e4-f3f6c0404500
# ╠═0616ece8-ccf8-4281-bfed-9c1192edf88e
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═d7753cf6-7452-421a-a3ec-76e07646f808
# ╠═550371ad-d411-4e66-9d63-7329322c6ea1
# ╠═0391fc17-09b7-47d7-b799-6dc6de13e82b
# ╠═ff959f21-c153-45b5-b0f5-10dd33e361ef
# ╠═ebdcdfaa-4f80-4143-b322-9b4869ed63e0
# ╠═14d10efd-9877-439d-bdb7-d6ca4bfa31f1
# ╠═9716541d-b8a0-40f8-864e-998307a6538c
# ╠═9d96ce6f-e39a-48a9-a8cc-519f236e6e94
# ╠═c5cf5bb3-c592-446f-89ea-47de31b50d6d
# ╠═057d0272-6bd5-4157-842d-f3f9527d937f
# ╠═0566ccb6-abd6-4236-8d8c-53d2cb0dd106
# ╠═8938b5a8-88a7-400e-bf1f-e238d6215d1a
# ╠═241ecb94-3e40-4956-9a4c-da9dd2f011c2
# ╠═482f1759-d9d5-40ac-9eac-664ad600180f
# ╠═ea229fa3-a0bd-421f-928f-6e52f5cf8fab
# ╠═1cc0814b-ba60-48bf-9257-520adf279484
# ╠═cd0b637d-a08a-467d-8b01-04681ca3d63d
# ╠═3f08cc02-f0c2-4462-b123-860c919adc08
# ╠═a90b80ce-2109-4c97-a726-cf5f269f1cb6
# ╠═f426c57d-174c-4c90-a525-ea6e7007f3cf
# ╠═c778d877-5e1a-4830-a038-969c1589fff5
# ╠═6377f893-f9a4-49a3-a778-9d3f4138b008
# ╟─85438f53-668d-4a1d-9767-7791102c3ee4
# ╠═f24bd557-f10c-4873-ae59-6e418e996ce6
# ╠═36d9e0e7-355a-4e37-bdab-dc30c5b1f177
# ╠═0d5894dc-5576-4962-986b-d776e2145abd
# ╠═432d993f-e2c7-49c8-854f-ca80bef7f0fd
# ╠═15e3b592-e7de-4e13-b8aa-a6a6d71e5e5b
# ╠═21fe1b1a-e9f4-49af-91e6-fafa33121526
# ╠═365e0470-7697-4720-a397-dd6b829dde92
# ╠═26d71001-8a17-4c66-9b61-622d90f5036c
# ╠═3b5a3e9f-a47f-4b60-af52-c17ead4a3c29
# ╟─36f02b83-26ef-4b0d-b1ac-d41f574ae430
# ╟─d2df1e48-632e-46b6-a798-590879044f5f
# ╠═8b7b6c0a-021c-4ec3-8556-70f81132c30a
# ╠═6c6837c6-7eba-4ffb-ba77-e3d893a23dbb
# ╠═a0b0577c-b60d-450c-90a0-b7d414a2c1e1
# ╠═c2a7909b-dfc1-4ae1-9a3e-cadfc7c866ed
# ╠═9bfa94e8-1bae-4379-a9af-a14a0a851edf
# ╠═a749aee0-e3f5-47e9-8f06-3763888f8729
# ╠═e3d0f216-57b0-4553-8ff1-0b94ab9d6855
# ╠═fa7758e4-8f59-4e37-99a1-264218aefc66
# ╠═c12f66b7-bbf5-4f5d-bf02-98ddcceec483
# ╠═e02787f9-c8a8-4d6a-bba4-2e2c1238db75
# ╠═a63d3ef8-be51-421f-820f-203b6096e09a
# ╠═88d4a195-9d7a-4335-8742-84f03b7e53eb
# ╠═eabc2a95-9ad6-4a8f-9df3-050612893b1f
# ╠═50b08d0f-a9fe-44f0-bb13-dd187fe8d121
# ╠═15a4591f-a7a8-4e2a-8cbc-dfe0d0add687
# ╠═d0532199-1ef4-4f42-9535-d9df253ce35d
# ╠═c4d1ee58-cf18-4518-bb6f-c2397a3a1830
# ╠═ccdebb27-95ab-4664-b9f3-51c8bef63cc5
# ╠═60466c98-8794-4790-92f1-6076c150364c
# ╠═ed04eef5-1f20-472f-8f0a-690b0d7749f1
# ╠═d21a88f3-5665-4a76-91ac-80408a9abe49
# ╠═958df2bd-86d2-4dee-8425-87b880547ed7
# ╠═b282b31c-ff82-4dd6-b3c8-fe6dc88745a8
# ╠═924b5c4f-7eda-4c0b-b036-301ffeeb4317
# ╠═ea459aea-0280-40a9-8fb3-4a0803c63be8
