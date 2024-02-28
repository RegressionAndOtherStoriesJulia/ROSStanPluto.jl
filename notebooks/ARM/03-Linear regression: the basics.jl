### A Pluto.jl notebook ###
# v0.19.38

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

	# Specific to ROSStanPluto
	using StanSample
	
    # Graphics related
    using CairoMakie
	using AlgebraOfGraphics
	
    # Include basic packages
    using RegressionAndOtherStories
end

# ╔═╡ eb7ea04a-da52-4e69-ac3e-87dc7f014652
md"## 03-Linear regression: the basics."

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
md"### 3.1 One predictor."


# ╔═╡ d8d8694e-5f61-4ac6-81a3-c6bac32fbb60
kiddata = CSV.read(arm_datadir("KidIQ", "kidiq.csv"), DataFrame)

# ╔═╡ 9033c35e-14d4-4b02-a5bc-ebe5fefbb489
begin
	kiddata_nohs = kiddata[kiddata.mom_hs .== 0, :]
	kiddata_hs = kiddata[kiddata.mom_hs .== 1, :]
end;

# ╔═╡ 78da3c8a-5bf6-4bb8-9440-2b33ead5df9e
md" ##### Regression with a binary predictor."

# ╔═╡ 52cbc564-3cfd-4898-89cf-c8bd6a9431b3
hs_lm = lm(@formula(kid_score ~ mom_hs), kiddata)

# ╔═╡ 3d56fdb1-6a6e-46e6-ac10-4a9e085f8011
hs_stan = "
data {
	int N;
	vector[N] y;
	vector[N] x;
}
parameters {
	real a;
	real b;
	real<lower=0> sigma;
}
model {
	vector[N] mu;
	a ~ normal(60, 10);
	b ~ normal(10, 2);
	sigma ~ exponential(1);
	mu = a + x * b;
	y ~ normal(mu, sigma);
}";

# ╔═╡ eaf6313a-758b-4b52-b66f-6db68bbf0601
let
	data = (N=nrow(kiddata), x=kiddata.mom_hs, y=kiddata.kid_score)
	global sm_mom_hs = SampleModel("mom_hs", hs_stan)
	rc = stan_sample(sm_mom_hs; data)
	success(rc) && describe(sm_mom_hs)
end

# ╔═╡ cf87a014-0619-45e6-a9cf-6bbb81a5b512
post_hs = read_samples(sm_mom_hs, :dataframe)

# ╔═╡ 5145a75b-6f76-41bc-91e4-1762db5bccb3
model_summary(post_hs, [:a, :b, :sigma])

# ╔═╡ 046c94ac-1493-406a-bafa-6dd87e5e5f78
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="Single variable regression kid_score ~ mom_hs", xlabel="Mother completed highschool", ylabel="Child test score")
	scatter!(kiddata.mom_hs, kiddata.kid_score)
	x = LinRange(0, 1, 100)
	for i in 1:200:4000
		lines!(x, post_hs.a[i] .+ post_hs.b[i] .* x; color=:lightgray)
	end
	lines!(x, coef(hs_lm)[1] .+ coef(hs_lm)[2] .* x)
	f
end

# ╔═╡ 470ce91f-2049-408c-b396-e3da2699afc3
md" ##### Regression with a continuous predictor."

# ╔═╡ 88ee5626-136c-45b8-9fd6-0ce35ce1619b
iq_stan = "
data {
	int N;
	vector[N] y;
	vector[N] x;
}
parameters {
	real a;
	real b;
	real<lower=0> sigma;
}
model {
	vector[N] mu;
	a ~ normal(25, 10);
	b ~ normal(1, 2);
	sigma ~ exponential(1);
	mu = a + x * b;
	y ~ normal(mu, sigma);
}";

# ╔═╡ 064bfef3-ad33-4586-a5d5-2e3007744ca2
let
	data = (N=nrow(kiddata), x=kiddata.mom_iq, y=kiddata.kid_score)
	global sm_iq = SampleModel("mom_iq", iq_stan)
	rc = stan_sample(sm_iq; data)
	success(rc) && describe(sm_iq)
end

