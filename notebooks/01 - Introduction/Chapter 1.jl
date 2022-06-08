### A Pluto.jl notebook ###
# v0.19.8

using Markdown
using InteractiveUtils

# ╔═╡ 5084b8f0-65ac-4704-b1fc-2a9008132bd7
using Pkg, DrWatson

# ╔═╡ 550371ad-d411-4e66-9d63-7329322c6ea1
begin
    # Specific to this notebook
    using GLM

	# Specific to ROSStanPluto
	using StanSample
	
    # Graphics related
    using GLMakie
    using Makie
    using AlgebraOfGraphics
    set_aog_theme!()

    # Include basic packages
    using RegressionAndOtherStories
end

# ╔═╡ eb7ea04a-da52-4e69-ac3e-87dc7f014652
md"#### Chapter 1 in Regression and Other Stories."

# ╔═╡ cf39df58-3371-4535-88e4-f3f6c0404500
md" ###### Widen the cells."

# ╔═╡ 0616ece8-ccf8-4281-bfed-9c1192edf88e
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

# ╔═╡ 4755dab0-d228-41d3-934a-56f2863a5652
md"###### A typical set of Julia packages to include in notebooks."

# ╔═╡ 5fdc1b11-ce9b-4f67-8e2e-5ab22cd75b70
md"
!!! note

All data files are available (as .csv files) in the data subdirectory of package RegressionAndOtherStories.jl.
"

# ╔═╡ 100e2ea9-17e5-4eef-b880-823311f5d496
ros_datadir()

# ╔═╡ 0391fc17-09b7-47d7-b799-6dc6de13e82b
md"### 1.1 ElectionsEconomy: hibbs.csv"

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

# ╔═╡ fa2fe95b-fe29-40c8-8dfc-27a35e720f3d
md" ### 1.2 ElectricCompany"

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

# ╔═╡ 3c03311f-bdb8-4c06-a870-3e70a628f684
let
	f = Figure()
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
	f = Figure()
	el = data(electric) * mapping(:post_test, col=:grade)
	plt = el * AlgebraOfGraphics.density() * mapping(color=:treatment)
	draw!(f[1, 1], plt)
	f
end

# ╔═╡ 1523996d-f20b-4c81-8f18-7a1587c3b556
let
	f = Figure()
	axis = (; width = 150, height = 150)
	el = data(electric) * mapping(:post_test, col=:grade, color=:treatment)
	plt = el * histogram(;bins=15) * mapping(row=:treatment)
	draw!(f[1, 1], plt; axis)
	f
end

# ╔═╡ 093c1e47-00be-407e-83a4-0ac96be3262c
let
	plt = data(electric) * visual(Violin) * mapping(:grade, :post_test, dodge=:treatment, color=:treatment)
	draw(plt)
end

# ╔═╡ 35307905-cee1-4f35-a149-cdaaf7fc1294
md" ### 1.3 Peacekeeping"

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
	f = Figure()
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
	f = Figure()
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

# ╔═╡ 783df69c-5368-4a9e-aabf-a46895712289
md" ### 1.4 SimpleCausal"

# ╔═╡ df82425a-4cf6-4b6d-9421-f8a5b59c4230
stan1_2 = "
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
begin
	data1_2 = (N = n, x = x, x_binary = x_binary, y = y)
	m1_2s = SampleModel("m1.2s", stan1_2);
	rc1_2 = stan_sample(m1_2s; data=data1_2)
end;

# ╔═╡ 7798b760-eeab-406a-820e-bf1019395a12
if success(rc1_2)
	post1_2s = read_samples(m1_2s, :dataframe)
	mod_sum = model_summary(post1_2s, Symbol.(names(post1_2s)))
end

# ╔═╡ e5f22961-b531-4519-bfb0-a8196d77ba6c
let
	x1 = 1.0:0.01:5.0
	f = Figure()
	medians = mod_sum[:, :median]
	ax = Axis(f[1, 1], title = "Regression with continuous treatment",
		xlabel = "Treatment", ylabel = "Outcome")
	sca1 = scatter!(x, y)
	annotations!("Slope of fitted line = $(round(medians[3], digits=2))",
		position = (2.8, 10), textsize=15)
	lin1 = lines!(x1, medians[1] .+ medians[3] * x1)

	x2 = 0.0:0.01:1.0
	ax = Axis(f[2, 1], title="Regression with binary treatment",
		xlabel = "Treatment", ylabel = "Outcome")
	sca1 = scatter!(x_binary, y)
	lin1 = lines!(x2, medians[2] .+ medians[4] * x2)
	annotations!("Slope of fitted line = $(round(medians[4], digits=2))", 
		position = (0.4, 12), textsize=15)
	f
