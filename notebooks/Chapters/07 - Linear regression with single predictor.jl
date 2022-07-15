### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 2b08cf3d-a148-4981-a389-2abfdc622bf7
using Pkg, DrWatson

# ╔═╡ a28841db-e3f9-4c90-8b7b-144814616800
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

# ╔═╡ ac149089-83e8-45f3-9f64-e55fcab01c5f
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

# ╔═╡ ec89f6e8-0e7b-4be4-9e9d-eec9a800e361
hdi = CSV.read(ros_datadir("HDI", "hdi.csv"), DataFrame)

# ╔═╡ eb645d53-9b17-4361-8d21-8d177c0f3393
hibbs = CSV.read(ros_datadir("ElectionsEconomy", "hibbs.csv"), DataFrame)

# ╔═╡ 2c099d92-5e66-42ae-a00e-e80b3ad540b2
hibbs_lm = lm(@formula(vote ~ growth), hibbs)

# ╔═╡ 8be7f5f7-8ccd-48ce-a097-265ad080eb64
residuals(hibbs_lm)

# ╔═╡ 9481b5e3-6128-4453-8e9f-47a7348046b9
mad(residuals(hibbs_lm))

# ╔═╡ 077cad7f-a2dd-47ef-90dc-96e73819be96
std(residuals(hibbs_lm))

# ╔═╡ 896816d9-6885-44d8-88a6-e4479e39068e
coef(hibbs_lm)

# ╔═╡ 0889d614-d08a-4a74-aefd-d60fb6f6cb03
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

# ╔═╡ 21b35727-bce3-432c-a7bf-30c08be527da
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

# ╔═╡ 17eea6aa-8993-4c04-be06-80100d6d9be4
let
	data = (N=nrow(hibbs), vote=hibbs.vote, growth=hibbs.growth)
	global m7_1s = SampleModel("hibbs", stan7_1)
	global rc7_1s = stan_sample(m7_1s; data)
	success(rc7_1s) && describe(m7_1s)
end

# ╔═╡ 527228aa-3276-47b1-b820-9f7e7be99837
 if success(rc7_1s)
	 post7_1s = success(rc7_1s) && read_samples(m7_1s, :dataframe)
	 ms7_1s = model_summary(post7_1s, [:a, :b, :sigma])
 end

# ╔═╡ 85766eab-6a2e-488f-a3a7-294465bd81c8
trankplot(post7_1s, "b")

# ╔═╡ 50ce2c67-6b33-4c22-afdc-0459154bd64e
let
	growth_range = LinRange(minimum(hibbs.growth), maximum(hibbs.growth), 200)
	votes = mean.(link(post7_1s, (r,x) -> r.a + x * r.b, growth_range))

	fig = Figure()
	xlabel = "Average growth personal income [%]"
	ylabel="Incumbent's party vote share"
	ax = Axis(fig[1, 1]; title="Regression line based on 4000 posterior samples", 
		subtitle = "(grey lines are based on first 200 draws of :a and :b)",
		xlabel, ylabel)
	for i in 1:200
		lines!(growth_range, post7_1s.a[i] .+ post7_1s.b[i] .* growth_range, color = :lightgrey)
	end
	scatter!(hibbs.growth, hibbs.vote)
	lines!(growth_range, votes, color = :red)
	fig
end

# ╔═╡ 2559d7d6-400c-44ed-afd6-6572ce50ac44
let
	println(46.3 + 3 * 2.0) # 52.3, σ = 3.6 (from ms7_1s above)
	probability_of_Clinton_winning = 1 - cdf(Normal(52.3, 3.6), 50)
end

