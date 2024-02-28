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

	# Specific to ROSStanPluto
	using StanSample
	
    # Graphics related
    using CairoMakie
	using AlgebraOfGraphics
	
    # Include basic packages
    using RegressionAndOtherStories
end

# ╔═╡ eb7ea04a-da52-4e69-ac3e-87dc7f014652
md"## See chapter 1 in Regression and Other Stories."

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

# ╔═╡ 87902f0e-5919-45b3-89a6-b88a7dab9363
md" ### 1.1 The three challenges of statistics."

# ╔═╡ 56aa0b49-1e8a-4390-904d-6f7551f849ea
md"
!!! note

It is not common for me to copy from the book but this particular section deserves an exception!"

# ╔═╡ 47a6a5f3-0a54-46fe-a581-7414c0d9294a
md"

The three challenges of statistical inference are:
1. Generalizing from sample to population, a problem that is associated with survey sampling but actually arises in nearly every application of statistical inference;
2. Generalizing from treatment to control group, a problem that is associated with causal inference, which is implicitly or explicitly part of the interpretation of most regressions we have seen; and
3. Generalizing from observed measurements to the underlying constructs of interest, as most of the time our data do not record exactly what we would ideally like to study.
All three of these challenges can be framed as problems of prediction (for new people or new items that are not in the sample, future outcomes under different potentially assigned treatments, and underlying constructs of interest, if they could be measured exactly).
"

# ╔═╡ 0391fc17-09b7-47d7-b799-6dc6de13e82b
md"### 1.2 Why learn regression?"

# ╔═╡ d830f41c-0fb6-4bff-9fe0-0bd51f444779
hibbs = CSV.read(ros_datadir("ElectionsEconomy", "hibbs.csv"), DataFrame)

# ╔═╡ 23d26498-9ef8-4698-b4fc-d7a586b118fb
arm_datadir()

# ╔═╡ 1a468606-361d-4f22-8c06-107ef789401d
ros_datadir()

# ╔═╡ 583ef308-a202-43d7-9fd2-cfbc1d1dcbb0
armm_datadir()

# ╔═╡ 35bee056-5cd8-48ee-b9c0-74a8b53229bd
hibbs_lm = lm(@formula(vote ~ growth), hibbs)

# ╔═╡ 3c4672aa-d17e-4681-9863-9ee026fefee6
residuals(hibbs_lm)

# ╔═╡ a9970ef7-1e0e-4976-b8c9-1db4dd3a222b
mad(residuals(hibbs_lm))

# ╔═╡ f48df50b-5450-4998-8dab-014c8b9d42a2
std(residuals(hibbs_lm))

# ╔═╡ be41c745-c87d-4f3a-ab4e-a8ae3b9ae091
coef(hibbs_lm)

# ╔═╡ 06ab4f30-68cc-4e35-9fa2-b8f8f25d3776
let
	fig = Figure(; size=default_figure_resolution)
	hibbs.label = string.(hibbs.year)
	xlabel = "Average growth personal income [%]"
	ylabel = "Incumbent's party vote share"
	let
		title = "Forecasting the election from the economy"
		ax = Axis(fig[1, 1]; title, xlabel, ylabel)
		for (ind, yr) in enumerate(hibbs.year)
			annotations!("$(yr)"; position=(hibbs.growth[ind], hibbs.vote[ind]), fontsize=10)
		end
	end
	let
		x = LinRange(-1, 4, 100)
		title = "Data and linear fit"
		ax = Axis(fig[1, 2]; title, xlabel, ylabel)
		scatter!(hibbs.growth, hibbs.vote)
		lines!(x, coef(hibbs_lm)[1] .+ coef(hibbs_lm)[2] .* x; color=:darkred)
		annotations!("vote = 46.2 + 3.0 * growth"; position=(0, 41))
	end
	fig
end

# ╔═╡ fa2fe95b-fe29-40c8-8dfc-27a35e720f3d
md" ### 1.3 Some examples of regression."

# ╔═╡ accfc0d8-968a-4b6c-bc1b-9da1aebe6cde
md" #### Electric company"

# ╔═╡ 305f0fb9-5e3a-45fd-8f57-edfdf65fb0e8
begin
	electric = CSV.read(ros_datadir("ElectricCompany", "electric.csv"), DataFrame)
	electric = electric[:, [:post_test, :pre_test, :grade, :treatment]]
	electric.grade = categorical(electric.grade)
	electric.treatment = categorical(electric.treatment)
	electric
end

