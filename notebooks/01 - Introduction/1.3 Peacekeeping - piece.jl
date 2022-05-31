### A Pluto.jl notebook ###
# v0.19.5

using Markdown
using InteractiveUtils

# ╔═╡ 5084b8f0-65ac-4704-b1fc-2a9008132bd7
using Pkg, DrWatson

# ╔═╡ f71640c9-3918-475e-b32b-c85424bbcf5e
begin
	# Graphics related
    using GLMakie
    using Makie

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ 0391fc17-09b7-47d7-b799-6dc6de13e82b
md"## Peacekeeping: peacekeeping.csv"

# ╔═╡ eb7ea04a-da52-4e69-ac3e-87dc7f014652
md"##### See Chapter 1.3, Figures 1.3 & 1.4 in Regression and Other Stories."

# ╔═╡ 60e7e09d-d313-4422-acd3-fb9c47fbbc08
md" ##### Widen the cells."

# ╔═╡ 28954718-9e3c-4d85-812a-fd47809c3a09
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
md"###### Included Julia packages."

# ╔═╡ 220d3576-d0da-4722-b020-bc6e99006194
peace = CSV.read(ros_datadir("PeaceKeeping", "peacekeeping.csv"), missingstring="NA", DataFrame)

# ╔═╡ 74190615-64d8-4d48-ba31-837a0910e88c
describe(peace)

# ╔═╡ 839f0a31-f952-4af4-80db-7e1286462ef6
md"###### A quick look at this Dates stuff!"

# ╔═╡ 01a43e67-6520-4962-b20b-730e6f971836
peace.cfdate[1]

# ╔═╡ 665134c3-d9b4-4794-973f-57e357fb47d2
DateTime(1992, 4, 25)

# ╔═╡ 0d3c398d-a36f-4d65-88e0-97f14e56788e
Date(1992, 8, 10) - Date(1992, 4, 25)

# ╔═╡ 32d89953-d300-409c-a746-56cea402264b
Date(1970,1,1)

# ╔═╡ 1565c134-fca9-4f64-8cee-0a38fc6758f8
Date(1970,1,1) + Dates.Day(8150)

# ╔═╡ 406b5011-eb81-40a4-81fa-8df1c615e10c
Date(1992, 4, 25) - Date(1970, 1, 1)

# ╔═╡ 4497bd70-0319-4741-ad1b-656d8d2146e0
peace.faildate[1] - peace.cfdate[1]

# ╔═╡ dfa1e05e-bdc7-42fc-979b-39afdfbe5420
begin
	pks_df = peace[peace.peacekeepers .== 1, [:cfdate, :faildate]]
	nopks_df = peace[peace.peacekeepers .== 0, [:cfdate, :faildate]]
end;

# ╔═╡ 312826c8-ae25-4690-b310-4d1902a25cf1
mean(peace.censored)

# ╔═╡ d63a9ace-7fe3-4952-a38f-9982b99e1f7d
length(unique(peace.war))

# ╔═╡ 52bee8d7-07be-4854-870e-4ce5959700b9
mean(peace[peace.peacekeepers .== 1, :censored])

# ╔═╡ edaccf90-460e-4714-8cfd-1d3c615e25be
mean(peace[peace.peacekeepers .== 0, :censored])

# ╔═╡ 5452ce24-c090-43f8-8b60-f39e30b888a3
mean(peace[peace.peacekeepers .== 1 .&& peace.censored .== 0, :delay])

# ╔═╡ 1bca06ef-fb6f-442f-a511-99f40d06ff19
mean(peace[peace.peacekeepers .== 0 .&& peace.censored .== 0, :delay])

# ╔═╡ 97e50d2c-74c5-4c46-b9ba-324528285cbc
median(peace[peace.peacekeepers .== 1 .&& peace.censored .== 0, :delay])

# ╔═╡ c7641910-2b2c-45db-8fb7-120c437cbbbd
median(peace[peace.peacekeepers .== 0 .&& peace.censored .== 0, :delay])

# ╔═╡ 399bf433-ae3d-4383-b12d-459f8b2558d4
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

# ╔═╡ 2123438d-77f9-4bed-97d3-4a7b67b8e144
md"
!!! note

Censored means conflict had not returned until end of observation period (2004)."

# ╔═╡ 89df5f75-1839-4cf2-b91d-8b1da367423d
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

# ╔═╡ 1b70b1ee-f84a-43b4-8942-dad2395f71fe
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

# ╔═╡ Cell order:
# ╟─0391fc17-09b7-47d7-b799-6dc6de13e82b
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╟─60e7e09d-d313-4422-acd3-fb9c47fbbc08
# ╠═28954718-9e3c-4d85-812a-fd47809c3a09
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═f71640c9-3918-475e-b32b-c85424bbcf5e
# ╠═220d3576-d0da-4722-b020-bc6e99006194
# ╠═74190615-64d8-4d48-ba31-837a0910e88c
# ╟─839f0a31-f952-4af4-80db-7e1286462ef6
# ╠═01a43e67-6520-4962-b20b-730e6f971836
# ╠═665134c3-d9b4-4794-973f-57e357fb47d2
# ╠═0d3c398d-a36f-4d65-88e0-97f14e56788e
# ╠═32d89953-d300-409c-a746-56cea402264b
# ╠═1565c134-fca9-4f64-8cee-0a38fc6758f8
# ╠═406b5011-eb81-40a4-81fa-8df1c615e10c
# ╠═4497bd70-0319-4741-ad1b-656d8d2146e0
# ╠═dfa1e05e-bdc7-42fc-979b-39afdfbe5420
# ╠═312826c8-ae25-4690-b310-4d1902a25cf1
# ╠═d63a9ace-7fe3-4952-a38f-9982b99e1f7d
# ╠═52bee8d7-07be-4854-870e-4ce5959700b9
# ╠═edaccf90-460e-4714-8cfd-1d3c615e25be
# ╠═5452ce24-c090-43f8-8b60-f39e30b888a3
# ╠═1bca06ef-fb6f-442f-a511-99f40d06ff19
# ╠═97e50d2c-74c5-4c46-b9ba-324528285cbc
# ╠═c7641910-2b2c-45db-8fb7-120c437cbbbd
# ╠═399bf433-ae3d-4383-b12d-459f8b2558d4
# ╟─2123438d-77f9-4bed-97d3-4a7b67b8e144
# ╠═89df5f75-1839-4cf2-b91d-8b1da367423d
# ╠═1b70b1ee-f84a-43b4-8942-dad2395f71fe
