### A Pluto.jl notebook ###
# v0.19.19

using Markdown
using InteractiveUtils

# ╔═╡ 5084b8f0-65ac-4704-b1fc-2a9008132bd7
using Pkg

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
        padding-right: max(160px, 30%);
    }
</style>
"""

# ╔═╡ 3d46979f-8d7e-4e05-8db5-7aa2d674c8c7
#default_figure_resolution = (1100, 600);

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
	fig = Figure(resolution = default_figure_resolution)
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
	f = Figure(resolution = default_figure_resolution)
	axis = (; width = 150, height = 150)
	el = data(electric) * mapping(:post_test, col=:grade, color=:treatment)
	plt = el * AlgebraOfGraphics.histogram(;bins=20) * mapping(row=:treatment)
	draw!(f[1, 1], plt; axis)
	f
end

# ╔═╡ 3c03311f-bdb8-4c06-a870-3e70a628f684
let
	f = Figure(resolution = default_figure_resolution)
	axis = (; width = 150, height = 150)
	el = data(electric) * mapping(:post_test, col=:grade, color=:treatment)
	plt = el * AlgebraOfGraphics.density() * mapping(row=:treatment)
	draw!(f[1, 1], plt; axis)
	f
end

# ╔═╡ fb1e8fd3-7217-4955-83bd-551693f1507b
md"
!!! note

In above cell, as density() is exported by both GLMakie and AlgebraOfGraphics, it needs to be qualified."

# ╔═╡ 30b7e449-bcc7-4dbe-aef3-a50b85048f03
let
	f = Figure(resolution = default_figure_resolution)
	el = data(electric) * mapping(:post_test, col=:grade)
	plt = el * AlgebraOfGraphics.density() * mapping(color=:treatment)
	draw!(f[1, 1], plt)
	f
end

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
	f = Figure(resolution = default_figure_resolution)
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
	f = Figure(resolution = default_figure_resolution)
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
array(nd1_4_1s, :b)

# ╔═╡ 55405cd5-9727-4d64-9994-170007f9ad1b
Array(post1_4_1s[:, ["b.1", "b.2"]])

# ╔═╡ e5f22961-b531-4519-bfb0-a8196d77ba6c
let
	x1 = 1.0:0.01:5.0
	f = Figure(resolution = default_figure_resolution)
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
	
	f = Figure(resolution = default_figure_resolution)
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
	
	f = Figure(resolution = default_figure_resolution)
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
	
	f = Figure(resolution = default_figure_resolution)
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

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
AlgebraOfGraphics = "cbdf2221-f076-402e-a563-3d30da359d67"
CairoMakie = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
GLM = "38e38edf-8417-5370-95a0-9cbb8c7f171a"
Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
RegressionAndOtherStories = "21324389-b050-441a-ba7b-9a837781bda0"
StanSample = "c1514b29-d3a0-5178-b312-660c88baa699"

[compat]
AlgebraOfGraphics = "~0.6.13"
CairoMakie = "~0.10.1"
GLM = "~1.8.1"
RegressionAndOtherStories = "~0.8.0"
StanSample = "~7.0.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.0-DEV"
manifest_format = "2.0"
project_hash = "1c4621161ffc52f18ae51ab1dffe12d1ed17c223"

[[deps.ANSIColoredPrinters]]
git-tree-sha1 = "574baf8110975760d391c710b6341da1afa48d8c"
uuid = "a4c015fc-c6ff-483c-b24f-f7ea428134e9"
version = "0.0.1"

[[deps.AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "69f7020bd72f069c219b5e8c236c1fa90d2cb409"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.2.1"

[[deps.AbstractTrees]]
git-tree-sha1 = "52b3b436f8f73133d7bc3a6c71ee7ed6ab2ab754"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.3"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "195c5505521008abea5aee4f96930717958eac6f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.4.0"

[[deps.AlgebraOfGraphics]]
deps = ["Colors", "Dates", "Dictionaries", "FileIO", "GLM", "GeoInterface", "GeometryBasics", "GridLayoutBase", "KernelDensity", "Loess", "Makie", "PlotUtils", "PooledArrays", "RelocatableFolders", "StatsBase", "StructArrays", "Tables"]
git-tree-sha1 = "3faa74d8af5a9bdcf79236c2984db71ba9e81e74"
uuid = "cbdf2221-f076-402e-a563-3d30da359d67"
version = "0.6.13"

[[deps.Animations]]
deps = ["Colors"]
git-tree-sha1 = "e81c509d2c8e49592413bfb0bb3b08150056c79d"
uuid = "27a7e980-b3e6-11e9-2bcd-0b925532e340"
version = "0.4.1"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Automa]]
deps = ["Printf", "ScanByte", "TranscodingStreams"]
git-tree-sha1 = "d50976f217489ce799e366d9561d56a98a30d7fe"
uuid = "67c07d97-cdcb-5c2c-af73-a7f9c32a568b"
version = "0.8.2"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "1dd4d9f5beebac0c03446918741b1a03dc5e5788"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.6"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CEnum]]
git-tree-sha1 = "eb4cb44a499229b3b8426dcfb5dd85333951ff90"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.2"

[[deps.CRC32c]]
uuid = "8bf52ea8-c179-5cab-976a-9e18b702a9bc"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "SnoopPrecompile", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "c700cce799b51c9045473de751e9319bdd1c6e94"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.9"

[[deps.Cairo]]
deps = ["Cairo_jll", "Colors", "Glib_jll", "Graphics", "Libdl", "Pango_jll"]
git-tree-sha1 = "d0b3f8b4ad16cb0a2988c6788646a5e6a17b6b1b"
uuid = "159f3aea-2a34-519c-b102-8c37f9878175"
version = "1.0.5"

[[deps.CairoMakie]]
deps = ["Base64", "Cairo", "Colors", "FFTW", "FileIO", "FreeType", "GeometryBasics", "LinearAlgebra", "Makie", "SHA", "SnoopPrecompile"]
git-tree-sha1 = "439517f69683932a078b2976ca040e21dd18598c"
uuid = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
version = "0.10.1"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.CategoricalArrays]]
deps = ["DataAPI", "Future", "Missings", "Printf", "Requires", "Statistics", "Unicode"]
git-tree-sha1 = "5084cc1a28976dd1642c9f337b28a3cb03e0f7d2"
uuid = "324d7699-5711-5eae-9e2f-1d82baa6b597"
version = "0.10.7"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "e7ff6cadf743c098e08fca25c91103ee4303c9bb"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.6"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "38f7a08f19d8810338d4f5085211c7dfa5d5bdd8"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.4"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorBrewer]]
deps = ["Colors", "JSON", "Test"]
git-tree-sha1 = "61c5334f33d91e570e1d0c3eb5465835242582c4"
uuid = "a2cac450-b92f-5266-8821-25eda20663c8"
version = "0.4.0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Random", "SnoopPrecompile"]
git-tree-sha1 = "aa3edc8f8dea6cbfa176ee12f7c2fc82f0608ed3"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.20.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "600cc5508d66b78aae350f7accdb58763ac18589"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.10"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "fc08e5930ee9a4e03f84bfb5211cb54e7769758a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.10"

[[deps.Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "00a2cccc7f098ff3b66806862d275ca3db9e6e5a"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.5.0"

[[deps.CompatHelperLocal]]
deps = ["DocStringExtensions", "Pkg", "UUIDs"]
git-tree-sha1 = "be25ab802a22a212ce4da944fe60d7c250ddcfe1"
uuid = "5224ae11-6099-4aaa-941d-3aab004bd678"
version = "0.1.25"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.2+0"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "fb21ddd70a051d882a1686a5a550990bbe371a95"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.4.1"

[[deps.Contour]]
git-tree-sha1 = "d05d9e7b7aedff4e5b51a029dced05cfb6125781"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.2"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "e8119c1a33d267e16108be441a287a6981ba1630"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.14.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SnoopPrecompile", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "d4f69885afa5e6149d0cab3818491565cf41446d"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.4.4"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.Dictionaries]]
deps = ["Indexing", "Random", "Serialization"]
git-tree-sha1 = "e82c3c97b5b4ec111f3c1b55228cebc7510525a2"
uuid = "85a47980-9c8c-11e8-2b9f-f7ca1fa99fb4"
version = "0.3.25"

[[deps.Distances]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "3258d0659f812acde79e8a74b11f17ac06d0ca04"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.7"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "a7756d098cbabec6b3ac44f369f74915e8cfd70a"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.79"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Documenter]]
deps = ["ANSIColoredPrinters", "Base64", "Dates", "DocStringExtensions", "IOCapture", "InteractiveUtils", "JSON", "LibGit2", "Logging", "Markdown", "REPL", "Test", "Unicode"]
git-tree-sha1 = "6030186b00a38e9d0434518627426570aac2ef95"
uuid = "e30172f5-a6a5-5a46-863b-614d45cd2de4"
version = "0.27.23"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e3290f2d49e661fbd94046d7e3726ffcb2d41053"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.4+0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bad72f730e9e91c08d9427d5e8db95478a3c323d"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.4.8+0"

[[deps.Extents]]
git-tree-sha1 = "5e1e4c53fa39afe63a7d356e30452249365fba99"
uuid = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
version = "0.1.1"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Pkg", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "74faea50c1d007c85837327f6775bea60b5492dd"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.2+2"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "90630efff0894f8142308e334473eba54c433549"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.5.0"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "7be5f99f7d15578798f338f5433b6c432ea8037b"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.16.0"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "e27c4ebe80e8699540f2d6c805cc12203b614f12"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.20"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "9a0472ec2f5409db243160a8b030f94c380167a3"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.13.6"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.FreeType]]
deps = ["CEnum", "FreeType2_jll"]
git-tree-sha1 = "cabd77ab6a6fdff49bfd24af2ebe76e6e018a2b4"
uuid = "b38be410-82b0-50bf-ab77-7b57e271db43"
version = "4.0.0"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FreeTypeAbstraction]]
deps = ["ColorVectorSpace", "Colors", "FreeType", "GeometryBasics"]
git-tree-sha1 = "38a92e40157100e796690421e34a11c107205c86"
uuid = "663a7486-cb36-511b-a19d-713bb74d65c9"
version = "0.10.0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLM]]
deps = ["Distributions", "LinearAlgebra", "Printf", "Reexport", "SparseArrays", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns", "StatsModels"]
git-tree-sha1 = "884477b9886a52a84378275737e2823a5c98e349"
uuid = "38e38edf-8417-5370-95a0-9cbb8c7f171a"
version = "1.8.1"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "6872f5ec8fd1a38880f027a26739d42dcda6691f"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.2"

[[deps.GeoInterface]]
deps = ["Extents"]
git-tree-sha1 = "fb28b5dc239d0174d7297310ef7b84a11804dfab"
uuid = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
version = "1.0.1"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "GeoInterface", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "fe9aea4ed3ec6afdfbeb5a4f39a2208909b162a6"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.5"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "d3b3624125c1474292d0d8ed0f65554ac37ddb23"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.74.0+2"

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "d61890399bc535850c4bf08e4e0d3a7ad0f21cbd"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.2"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.GridLayoutBase]]
deps = ["GeometryBasics", "InteractiveUtils", "Observables"]
git-tree-sha1 = "678d136003ed5bceaab05cf64519e3f956ffa4ba"
uuid = "3955a311-db13-416c-9275-1d80ed98e5e9"
version = "0.9.1"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions", "Test"]
git-tree-sha1 = "709d864e3ed6e3545230601f94e11ebc65994641"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.11"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.ImageAxes]]
deps = ["AxisArrays", "ImageBase", "ImageCore", "Reexport", "SimpleTraits"]
git-tree-sha1 = "c54b581a83008dc7f292e205f4c409ab5caa0f04"
uuid = "2803e5a7-5153-5ecf-9a86-9b4c37f5f5ac"
version = "0.6.10"

[[deps.ImageBase]]
deps = ["ImageCore", "Reexport"]
git-tree-sha1 = "b51bb8cae22c66d0f6357e3bcb6363145ef20835"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.5"

[[deps.ImageCore]]
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Graphics", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "Reexport"]
git-tree-sha1 = "acf614720ef026d38400b3817614c45882d75500"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.9.4"

[[deps.ImageIO]]
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs"]
git-tree-sha1 = "342f789fd041a55166764c351da1710db97ce0e0"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.6"

[[deps.ImageMetadata]]
deps = ["AxisArrays", "ImageAxes", "ImageBase", "ImageCore"]
git-tree-sha1 = "36cbaebed194b292590cba2593da27b34763804a"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.8"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "87f7662e03a649cffa2e05bf19c303e168732d3e"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.2+0"

[[deps.Indexing]]
git-tree-sha1 = "ce1566720fd6b19ff3411404d4b977acd4814f9f"
uuid = "313cdc1a-70c2-5d6a-ae34-0150d3930a38"
version = "1.1.1"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "5cd07aab533df5170988219191dfad0519391428"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.3"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "0cf92ec945125946352f3d46c96976ab972bde6f"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.3.2"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "721ec2cf720536ad005cb38f50dbba7b02419a15"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.14.7"

[[deps.IntervalSets]]
deps = ["Dates", "Random", "Statistics"]
git-tree-sha1 = "16c0cc91853084cb5f58a78bd209513900206ce6"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.4"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "49510dfcb407e572524ba94aeae2fced1f3feb0f"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.8"

[[deps.InvertedIndices]]
git-tree-sha1 = "82aec7a3dd64f4d9584659dc0b62ef7db2ef3e19"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.2.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.Isoband]]
deps = ["isoband_jll"]
git-tree-sha1 = "f9b6d97355599074dc867318950adaa6f9946137"
uuid = "f1662d9f-8043-43de-a69a-05efc1cc6ff4"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "a77b273f1ddec645d1b7c4fd5fb98c8f90ad10a5"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.1"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b53380851c6e6664204efb2e62cd24fa5c47e4ba"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.2+0"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "9816b296736292a80b9a3200eb7fbb57aaa3917a"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.5"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LazyModules]]
git-tree-sha1 = "a560dd966b386ac9ae60bdd3a3d3a326062d3c3e"
uuid = "8cdb02fc-e678-4876-92c5-9defec4f444e"
version = "0.3.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c7cb1f5d892775ba13767a87c7ada0b980ea0a71"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+2"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Loess]]
deps = ["Distances", "LinearAlgebra", "Statistics"]
git-tree-sha1 = "46efcea75c890e5d820e670516dc156689851722"
uuid = "4345ca2d-374a-55d4-8d30-97f9976e7612"
version = "0.5.4"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "946607f84feb96220f480e0422d3484c49c00239"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.19"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "2ce8695e1e699b68702c03402672a69f54b8aca9"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2022.2.0+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "42324d08725e200c23d4dfb549e0d5d89dede2d2"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.10"

[[deps.Makie]]
deps = ["Animations", "Base64", "ColorBrewer", "ColorSchemes", "ColorTypes", "Colors", "Contour", "Distributions", "DocStringExtensions", "Downloads", "FFMPEG", "FileIO", "FixedPointNumbers", "Formatting", "FreeType", "FreeTypeAbstraction", "GeometryBasics", "GridLayoutBase", "ImageIO", "InteractiveUtils", "IntervalSets", "Isoband", "KernelDensity", "LaTeXStrings", "LinearAlgebra", "MakieCore", "Markdown", "Match", "MathTeXEngine", "MiniQhull", "Observables", "OffsetArrays", "Packing", "PlotUtils", "PolygonOps", "Printf", "Random", "RelocatableFolders", "Setfield", "Showoff", "SignedDistanceFields", "SnoopPrecompile", "SparseArrays", "StableHashTraits", "Statistics", "StatsBase", "StatsFuns", "StructArrays", "TriplotBase", "UnicodeFun"]
git-tree-sha1 = "20f42c8f4d70a795cb7927d7312b98a255209155"
uuid = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
version = "0.19.1"

[[deps.MakieCore]]
deps = ["Observables"]
git-tree-sha1 = "c5b3ce048ee73a08bbca1b9f4a776e64257611d5"
uuid = "20f20a25-4f0e-4fdf-b5d1-57303727442b"
version = "0.6.1"

[[deps.MappedArrays]]
git-tree-sha1 = "e8b359ef06ec72e8c030463fe02efe5527ee5142"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.1"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.Match]]
git-tree-sha1 = "1d9bc5c1a6e7ee24effb93f175c9342f9154d97f"
uuid = "7eb4fadd-790c-5f42-8a69-bfa0b872bfbf"
version = "1.2.0"

[[deps.MathTeXEngine]]
deps = ["AbstractTrees", "Automa", "DataStructures", "FreeTypeAbstraction", "GeometryBasics", "LaTeXStrings", "REPL", "RelocatableFolders", "Test", "UnicodeFun"]
git-tree-sha1 = "f04120d9adf4f49be242db0b905bea0be32198d1"
uuid = "0a4f8689-d25c-4efe-a92b-7142dfc1aa53"
version = "0.5.4"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.MiniQhull]]
deps = ["QhullMiniWrapper_jll"]
git-tree-sha1 = "9dc837d180ee49eeb7c8b77bb1c860452634b0d1"
uuid = "978d7f02-9e05-4691-894f-ae31a51d76ca"
version = "0.4.0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "7b86a5d4d70a9f5cdf2dacb3cbe6d251d1a61dbe"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.4"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "a7c3d1da1189a1c2fe843a3bfa04d18d20eb3211"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.1"

[[deps.NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "2fd5787125d1a93fbe30961bd841707b8a80d75b"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.9.6"

[[deps.NamedTupleTools]]
git-tree-sha1 = "90914795fc59df44120fe3fff6742bb0d7adb1d0"
uuid = "d9ec5142-1e00-5aa0-9d6a-321866360f50"
version = "0.14.3"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore", "ImageMetadata"]
git-tree-sha1 = "5ae7ca23e13855b3aba94550f26146c01d259267"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.1.0"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Observables]]
git-tree-sha1 = "6862738f9796b3edc1c09d0890afce4eca9e7e93"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.5.4"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "f71d8950b724e9ff6110fc948dff5a329f901d64"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.8"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+0"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "327f53360fdb54df7ecd01e96ef1983536d1e633"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.2"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "923319661e9a22712f24596ce81c54fc0366f304"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.1.1+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6e9dba33f9f2c44e08a020b0caf6903be540004"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.19+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+0"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "cf494dca75a69712a72b80bc48f59dcf3dea63ec"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.16"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "f809158b27eba0c18c269cf2a2be6ed751d3e81d"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.3.17"

[[deps.Packing]]
deps = ["GeometryBasics"]
git-tree-sha1 = "ec3edfe723df33528e085e632414499f26650501"
uuid = "19eb6ba3-879d-56ad-ad62-d5c202156566"
version = "0.5.0"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "03a7a85b76381a3d04c7a1656039197e70eda03d"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.11"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "84a314e3926ba9ec66ac097e3635e270986b0f10"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.50.9+0"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates", "SnoopPrecompile"]
git-tree-sha1 = "6466e524967496866901a78fca3f2e9ea445a559"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.2"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.0"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "f6cf8e7944e50901594838951729a1861e668cb8"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.3.2"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "SnoopPrecompile", "Statistics"]
git-tree-sha1 = "5b7690dd212e026bbab1860016a6601cb077ab66"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.3.2"

[[deps.PolygonOps]]
git-tree-sha1 = "77b3d3605fc1cd0b42d95eba87dfcd2bf67d5ff6"
uuid = "647866c9-e3ac-4575-94e7-e3d426903924"
version = "0.1.2"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "LaTeXStrings", "Markdown", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "96f6db03ab535bdb901300f88335257b0018689d"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.2.2"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "d7a7aef8f8f2d537104f170139553b14dfe39fe9"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.2"

[[deps.QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "18e8f4d1426e965c7b532ddd260599e1510d26ce"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.0"

[[deps.QhullMiniWrapper_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Qhull_jll"]
git-tree-sha1 = "607cf73c03f8a9f83b36db0b86a3a9c14179621f"
uuid = "460c41e3-6112-5d7f-b78c-b6823adb3f2d"
version = "1.0.0+1"

[[deps.Qhull_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "238dd7e2cc577281976b9681702174850f8d4cbc"
uuid = "784f63db-0788-585a-bace-daefebcd302b"
version = "8.0.1001+0"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "97aa253e65b784fd13e83774cadc95b38011d734"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.6.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "dc84268fe0e3335a62e315a3a7cf2afa7178a734"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.3"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RegressionAndOtherStories]]
deps = ["CSV", "CategoricalArrays", "DataFrames", "DataStructures", "Dates", "DelimitedFiles", "Distributions", "DocStringExtensions", "GLM", "KernelDensity", "LaTeXStrings", "LinearAlgebra", "NamedArrays", "NamedTupleTools", "Parameters", "Random", "Reexport", "Requires", "Statistics", "StatsBase", "StatsFuns", "Unicode"]
git-tree-sha1 = "6cbbd94bebdd0548858d7e8d8a7531a01419f6d1"
uuid = "21324389-b050-441a-ba7b-9a837781bda0"
version = "0.8.0"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "90bc7a7c96410424509e4263e277e43250c05691"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.0"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMD]]
deps = ["SnoopPrecompile"]
git-tree-sha1 = "34edfe91375e5883875987e740c554b92c48fc41"
uuid = "fdea26ae-647d-5447-a871-4b548cad5224"
version = "3.4.3"

[[deps.ScanByte]]
deps = ["Libdl", "SIMD"]
git-tree-sha1 = "2436b15f376005e8790e318329560dcc67188e84"
uuid = "7b38b023-a4d7-4c5e-8d43-3f3097f304eb"
version = "0.3.3"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "f94f779c94e58bf9ea243e77a37e16d9de9126bd"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.1"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "efd23b378ea5f2db53a55ae53d3133de4e080aa9"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.16"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.ShiftedArrays]]
git-tree-sha1 = "503688b59397b3307443af35cd953a13e8005c16"
uuid = "1277b4bf-5013-50f5-be3d-901d8477a67a"
version = "2.0.0"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SignedDistanceFields]]
deps = ["Random", "Statistics", "Test"]
git-tree-sha1 = "d263a08ec505853a5ff1c1ebde2070419e3f28e9"
uuid = "73760f76-fbc4-59ce-8f25-708e95d2df96"
version = "0.4.0"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "8fb59825be681d451c246a795117f317ecbcaa28"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.2"

[[deps.SnoopPrecompile]]
deps = ["Preferences"]
git-tree-sha1 = "e760a70afdcd461cf01a575947738d359234665c"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "a4ada03f999bd01b3a25dcaa30b2d929fe537e00"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.0"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "d75bda01f8c31ebb72df80a46c88b25d1c79c56d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.7"

[[deps.StableHashTraits]]
deps = ["CRC32c", "Compat", "Dates", "SHA", "Tables", "TupleTools", "UUIDs"]
git-tree-sha1 = "0b8b801b8f03a329a4e86b44c5e8a7d7f4fe10a3"
uuid = "c5dd0088-6c3f-4803-b00e-f31a60c170fa"
version = "0.3.1"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.StanBase]]
deps = ["CSV", "DataFrames", "DelimitedFiles", "Distributed", "DocStringExtensions", "Documenter", "JSON", "NamedTupleTools", "Parameters", "Random", "Unicode"]
git-tree-sha1 = "70258a57edc0eff2a1e11185b49c7d66e3de075b"
uuid = "d0ee94f6-a23d-54aa-bbe9-7f572d6da7f5"
version = "4.7.5"

[[deps.StanSample]]
deps = ["CSV", "CompatHelperLocal", "DataFrames", "DelimitedFiles", "Distributed", "DocStringExtensions", "JSON", "NamedTupleTools", "OrderedCollections", "Parameters", "Random", "Reexport", "Requires", "Serialization", "StanBase", "TableOperations", "Tables", "Unicode"]
git-tree-sha1 = "ddafb9724c190a9e3013674d95f6700a227e67c5"
uuid = "c1514b29-d3a0-5178-b312-660c88baa699"
version = "7.0.1"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "6954a456979f23d05085727adb17c4551c19ecd1"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.12"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6b7ba252635a5eff6a0b0664a41ee140a1c9e72a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f9af7f195fb13589dd2e2d57fdb401717d2eb1f6"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.5.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "HypergeometricFunctions", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "ab6083f09b3e617e34a956b43e9d51b824206932"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.1.1"

[[deps.StatsModels]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "Printf", "REPL", "ShiftedArrays", "SparseArrays", "StatsBase", "StatsFuns", "Tables"]
git-tree-sha1 = "a5e15f27abd2692ccb61a99e0854dfb7d48017db"
uuid = "3eaba693-59b7-5ba5-a881-562e759f1c8d"
version = "0.6.33"

[[deps.StringManipulation]]
git-tree-sha1 = "46da2434b41f41ac3594ee9816ce5541c6096123"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.0"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "GPUArraysCore", "StaticArraysCore", "Tables"]
git-tree-sha1 = "b03a3b745aa49b566f128977a7dd1be8711c5e71"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.14"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableOperations]]
deps = ["SentinelArrays", "Tables", "Test"]
git-tree-sha1 = "e383c87cf2a1dc41fa30c093b2a19877c83e1bc1"
uuid = "ab02a1b2-a7df-11e8-156e-fb1833f50b87"
version = "1.2.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "c79322d36826aa2f4fd8ecfa96ddb47b174ac78d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "ProgressMeter", "UUIDs"]
git-tree-sha1 = "7e6b0e3e571be0b4dd4d2a9a3a83b65c04351ccc"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.6.3"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "94f38103c984f89cf77c402f2a68dbd870f8165f"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.11"

[[deps.TriplotBase]]
git-tree-sha1 = "4d4ed7f294cda19382ff7de4c137d24d16adc89b"
uuid = "981d1d27-644d-49a2-9326-4793e63143c3"
version = "0.1.0"

[[deps.TupleTools]]
git-tree-sha1 = "3c712976c47707ff893cf6ba4354aa14db1d8938"
uuid = "9d95972d-f1c8-5527-a6e0-b4b365fa01f6"
version = "1.3.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[deps.WorkerUtilities]]
git-tree-sha1 = "cd1659ba0d57b71a464a29e64dbc67cfe83d54e7"
uuid = "76eceee3-57b5-4d4a-8e66-0e911cebbf60"
version = "1.6.1"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "93c41695bc1c08c46c5899f4fe06d6ead504bb73"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.10.3+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.isoband_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51b5eeb3f98367157a7a12a1fb0aa5328946c03c"
uuid = "9a68df92-36a6-505f-a73e-abb412b6bfb4"
version = "0.2.3+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a2ea60308f0996d26f1e5354e10c24e9ef905d4"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.4.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.2.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "libpng_jll"]
git-tree-sha1 = "d4f63314c8aa1e48cd22aa0c17ed76cd1ae48c3c"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.10.3+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"
"""

# ╔═╡ Cell order:
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╟─cf39df58-3371-4535-88e4-f3f6c0404500
# ╠═0616ece8-ccf8-4281-bfed-9c1192edf88e
# ╠═3d46979f-8d7e-4e05-8db5-7aa2d674c8c7
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═550371ad-d411-4e66-9d63-7329322c6ea1
# ╟─87902f0e-5919-45b3-89a6-b88a7dab9363
# ╟─56aa0b49-1e8a-4390-904d-6f7551f849ea
# ╟─47a6a5f3-0a54-46fe-a581-7414c0d9294a
# ╟─0391fc17-09b7-47d7-b799-6dc6de13e82b
# ╠═d830f41c-0fb6-4bff-9fe0-0bd51f444779
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
# ╠═3c03311f-bdb8-4c06-a870-3e70a628f684
# ╟─fb1e8fd3-7217-4955-83bd-551693f1507b
# ╠═30b7e449-bcc7-4dbe-aef3-a50b85048f03
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
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002