# ╔═╡ 43e020d2-063c-43da-b7b3-bbc989002e9e
md"##### A quick look at the overall values of `pre_test` and `post_test`."

# ╔═╡ 3bc6b063-6f3d-4474-99b2-c9270513778a
describe(electric)

# ╔═╡ 82c83206-d5d7-4cc2-b4cd-d43e9c84c68a
all(completecases(electric)) == true

# ╔═╡ 420b8920-5f2a-4e3b-a32e-622252b84444
md" ##### Post-test density for each grade conditioned on treatment."

# ╔═╡ 54e3c7b6-c2b0-47d0-890a-5c55a19e42d9
let
	f = Figure(; size=default_figure_resolution)
	axis = (; width = 200, height = 200)
	el = data(electric) * mapping(:post_test, col=:grade, color=:treatment)
	plt = el * AlgebraOfGraphics.histogram(;bins=20) * mapping(row=:treatment)
	draw!(f[1, 1], plt; axis)
	f
end

# ╔═╡ 63020f0b-ff5e-453b-ba70-98340c3d5265
let
	f = Figure(; size=default_figure_resolution)
	axis = Axis(f[1, 1])
	for i in unique(electric.grade)
		for j in unique(electric.treatment)
			tmp = electric[electric.grade .== i .&& electric.treatment .== 0, :]
			CairoMakie.density!(tmp.post_test)
		end
	end
	axis = Axis(f[2, 1])
	for i in unique(electric.grade)
		for j in unique(electric.treatment)
			tmp = electric[electric.grade .== i .&& electric.treatment .== 1, :]
			CairoMakie.density!(tmp.post_test)
		end
	end
	f
end

# ╔═╡ 308b5a5d-991e-4fe7-8ceb-c8e3f4f269e1
let
	f = Figure(; size=default_figure_resolution)
	for i in unique(electric.grade)
		for j in unique(electric.treatment)
			axis = Axis(f[1, i]; title="Grade=$i. Treatment=0")
			xlims!(25, 140)
			tmp = electric[electric.grade .== i .&& electric.treatment .== 0, :]
			CairoMakie.density!(tmp.post_test)
		end
	end
	for i in unique(electric.grade)
		for j in unique(electric.treatment)
			axis = Axis(f[2, i]; title="Grade=$i. Treatment=1")
			xlims!(25, 140)
			tmp = electric[electric.grade .== i .&& electric.treatment .== 1, :]
			CairoMakie.density!(tmp.post_test)
		end
	end
	f
end

# ╔═╡ fb1e8fd3-7217-4955-83bd-551693f1507b
md"
!!! note

In above cell, as density() is exported by both CairoMakie and AlgebraOfGraphics, it needs to be qualified."

# ╔═╡ 093c1e47-00be-407e-83a4-0ac96be3262c
let
	plt = data(electric) * visual(Violin) * mapping(:grade, :post_test, dodge=:treatment, color=:treatment)
	draw(plt)
end

# ╔═╡ 35307905-cee1-4f35-a149-cdaaf7fc1294
md" #### Peacekeeping"

# ╔═╡ f4b870c6-240d-4a46-98c8-1a0dbe7dfc6b
peace = CSV.read(ros_datadir("PeaceKeeping", "peacekeeping.csv"), missingstring="NA", DataFrame)

# ╔═╡ 00f43b7d-2594-4433-a18f-92d9899fb014
describe(peace)

# ╔═╡ 0eb862b2-d3be-4626-a4e6-3a6bb736c960
md"##### A quick look at this Dates stuff!"

# ╔═╡ baa075dd-18cc-4fac-93ca-5b2011e54c26
peace.cfdate[1]

# ╔═╡ bf4e1ded-1e5e-4e8e-a027-106cc6836ed2
DateTime(1992, 4, 25)

# ╔═╡ 76e1793f-ad85-4714-9dde-4347f47a60fc
Date(1992, 8, 10) - Date(1992, 4, 25)

# ╔═╡ da2e1e8e-8477-4a1a-8bbe-a8a08b5f32ed
Date(1970,1,1)

# ╔═╡ 46e101c6-7d21-4a8a-b96d-3c58b4cdb992
Date(1970,1,1) + Dates.Day(8150)

# ╔═╡ 492f405f-bded-4a0c-9e2a-26c4eca588ce
Date(1992, 4, 25) - Date(1970, 1, 1)

# ╔═╡ 491daea4-d345-4167-a3f1-06669df7106c
peace.faildate[1] - peace.cfdate[1]

