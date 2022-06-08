### A Pluto.jl notebook ###
# v0.19.8

using Markdown
using InteractiveUtils

# ╔═╡ 5084b8f0-65ac-4704-b1fc-2a9008132bd7
using Pkg

# ╔═╡ bd4ab5bf-3657-4f1e-8051-af1d175e8d60
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

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ 0391fc17-09b7-47d7-b799-6dc6de13e82b
md"## ElectricCompany: electric.csv"

# ╔═╡ eb7ea04a-da52-4e69-ac3e-87dc7f014652
md"##### See Chapter 1.3, Figure 1.2 in Regression and Other Stories."

# ╔═╡ 69e5c6ca-7623-459b-9a82-c56c0dcc9c56
md" ##### Widen the cells."

# ╔═╡ 69f18fc3-0541-46e1-b916-e514932b973e
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

# ╔═╡ a4139439-b6f4-45bf-b48c-d6febfe3ed24
md"
!!! note

Most data files are obtained from RegressionAndOtherStories.jl and retrieved through `ros_datadir(\"ElectricCompany\", \"electric.csv\")`.

In some cases we will generate/simulate data and this will be (temporarily) stored locally (i.e. not in the RegressionAndOtherStories.jl repository).
"

# ╔═╡ 6c2043f4-dcbd-4535-a5ae-61c109519879
begin
	electric = CSV.read(ros_datadir("ElectricCompany", "electric.csv"), DataFrame)
	electric = electric[:, [:post_test, :pre_test, :grade, :treatment]]
	electric.grade = categorical(electric.grade)
	electric.treatment = categorical(electric.treatment)
	electric
end

# ╔═╡ 839f0a31-f952-4af4-80db-7e1286462ef6
md"###### A quick look at the overall values of `pre_test` and `post_test`."

# ╔═╡ feb040a2-c646-4908-8d37-8f9b75075271
describe(electric)

# ╔═╡ 91b774c2-0d3c-464a-875d-49ac86bc5ad7
all(completecases(electric)) == true

# ╔═╡ 03e1d3e6-fd23-4a45-90b5-5d97e8561ecf
md" #### Post-test density for each grade conditioned on treatment."

# ╔═╡ 014432a8-4ede-43dc-aa76-65f2cc2e43db
let
	f = Figure()
	axis = (; width = 150, height = 150)
	el = data(electric) * mapping(:post_test, col=:grade, color=:treatment)
	plt = el * AlgebraOfGraphics.density() * mapping(row=:treatment)
	draw!(f[1, 1], plt; axis)
	f
end	

# ╔═╡ 999999b1-ef29-4246-8eea-4d12967c06ed
md"
!!! note

In above cell, as density() is exported by both GLMakie and AlgebraOfGraphics, it needs to be qualified."

# ╔═╡ 89a2555f-6566-4e70-88f1-b92a242fa67f
let
	f = Figure()
	el = data(electric) * mapping(:post_test, col=:grade)
	plt = el * AlgebraOfGraphics.density() * mapping(color=:treatment)
	draw!(f[1, 1], plt)
	f
end	

# ╔═╡ 6ca81d3f-3f53-445b-828c-704352382cb3
let
	f = Figure()
	axis = (; width = 150, height = 150)
	el = data(electric) * mapping(:post_test, col=:grade, color=:treatment)
	plt = el * histogram(;bins=15) * mapping(row=:treatment)
	draw!(f[1, 1], plt; axis)
	f
end	

# ╔═╡ 7655d34a-2862-4d2d-9897-004ebb9f41bc
let
	plt = data(electric) * visual(Violin) * mapping(:grade, :post_test, dodge=:treatment, color=:treatment)
	draw(plt)
end

# ╔═╡ Cell order:
# ╟─0391fc17-09b7-47d7-b799-6dc6de13e82b
# ╟─eb7ea04a-da52-4e69-ac3e-87dc7f014652
# ╟─69e5c6ca-7623-459b-9a82-c56c0dcc9c56
# ╠═69f18fc3-0541-46e1-b916-e514932b973e
# ╟─4755dab0-d228-41d3-934a-56f2863a5652
# ╠═5084b8f0-65ac-4704-b1fc-2a9008132bd7
# ╠═bd4ab5bf-3657-4f1e-8051-af1d175e8d60
# ╟─a4139439-b6f4-45bf-b48c-d6febfe3ed24
# ╠═6c2043f4-dcbd-4535-a5ae-61c109519879
# ╟─839f0a31-f952-4af4-80db-7e1286462ef6
# ╠═feb040a2-c646-4908-8d37-8f9b75075271
# ╠═91b774c2-0d3c-464a-875d-49ac86bc5ad7
# ╟─03e1d3e6-fd23-4a45-90b5-5d97e8561ecf
# ╠═014432a8-4ede-43dc-aa76-65f2cc2e43db
# ╟─999999b1-ef29-4246-8eea-4d12967c06ed
# ╠═89a2555f-6566-4e70-88f1-b92a242fa67f
# ╠═6ca81d3f-3f53-445b-828c-704352382cb3
# ╠═7655d34a-2862-4d2d-9897-004ebb9f41bc
