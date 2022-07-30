### A Pluto.jl notebook ###
# v0.19.10

using Markdown
using InteractiveUtils

# ╔═╡ da0eb04e-9930-4f49-809b-3ba5fe16a59c
using Pkg, DrWatson

# ╔═╡ d7992c39-0617-42b5-b977-f04260d2bd03
begin
	# Specific to ROSStanPluto
    using StanSample
	
	# Graphics related
    using GLMakie

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ f90c8b82-a52d-45a4-86eb-d2c7eb905692
md"### KidIQ: kidiq.csv"

# ╔═╡ 2daed834-e53d-4530-98bd-e80b5b99162f
md" ###### Widen the notebook."

# ╔═╡ d1c76cd1-2537-470e-a9d5-ebaa5b9dec7e
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


# ╔═╡ dfe95bfa-507a-4831-b3b5-f26b1d537112
kidiq = CSV.read(ros_datadir("KidIQ", "kidiq.csv"), DataFrame)

# ╔═╡ 4a4605a4-084a-4d64-a444-fa0fcf41ef91
let
	f = Figure()
	ax = Axis(f[1, 1]; title="KidIQ data: kid_score ~ mom_hs")
	scatter!(kidiq[kidiq.mom_hs .== 0, :mom_hs], kidiq[kidiq.mom_hs .== 0, :kid_score]; color=:red, markersize = 3)
	scatter!(kidiq[kidiq.mom_hs .== 1, :mom_hs], kidiq[kidiq.mom_hs .== 1, :kid_score]; color=:blue, markersize = 3)
	ax = Axis(f[1, 2]; title="KidIQ data: kid_score ~ mom_iq")
	scatter!(kidiq[kidiq.mom_hs .== 0, :mom_iq], kidiq[kidiq.mom_hs .== 0, :kid_score]; color=:red, markersize = 3)
	scatter!(kidiq[kidiq.mom_hs .== 1, :mom_iq], kidiq[kidiq.mom_hs .== 1, :kid_score]; color=:blue, markersize = 3)
	current_figure()
end

# ╔═╡ d8d8e6b4-6406-43ac-9472-a7afab027aef
stan10_1 = "
data {
	int N;
	vector[N] mom_hs;
	vector[N] kid_score;
}
parameters {
	real a;
	real b;
	real sigma;
}
model {
	vector[N] mu;
	a ~ normal(100, 10);
	b ~ normal(5, 10);
	mu = a + b * mom_hs;
	kid_score ~ normal(mu, sigma);
}
";

# ╔═╡ b5c45959-87c3-4a54-b166-e5795509e316
let
	data =(N = nrow(kidiq), mom_hs = kidiq.mom_hs, mom_iq = kidiq.mom_iq, kid_score = kidiq.kid_score)
	global m10_1s = SampleModel("m10.1s", stan10_1)
	global rc10_1s = stan_sample(m10_1s; data)
	success(rc10_1s) && describe(m10_1s)
end

# ╔═╡ 2e1f291f-8e84-4903-b368-a99279a15fcd
if success(rc10_1s)
	post10_1s = read_samples(m10_1s, :dataframe)
	ms10_1s = model_summary(post10_1s, [:a, :b, :sigma])
end

# ╔═╡ b77b121b-38d3-485c-a9a2-c9ae87fe3423
let
	f = Figure()
	ax = Axis(f[1, 1]; title="KidIQ data: kid_score ~ mom_hs")
	scatter!(kidiq[kidiq.mom_hs .== 0, :mom_hs], kidiq[kidiq.mom_hs .== 0, :kid_score]; color=:red, markersize = 3)
	scatter!(kidiq[kidiq.mom_hs .== 1, :mom_hs], kidiq[kidiq.mom_hs .== 1, :kid_score]; color=:blue, markersize = 3)
	lines!([0.0, 1.0], [ms10_1s[:a, :median], ms10_1s[:a, :median] + ms10_1s[:b, :median]])
	current_figure()
end

# ╔═╡ e348f77e-708f-43ed-863e-795330637846
stan10_2 = "
data {
	int N;
	vector[N] mom_iq;
	vector[N] kid_score;
}
parameters {
	real a;
	real b;
	real sigma;
}
model {
	vector[N] mu;
	a ~ normal(25, 3);
	b ~ normal(1, 2);
	mu = a + b * mom_iq;
	kid_score ~ normal(mu, sigma);
}
";

# ╔═╡ f6129e51-a64d-42ff-812a-bc62152777be
let
	data =(N = nrow(kidiq), mom_hs = kidiq.mom_hs, mom_iq = kidiq.mom_iq, kid_score = kidiq.kid_score)
	global m10_2s = SampleModel("m10.2s", stan10_2)
	global rc10_2s = stan_sample(m10_2s; data)
	success(rc10_2s) && describe(m10_2s)
end

# ╔═╡ 0ed2981d-f505-4f99-81dd-26d7a4fa3039
if success(rc10_2s)
	post10_2s = read_samples(m10_2s, :dataframe)
end

# ╔═╡ dbec5dce-5c24-4ee5-ba33-10385d650d41
ms10_2s = success(rc10_2s) && model_summary(post10_2s, [:a, :b, :sigma])