end

# ╔═╡ 7d7feaf5-1b91-4293-a03d-2598168d0439
stan1_3 = "
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
begin
	#Random.seed!(1533)
	n1 = 50
	x1 = rand(Uniform(1, 5), n1)
	y1 = [rand(Normal(5 + 30exp(-x1[i]), 2), 1)[1] for i in 1:n]
	data1_3 = (N = n1, x = x1, y = y1)
	m1_3s = SampleModel("m1.3s", stan1_3);
	rc1_3 = stan_sample(m1_3s; data=data1_3)
end;

# ╔═╡ 9d1a2f40-e10b-47bc-b5db-5bd8ba6f66e3
if success(rc1_3)
	df1_3s = read_samples(m1_3s, :dataframe)
end

# ╔═╡ eaed7d4a-f897-4008-ba9e-c61353c28410
â₁, â₂, b̂, b̂ₑₓₚ, σ̂₁, σ̂₂ = median(Array(df1_3s); dims=1)

# ╔═╡ a772d1be-e8b8-40bb-be95-1ed053dc67de
let
	x1 = 1.0:0.1:5.9
	f = Figure()
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
	x = range(0, maximum(df1_8.xx), length=40)
	
	f = Figure()
	ax = Axis(f[1, 1]; title="Figure 1.8")
	scatter!(df1_8.xx[df1_8.z .== 0], df1_8.yy[df1_8.z .== 0])
	scatter!(df1_8.xx[df1_8.z .== 1], df1_8.yy[df1_8.z .== 1])
	lines!(x, â₁ .+ b̂₁ * x, label = "Control")
	lines!(x, â₂ .+ b̂₂ * x, label = "Treated")
	axislegend(; position=(:right, :bottom))
	current_figure()
end

# ╔═╡ 08710628-ff52-4a95-a4f5-5dfce2fda165
md" ### 1.5 Helicopters"

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
stan1_4 = "
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
begin
	data1_4 = (N = nrow(helis), y = helis.time_sec, w = helis.width_cm, l = helis.length_cm)
	m1_4s = SampleModel("m1.4s", stan1_4);
	rc1_4 = stan_sample(m1_4s; data=data1_4)
end;

# ╔═╡ fbb2e703-fbff-4dd4-a58c-3b2f5b6f49e1
if success(rc1_4)
	post1_4s_df = read_samples(m1_4s, :dataframe)
	post1_4s_df[!, :chain] = repeat(collect(1:m1_4s.num_chains);
		inner=m1_4s.num_samples)
	post1_4s_df[!, :chain] = categorical(post1_4s_df.chain)
	post1_4s_df
end

# ╔═╡ e1942cd4-87ee-44d3-86ff-519ed75adbc0
means = mean(Array(post1_4s_df); dims=1)

# ╔═╡ f7ba1202-2fe8-4289-8905-96e9849a513d
plot_chains(post1_4s_df, [:a, :b, :c])

# ╔═╡ 50588b61-75b1-42b6-9870-43641811d0ad
plot_chains(post1_4s_df, [:sigma])

# ╔═╡ 790839f9-0b49-4da2-8dc1-00bab883e3af
let
	w = 1.0:0.01:8.0
	l = 6.0:0.01:15.0
	f = Figure()
	ax = Axis(f[1, 1], title = "Time on width or width",
		xlabel = "Width/Length", ylabel = "Time in the air")
	lines!(w, mean(post1_4s_df.a) .+ mean(post1_4s_df.b) .* w .+ mean(post1_4s_df.c))
	lines!(l, mean(post1_4s_df.a) .+ mean(post1_4s_df.c) .* l .+ mean(post1_4s_df.b))

	current_figure()
end