# ╔═╡ acda3b77-ccac-45a9-be64-c3747682629b
begin
	pks_df = peace[peace.peacekeepers .== 1, [:cfdate, :faildate]]
	nopks_df = peace[peace.peacekeepers .== 0, [:cfdate, :faildate]]
end;

# ╔═╡ 84723e78-2b12-4652-87eb-34b6026d5ff9
mean(peace.censored)

# ╔═╡ 43e79699-c47d-405b-b1db-eaa51d4fc2c4
length(unique(peace.war))

# ╔═╡ 29ef3b78-adb5-4248-b8d0-d745b3da0e2e
mean(peace[peace.peacekeepers .== 1, :censored])

# ╔═╡ c0f85cc0-fed0-40a4-887d-80d3ef8ebba6
mean(peace[peace.peacekeepers .== 0, :censored])

# ╔═╡ 99adcb27-1150-47f7-9ea3-4bc47c3382ff
mean(peace[peace.peacekeepers .== 1 .&& peace.censored .== 0, :delay])

# ╔═╡ bf4d2451-b429-4f87-9c0f-e4706b70f85c
mean(peace[peace.peacekeepers .== 0 .&& peace.censored .== 0, :delay])

# ╔═╡ 733e1631-b367-4668-81ff-d7518a502f99
median(peace[peace.peacekeepers .== 1 .&& peace.censored .== 0, :delay])

# ╔═╡ 12b83909-e746-42e0-848a-6ec92636f718
median(peace[peace.peacekeepers .== 0 .&& peace.censored .== 0, :delay])

# ╔═╡ 1182e0db-b7da-4233-a24a-27fa16e5c49b
let
	f = Figure(; size=default_figure_resolution)
	pks = peace[peace.peacekeepers .== 1 .&& peace.censored .== 0, :]
	nopks = peace[peace.peacekeepers .== 0 .&& peace.censored .== 0,:]
	
	for i in 1:2
		title = i == 1 ? "Peacekeepers" : "No peacekeepers"

		ax = Axis(f[i, 1]; title, xlabel="Years until return to war",
	    ylabel = "Frequency", yminorticksvisible = true,
		yminorgridvisible = true, yminorticks = IntervalsBetween(8))

		xlims!(ax, [0, 8])
		hist!(i == 1 ? pks.delay : nopks.delay)
	end
	f
end

# ╔═╡ 533858b2-0b7e-4f4f-ac3d-a3d49856ef4b
md"
!!! note

Censored means conflict had not returned until end of observation period (2004)."

# ╔═╡ edd2dbf1-ae2b-4453-a5e3-94b4a51be521
begin
	# Filter out missing badness rows.
	pb = peace[peace.badness .!== missing, :];	
	
	# Delays until return to war for uncensored, peacekeeper cases
	pks_uc = pb[pb.peacekeepers .== 1 .&& pb.censored .== 0, :delay]
	# Delays until return to war for censored, peacekeeper cases
	pks_c = pb[pb.peacekeepers .== 1 .&& pb.censored .== 1, :delay]

	# No peacekeepr cases.
	nopks_uc = pb[pb.peacekeepers .== 0 .&& pb.censored .== 0, :delay]
	nopks_c = pb[pb.peacekeepers .== 0 .&& pb.censored .== 1, :delay]

	# Crude measure (:badness) used for assessing situation
	badness_pks_uc = pb[pb.peacekeepers .== 1 .&& pb.censored .== 0, 
		:badness]
	badness_pks_c = pb[pb.peacekeepers .== 1 .&& pb.censored .== 1, 
		:badness]
	badness_nopks_uc = pb[pb.peacekeepers .== 0 .&& pb.censored .== 0, 
		:badness]
	badness_nopks_c = pb[pb.peacekeepers .== 0 .&& pb.censored .== 1, 
		:badness]
end;

# ╔═╡ 2ec2b2b1-f1d2-4cd5-a23f-2b80abc5d4cd
begin
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1], title = "With UN peacekeepers",
		xlabel = "Pre-treatment measure of problems in country", 
		ylabel = "Delay [yrs] before return to conflict")
	sca1 = scatter!(badness_pks_uc, pks_uc)
	sca2 = scatter!(badness_pks_c, pks_c)
	xlims!(ax, [-13, -2.5])
	Legend(f[1, 2], [sca1, sca2], ["Uncensored", "Censored"])
	ax.xticks = ([-12, -4], ["no so bad", "really bad"])

	
	ax = Axis(f[2, 1], title = "Without UN peacekeepers",
		xlabel = "Pre-treatment measure of problems in country", 
		ylabel = "Delay [yrs] before return to conflict")
	sca1 = scatter!(badness_nopks_uc, nopks_uc)
	sca2 = scatter!(badness_nopks_c, nopks_c)
	xlims!(ax, [-13, -2.5])
	Legend(f[2, 2], [sca1, sca2], ["Uncensored", "Censored"])
	ax.xticks = ([-12, -4], ["no so bad", "really bad"])

	f
