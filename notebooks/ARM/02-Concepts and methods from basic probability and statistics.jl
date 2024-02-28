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

	# Specific to ROSStanPluto
	using StanSample
	
    # Graphics related
    using CairoMakie
	using AlgebraOfGraphics
	
    # Include basic packages
    using RegressionAndOtherStories
end

# ╔═╡ eb7ea04a-da52-4e69-ac3e-87dc7f014652
md"## 02-Concepts and methods from basic probability and statistics."

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
md"### 2.1 Probability distributions."

# ╔═╡ bb4c4a68-4f44-4858-a9a2-433fafcc3832
md" ###### Normal distribution; means and variances."

# ╔═╡ 94bb15d6-2adc-4c78-a9fc-59fd0bf865e4
begin
	heights = DataFrame()
	heights.women = rand(Normal(63.7, 2.7), 10000)
	heights.men = rand(Normal(69.1, 2.9), 10000)
	heights.women_cm = 2.54 * rand(Normal(63.7, 2.7), 10000)
	heights.men_cm = 2.54 * rand(Normal(69.1, 2.9), 10000)
	heights
end

# ╔═╡ 1ae3fb49-4a88-472d-b433-5dbbb53a0fcf
let
	mean_diff = mean(heights.men) - mean(heights.women)
	mean_diff_cm = 2.54 * (mean(heights.men) - mean(heights.women))
	mean_sd = √(2.9^2/10000 + 2.9^2/10000)
	[mean_diff, mean_sd, mean_diff_cm, 2.54 * mean_sd]
end

# ╔═╡ bbdaae20-a8a4-48ce-84c8-8b7a43b27856
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="heights of women [in]\n(normal distribution)")
	CairoMakie.density!(heights.women; strokecolor = :blue, strokewidth = 3, strokearound = false, color=:white)
	ax = Axis(f[1, 2]; title="heights of men [in]\n(normal distribution)")
	CairoMakie.density!(heights.men; strokecolor = :blue, strokewidth = 3, strokearound = false, color=:white)
	ax = Axis(f[1, 3]; title="heights of all [in]\n(not a normal distribution)")
	allheights = vcat(heights.women, heights.men)
	CairoMakie.density!(allheights; strokecolor = :blue, strokewidth = 3, strokearound = false, color=:white)
	ax = Axis(f[2, 1]; title="heights of women [cm] \n(normal distribution)")
	CairoMakie.density!(heights.women_cm; strokecolor = :blue, strokewidth = 3, strokearound = false, color=:white)
	ax = Axis(f[2, 2]; title="heights of men [cm] \n(normal distribution)")
	CairoMakie.density!(heights.men_cm; strokecolor = :blue, strokewidth = 3, strokearound = false, color=:white)
	ax = Axis(f[2, 3]; title="heights of all [cm] \n(not a normal distribution)")
	allheights = vcat(heights.women_cm, heights.men_cm)
	CairoMakie.density!(allheights; strokecolor = :blue, strokewidth = 3, strokearound = false, color=:white)
	f
end

# ╔═╡ bffc1b80-1fba-44de-b32b-9165427c8abf
md" ###### Multivariate normal distribution."

# ╔═╡ fc1e8652-b057-48f6-a42a-f48b72c051b4
let
	Σ = [1 0.2; 0.2 1]
	m = rand(MvNormal([2, 4], Σ), 1000)
	println(cov(m[1, :], m[2, :]))
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1])
	CairoMakie.density!(m[1, :])
	CairoMakie.density!(m[2, :])
	f
end

# ╔═╡ 72c07439-f112-4fce-8380-fca8b8eb2cc5
md" ###### Lognormal distribution."

# ╔═╡ 29b24781-9f34-4a03-98ab-cd921f1b049f
let
	x = rand(LogNormal(5.13, 0.17), 1000)
	println([mean(log.(x)), std(log.(x))])
	y = rand(Normal(exp(5.13 + 0.17^2/2), exp(5.13 + 0.17^2/2) * sqrt(exp(0.17^2) - 1)), 1000)
	println([exp(5.13 + 0.17^2/2), exp(5.13 + 0.17^2/2) * sqrt(exp(0.17^2) - 1)])
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="log weights of men\n(normal distributions)", xlabel="logarithm of weights [lb]")
	CairoMakie.density!(log.(x); strokecolor = :blue, strokewidth = 3, strokearound = false, color=:white)
	ax = Axis(f[1, 2]; title="weights of men\n(lognormal distributions)", xlabel="weights [lb]")
	CairoMakie.density!(y; strokecolor = :red, strokewidth = 3, strokearound = false, color=:white)
	f
end

