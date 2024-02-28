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
	using MixedModels

    # Specific to ROSStanPluto
    using StanSample
    
    # Graphics related
    using CairoMakie
    using AlgebraOfGraphics
    
    # Include basic packages
    using RegressionAndOtherStories
end

# ╔═╡ eb7ea04a-da52-4e69-ac3e-87dc7f014652
md"## 12-Linear regression: the basics."

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

# ╔═╡ e157be84-f554-4e02-924b-f60334ab50bf
md"### 12.2 Partial pooling with no predictor."

# ╔═╡ eddf42b9-5629-4ae7-927d-e47ce6e36558
begin
	radon = CSV.read(arm_datadir("radon", "radon.csv"), DataFrame)
	radon = radon[radon.state .== "MN", [:activity, :floor, :county, :stfips, :cntyfips]]
	radon.county = strip.(Array(radon.county))
	radon
end;

# ╔═╡ 1ad4e27e-f8fe-4138-b763-81b516a153e9
begin
	cty = CSV.read(arm_datadir("radon", "cty.csv"), DataFrame)
	cty = cty[cty.st .== "MN", :]
	radon.fips = radon.stfips .* 1000 .+ radon.cntyfips
	cty.fips = 1000 * cty.stfips + cty.ctfips
	log_uranium = Float64[]
	for r in eachrow(radon)
		ind = findfirst(x -> x == r.fips, cty.fips)
		if isnothing(ind)
			println(r.cty)
		else
			append!(log_uranium, log(cty.Uppm[ind]))
		end
	end
	radon.log_uranium = log_uranium
	radon
end;

# ╔═╡ 0e729c44-2a01-4d2e-b99c-1da6931f68c2
begin
	unique_counties = unique(radon.county)
	unique_no = Int[]
	for r in eachrow(radon)
		append!(unique_no, findfirst(x -> x == r.county, unique_counties))
	end
	radon.county_no = unique_no
	radon[!, :log_radon] = log.(radon.activity)
	for i in 1:nrow(radon)
		if radon.activity[i] <= 1.0
			radon.log_radon[i] = 0.1
		end
	end
	radon
end

# ╔═╡ a7e1d46b-95fd-4135-9f7d-1c1233666e34
radon[end,:]

# ╔═╡ 42e94333-4cba-4c5e-b761-1bba53d7a8b3
md" #### Estimated using MixedModels.jl."

# ╔═╡ c5ecab52-4413-444f-9d82-6055f5cbe8a2
complete_pooling_no_predictor = lm(@formula(log_radon ~ 1), radon)

# ╔═╡ dd6cb0bb-6184-43d3-8325-120305ad32aa
no_pooling_no_predictor = fit(MixedModel, @formula(log_radon ~ 1 + (1|county)), radon)

# ╔═╡ 4596bdac-8791-41e7-b953-ba2447f72996
print(no_pooling_no_predictor)

# ╔═╡ 4f99762a-eea9-4a39-83b3-f75aca986f22
no_pooling_one_predictor = fit(MixedModel, @formula(log_radon ~ 1 + floor + (1|county)), radon)

# ╔═╡ 2fb0b042-4fb2-47cc-a39b-3f0b1a9404ee
print(no_pooling_one_predictor)

# ╔═╡ c2f30632-c733-4406-ba8b-d01a86315f56
ranef(no_pooling_one_predictor)

# ╔═╡ 5eee5d0e-2feb-4b89-b270-04531f0078fd
md" #### Estimates using Stan."

# ╔═╡ d1813ac6-865f-4a64-8031-4c27cdbbeb13
partial_pooling_no_predictor_stan = "
data {
  int<lower=1> N;
  int<lower=1> J; // number of counties
  array[N] int<lower=1, upper=J> county;
  vector[N] y;
}
parameters {
  real mu_a;
  real<lower=0> sigma_a;
  real<lower=0> sigma_y;
  vector<offset=mu_a, multiplier=sigma_a>[J] a; // county intercepts
}
model {
  mu_a ~ std_normal();
  sigma_a ~ cauchy(0, 2.5);
  sigma_y ~ cauchy(0, 2.5);
  a ~ normal(mu_a, sigma_a);
  y ~ normal(a[county], sigma_y);
}";