end

# ╔═╡ 63917762-446c-4230-ae22-d42f0752ff36
md" ### 1.4 Challenges in building, understanding, and interpreting regression."

# ╔═╡ 783df69c-5368-4a9e-aabf-a46895712289
md" #### Simple causal"

# ╔═╡ 8f61506c-bccf-4614-b2ae-ce6379f71da7
md"
!!! note

In models like below I usually prefer to create 2 separate Stan Language models, one for the continuous case and another for the binary case. But they can be combined in a single model as shown below. I'm using this example to show one way to handle vectors returned from Stan's cmdstan."

# ╔═╡ df82425a-4cf6-4b6d-9421-f8a5b59c4230
stan1_4_1 = "
data {
	int N;
	vector[N] x;
	vector[N] x_binary;
	vector[N] y;
}
parameters {
	vector[2] a;
	vector[2] b;
	vector<lower=0>[2] sigma;
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

# ╔═╡ 20771b96-adb5-4fc9-9679-0a8d42f8f09a
md"
!!! note

Aki Vehtari did not include a seed number in his code.
"

# ╔═╡ 675edafd-145c-43ac-aa3b-2c830b3645e1
begin
	Random.seed!(123)
	n = 50
	x = rand(Uniform(1, 5), n)
	x_binary = [x[i] < 3 ? 0 : 1 for i in 1:n]
	y = [rand(Normal(10 + 3x[i], 3), 1)[1] for i in 1:n]
end;

# ╔═╡ 3fb34dce-1b9d-4bdf-b94e-03a13fd09d30
let
	data = (N = n, x = x, x_binary = x_binary, y = y)
	global m1_4_1s = SampleModel("m1_4_1s", stan1_4_1);
	global rc1_4_1s = stan_sample(m1_4_1s; data)
	success(rc1_4_1s) && describe(m1_4_1s)
end

# ╔═╡ adb8c432-07ef-4844-a75f-c48dffc8746f
md"
!!! note

This is a good point to take a quick look at Pluto cell metadata: the top left `eye` symbol and the top right `3-dots in a circle` glyph (both only visible when the curser is in the input cell). Both are used quite often in these notebooks. Try them out!"

# ╔═╡ efc0e0d6-5d4a-43af-8077-d793caf3a4b4
md" ###### The output of above method of the function `model_summary(::SampleModel)`, called directly on a SampleModel, is different from method `model_summary(::DataFrame)`, typically used later on. Above table shows important mcmc diagnostic columns like `n_eff` and `r_hat`." 

# ╔═╡ 3ca17b14-5c31-490a-9647-946d5470f755
md" ###### If Stan parameters are vectors (as in this example), cmdstan returns those using '.' notation, e.g. a.1, a.2, ..."

# ╔═╡ 942a32ff-1edd-4e84-a1fd-ace09d2b09ec
if success(rc1_4_1s)
	post1_4_1s = read_samples(m1_4_1s, :dataframe)
	model_summary(post1_4_1s, names(post1_4_1s))
end

# ╔═╡ df2896d5-2820-4115-b8fa-bc10ed79f953
md" ###### With vector parameters `read_samples()` can create a nested DataFrame:" 

# ╔═╡ 057a873c-53f9-488a-afde-4444d1ee8f72
nd1_4_1s = read_samples(m1_4_1s, :nesteddataframe)

# ╔═╡ 7798b760-eeab-406a-820e-bf1019395a12
ms1_4_1s = success(rc1_4_1s) && model_summary(post1_4_1s, names(post1_4_1s))

# ╔═╡ 3cb3dc1f-ed9d-47d4-844b-feb5166561dc
ms1_4_1s["b.2", "mad_sd"]

# ╔═╡ 21cd68c8-4e6b-4030-a42d-f9d14abd60ce
md" ###### Nested dataframes are handy to obtain a matrix of say the b values:"

# ╔═╡ a76df572-cf7f-451a-84b0-5023b146da0e
nd1_4_1s.b

# ╔═╡ 55405cd5-9727-4d64-9994-170007f9ad1b
Array(post1_4_1s[:, ["b.1", "b.2"]])

# ╔═╡ e5f22961-b531-4519-bfb0-a8196d77ba6c
let
	x1 = 1.0:0.01:5.0
	f = Figure(; size=default_figure_resolution)
	medians = ms1_4_1s[:, "median"]
	ax = Axis(f[1, 2], title = "Regression on continuous treatment",
		xlabel = "Treatment level", ylabel = "Outcome")
	sca1 = scatter!(x, y)
	annotations!("Slope of fitted line = $(round(medians[3], digits=2))",
		position = (2.8, 10), fontsize=15)
	lin1 = lines!(x1, medians[1] .+ medians[3] * x1)

	x2 = 0.0:0.01:1.0
	ax = Axis(f[1, 1], title="Regression on binary treatment",
		xlabel = "Treatment", ylabel = "Outcome")
	sca1 = scatter!(x_binary, y)
	lin1 = lines!(x2, medians[2] .+ medians[4] * x2)
	annotations!("Slope of fitted line = $(round(medians[4], digits=2))", 
		position = (0.4, 10), fontsize=15)
	f
end

# ╔═╡ 7d7feaf5-1b91-4293-a03d-2598168d0439
stan1_4_2 = "
data {
	int N;
	vector[N] x;
	vector[N] y;
}
parameters {
	vector[2] a;
	real b;
	real b_exp;
	vector<lower=0>[2] sigma;
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

# ╔═╡ 615aa9cb-e138-4ef5-917a-ceb3ab6235c1
let
	#Random.seed!(1533)
	n1 = 50
	x1 = rand(Uniform(1, 5), n1)
	y1 = [rand(Normal(5 + 30exp(-x1[i]), 2), 1)[1] for i in 1:n]
	data = (N = n1, x = x1, y = y1)
	global m1_4_2s = SampleModel("m1.4_2s", stan1_4_2);
	global rc1_4_2s = stan_sample(m1_4_2s; data)
	success(rc1_4_2s) && describe(m1_4_2s)
end

# ╔═╡ 9d1a2f40-e10b-47bc-b5db-5bd8ba6f66e3
if success(rc1_4_2s)
	post1_4_2s = read_samples(m1_4_2s, :dataframe)
	ms1_4_2s = model_summary(post1_4_2s, ["a.1", "a.2", "b", "b_exp", "sigma.1", "sigma.2"])
end

# ╔═╡ 67f0dd34-459f-4eb7-bfbd-eb794a375127
nd1_4_2s = read_samples(m1_4_2s, :nesteddataframe)

# ╔═╡ c122ba29-e2cc-4e1d-a660-cea950221088
array(nd1_4_2s, :a)

# ╔═╡ eaed7d4a-f897-4008-ba9e-c61353c28410
â₁, â₂, b̂, b̂ₑₓₚ, σ̂₁, σ̂₂ = [ms1_4_2s[p, "median"] for p in ["a.1", "a.2", "b", "b_exp", "sigma.1", "sigma.2"]];

# ╔═╡ 10e61721-da24-444e-b668-a910d4faff8a
â₂

# ╔═╡ a772d1be-e8b8-40bb-be95-1ed053dc67de
let
	x1 = LinRange(1, 6, 50)
	y1 = [rand(Normal(5 + 30exp(-x1[i]), 2), 1)[1] for i in 1:length(x1)]
	
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1], title = "Linear regression",
		xlabel = "Treatments", ylabel = "Outcomes")
	scatter!(x1, y1)
	lines!(x1, â₁ .+ b̂ .* x1)

	ax = Axis(f[2, 1], title = "Non-linear regression",
		xlabel = "Treatments", ylabel = "Outcomes")
	scatter!(x1, y1)
	lines!(x1, â₂ .+ b̂ₑₓₚ .* exp.(-x1))
	f
