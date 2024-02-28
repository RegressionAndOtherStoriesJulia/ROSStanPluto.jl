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

# ╔═╡ 8e32db5a-0135-4e58-b28f-bb909808860a
md" ##### Counties used for plotting."m

# ╔═╡ d44841ab-1d07-488b-91a3-b4db544ffa58
begin
	ctys = [36, 1, 35, 21, 14, 71, 61, 70]
	unique(radon.county)[ctys]
end

# ╔═╡ 8fdfa595-239e-478f-aedb-c40cd39257a7
md" ##### Create a grouped dataframe for radon data."

# ╔═╡ 370439ad-bea0-437c-9d3f-37452ecc1404
gdf = groupby(radon, :county_no)

# ╔═╡ 686f281a-8c45-4a04-9aec-c04a62ed5583
md" ##### Complete pooling for intercept and slope (no per county effects)."

# ╔═╡ 4b4fb71d-9ae2-486e-a8a9-ba9bbe872964
cp_is_lm = lm(@formula(log_radon ~ 1 + floor), radon)

# ╔═╡ 990055b5-abfd-4f5f-9f25-7bf040f338f6
md" ##### No pooling, per county intercept, no predictor."

# ╔═╡ 90653162-a56a-48e0-85bc-20cab8c62730
np_i_mm = fit(MixedModel, @formula(log_radon ~ (1 | county)), radon)

# ╔═╡ e66a396e-62e6-401c-b58c-f8a03702727f
ranef(np_i_mm)

# ╔═╡ f5e62752-c0fb-42ea-aa9c-ec8a0f63528f
md" ##### No pooling, per county intersept and slope."

# ╔═╡ 4813e99f-1509-477f-8a37-9a28ed928f47
begin
	np_is_lm = typeof(cp_is_lm)[]
	for i in 1:85
		append!(np_is_lm, [lm(@formula(log_radon ~ 1 + floor), gdf[i])])
	end
	coef.(np_is_lm[ctys])
end

# ╔═╡ 3e0ba1e9-7e90-466c-80cb-e02e68bf7e64
np_is_lm[36]

# ╔═╡ ed2e68eb-8322-41d7-834d-f1e6013b4524
m0_stan = "
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
}";

# ╔═╡ 7da793e3-e807-4309-9d6d-6a25c22439bd
let
	data = (N=nrow(radon), J=maximum(radon.county_no), county= radon.county_no, x=radon.floor,
		y=radon.log_radon)
	global m0_sm = SampleModel("m0", m0_stan)
	m0_rc = stan_sample(m0_sm; data)
	if success(m0_rc)
		global m0_ndf = read_samples(m0_sm, :nesteddataframe)
	end
	success(m0_rc) && read_summary(m0_sm)
end


# ╔═╡ 144f7ad7-c18a-446c-a67c-de677c71baf9
sel_ctys = read_summary(m0_sm)[(11 .+ ctys),:]

# ╔═╡ 42e94333-4cba-4c5e-b761-1bba53d7a8b3
md" #### Estimates using MixedModels.jl."

# ╔═╡ 3a3f151e-c225-499a-8560-c4c5e92b718d
m1 = fit(MixedModel, @formula(log_radon ~ 1 + (1|county)), radon)

# ╔═╡ 9e25248c-b9d2-4ffc-9cb8-cf0eb7344889
print(m1)

# ╔═╡ f85492aa-2518-401d-a514-e571cd738877
coef(m1)

# ╔═╡ 6a41a617-15b1-4800-bfac-f8a9535339f4
ranef(m1)

# ╔═╡ 94ef4d5a-04ec-4441-b15b-fe51404561b9
begin
	by_county_13_1 = combine(gdf, :log_radon => mean)
	by_county_13_1.obs = [nrow(g) for g in gdf]
	by_county_13_1.log_radon_std = combine(gdf, :log_radon => std)[:, :log_radon_std]
	by_county_13_1.log_radon_se = by_county_13_1.log_radon_std ./ sqrt.(by_county_13_1.obs)
	for r in eachrow(by_county_13_1)
		if isnan(r.log_radon_std)
			r.log_radon_std = std(radon.log_radon)
			r.log_radon_se = std(radon.log_radon) ./ sqrt.(r.obs)
		end
	end
	by_county_13_1.log_uranium_mean = combine(gdf, :log_uranium => mean)[:, :log_uranium_mean]
	by_county_13_1.intercept = (coef(m1)[1] .+ ranef(m1)[1])[1, :]
	by_county_13_1[ctys,:]