# ╔═╡ 96fdf0a7-d13b-4db4-b03a-277ad79adf84
let
	data = (N=nrow(radon), J=maximum(radon.county_no), county=radon.county_no, y=radon.log_radon)
	global partial_pooling_no_predictor_sm = SampleModel("no_predictor", partial_pooling_no_predictor_stan)
	partial_pooling_no_predictor_rc = stan_sample(partial_pooling_no_predictor_sm; data)
	if success(partial_pooling_no_predictor_rc)
		global partial_pooling_no_predictor_ndf = read_samples(partial_pooling_no_predictor_sm, :nesteddataframe)
	end
	success(partial_pooling_no_predictor_rc) && read_summary(partial_pooling_no_predictor_sm)
end


# ╔═╡ ee748d03-fefc-4d9c-9523-325b94958ef9
let
	a = zeros(nrow(partial_pooling_no_predictor_ndf), length(partial_pooling_no_predictor_ndf.a[1]))
	for i in 1:nrow(partial_pooling_no_predictor_ndf)
		a[i, :] = partial_pooling_no_predictor_ndf.a[i]
	end
	mean(a; dims=1)
end

# ╔═╡ 12d9eb41-e6a0-4525-8483-06d806f0028c
mean(partial_pooling_no_predictor_ndf.a; dims=1)

# ╔═╡ d58141e6-e849-4030-a7df-424aa67daf69
std(partial_pooling_no_predictor_ndf.a)

# ╔═╡ d3b16cce-6dc8-48a3-8a85-6989f90780c4
begin
	gdf = groupby(radon, :county_no)
end

# ╔═╡ 04c9fb2b-9d72-439f-a1c3-32efd4ff3bc2
begin
	by_county_12_2 = combine(gdf, :log_radon => mean)
	by_county_12_2.log_radon_std = combine(gdf, :log_radon => std)[:, :log_radon_std]
	by_county_12_2.obs = [nrow(g) for g in gdf]
	by_county_12_2.log_radon_se = by_county_12_2.log_radon_std ./ sqrt.(by_county_12_2.obs)
	for r in eachrow(by_county_12_2)
		if isnan(r.log_radon_std)
			r.log_radon_std = std(radon.log_radon)
			r.log_radon_se = std(radon.log_radon) ./ sqrt.(r.obs)
		end
	end
	by_county_12_2.mean_a = mean(partial_pooling_no_predictor_ndf.a)
	by_county_12_2.mean_std = std(partial_pooling_no_predictor_ndf.a)
	by_county_12_2.mean_se = std(partial_pooling_no_predictor_ndf.a) ./ sqrt.(by_county_12_2.obs)
	by_county_12_2
end

# ╔═╡ 71e3bd68-776f-4125-816c-9c1a696d6b76
let
	f = Figure(;size = default_figure_resolution)
	ax = Axis(f[1, 1]; title="...",)
	x_range = 1:nrow(by_county_12_2)
	scatter!(x_range, by_county_12_2.log_radon_mean; color=:darkred)
	for i in x_range
		r = by_county_12_2[i, :]
		lines!([i, i], [r.log_radon_mean - r.log_radon_se, r.log_radon_mean + r.log_radon_se]; color=:gray)
	end
	hlines!(read_summary(partial_pooling_no_predictor_sm)[8, :mean]; linestyle=:dot)
	f
end

# ╔═╡ dfebaaec-e21b-48e6-86f1-fffff80e8465
let
	f = Figure(;size = default_figure_resolution)
	ax = Axis(f[1, 1]; title="No pooling", xlabel="Sample size in county (log10 scale)",
		ylabel="Sample mean in county", xticks=([0.0, 1.0, 2.0], ["1", "10", "100"]))
	ylims!(0, 3.5)
	x_range = 1:nrow(by_county_12_2)
	for i in x_range
		r = by_county_12_2[i, :]
		lrobs = jitter(log10.(r.obs), 0.05)
		scatter!(lrobs, r.log_radon_mean; color=:darkred)
		lines!([lrobs, lrobs], [r.log_radon_mean - r.log_radon_se, r.log_radon_mean + r.log_radon_se]; color=:gray)
	end
	hlines!(read_summary(partial_pooling_no_predictor_sm)[8, :mean]; linestyle=:dot)
	f