# ╔═╡ 90f0236a-2c5b-4ea8-83cf-490037bf8c15
let
	f = Figure()
	ax = Axis(f[1, 1]; title="KidIQ data: kid_score ~ mom_iq")
	scatter!(kidiq[kidiq.mom_hs .== 0, :mom_iq], kidiq[kidiq.mom_hs .== 0, :kid_score]; color=:red, markersize = 3)
	scatter!(kidiq[kidiq.mom_hs .== 1, :mom_iq], kidiq[kidiq.mom_hs .== 1, :kid_score]; color=:blue, markersize = 3)
	x = LinRange(70.0, 140.0, 100)
	lines!(x, ms10_2s[:a, :median] .+ ms10_2s[:b, :median] .* x)
	current_figure()
end

# ╔═╡ 1204cbcb-a765-461e-a477-ae3d9913b1bf
stan10_3 = "
data {
	int N;
	vector[N] mom_hs;
	vector[N] mom_iq;
	vector[N] kid_score;
}
parameters {
	real a;
	real b;
	real c;
	real sigma;
}
model {
	vector[N] mu;
	a ~ normal(25, 2);
	b ~ normal(5, 2);
	c ~ normal(1, 2);
	mu = a + b * mom_hs + c * mom_iq;
	kid_score ~ normal(mu, sigma);
}
";

# ╔═╡ b1c6c6a5-1784-438a-b930-49ce7aef80ab
begin
	data10_3 =(N = nrow(kidiq), mom_hs = kidiq.mom_hs, mom_iq = kidiq.mom_iq, kid_score = kidiq.kid_score)
	global m10_3s = SampleModel("m10.3s", stan10_3)
	global rc10_3s = stan_sample(m10_3s; data= data10_3)
	success(rc10_3s) && describe(m10_3s)
end

# ╔═╡ b6330c4f-8129-4bbd-aa39-3ddd00c062b5
post10_3s = read_samples(m10_3s, :dataframe)

# ╔═╡ 710348c0-e52b-461c-b024-ebf566fa2e17
ms10_3s = model_summary(post10_3s, [:a, :b, :c, :sigma])

# ╔═╡ 6014b70b-c10d-4b91-94f7-79dc291cc92b
let
	momnohs(x) = x == 0
	nohs = findall(momnohs, kidiq.mom_hs)

	momhs(x) = x == 1
	hs = findall(momhs, kidiq.mom_hs)
	
	f = Figure()
	ax = Axis(f[1, 1]; title="KidIQ data: kid_score ~ mom_hs + mom_iq")
	sca1 = scatter!(kidiq[kidiq.mom_hs .== 0, :mom_iq], kidiq[kidiq.mom_hs .== 0, :kid_score]; color=:red, markersize = 3)
	sca2 = scatter!(kidiq[kidiq.mom_hs .== 1, :mom_iq], kidiq[kidiq.mom_hs .== 1, :kid_score]; color=:blue, markersize = 3)
	x = sort(kidiq.mom_iq[nohs])
	lin1 =lines!(x, ms10_3s[:a, :median] .+ ms10_3s[:b, :median] .* kidiq.mom_hs[nohs] .+ ms10_3s[:c, :median] .* x; 
		color=:darkred)
	x = sort(kidiq.mom_iq[hs])
	lin2 =lines!(x, ms10_3s[:a, :median] .+ ms10_3s[:b, :median] .* kidiq.mom_hs[hs] .+ ms10_3s[:c, :median] .* x; 	
		color=:darkblue)
	Legend(f[1, 2],
    	[sca1, sca2, lin1, lin2],
    	["No high school", "High school", "No high school", "High School"])
	current_figure()
end

# ╔═╡ Cell order:
# ╟─f90c8b82-a52d-45a4-86eb-d2c7eb905692
# ╟─2daed834-e53d-4530-98bd-e80b5b99162f
# ╠═d1c76cd1-2537-470e-a9d5-ebaa5b9dec7e
# ╠═da0eb04e-9930-4f49-809b-3ba5fe16a59c
# ╠═d7992c39-0617-42b5-b977-f04260d2bd03
# ╠═dfe95bfa-507a-4831-b3b5-f26b1d537112
# ╠═4a4605a4-084a-4d64-a444-fa0fcf41ef91
# ╠═d8d8e6b4-6406-43ac-9472-a7afab027aef
# ╠═b5c45959-87c3-4a54-b166-e5795509e316
# ╠═2e1f291f-8e84-4903-b368-a99279a15fcd
# ╠═b77b121b-38d3-485c-a9a2-c9ae87fe3423
# ╠═e348f77e-708f-43ed-863e-795330637846
# ╠═f6129e51-a64d-42ff-812a-bc62152777be
# ╠═0ed2981d-f505-4f99-81dd-26d7a4fa3039
# ╠═dbec5dce-5c24-4ee5-ba33-10385d650d41
# ╠═90f0236a-2c5b-4ea8-83cf-490037bf8c15
# ╠═1204cbcb-a765-461e-a477-ae3d9913b1bf
# ╠═b1c6c6a5-1784-438a-b930-49ce7aef80ab
# ╠═b6330c4f-8129-4bbd-aa39-3ddd00c062b5
# ╠═710348c0-e52b-461c-b024-ebf566fa2e17
# ╠═6014b70b-c10d-4b91-94f7-79dc291cc92b