# ╔═╡ cae9dea3-010e-48f9-b45f-1230b4456031
let
	f = Figure()
	ax = Axis(f[1, 1]; title = "")
	x_range = LinRange(30, 70, 100)
	y = pdf.(Normal(52.3, 3.6), x_range)
	lines!(x_range, y)

	x1 = range(50, 70; length=200)
	band!(x1, fill(0, length(x1)), pdf.(Normal(52.3, 3.6), x1);
		color = (:grey, 0.75), label = "Label")

	annotations!("Predicted\n74% change\nof Clinton victory", position=(51, 0.02), textsize=13)
	f
end

# ╔═╡ ff398b3a-1689-458c-bb75-43ef649a4561
let
	a = 46.3
	b = 3.0
	sigma = 3.9
	x = hibbs.growth
	n = length(x)

	y = a .+ b .* x + rand(Normal(0, sigma), n)
	fake = DataFrame(x = x, y = y)

	data = (N=nrow(fake), vote=fake.y, growth=fake.x)
	global m7_2s = SampleModel("fake", stan7_1)
	global rc7_2s = stan_sample(m7_2s; data)
	success(rc7_2s) && describe(m7_2s)
end

# ╔═╡ cf4e7277-514a-4338-b1b3-203399627701
if success(rc7_2s)
	post7_2s = read_samples(m7_2s, :dataframe)
	ms7_2s = model_summary(post7_2s, names(post7_2s))
end

# ╔═╡ 3c2905c3-071e-4f2c-bb4a-dcc322df9553
ms7_1s

# ╔═╡ f4d38b34-e3b8-454b-b4cd-0c381c5fa397
function sim(sm::SampleModel)
	a = 46.3
	b = 3.0
	sigma = 3.9
	x = hibbs.growth
	n = length(x)

	y = a .+ b .* x + rand(Normal(0, sigma), n)
	println(mean(y))
	data_sim = (N=n, vote=y, growth=x)
	rc = stan_sample(sm; data=data_sim)
	post = read_samples(sm, :dataframe)
	ms = model_summary(post, Symbol.([:a, :b, :sigma]))
	b̂ = ms[:b, :mean] 
	b_se = ms[:b, :std]

	(
		b̂ = b̂, 
		b_se = b_se,
		cover_68 = Int(abs(b - b̂) < b_se),
		cover_95 = Int(abs(b - b̂) < 2b_se)
	)
end

# ╔═╡ 428e860e-973a-4154-959e-6294182b1065
m7_2_1s = SampleModel("fake_sim", stan7_1);

# ╔═╡ b3787442-f109-42c5-a1a5-ec199054d3ff
sim(m7_2_1s)

# ╔═╡ f39782c5-a0d0-4546-9e0d-bd0ff6eeaa95
md"## See chapter 7 in Regression and Other Stories."

# ╔═╡ 92ce35e9-ac0a-4f56-a4f8-0649545f4fcf
md" ##### Widen the notebook."

# ╔═╡ 7cb5adb7-fefd-44b5-b60e-37eafdd1e6a0
md"##### A typical set of Julia packages to include in notebooks."

# ╔═╡ a8d7b228-2f7a-434b-b56d-630ae574e233
md"### 7.1 Example: Predicting presidential vote from the economy."

# ╔═╡ 28f6f692-65a1-4b97-825b-62ba6d734244
md"
!!! note

Sometimes I hide or show the output logs. To show them, click on the little circle with 3 dots visible in the top right of the input cell if the cursor is in there. Try it!"

# ╔═╡ 792dbc25-9c7f-4bea-8f67-830d1d9369d4
md" ### 7.2 Checking the model-fitting procedure using simulation."

# ╔═╡ 87f78968-4b8c-48a1-aded-c2af42ef01b1
isdefined(Main, :StanSample)

# ╔═╡ 33a2a072-3cbd-448a-9a9b-7c479f960c28
ms7_1s

# ╔═╡ ccb8833d-f78e-41c7-b6dc-88fe2310c9e7
md" ###### Or use the underlying DataFrame directly."

# ╔═╡ eabd5679-2e9b-48d7-a2ec-b2b90f5c4cfd
ms7_1s["a", "mad_sd"]