end

# ╔═╡ 2db5fe47-d8d1-4ac9-b648-97927e8ef4ca
let
	f = Figure(;size = default_figure_resolution)
	ax = Axis(f[1, 1]; title="No pooling", xlabel="Sample size in county (log10 scale)",
		ylabel="Sample mean in county", xticks=([0.0, 1.0, 2.0], ["1", "10", "100"]))
	ylims!(0, 3.3)
	x_range = 1:nrow(by_county_12_2)
	for i in x_range
		r = by_county_12_2[i, :]
		lrobs = jitter(log10.(r.obs), 0.02)
		scatter!(lrobs, r.log_radon_mean; color=:darkred)
		lines!([lrobs, lrobs], [r.log_radon_mean - r.log_radon_se, r.log_radon_mean + r.log_radon_se]; color=:gray)
	end
	hlines!(read_summary(partial_pooling_no_predictor_sm)[8, :mean]; linestyle=:dot)
	
	ax = Axis(f[1, 2]; title="Multi level model", xlabel="Sample size in county (log10 scale)",
		ylabel="Sample mean in county", xticks=([0.0, 1.0, 2.0], ["1", "10", "100"]))
	ylims!(0, 3.3)
	x_range = 1:nrow(by_county_12_2)
	for i in x_range
		r = by_county_12_2[i, :]
		lrobs = jitter(log10.(r.obs), 0.02)
		scatter!(lrobs, r.mean_a; color=:darkred)
		lines!([lrobs, lrobs], [r.mean_a - r.mean_se, r.mean_a + r.mean_se]; color=:gray)
	end
	hlines!(read_summary(partial_pooling_no_predictor_sm)[8, :mean]; linestyle=:dot)
	f
end

# ╔═╡ 95ef66c4-70eb-42f0-9b67-4b7d4f5c5462
md" #### Select counties to be used for county plots."

# ╔═╡ 4a8c7346-a43c-451c-b8ba-af1c108cb597
by_county_12_2[36, :]

# ╔═╡ b1727a7d-fa82-4abe-be85-dbd7cf2ef78b
unique(radon.county)[36]

# ╔═╡ acc82240-1584-4799-acaa-0edbac2c2e28
begin
	ctys = [36, 1, 35, 21, 14, 71, 61, 70]
	unique(radon.county)[ctys]
end

# ╔═╡ 609dc4fc-1304-4319-ba2e-4fd6d151b72f
by_county_12_2[ctys, :]

# ╔═╡ 6f035731-1ba1-48d3-9783-948925f54919
md" ### 12.3 Partial pooling with a predictor."