# ╔═╡ 45dc9e7f-56bb-400b-8fab-f7b0f8dc131b
post_iq = read_samples(sm_iq, :dataframe)

# ╔═╡ 2c5010b8-ffe3-495d-a67d-b1e311674654
ms_iq = model_summary(post_iq, [:a, :b, :sigma])

# ╔═╡ ae723d91-1ec0-42f9-98fd-e0a5a716dabb
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="Single variable regression kid_score ~ mom_iq", xlabel="Mother IQ", ylabel="Child test score")
	scatter!(kiddata_nohs.mom_iq, kiddata_nohs.kid_score; color=:gray)
	scatter!(kiddata_hs.mom_iq, kiddata_hs.kid_score; color=:lightgray)
	x = LinRange(70, 140, 100)
	for i in 1:200:4000
		lines!(x, post_iq.a[i] .+ post_iq.b[i] .* x; color=:lightgray)
	end
	f
end

# ╔═╡ a27c6fb6-6f06-41f3-a05a-df0f7ded838d
md" ### 3.2 Regression with multiple predictors."

# ╔═╡ c98af998-0c73-469a-8d96-14f1405a5fdb
hs_iq_lm = lm(@formula(kid_score ~ mom_hs + mom_iq), kiddata)

# ╔═╡ 449c2a7c-fa52-41bb-8f64-0de1d669d070
hs_iq_stan = "
data {
	int N;
	vector[N] y;
	vector[N] x;
	vector[N] w;
}
parameters {
	real a;
	real b;
	real c;
	real<lower=0> sigma;
}
model {
	vector[N] mu;
	a ~ normal(25, 10);
	b ~ normal(1, 2);
	c ~ normal(5, 1);
	sigma ~ exponential(1);
	mu = a + x * b + w * c;
	y ~ normal(mu, sigma);
}";

# ╔═╡ ebca6cf2-da08-47be-8b0f-738718f3d4f5
# ╠═╡ show_logs = false
let
	data = (N=nrow(kiddata), w=kiddata.mom_hs, x=kiddata.mom_iq, y=kiddata.kid_score)
	global sm_hs_iq = SampleModel("hs_iq", hs_iq_stan)
	rc = stan_sample(sm_hs_iq; data)
	success(rc) && describe(sm_hs_iq)
end

# ╔═╡ c4902fa7-0d87-4478-b8ba-64d5e2bf3c31
post_hs_iq = read_samples(sm_hs_iq, :dataframe)

# ╔═╡ f398e007-9027-4e44-9023-dbfe78c6c94d
ms_hs_iq = model_summary(post_hs_iq, [:a, :b, :c, :sigma])

# ╔═╡ 5d6ceaa2-4cba-460e-b092-44ef23c6306d
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="Regression kid_score ~ mom_hs + mom_iq", xlabel="Mother IQ", ylabel="Child test score")
	snohs = scatter!(kiddata_nohs.mom_iq, kiddata_nohs.kid_score; color=:gray)
	shs = scatter!(kiddata_hs.mom_iq, kiddata_hs.kid_score; color=:lightgray)
	x = LinRange(70, 140, 100)
	â, b̂, ĉ, σ̂ = ms_hs_iq[:, :mean]
	hs = lines!(x, â .+ b̂ .* x .+ ĉ .* 1; color=:lightgray, linewidth=4)
	no_hs = lines!(x, â .+ b̂ .* x; color=:gray, linewidth=3)

	Legend(f[1, 2], [shs, snohs, hs, no_hs],
		["Highschool completed", "No highschool completed", 
		 "Highschool completed", "No highschool completed"])

	f
end

# ╔═╡ 0c6f98a0-3537-4a2c-af4f-953a589f416a
md" ### 3.3 Interactions."

# ╔═╡ 658d42a3-1b67-4209-ade0-851d5fbd06b9
sep_lm = lm(@formula(kid_score ~ mom_hs + mom_iq + mom_hs*mom_iq), kiddata)