end

# ╔═╡ c4799717-da18-45cb-b544-ac989184d6f4
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

# ╔═╡ 86fce3c6-654d-4a3f-8540-2ec57b3395f3
lm1_8 = lm(@formula(yy ~ xx + z), df1_8)

# ╔═╡ 25db1637-e88e-4bc2-92e4-a968be42c626
lm1_8_0 = lm(@formula(yy ~ xx), df1_8[df1_8.z .== 0, :])

# ╔═╡ 99ee57e4-52ce-44e2-baea-bc04544d0d31
lm1_8_1 = lm(@formula(yy ~ xx), df1_8[df1_8.z .== 1, :])

# ╔═╡ 4d5b73d4-c5a5-4dfd-9354-78db442545b5
let
	â₁, b̂₁ = coef(lm1_8_0)
	â₂, b̂₂ = coef(lm1_8_1)
	x = LinRange(0, maximum(df1_8.xx), 40)
	
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="Figure 1.8")
	scatter!(df1_8.xx[df1_8.z .== 0], df1_8.yy[df1_8.z .== 0])
	scatter!(df1_8.xx[df1_8.z .== 1], df1_8.yy[df1_8.z .== 1])
	lines!(x, â₁ .+ b̂₁ * x, label = "Control")
	lines!(x, â₂ .+ b̂₂ * x, label = "Treated")
	axislegend(; position=(:right, :bottom))
	current_figure()