end

# ╔═╡ dd6cb0bb-6184-43d3-8325-120305ad32aa
m3 = fit(MixedModel, @formula(log_radon ~ floor + (1 + floor|county)), radon)


# ╔═╡ e980df72-445a-490b-a71b-f96af895a94b
print(m3)

# ╔═╡ ebc6a7fa-461c-443c-9813-2ab7d678f082
coef(m3)

# ╔═╡ 2943d567-3cb5-4e06-9fe7-2f8256740f97
ranef(m3)

# ╔═╡ 1f84b706-c19d-4b22-b6f7-448c9b362c19
begin
	by_county_13_3 = combine(gdf, :log_radon => mean)
	by_county_13_3.log_uranium_mean = combine(gdf, :log_uranium => mean)[:, :log_uranium_mean]
	by_county_13_3.log_radon_std = combine(gdf, :log_radon => std)[:, :log_radon_std]
	by_county_13_3.obs = [nrow(g) for g in gdf]
	by_county_13_3.log_radon_se = by_county_13_1.log_radon_std ./ sqrt.(by_county_13_1.obs)
	for r in eachrow(by_county_13_1)
		if isnan(r.log_radon_std)
			r.log_radon_std = std(radon.log_radon)
			r.log_radon_se = std(radon.log_radon) ./ sqrt.(r.obs)
		end
	end
	by_county_13_3.intercept = (coef(m3) .+ ranef(m3)[1])[1, :]
	by_county_13_3.beta_floor = (coef(m3) .+ ranef(m3)[1])[2, :]
	by_county_13_3
end

# ╔═╡ a5c3f328-27fd-409f-b739-b18736798d72
m4 = fit(MixedModel, @formula(log_radon ~ log_uranium + log_uranium*floor + (1 + floor|county)), radon)

# ╔═╡ 3c74730a-e1e8-47d6-b440-89714b826897
print(m4)

# ╔═╡ c62f1f59-7658-4146-81fe-74164410b87d
ranef(m4)

# ╔═╡ 2f41ecfe-db40-4f7e-91bc-3f142ae1d395


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
# ╟─8e32db5a-0135-4e58-b28f-bb909808860a
# ╠═d44841ab-1d07-488b-91a3-b4db544ffa58
# ╟─8fdfa595-239e-478f-aedb-c40cd39257a7
# ╠═370439ad-bea0-437c-9d3f-37452ecc1404
# ╟─686f281a-8c45-4a04-9aec-c04a62ed5583
# ╠═4b4fb71d-9ae2-486e-a8a9-ba9bbe872964
# ╟─990055b5-abfd-4f5f-9f25-7bf040f338f6
# ╠═90653162-a56a-48e0-85bc-20cab8c62730
# ╠═e66a396e-62e6-401c-b58c-f8a03702727f
# ╟─f5e62752-c0fb-42ea-aa9c-ec8a0f63528f
# ╠═4813e99f-1509-477f-8a37-9a28ed928f47
# ╠═3e0ba1e9-7e90-466c-80cb-e02e68bf7e64
# ╠═94ef4d5a-04ec-4441-b15b-fe51404561b9
# ╠═ed2e68eb-8322-41d7-834d-f1e6013b4524
# ╠═7da793e3-e807-4309-9d6d-6a25c22439bd
# ╠═144f7ad7-c18a-446c-a67c-de677c71baf9
# ╟─42e94333-4cba-4c5e-b761-1bba53d7a8b3
# ╠═3a3f151e-c225-499a-8560-c4c5e92b718d
# ╠═9e25248c-b9d2-4ffc-9cb8-cf0eb7344889
# ╠═f85492aa-2518-401d-a514-e571cd738877
# ╠═6a41a617-15b1-4800-bfac-f8a9535339f4
# ╠═dd6cb0bb-6184-43d3-8325-120305ad32aa
# ╠═e980df72-445a-490b-a71b-f96af895a94b
# ╠═ebc6a7fa-461c-443c-9813-2ab7d678f082
# ╠═2943d567-3cb5-4e06-9fe7-2f8256740f97
# ╠═1f84b706-c19d-4b22-b6f7-448c9b362c19
# ╠═a5c3f328-27fd-409f-b739-b18736798d72
# ╠═3c74730a-e1e8-47d6-b440-89714b826897
# ╠═c62f1f59-7658-4146-81fe-74164410b87d
# ╠═2f41ecfe-db40-4f7e-91bc-3f142ae1d395