# ╔═╡ 4a4b9067-1425-4a78-af90-a31c0b878a4f
sep_stan = "
data {
	int N;
	vector[N] y; // kid_score
	vector[N] x; // mom_hs
	vector[N] w; // mom_iq
	vector[N] u; // Interaction mom_iq * mom_hs
}
parameters {
	real a; // intercept
	real b; // mom_hs coefficient
	real c; // mom_iq coefficient
	real d; // interaction coefficient
	real<lower=0> sigma;
}
model {
	vector[N] mu;
	a ~ normal(-10, 2);
	b ~ normal(50, 3);
	c ~ normal(1, 1);
	d ~ normal(0, 1);
	sigma ~ exponential(1);
	mu = a + x * b + w * c + u * d;
	y ~ normal(mu, sigma);
}";

# ╔═╡ fd5b9e3a-fc82-402a-a833-f945c33cf812
let
	data = (
		N=nrow(kiddata), x=kiddata.mom_hs, w=kiddata.mom_iq,
		u=kiddata.mom_iq.*kiddata.mom_hs, y=kiddata.kid_score)
	global sm_sep = SampleModel("sep", sep_stan)
	rc = stan_sample(sm_sep; data)
	success(rc) && describe(sm_sep)
end

# ╔═╡ 2361cc3e-a09a-4e91-baa2-b8ac3399a924
post_sep = read_samples(sm_sep, :dataframe)

# ╔═╡ e4a20bd2-951f-480d-8d59-5742fc3d5cf3
ms_sep = model_summary(post_sep, [:a, :b, :c, :d, :sigma])

# ╔═╡ 1425da3b-4a0a-416f-839d-b115b3a08bdd
a, b, c, d, sigma = ms_sep[:, :mean]

# ╔═╡ bc49f417-d1d1-487e-b259-b2e050bb29e3
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="Regression kid_score ~ mom_hs + mom_iq + mom_hs*mom_iq",
		xlabel="Mother IQ score", ylabel="Child test score")
	snohs = scatter!(kiddata_nohs.mom_iq, kiddata_nohs.kid_score; color=:gray)
	shs = scatter!(kiddata_hs.mom_iq, kiddata_hs.kid_score; color=:lightgray)
	x = LinRange(70, 140, 100)
	a, b, c, d, sigma = ms_sep[:, :mean]
	hs = lines!(x, a .+ b .* 1 .+ (c .+ d) .* x; color=:lightgray, linewidth=4)
	no_hs = lines!(x, a .+ c .* x; color=:gray, linewidth=3)
	
	ax = Axis(f[1, 2]; title="Regression kid_score ~ mom_hs + mom_iq + mom_hs*mom_iq",
		xlabel="Mother IQ score", ylabel="Child test score")
	snohs = scatter!(kiddata_nohs.mom_iq, kiddata_nohs.kid_score; color=:gray)
	shs = scatter!(kiddata_hs.mom_iq, kiddata_hs.kid_score; color=:lightgray)
	x = LinRange(0, 140, 100)
	a, b, c, d, sigma = ms_sep[:, :mean]
	hs = lines!(x, a .+ b .* 1 .+ (c .+ d) .* x; color=:lightgray, linewidth=4)
	no_hs = lines!(x, a .+ c .* x; color=:gray, linewidth=3)

	Legend(f[1, 3], [shs, snohs, hs, no_hs],
		["Highschool completed", "No highschool completed", "Highschool completed", "No highschool completed"])

	f
end

# ╔═╡ 5967733c-004d-41f0-a468-c8fcce773e63
md" ### 3.4 Statistical inference."

# ╔═╡ ceddd149-d4db-480f-b2f6-7a7b0e9348a9
md" See above."

# ╔═╡ 41725e4d-fd74-4729-afcc-e53252bd09cc
md" ### 3.5 Graphical display of data and fitted model."

# ╔═╡ e55fd39e-f3e4-41ef-82ab-68e022b3bab0
md" See above."

# ╔═╡ f5026f11-d432-4ea4-90bc-0cafd4c7a351
md" ### 3.6 Assumptions and diagnostics."