end

# ╔═╡ 08d695b3-8f77-4079-9106-3d38d9762cc3
md" ### 1.5 Classical and Bayesian inference."

# ╔═╡ 74b247dc-c058-433b-9881-e1b85dacae84
md" ### 1.6 Computing least-squares and Bayesian regression."

# ╔═╡ effd481c-a47f-404a-a42f-207528b9b41b
md" ### 1.8 Exercises."

# ╔═╡ 08710628-ff52-4a95-a4f5-5dfce2fda165
md" #### Helicopters"

# ╔═╡ b2045d0f-afc1-4046-90c5-55f39cf11c84
helicopters = CSV.read(ros_datadir("Helicopters", "helicopters.csv"), DataFrame)

# ╔═╡ 72f0a072-9c65-4a91-98b5-8967f2f6a5f3
md" ##### Simulate 40 helicopters."

# ╔═╡ f7444121-7211-4999-ac6b-3a3c8738a4e3
begin
	helis = DataFrame(width_cm = rand(Normal(5, 2), 40), length_cm = rand(Normal(10, 4), 40))
	helis.time_sec = 0.5 .+ 0.04 .* helis.width_cm .+ 0.08 .* helis.length_cm .+ 0.1 .* rand(Normal(0, 1), 40)
	helis
end

# ╔═╡ 82becf62-2701-4af6-87e6-4ee0a0c91eac
stan1_5 = "
data {
	int N;
	vector[N] w;
	vector[N] l;
	vector[N] y;
}
parameters {
	real a;
	real b;
	real c;
	real<lower=0> sigma;
}
model {
	// Priors
	a ~ normal(10, 5);
	b ~ normal(0, 5);
	sigma ~ exponential(1);

	// Likelihood time on width
	vector[N] mu;
	for ( i in 1:N )
		mu[i] = a + b * w[i] + c * l[i];
	y ~ normal(mu, sigma);
}
";

# ╔═╡ 12588d28-10dc-4551-84f2-ecf82a09aef0
let
	data = (N = nrow(helis), y = helis.time_sec, w = helis.width_cm, l = helis.length_cm)
	global m1_5s = SampleModel("m1.5s", stan1_5);
	global rc1_5s = stan_sample(m1_5s; data)
	success(rc1_5s) && describe(m1_5s)
end

# ╔═╡ fbb2e703-fbff-4dd4-a58c-3b2f5b6f49e1
if success(rc1_5s)
	post1_5s = read_samples(m1_5s, :dataframe)
	model_summary(post1_5s, [:a, :b, :c, :sigma]; digits=4)
end

# ╔═╡ f7ba1202-2fe8-4289-8905-96e9849a513d
plot_chains(post1_5s, [:a, :b, :c])

# ╔═╡ 50588b61-75b1-42b6-9870-43641811d0ad
plot_chains(post1_5s, [:sigma])

# ╔═╡ 790839f9-0b49-4da2-8dc1-00bab883e3af
let
	w_range = LinRange(1.0, 8.0, 100)
	w_times = mean.(link(post1_5s, (r, w) -> r.a + r.c + r.b * w, w_range))
	l_range = LinRange(6.0, 15.0, 100)
	l_times = mean.(link(post1_5s, (r, l) -> r.a + r.b + r.c * l, l_range))
	
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1], title = "Time in the air on width and length",
		xlabel = "Width/Length", ylabel = "Time in the air")
	
	lines!(w_range, w_times; label="Width")
	lines!(l_range, l_times; label="Length")

	f[1, 2] = Legend(f, ax, "Regression lines", framevisible = false)
	
	current_figure()
end

# ╔═╡ b518fea5-298c-46f0-a749-4238ba2af17f
lnk1_5s = link(post1_5s, (r, l) -> r.a + r.b + r.c * l, [5, 10,12])