# ╔═╡ af12c745-8b1d-4adf-bad8-11bdb88ba43a
complete_pooling_one_predictor_stan = "
data {
  int<lower=1> N;
  vector[N] x;
  vector[N] y;
}
transformed data {
  matrix[N, 1] cov = [x']';
}
parameters {
  real alpha;
  vector[1] beta;
  real<lower=0> sigma;
}
model {
  sigma ~ cauchy(0, 2.5);
  y ~ normal_id_glm(cov, alpha, beta, sigma);
}
";

# ╔═╡ b71d881e-e585-47d8-a57b-31b493e8b9f9
let
	data = (N=nrow(radon), x=radon.floor, y=radon.log_radon)
	global complete_pooling_one_predictor_sm = SampleModel("complete_pool_one_predictor", complete_pooling_one_predictor_stan)
	complete_pooling_one_predictor_rc = stan_sample(complete_pooling_one_predictor_sm; data)
	if success(complete_pooling_one_predictor_rc)
		global complete_pooling_one_predictor_ndf = read_samples(complete_pooling_one_predictor_sm, :nesteddataframe)
	end
	success(complete_pooling_one_predictor_rc) && read_summary(complete_pooling_one_predictor_sm)
end

# ╔═╡ f7e27837-4ea2-4279-8de5-b6a13a5d7d34
partial_pooling_one_predictor_stan = "
data {
  int<lower=1> N;
  int<lower=1> J; // number of counties
  array[N] int<lower=1, upper=J> county;
  vector[N] x;
  vector[N] y;
}
transformed data {
  matrix[N, 1] cov = [x']';
}
parameters {
  vector[1] beta;
  real<lower=0> sigma_a;
  real<lower=0> sigma_y;
  real mu_a;
  vector<offset=mu_a, multiplier=sigma_a>[J] a;
}
model {
  beta ~ std_normal();
  mu_a ~ std_normal();
  sigma_a ~ cauchy(0, 2.5);
  sigma_y ~ cauchy(0, 2.5);
  
  a ~ normal(mu_a, sigma_a);
  y ~ normal_id_glm(cov, a[county], beta, sigma_y);
}
";

# ╔═╡ a2224412-f288-4b12-9abe-7ed7f9e2d318
let
	data = (N=nrow(radon), J=maximum(radon.county_no), county= radon.county_no, x=radon.floor,
		y=radon.log_radon)
	global partial_pooling_one_predictor_sm = SampleModel("partial_pooling_one_predictor", partial_pooling_one_predictor_stan)
	partial_pooling_one_predictor_rc = stan_sample(partial_pooling_one_predictor_sm; data)
	if success(partial_pooling_one_predictor_rc)
		global partial_pooling_one_predictor_ndf = read_samples(partial_pooling_one_predictor_sm, :nesteddataframe)
	end
	success(partial_pooling_one_predictor_rc) && read_summary(partial_pooling_one_predictor_sm)
end

# ╔═╡ c6ede584-4ea1-4565-a91e-bb316c0ee1f0
size(partial_pooling_one_predictor_ndf.a[1])

# ╔═╡ 7f8aa236-fade-435b-918a-8a3ad507cca1
mean(partial_pooling_one_predictor_ndf.a)

# ╔═╡ a627a5d8-7bd9-4c2f-835d-081b7a1f95f3
size(read_summary(partial_pooling_one_predictor_sm))

# ╔═╡ 315935bd-a3f6-4b06-bc5b-075be31c09a5
begin
	by_county_12_3 = combine(gdf, :log_radon => mean)
	acp = mean(complete_pooling_one_predictor_ndf.alpha)
	bcp = mean(complete_pooling_one_predictor_ndf.beta)[1]
	by_county_12_3.alpha_complete_pool = repeat([acp], nrow(by_county_12_3))
	by_county_12_3.beta_complete_pool = repeat([bcp], nrow(by_county_12_3))
	alpha_no_pool = read_summary(partial_pooling_one_predictor_sm)[12:end, :mean]
	beta_no_pool = repeat([read_summary(partial_pooling_one_predictor_sm)[8, :mean]], nrow(by_county_12_3))
	by_county_12_3.alpha_no_pool = alpha_no_pool
	by_county_12_3.beta_no_pool = beta_no_pool
	by_county_12_3
end

# ╔═╡ dc5b0d74-725b-4009-bc0c-762e9b3a9fc6
by_county_12_3[36, :]

# ╔═╡ 68827fe5-dc42-4fdd-8012-121d4dd68c68
md"
!!! note

Still figuring out what is happening with `Lac Qui Parle`. Definitely partial pooling here."

# ╔═╡ fe30f1d9-e81e-4e2d-bf4f-bea8b1c881ae
let
	fs = [[1, 1], [1, 2], [1, 3], [1, 4], [2, 1], [2, 2], [2, 3], [2, 4]]
	f = Figure(; size=default_figure_resolution)
	x = -0.1:0.01:1.1
	for (ind, g) in enumerate(ctys)
		g = gdf[ctys[ind]]
		c = by_county_12_3[ctys[ind], :]
		ax = Axis(f[fs[ind]...]; title="$(g.county[1])", xlabel="floor", ylabel="log radon level")
		ylims!(-0, 3)
		for r in eachrow(gdf[ctys[ind]])
			scatter!(jitter(r.floor, 0.1), r.log_radon; color=:black)
		end
		lines!(x, c.alpha_complete_pool .+ c.beta_complete_pool .* x; linestyle=:dash)
		lines!(x, c.alpha_no_pool .+ c.beta_no_pool .* x; color=:darkred)
	end
	f
end	

# ╔═╡ ae2dde4b-ce4e-4753-bfdd-6aef0cd20e8d
gdf[ctys[1]]

# ╔═╡ a7c908eb-b7b1-4eea-8d73-0e9a4e189b3e
by_county_12_3[ctys, :]

# ╔═╡ 8145d748-cd76-4f92-a711-8f2a1dfd77cb
md" ##### R results for `alpha_no_pool`

# A tibble: 8 × 10
  variable  mean median     sd    mad    q5   q95  rhat ess_bulk ess_tail
  <chr>    <dbl>  <dbl>  <dbl>  <dbl> <dbl> <dbl> <dbl>    <dbl>    <dbl>
1 a[36]    1.87   1.87  0.295  0.296  1.41   2.37  1.00    6182.    3002.
2 a[1]     1.18   1.19  0.262  0.263  0.749  1.60  1.00    9845.    3045.
3 a[35]    1.08   1.08  0.223  0.223  0.721  1.45  1.00    8368.    2897.
4 a[21]    1.63   1.63  0.200  0.192  1.30   1.96  1.00    9463.    2408.
5 a[14]    1.83   1.83  0.176  0.180  1.55   2.13  1.00    8238.    2808.
6 a[71]    1.48   1.48  0.141  0.139  1.25   1.71  1.00    9062.    2638.
7 a[61]    1.20   1.20  0.126  0.126  0.994  1.41  1.00   11905.    2275.
8 a[70]    0.889  0.889 0.0714 0.0723 0.774  1.01  1.00    4924.    3075.
";

# ╔═╡ 8f1a6252-7471-489e-b487-365e03b9fd15
gdf[36]

# ╔═╡ 37a7a4a8-0ecc-4124-8ea4-ad7e13599a88
l36 = lm(@formula(log_radon ~ 1 + floor), gdf[36])

# ╔═╡ d6ea1669-828f-4ade-b538-977266a0a985
typeof(l36)

# ╔═╡ ef8a7bfe-9078-43c7-a428-387a68db7c87
begin
	lms = typeof(l36)[]
	for i in 1:85
		append!(lms, [lm(@formula(log_radon ~ 1 + floor), gdf[i])])
	end
	coef.(lms[ctys])
end

# ╔═╡ bd386faf-9656-45ef-ae87-ed02b9d2dbea
md"
!!! note
Intercept from MixedModels.jl, slope from Stan model."

# ╔═╡ 03795e4d-9d39-4ff1-8020-97173edd1e23
let
	fs = [[1, 1], [1, 2], [1, 3], [1, 4], [2, 1], [2, 2], [2, 3], [2, 4]]
	f = Figure(; size=default_figure_resolution)
	x = -0.1:0.01:1.1
	local cpool, ppool, npool
	for (ind, g) in enumerate(ctys)
		g = gdf[ctys[ind]]
		c = by_county_12_3[ctys[ind], :]
		ax = Axis(f[fs[ind]...]; title="$(g.county[1])", xlabel="floor", ylabel="log radon level")
		ylims!(-1, 3)
		for r in eachrow(gdf[ctys[ind]])
			scatter!(jitter(r.floor, 0.1), r.log_radon; color=:black)
		end
		cpool = lines!(x, c.alpha_complete_pool .+ c.beta_complete_pool .* x; linestyle=:dash)
		ppool = lines!(x, c.alpha_no_pool .+ c.beta_no_pool .* x; color=:darkred)
		npool = lines!(x, coef(lms[ctys[ind]])[1] .+  c.beta_no_pool .* x; color=:darkblue)
	end
	Legend(f[1:2, 5], [cpool, ppool, npool], ["Complete pooling", "Partial pooling", "No pooling"])
	f
end	

# ╔═╡ 3db18970-ee19-4a7a-96b0-67d96de46447
md"
!!! note
VIntercept and varying slopes model from MixedModels.jl."

# ╔═╡ 5b0d4b4a-5595-4668-bed1-f98d5c1d5a64
let
	fs = [[1, 1], [1, 2], [1, 3], [1, 4], [2, 1], [2, 2], [2, 3], [2, 4]]
	f = Figure(; size=default_figure_resolution)
	x = -0.1:0.01:1.1
	local cpool, ppool, npool
	for (ind, g) in enumerate(ctys)
		g = gdf[ctys[ind]]
		c = by_county_12_3[ctys[ind], :]
		ax = Axis(f[fs[ind]...]; title="$(g.county[1])", xlabel="floor", ylabel="log radon level")
		ylims!(-1, 3)
		for r in eachrow(gdf[ctys[ind]])
			scatter!(jitter(r.floor, 0.1), r.log_radon; color=:black)
		end
		cpool = lines!(x, c.alpha_complete_pool .+ c.beta_complete_pool .* x; linestyle=:dash)
		ppool = lines!(x, c.alpha_no_pool .+ c.beta_no_pool .* x; color=:darkred)
		npool = lines!(x, coef(lms[ctys[ind]])[1] .+  coef(lms[ctys[ind]])[2] .* x; color=:darkblue)
	end
	Legend(f[1:2, 5], [cpool, ppool, npool], ["Complete pooling", "Partial pooling", "No pooling"])
	f
end	

# ╔═╡ b423fa90-bd50-468e-9c38-1572ddf85aeb
md" ### 12.4 Quickly fitting multilevel models."

# ╔═╡ b45e5353-9c38-42b7-9a1f-7707508bfc19
md" #### See the use of MixedModels.jl in above sections."

# ╔═╡ 1a21032a-3d85-45a2-bb8b-a2ec264d7ce4
md" ### 12.5 Five ways to write the same model."

# ╔═╡ 1b699afc-e150-4702-ac29-216606336d65
full_model = fit(MixedModel, @formula(log_radon ~ floor + log_uranium + (1|county)), radon)

# ╔═╡ 1f2ca7f2-8292-4594-8679-f0a6fc5f910c
display(full_model)

# ╔═╡ 24f53ddb-3e2d-4752-9447-a9d82c0feec1
ranef(full_model)[1][1:end]

# ╔═╡ 8ac2e1fd-8c93-4a2d-9366-3f6223ac7ed6
coef(full_model)[1] .+ ranef(full_model)[1][1:end]

# ╔═╡ 0cc51876-d096-41f2-a8aa-463b1196cc68
gdf[85]

# ╔═╡ e87a5387-cd29-4589-8cf2-040380979c6b
y_x_stan = "
data {
  int<lower=0> N;
  vector[N] x;
  vector[N] y;
}
parameters {
  vector[2] beta;
  real<lower=0> sigma;
}
model {
	sigma ~ cauchy(0, 2.5);
  y ~ normal(beta[1] + beta[2] * x, sigma);
}";

# ╔═╡ 7b939f71-76a4-43c8-a32e-f2e085dacc0c
let
	data = (N=nrow(radon), county= radon.county_no, x=radon.floor, y=radon.log_radon)
	global y_x_sm = SampleModel("y_x", y_x_stan)
	y_x_rc = stan_sample(y_x_sm; data)
	if success(y_x_rc)
		global y_x_ndf = read_samples(y_x_sm, :nesteddataframe)
	end
	success(y_x_rc) && read_summary(y_x_sm)
end

# ╔═╡ Cell order:
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╟─cf39df58-3371-4535-88e4-f3f6c0404500
# ╠═0616ece8-ccf8-4281-bfed-9c1192edf88e
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═d7753cf6-7452-421a-a3ec-76e07646f808
# ╠═550371ad-d411-4e66-9d63-7329322c6ea1
# ╠═e157be84-f554-4e02-924b-f60334ab50bf
# ╠═eddf42b9-5629-4ae7-927d-e47ce6e36558
# ╠═1ad4e27e-f8fe-4138-b763-81b516a153e9
# ╠═0e729c44-2a01-4d2e-b99c-1da6931f68c2
# ╠═a7e1d46b-95fd-4135-9f7d-1c1233666e34
# ╟─42e94333-4cba-4c5e-b761-1bba53d7a8b3
# ╠═c5ecab52-4413-444f-9d82-6055f5cbe8a2
# ╠═dd6cb0bb-6184-43d3-8325-120305ad32aa
# ╠═4596bdac-8791-41e7-b953-ba2447f72996
# ╠═4f99762a-eea9-4a39-83b3-f75aca986f22
# ╠═2fb0b042-4fb2-47cc-a39b-3f0b1a9404ee
# ╠═c2f30632-c733-4406-ba8b-d01a86315f56
# ╟─5eee5d0e-2feb-4b89-b270-04531f0078fd
# ╠═d1813ac6-865f-4a64-8031-4c27cdbbeb13
# ╠═96fdf0a7-d13b-4db4-b03a-277ad79adf84
# ╠═ee748d03-fefc-4d9c-9523-325b94958ef9
# ╠═12d9eb41-e6a0-4525-8483-06d806f0028c
# ╠═d58141e6-e849-4030-a7df-424aa67daf69
# ╠═d3b16cce-6dc8-48a3-8a85-6989f90780c4
# ╠═04c9fb2b-9d72-439f-a1c3-32efd4ff3bc2
# ╠═71e3bd68-776f-4125-816c-9c1a696d6b76
# ╠═dfebaaec-e21b-48e6-86f1-fffff80e8465
# ╠═2db5fe47-d8d1-4ac9-b648-97927e8ef4ca
# ╟─95ef66c4-70eb-42f0-9b67-4b7d4f5c5462
# ╠═4a8c7346-a43c-451c-b8ba-af1c108cb597
# ╠═b1727a7d-fa82-4abe-be85-dbd7cf2ef78b
# ╠═acc82240-1584-4799-acaa-0edbac2c2e28
# ╠═609dc4fc-1304-4319-ba2e-4fd6d151b72f
# ╟─6f035731-1ba1-48d3-9783-948925f54919
# ╠═af12c745-8b1d-4adf-bad8-11bdb88ba43a
# ╠═b71d881e-e585-47d8-a57b-31b493e8b9f9
# ╠═f7e27837-4ea2-4279-8de5-b6a13a5d7d34
# ╠═a2224412-f288-4b12-9abe-7ed7f9e2d318
# ╠═c6ede584-4ea1-4565-a91e-bb316c0ee1f0
# ╠═7f8aa236-fade-435b-918a-8a3ad507cca1
# ╠═a627a5d8-7bd9-4c2f-835d-081b7a1f95f3
# ╠═315935bd-a3f6-4b06-bc5b-075be31c09a5
# ╠═dc5b0d74-725b-4009-bc0c-762e9b3a9fc6
# ╟─68827fe5-dc42-4fdd-8012-121d4dd68c68
# ╠═fe30f1d9-e81e-4e2d-bf4f-bea8b1c881ae
# ╠═ae2dde4b-ce4e-4753-bfdd-6aef0cd20e8d
# ╠═a7c908eb-b7b1-4eea-8d73-0e9a4e189b3e
# ╠═8145d748-cd76-4f92-a711-8f2a1dfd77cb
# ╠═8f1a6252-7471-489e-b487-365e03b9fd15
# ╠═37a7a4a8-0ecc-4124-8ea4-ad7e13599a88
# ╠═d6ea1669-828f-4ade-b538-977266a0a985
# ╠═ef8a7bfe-9078-43c7-a428-387a68db7c87
# ╟─bd386faf-9656-45ef-ae87-ed02b9d2dbea
# ╠═03795e4d-9d39-4ff1-8020-97173edd1e23
# ╟─3db18970-ee19-4a7a-96b0-67d96de46447
# ╠═5b0d4b4a-5595-4668-bed1-f98d5c1d5a64
# ╟─b423fa90-bd50-468e-9c38-1572ddf85aeb
# ╟─b45e5353-9c38-42b7-9a1f-7707508bfc19
# ╟─1a21032a-3d85-45a2-bb8b-a2ec264d7ce4
# ╠═1b699afc-e150-4702-ac29-216606336d65
# ╠═1f2ca7f2-8292-4594-8679-f0a6fc5f910c
# ╠═24f53ddb-3e2d-4752-9447-a9d82c0feec1
# ╠═8ac2e1fd-8c93-4a2d-9366-3f6223ac7ed6
# ╠═0cc51876-d096-41f2-a8aa-463b1196cc68
# ╠═e87a5387-cd29-4589-8cf2-040380979c6b
# ╠═7b939f71-76a4-43c8-a32e-f2e085dacc0c