# ╔═╡ 2d826832-2dd5-4b54-b7a8-57c628c00c53
ms7_1s[:a, :mad_sd]

# ╔═╡ d678f638-7d6f-4dd2-aefb-34ca7e5d4687
ms7_1s[:, :mad_sd]

# ╔═╡ 61a59205-668e-45c3-b957-31d1f2f1bcf2
ms7_1s[:c, :mad_sd]

# ╔═╡ f090f45c-c907-42fc-bad1-a3f5a4a6b6db
ms7_1s[:a, :mad]

# ╔═╡ d0590cfc-8ed7-49ca-bf44-2f5abd549043
ms7_1s[3, [:median, :mad_sd]]

# ╔═╡ e1201036-f28c-406d-8614-2e2b1327fcef
eltype(ms7_1s.parameters)

# ╔═╡ 21dab61a-148d-4f99-ab7a-d006aa7bea62
# ╠═╡ show_logs = false
let
	n_fake = 10  # 1000
	df = DataFrame()
	cover_68 = Float64[]
	cover_95 = Float64[]
	m7_2_1s = SampleModel("fake_sim_1", stan7_1)

	for i in 1:n_fake
		res = sim(m7_2_1s)
		append!(df, DataFrame(;res...))
	end
	describe(df)
end

# ╔═╡ 8ff83066-3a60-46bb-8667-9cad0a7f9309
md"
!!! note

In above cell, I have hidden the logs. To show them, click on the little circle with 3 dots."

# ╔═╡ e2b8951a-59df-4066-b39e-aba71e3141d5
md" ### 7.3 Formulating comparisons as regression models."

# ╔═╡ 322e4310-102e-4d1a-8507-f30e69604d8f
stan7_3 = "
data {
	int N;
	vector[N] y;
}
parameters {
	real a;
	real sigma;
}
model {
	y ~ normal(a, sigma);
}
";

# ╔═╡ 21cfb523-a5be-4db9-a03b-0a5d149bff53
 begin
 	r₀ = [-0.3, 4.1, -4.9, 3.3, 6.4, 7.2, 10.7, -4.6, 4.7, 6.0, 1.1, -6.7, 10.2, 9.7, 5.6,
		1.7, 1.3, 6.2, -2.1, 6.5]
	[mean(r₀), std(r₀)/sqrt(length(r₀))]
 end

# ╔═╡ 8498471e-17d5-424a-aa83-822b59fd097c
begin
	Random.seed!(3)
	n₀ = 20
	y₀ = r₀
	fake_0 = DataFrame(y₀ = r₀)
	data_0 = (N = nrow(fake_0), y = fake_0.y₀)

	n₁ = 30
	y₁ = rand(Normal(8.0, 5.0), n₁)
	data_1 = (N = n₁, y = y₁)

	se_0 = std(y₀)/sqrt(n₀)
	se_1 = std(y₁)/sqrt(n₁)
	
	(diff=mean(y₁)-mean(y₀), se_0=se_0, se_1=se_1, se=sqrt(se_0^2 + se_1^2))
end

# ╔═╡ e96dbbf1-0775-44e2-bc7c-95d1bedf4cbb
# ╠═╡ show_logs = false
begin
	m7_3_0s = SampleModel("fake_0", stan7_3)
	rc7_3_0s = stan_sample(m7_3_0s; data=data_0)
	success(rc7_3_0s) && describe(m7_3_0s)
end

# ╔═╡ 1f1d9ff2-a5ed-4872-a47e-d3d0d1302e3e
# ╠═╡ show_logs = false
begin
	m7_3_1s = SampleModel("fake_1", stan7_3)
	rc7_3_1s = stan_sample(m7_3_1s; data=data_1)
	success(rc7_3_1s) && describe(m7_3_1s)
end