# ╔═╡ 7434c4d4-b398-41c3-ab52-1b1b8a4b4f72
median.(lnk1_5s)

# ╔═╡ 07ea7258-f35d-439a-9c20-71e4b95df808
mad.(lnk1_5s)

# ╔═╡ b413c2d6-dc44-4437-8123-ee7793863387
mean.(link(post1_5s, (r, l) -> r.a + r.b + r.c * l, [5, 10,12]))

# ╔═╡ 7200f437-e573-42f0-9bd0-246d51373647
read_samples(m1_5s, :nesteddataframe)

# ╔═╡ Cell order:
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╟─cf39df58-3371-4535-88e4-f3f6c0404500
# ╠═0616ece8-ccf8-4281-bfed-9c1192edf88e
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═d7753cf6-7452-421a-a3ec-76e07646f808
# ╠═550371ad-d411-4e66-9d63-7329322c6ea1
# ╟─87902f0e-5919-45b3-89a6-b88a7dab9363
# ╟─56aa0b49-1e8a-4390-904d-6f7551f849ea
# ╟─47a6a5f3-0a54-46fe-a581-7414c0d9294a
# ╟─0391fc17-09b7-47d7-b799-6dc6de13e82b
# ╠═d830f41c-0fb6-4bff-9fe0-0bd51f444779
# ╠═23d26498-9ef8-4698-b4fc-d7a586b118fb
# ╠═1a468606-361d-4f22-8c06-107ef789401d
# ╠═583ef308-a202-43d7-9fd2-cfbc1d1dcbb0
# ╠═35bee056-5cd8-48ee-b9c0-74a8b53229bd
# ╠═3c4672aa-d17e-4681-9863-9ee026fefee6
# ╠═a9970ef7-1e0e-4976-b8c9-1db4dd3a222b
# ╠═f48df50b-5450-4998-8dab-014c8b9d42a2
# ╠═be41c745-c87d-4f3a-ab4e-a8ae3b9ae091
# ╠═06ab4f30-68cc-4e35-9fa2-b8f8f25d3776
# ╟─fa2fe95b-fe29-40c8-8dfc-27a35e720f3d
# ╟─accfc0d8-968a-4b6c-bc1b-9da1aebe6cde
# ╠═305f0fb9-5e3a-45fd-8f57-edfdf65fb0e8
# ╟─43e020d2-063c-43da-b7b3-bbc989002e9e
# ╠═3bc6b063-6f3d-4474-99b2-c9270513778a
# ╠═82c83206-d5d7-4cc2-b4cd-d43e9c84c68a
# ╟─420b8920-5f2a-4e3b-a32e-622252b84444
# ╠═54e3c7b6-c2b0-47d0-890a-5c55a19e42d9
# ╠═63020f0b-ff5e-453b-ba70-98340c3d5265
# ╠═308b5a5d-991e-4fe7-8ceb-c8e3f4f269e1
# ╟─fb1e8fd3-7217-4955-83bd-551693f1507b
# ╠═093c1e47-00be-407e-83a4-0ac96be3262c
# ╟─35307905-cee1-4f35-a149-cdaaf7fc1294
# ╠═f4b870c6-240d-4a46-98c8-1a0dbe7dfc6b
# ╠═00f43b7d-2594-4433-a18f-92d9899fb014
# ╟─0eb862b2-d3be-4626-a4e6-3a6bb736c960
# ╠═baa075dd-18cc-4fac-93ca-5b2011e54c26
# ╠═bf4e1ded-1e5e-4e8e-a027-106cc6836ed2
# ╠═76e1793f-ad85-4714-9dde-4347f47a60fc
# ╠═da2e1e8e-8477-4a1a-8bbe-a8a08b5f32ed
# ╠═46e101c6-7d21-4a8a-b96d-3c58b4cdb992
# ╠═492f405f-bded-4a0c-9e2a-26c4eca588ce
# ╠═491daea4-d345-4167-a3f1-06669df7106c
# ╠═acda3b77-ccac-45a9-be64-c3747682629b
# ╠═84723e78-2b12-4652-87eb-34b6026d5ff9
# ╠═43e79699-c47d-405b-b1db-eaa51d4fc2c4
# ╠═29ef3b78-adb5-4248-b8d0-d745b3da0e2e
# ╠═c0f85cc0-fed0-40a4-887d-80d3ef8ebba6
# ╠═99adcb27-1150-47f7-9ea3-4bc47c3382ff
# ╠═bf4d2451-b429-4f87-9c0f-e4706b70f85c
# ╠═733e1631-b367-4668-81ff-d7518a502f99
# ╠═12b83909-e746-42e0-848a-6ec92636f718
# ╠═1182e0db-b7da-4233-a24a-27fa16e5c49b
# ╟─533858b2-0b7e-4f4f-ac3d-a3d49856ef4b
# ╠═edd2dbf1-ae2b-4453-a5e3-94b4a51be521
# ╠═2ec2b2b1-f1d2-4cd5-a23f-2b80abc5d4cd
# ╟─63917762-446c-4230-ae22-d42f0752ff36
# ╟─783df69c-5368-4a9e-aabf-a46895712289
# ╟─8f61506c-bccf-4614-b2ae-ce6379f71da7
# ╠═df82425a-4cf6-4b6d-9421-f8a5b59c4230
# ╟─20771b96-adb5-4fc9-9679-0a8d42f8f09a
# ╠═675edafd-145c-43ac-aa3b-2c830b3645e1
# ╠═3fb34dce-1b9d-4bdf-b94e-03a13fd09d30
# ╟─adb8c432-07ef-4844-a75f-c48dffc8746f
# ╟─efc0e0d6-5d4a-43af-8077-d793caf3a4b4
# ╟─3ca17b14-5c31-490a-9647-946d5470f755
# ╠═942a32ff-1edd-4e84-a1fd-ace09d2b09ec
# ╟─df2896d5-2820-4115-b8fa-bc10ed79f953
# ╠═057a873c-53f9-488a-afde-4444d1ee8f72
# ╠═7798b760-eeab-406a-820e-bf1019395a12
# ╠═3cb3dc1f-ed9d-47d4-844b-feb5166561dc
# ╟─21cd68c8-4e6b-4030-a42d-f9d14abd60ce
# ╠═a76df572-cf7f-451a-84b0-5023b146da0e
# ╠═55405cd5-9727-4d64-9994-170007f9ad1b
# ╠═e5f22961-b531-4519-bfb0-a8196d77ba6c
# ╠═7d7feaf5-1b91-4293-a03d-2598168d0439
# ╠═615aa9cb-e138-4ef5-917a-ceb3ab6235c1
# ╠═9d1a2f40-e10b-47bc-b5db-5bd8ba6f66e3
# ╠═67f0dd34-459f-4eb7-bfbd-eb794a375127
# ╠═c122ba29-e2cc-4e1d-a660-cea950221088
# ╠═eaed7d4a-f897-4008-ba9e-c61353c28410
# ╠═10e61721-da24-444e-b668-a910d4faff8a
# ╠═a772d1be-e8b8-40bb-be95-1ed053dc67de
# ╠═c4799717-da18-45cb-b544-ac989184d6f4
# ╠═86fce3c6-654d-4a3f-8540-2ec57b3395f3
# ╠═25db1637-e88e-4bc2-92e4-a968be42c626
# ╠═99ee57e4-52ce-44e2-baea-bc04544d0d31
# ╠═4d5b73d4-c5a5-4dfd-9354-78db442545b5
# ╟─08d695b3-8f77-4079-9106-3d38d9762cc3
# ╟─74b247dc-c058-433b-9881-e1b85dacae84
# ╟─effd481c-a47f-404a-a42f-207528b9b41b
# ╟─08710628-ff52-4a95-a4f5-5dfce2fda165
# ╠═b2045d0f-afc1-4046-90c5-55f39cf11c84
# ╟─72f0a072-9c65-4a91-98b5-8967f2f6a5f3
# ╠═f7444121-7211-4999-ac6b-3a3c8738a4e3
# ╠═82becf62-2701-4af6-87e6-4ee0a0c91eac
# ╠═12588d28-10dc-4551-84f2-ecf82a09aef0
# ╠═fbb2e703-fbff-4dd4-a58c-3b2f5b6f49e1
# ╠═f7ba1202-2fe8-4289-8905-96e9849a513d
# ╠═50588b61-75b1-42b6-9870-43641811d0ad
# ╠═790839f9-0b49-4da2-8dc1-00bab883e3af
# ╠═b518fea5-298c-46f0-a749-4238ba2af17f
# ╠═7434c4d4-b398-41c3-ab52-1b1b8a4b4f72
# ╠═07ea7258-f35d-439a-9c20-71e4b95df808
# ╠═b413c2d6-dc44-4437-8123-ee7793863387
# ╠═7200f437-e573-42f0-9bd0-246d51373647