# ╔═╡ 70e53d64-1604-4ac8-bf92-a0e1fee91dec
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="Residuals kid_score ~ mom_hs + mom_iq", xlabel="Mother IQ", ylabel="Residual")
	x = LinRange(70, 140, 100)
	â, b̂, σ̂ = ms_iq[:, :mean]
	pred = â .+ b̂ .* kiddata.mom_iq
	scatter!(kiddata.kid_score .- pred; color=:gray)
	sd = std(pred)
	hlines!([-2sd, 2sd]; linestyle=:dashdot)
	hlines!([0]; linestyle=:dot)
	f
end

# ╔═╡ 339fdffb-3674-4100-8b6c-b6f8774cc287
md" ### 3.7 Prediction and validation."

# ╔═╡ cc2b6f83-d8d8-40a9-af82-e4ee7300aa7b
md" TBD."

# ╔═╡ Cell order:
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╟─cf39df58-3371-4535-88e4-f3f6c0404500
# ╠═0616ece8-ccf8-4281-bfed-9c1192edf88e
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═d7753cf6-7452-421a-a3ec-76e07646f808
# ╠═550371ad-d411-4e66-9d63-7329322c6ea1
# ╟─0391fc17-09b7-47d7-b799-6dc6de13e82b
# ╠═d8d8694e-5f61-4ac6-81a3-c6bac32fbb60
# ╠═9033c35e-14d4-4b02-a5bc-ebe5fefbb489
# ╟─78da3c8a-5bf6-4bb8-9440-2b33ead5df9e
# ╠═52cbc564-3cfd-4898-89cf-c8bd6a9431b3
# ╠═3d56fdb1-6a6e-46e6-ac10-4a9e085f8011
# ╠═eaf6313a-758b-4b52-b66f-6db68bbf0601
# ╠═cf87a014-0619-45e6-a9cf-6bbb81a5b512
# ╠═5145a75b-6f76-41bc-91e4-1762db5bccb3
# ╠═046c94ac-1493-406a-bafa-6dd87e5e5f78
# ╟─470ce91f-2049-408c-b396-e3da2699afc3
# ╠═88ee5626-136c-45b8-9fd6-0ce35ce1619b
# ╠═064bfef3-ad33-4586-a5d5-2e3007744ca2
# ╠═45dc9e7f-56bb-400b-8fab-f7b0f8dc131b
# ╠═2c5010b8-ffe3-495d-a67d-b1e311674654
# ╠═ae723d91-1ec0-42f9-98fd-e0a5a716dabb
# ╟─a27c6fb6-6f06-41f3-a05a-df0f7ded838d
# ╠═c98af998-0c73-469a-8d96-14f1405a5fdb
# ╠═449c2a7c-fa52-41bb-8f64-0de1d669d070
# ╠═ebca6cf2-da08-47be-8b0f-738718f3d4f5
# ╠═c4902fa7-0d87-4478-b8ba-64d5e2bf3c31
# ╠═f398e007-9027-4e44-9023-dbfe78c6c94d
# ╠═5d6ceaa2-4cba-460e-b092-44ef23c6306d
# ╟─0c6f98a0-3537-4a2c-af4f-953a589f416a
# ╠═658d42a3-1b67-4209-ade0-851d5fbd06b9
# ╠═4a4b9067-1425-4a78-af90-a31c0b878a4f
# ╠═fd5b9e3a-fc82-402a-a833-f945c33cf812
# ╠═2361cc3e-a09a-4e91-baa2-b8ac3399a924
# ╠═e4a20bd2-951f-480d-8d59-5742fc3d5cf3
# ╠═1425da3b-4a0a-416f-839d-b115b3a08bdd
# ╠═bc49f417-d1d1-487e-b259-b2e050bb29e3
# ╟─5967733c-004d-41f0-a468-c8fcce773e63
# ╟─ceddd149-d4db-480f-b2f6-7a7b0e9348a9
# ╟─41725e4d-fd74-4729-afcc-e53252bd09cc
# ╟─e55fd39e-f3e4-41ef-82ab-68e022b3bab0
# ╟─f5026f11-d432-4ea4-90bc-0cafd4c7a351
# ╠═70e53d64-1604-4ac8-bf92-a0e1fee91dec
# ╟─339fdffb-3674-4100-8b6c-b6f8774cc287
# ╟─cc2b6f83-d8d8-40a9-af82-e4ee7300aa7b