# ╔═╡ a1799c25-90f3-48a5-857c-3931b76c920d
md" 
!!! note

In above cells, the logs are hidden."

# ╔═╡ 21a222f3-9aaf-429b-8458-bf28623287bd
if success(rc7_3_0s)
	post7_3_0s = read_samples(m7_3_0s, :dataframe)
	sm7_3_0s = model_summary(post7_3_0s, [:a, :sigma])
end

# ╔═╡ 38c38e2f-0c13-4a7b-a379-ddeeffbe6f80
if success(rc7_3_1s)
	post7_3_1s = read_samples(m7_3_1s, :dataframe)
	sm7_3_1s = model_summary(post7_3_1s, [:a, :sigma])
end

# ╔═╡ 0d5ff413-44b3-420d-807b-43c532c616f7
stan7_3_2 = "
data {
	int N;
	vector[N] y;
	vector[N] x;
}
parameters {
	real a;
	real b;
	real sigma;
}
model {
	vector[N] mu;
	mu = a + b * x;
	y ~ normal(mu, sigma);
}
";

# ╔═╡ f364f536-3b00-4892-a0c4-3eaf07bafccd
# ╠═╡ show_logs = false
let
	n = n₀ + n₁
	y = vcat(y₀, y₁)
	x = vcat(zeros(Int, n₀), ones(Int, n₁))
	global fake = DataFrame(x=x, y=y)
	data = (N = n, x = x, y = y)
	global m7_3_2s = SampleModel("fake_2", stan7_3_2)
	global rc7_3_2s = stan_sample(m7_3_2s; data)
	success(rc7_3_2s) && describe(m7_3_2s, [:a, :b, :sigma])
end

# ╔═╡ 8e4cb62d-8252-4203-a345-00fb8628d9bb
if success(rc7_3_2s)
	post7_3_2s = read_samples(m7_3_2s, :dataframe)
	sm7_3_2s = model_summary(post7_3_2s, [:a, :b, :sigma])
end

# ╔═╡ a4ffdd25-d2f7-43e4-83a7-176d813f9d48
let
	f = Figure()
	ax = Axis(f[1, 1]; title="Least-squares regression on an indicator is\nthe same as computing a difference in means",
	xlabel="Indicator, x", ylabel="y")
	x_range = LinRange(0, 1, 100)
	â = sm7_3_2s[:a, :median]
	b̂ = sm7_3_2s[:b, :median]
	y = â .+ b̂ .* x_range
	lines!(x_range, y)
	x = vcat(zeros(Int, n₀), ones(Int, n₁))
	scatter!(fake.x, fake.y)
	ȳ₀ = mean(y₀)
	ȳ₁ = mean(y₁)
	hlines!(ax, [ȳ₀, ȳ₁]; color=:lightgrey)
	annotations!("ȳ₀ = $(round(ȳ₀, digits=1))", position=(0.05, 2.4), textsize=15)
	annotations!("ȳ₁ = $(round(ȳ₁, digits=1))", position=(0.9, 8.2), textsize=15)
	annotations!("y = $(round(â, digits=1)) + $(round(b̂, digits=1)) * x", position=(0.43, 4.4), textsize=15)
	f
end