# ╔═╡ 8e5fe5ec-cac1-40b6-ac85-7f25a86bd19e
rand(LogNormal(5.13, 0.17), 10)

# ╔═╡ e01190e6-b587-4922-9306-a64de22e7cd8
std(rand(LogNormal(5.13, 0.17), 10))

# ╔═╡ 2f9d7648-cd30-4d76-8d89-62887c1135cd
md" ###### Binomial distribution."

# ╔═╡ 7720cd7e-1c8b-4611-8599-3d0d5bb6e386
rand(Binomial(20, 0.3), 10)

# ╔═╡ 6cc1fb6e-e2fc-41da-a109-ae4b182f27e9
mean(rand(Binomial(20, 0.3), 1000))

# ╔═╡ 9579c3ec-8be3-4e8d-b6b1-e81316b3e703
sqrt(0.3 * (1-0.3) / 20)

# ╔═╡ e85435cf-8b97-445d-acfd-cd1f48837b9f
md" ###### Poisson distribution."

# ╔═╡ 5b82824f-80e6-448f-8c74-0392320fcd24
rand(Poisson(4.52), 10)

# ╔═╡ 591a78cc-0a76-450f-b540-ae224439f237
mean(rand(Poisson(4.52), 1000))

# ╔═╡ 49a5e9c2-10e1-4434-853f-4126411dfb18
md" ### 2.2 Statistical inference."

# ╔═╡ 0fa6a0fa-ea53-429c-9d42-0d52961f2d3a
md" ### 2.3 Classical confidence intervals."


# ╔═╡ 23315e2c-1461-4b22-aeea-6df46b6118e2
let
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="Quantiles of observations example")
	wdf = Normal(63.65, 2.68)
	x = range(55.0, 72.5 ; length=100)
	lines!(x, pdf.(wdf, x); color=:darkblue)
	
	x1 = range(63.65 - 3 * 2.68, 63.65 - 2 * 2.68; length=20)
	band!(x1, fill(0, length(x1)), pdf.(wdf, x1);
		color = (:blue, 0.25), label = "Label")

	x1 = range(63.65 + 2 * 2.68, 63.65 + 3 * 2.68; length=20)
	band!(x1, fill(0, length(x1)), pdf.(wdf, x1);
		color = (:blue, 0.25), label = "Label")
	
	x1 = range(63.65 - 2 * 2.68, 63.65 - 1 * 2.68; length=20)
	band!(x1, fill(0, length(x1)), pdf.(wdf, x1);
		color = (:blue, 0.45), label = "Label")

	x1 = range(63.65 + 1 * 2.68, 63.65 + 2 * 2.68; length=20)
	band!(x1, fill(0, length(x1)), pdf.(wdf, x1);
		color = (:blue, 0.45), label = "Label")
	
	x1 = range(63.65 - 1 * 2.68, 63.65; length=20)
	band!(x1, fill(0, length(x1)), pdf.(wdf, x1);
		color = (:blue, 0.55), label = "Label")

	x1 = range(63.65, 63.65 + 2.68; length=20)
	band!(x1, fill(0, length(x1)), pdf.(wdf, x1);
		color = (:blue, 0.55), label = "Label")

	text!("68%", position = (63.65, 0.05), align = (:center,  :center),
    	fontsize = 30)
	text!("13.5%", position = (67.5, 0.02), align = (:center,  :center),
    	fontsize = 20)
	text!("13.5%", position = (59.6, 0.02), align = (:center,  :center),
    	fontsize = 20)
	text!("2.5%", position = (69.75, 0.0045), align = (:center,  :center),
    	fontsize = 15)
	text!("2.5%", position = (57.7, 0.0045), align = (:center,  :center),
    	fontsize = 15)
	f
end