# ╔═╡ Cell order:
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╟─cf39df58-3371-4535-88e4-f3f6c0404500
# ╠═0616ece8-ccf8-4281-bfed-9c1192edf88e
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═550371ad-d411-4e66-9d63-7329322c6ea1
# ╟─5fdc1b11-ce9b-4f67-8e2e-5ab22cd75b70
# ╠═100e2ea9-17e5-4eef-b880-823311f5d496
# ╟─0391fc17-09b7-47d7-b799-6dc6de13e82b
# ╠═d830f41c-0fb6-4bff-9fe0-0bd51f444779
# ╠═35bee056-5cd8-48ee-b9c0-74a8b53229bd
# ╠═3c4672aa-d17e-4681-9863-9ee026fefee6
# ╠═a9970ef7-1e0e-4976-b8c9-1db4dd3a222b
# ╠═f48df50b-5450-4998-8dab-014c8b9d42a2
# ╠═be41c745-c87d-4f3a-ab4e-a8ae3b9ae091
# ╠═06ab4f30-68cc-4e35-9fa2-b8f8f25d3776
# ╟─fa2fe95b-fe29-40c8-8dfc-27a35e720f3d
# ╠═305f0fb9-5e3a-45fd-8f57-edfdf65fb0e8
# ╟─43e020d2-063c-43da-b7b3-bbc989002e9e
# ╠═3bc6b063-6f3d-4474-99b2-c9270513778a
# ╠═82c83206-d5d7-4cc2-b4cd-d43e9c84c68a
# ╟─420b8920-5f2a-4e3b-a32e-622252b84444
# ╠═3c03311f-bdb8-4c06-a870-3e70a628f684
# ╟─fb1e8fd3-7217-4955-83bd-551693f1507b
# ╠═30b7e449-bcc7-4dbe-aef3-a50b85048f03
# ╠═1523996d-f20b-4c81-8f18-7a1587c3b556
# ╠═093c1e47-00be-407e-83a4-0ac96be3262c
# ╟─35307905-cee1-4f35-a149-cdaaf7fc1294
# ╠═f4b870c6-240d-4a46-98c8-1a0dbe7dfc6b
# ╠═00f43b7d-2594-4433-a18f-92d9899fb014
# ╠═0eb862b2-d3be-4626-a4e6-3a6bb736c960
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
# ╟─783df69c-5368-4a9e-aabf-a46895712289
# ╠═df82425a-4cf6-4b6d-9421-f8a5b59c4230
# ╟─20771b96-adb5-4fc9-9679-0a8d42f8f09a
# ╠═675edafd-145c-43ac-aa3b-2c830b3645e1
# ╠═3fb34dce-1b9d-4bdf-b94e-03a13fd09d30
# ╠═7798b760-eeab-406a-820e-bf1019395a12
# ╠═e5f22961-b531-4519-bfb0-a8196d77ba6c
# ╠═7d7feaf5-1b91-4293-a03d-2598168d0439
# ╠═615aa9cb-e138-4ef5-917a-ceb3ab6235c1
# ╠═9d1a2f40-e10b-47bc-b5db-5bd8ba6f66e3
# ╠═eaed7d4a-f897-4008-ba9e-c61353c28410
# ╠═a772d1be-e8b8-40bb-be95-1ed053dc67de
# ╠═c4799717-da18-45cb-b544-ac989184d6f4
# ╠═86fce3c6-654d-4a3f-8540-2ec57b3395f3
# ╠═25db1637-e88e-4bc2-92e4-a968be42c626
# ╠═99ee57e4-52ce-44e2-baea-bc04544d0d31
# ╠═4d5b73d4-c5a5-4dfd-9354-78db442545b5
# ╟─08710628-ff52-4a95-a4f5-5dfce2fda165
# ╠═b2045d0f-afc1-4046-90c5-55f39cf11c84
# ╟─72f0a072-9c65-4a91-98b5-8967f2f6a5f3
# ╠═f7444121-7211-4999-ac6b-3a3c8738a4e3
# ╠═82becf62-2701-4af6-87e6-4ee0a0c91eac
# ╠═12588d28-10dc-4551-84f2-ecf82a09aef0
# ╠═fbb2e703-fbff-4dd4-a58c-3b2f5b6f49e1
# ╠═e1942cd4-87ee-44d3-86ff-519ed75adbc0
# ╠═f7ba1202-2fe8-4289-8905-96e9849a513d
# ╠═50588b61-75b1-42b6-9870-43641811d0ad
# ╠═790839f9-0b49-4da2-8dc1-00bab883e3af