# ╔═╡ Cell order:
# ╟─f39782c5-a0d0-4546-9e0d-bd0ff6eeaa95
# ╟─92ce35e9-ac0a-4f56-a4f8-0649545f4fcf
# ╠═ac149089-83e8-45f3-9f64-e55fcab01c5f
# ╠═2b08cf3d-a148-4981-a389-2abfdc622bf7
# ╟─7cb5adb7-fefd-44b5-b60e-37eafdd1e6a0
# ╠═a28841db-e3f9-4c90-8b7b-144814616800
# ╟─a8d7b228-2f7a-434b-b56d-630ae574e233
# ╠═ec89f6e8-0e7b-4be4-9e9d-eec9a800e361
# ╠═eb645d53-9b17-4361-8d21-8d177c0f3393
# ╠═2c099d92-5e66-42ae-a00e-e80b3ad540b2
# ╠═8be7f5f7-8ccd-48ce-a097-265ad080eb64
# ╠═9481b5e3-6128-4453-8e9f-47a7348046b9
# ╠═077cad7f-a2dd-47ef-90dc-96e73819be96
# ╠═896816d9-6885-44d8-88a6-e4479e39068e
# ╠═0889d614-d08a-4a74-aefd-d60fb6f6cb03
# ╠═21b35727-bce3-432c-a7bf-30c08be527da
# ╠═17eea6aa-8993-4c04-be06-80100d6d9be4
# ╟─28f6f692-65a1-4b97-825b-62ba6d734244
# ╠═527228aa-3276-47b1-b820-9f7e7be99837
# ╠═85766eab-6a2e-488f-a3a7-294465bd81c8
# ╠═50ce2c67-6b33-4c22-afdc-0459154bd64e
# ╠═2559d7d6-400c-44ed-afd6-6572ce50ac44
# ╠═cae9dea3-010e-48f9-b45f-1230b4456031
# ╟─792dbc25-9c7f-4bea-8f67-830d1d9369d4
# ╠═ff398b3a-1689-458c-bb75-43ef649a4561
# ╠═cf4e7277-514a-4338-b1b3-203399627701
# ╠═3c2905c3-071e-4f2c-bb4a-dcc322df9553
# ╠═f4d38b34-e3b8-454b-b4cd-0c381c5fa397
# ╠═428e860e-973a-4154-959e-6294182b1065
# ╠═b3787442-f109-42c5-a1a5-ec199054d3ff
# ╠═be406a49-edea-4dad-a51a-52aea7853422
# ╠═87f78968-4b8c-48a1-aded-c2af42ef01b1
# ╠═33a2a072-3cbd-448a-9a9b-7c479f960c28
# ╟─ccb8833d-f78e-41c7-b6dc-88fe2310c9e7
# ╠═eabd5679-2e9b-48d7-a2ec-b2b90f5c4cfd
# ╠═2d826832-2dd5-4b54-b7a8-57c628c00c53
# ╠═d678f638-7d6f-4dd2-aefb-34ca7e5d4687
# ╠═a68f5fed-2940-44d5-b19e-730715acb452
# ╠═61a59205-668e-45c3-b957-31d1f2f1bcf2
# ╠═f090f45c-c907-42fc-bad1-a3f5a4a6b6db
# ╠═d0590cfc-8ed7-49ca-bf44-2f5abd549043
# ╠═e1201036-f28c-406d-8614-2e2b1327fcef
# ╠═21dab61a-148d-4f99-ab7a-d006aa7bea62
# ╟─8ff83066-3a60-46bb-8667-9cad0a7f9309
# ╟─e2b8951a-59df-4066-b39e-aba71e3141d5
# ╠═322e4310-102e-4d1a-8507-f30e69604d8f
# ╠═21cfb523-a5be-4db9-a03b-0a5d149bff53
# ╠═8498471e-17d5-424a-aa83-822b59fd097c
# ╠═e96dbbf1-0775-44e2-bc7c-95d1bedf4cbb
# ╠═1f1d9ff2-a5ed-4872-a47e-d3d0d1302e3e
# ╟─a1799c25-90f3-48a5-857c-3931b76c920d
# ╠═21a222f3-9aaf-429b-8458-bf28623287bd
# ╠═38c38e2f-0c13-4a7b-a379-ddeeffbe6f80
# ╠═0d5ff413-44b3-420d-807b-43c532c616f7
# ╠═f364f536-3b00-4892-a0c4-3eaf07bafccd
# ╠═8e4cb62d-8252-4203-a345-00fb8628d9bb
# ╠═a4ffdd25-d2f7-43e4-83a7-176d813f9d48