# ╔═╡ 2793e753-7c1c-4931-81ec-92a423ce1eee
let
	x = [35, 34, 38, 35, 37]
	n = length(x)

	mean_x = mean(x)
	println([mean_x, std(x)])

	se_x = std(x)/sqrt(n)
	println(se_x)
	
	xt = rand(TDist(n - 1), 1000)
	qt = [
			round.(mean_x .+ quantile(xt, 0.025) .* se_x; digits=1),
			round.(mean_x .+ quantile(xt, 0.16) .* se_x; digits=1),
			round.(mean_x .+ quantile(xt, 0.25) .* se_x; digits=1),
			round.(mean_x .+ quantile(xt, 0.75) .* se_x; digits=1),
			round.(mean_x .+ quantile(xt, 0.84) .* se_x; digits=1),
			round.(mean_x .+ quantile(xt, 0.975) .* se_x; digits=1)
	]
	println(qt)
		
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="TDist(4) based quantiles of mean")
	xlims!(25, 45)
	vlines!([mean_x]; color=:darkred, linestyle=:dash)

	wdf = Normal(mean_x, std(x))
	x = range(25.0, 45.0 ; length=300)
	lines!(x, pdf.(wdf, x); color=:darkblue)

	x1 = range(qt[1], qt[2]; length=100)
	band!(x1, fill(0, length(x1)), pdf.(wdf, x1);
		color = (:blue, 0.25), label = "Label")
	
	x1 = range(qt[2], qt[3]; length=100)
	band!(x1, fill(0, length(x1)), pdf.(wdf, x1);
		color = (:blue, 0.45), label = "Label")
	
	x1 = range(qt[3], qt[4]; length=100)
	band!(x1, fill(0, length(x1)), pdf.(wdf, x1);
		color = (:blue, 0.55), label = "Label")

	x1 = range(qt[4], qt[5]; length=100)
	band!(x1, fill(0, length(x1)), pdf.(wdf, x1);
		color = (:blue, 0.45), label = "Label")
	
	x1 = range(qt[5], qt[6]; length=100)
	band!(x1, fill(0, length(x1)), pdf.(wdf, x1);
		color = (:blue, 0.25), label = "Label")
	
	f
end

# ╔═╡ c9cb2ec6-a125-42a4-a731-d77be736919c
df_poll = CSV.read(arm_datadir("Death", "polls.csv"), DataFrame)

# ╔═╡ d1338db8-1534-426c-a0b1-f4ddf7cfb03e
md" ###### Comparisons, visual and numerical."

# ╔═╡ 4757000a-324a-4c03-8ce1-e0b2514fd10c
begin
	f = Figure(; size=default_figure_resolution)
	ax = Axis(f[1, 1]; title="Death penalty opinions", xlabel="Year", ylabel="Percentage support for the death penalty")
	scatter!(df_poll.year, df_poll.support .* 100)
	err_lims = [100(sqrt(df_poll.support[i]*(1-df_poll.support[i])/1000)) for i in 1:nrow(df_poll)]
	errorbars!(df_poll.year, df_poll.support .* 100, err_lims, color = :red)
	f
end

# ╔═╡ 5a1275e4-30f2-4943-bd14-00525c10cf40
md" ### 2.4 Classical hypothesis testing."

# ╔═╡ Cell order:
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╟─cf39df58-3371-4535-88e4-f3f6c0404500
# ╠═0616ece8-ccf8-4281-bfed-9c1192edf88e
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═d7753cf6-7452-421a-a3ec-76e07646f808
# ╠═550371ad-d411-4e66-9d63-7329322c6ea1
# ╟─0391fc17-09b7-47d7-b799-6dc6de13e82b
# ╟─bb4c4a68-4f44-4858-a9a2-433fafcc3832
# ╠═94bb15d6-2adc-4c78-a9fc-59fd0bf865e4
# ╠═1ae3fb49-4a88-472d-b433-5dbbb53a0fcf
# ╠═bbdaae20-a8a4-48ce-84c8-8b7a43b27856
# ╟─bffc1b80-1fba-44de-b32b-9165427c8abf
# ╠═fc1e8652-b057-48f6-a42a-f48b72c051b4
# ╟─72c07439-f112-4fce-8380-fca8b8eb2cc5
# ╠═29b24781-9f34-4a03-98ab-cd921f1b049f
# ╠═8e5fe5ec-cac1-40b6-ac85-7f25a86bd19e
# ╠═e01190e6-b587-4922-9306-a64de22e7cd8
# ╟─2f9d7648-cd30-4d76-8d89-62887c1135cd
# ╠═7720cd7e-1c8b-4611-8599-3d0d5bb6e386
# ╠═6cc1fb6e-e2fc-41da-a109-ae4b182f27e9
# ╠═9579c3ec-8be3-4e8d-b6b1-e81316b3e703
# ╟─e85435cf-8b97-445d-acfd-cd1f48837b9f
# ╠═5b82824f-80e6-448f-8c74-0392320fcd24
# ╠═591a78cc-0a76-450f-b540-ae224439f237
# ╟─49a5e9c2-10e1-4434-853f-4126411dfb18
# ╟─0fa6a0fa-ea53-429c-9d42-0d52961f2d3a
# ╠═23315e2c-1461-4b22-aeea-6df46b6118e2
# ╠═2793e753-7c1c-4931-81ec-92a423ce1eee
# ╠═c9cb2ec6-a125-42a4-a731-d77be736919c
# ╟─d1338db8-1534-426c-a0b1-f4ddf7cfb03e
# ╠═4757000a-324a-4c03-8ce1-e0b2514fd10c
# ╟─5a1275e4-30f2-4943-bd14-00525c10cf40
