### A Pluto.jl notebook ###
# v0.19.5

using Markdown
using InteractiveUtils

# ╔═╡ e6b9a944-9070-4f7e-a8d8-4952382ce776
using Pkg

# ╔═╡ 0cbcd8d3-d49a-45c9-8691-3053a3e4b9a6
begin
	# Graphics related
    using GLMakie
    using Makie
	using AlgebraOfGraphics
	
	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ 617ec9f2-dde7-4467-a284-183bee62ca15
md" ### Names: allnames_clean.csv"

# ╔═╡ 957eb622-a1c2-4851-890c-7306abe2eea6
md"##### See Chapter 2.3 in Regression and Other Stories."

# ╔═╡ 6a7e952c-efd0-4e8d-92d6-be9b1302e7eb
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

# ╔═╡ 2ff8263d-c869-46dd-ab88-fb66a84604ee
md"###### A typical set of Julia packages to include in notebooks."

# ╔═╡ 011b3870-cc26-4d10-8ea1-5c1acdadc47c
cleannames = CSV.read(ros_datadir("Names", "allnames_clean.csv"), DataFrame)

# ╔═╡ d3875ea5-5bab-4174-8dcd-7936125e47c6
size(cleannames)

# ╔═╡ 6dbde335-ab1c-44e6-92a4-accc65be8376
names(cleannames)

# ╔═╡ e0ae9e62-93f6-4abb-8411-da82f32ae489
df = cleannames[cleannames.sex .== "M", ["name", "sex", "X1906", "X1956", "X2006"]]

# ╔═╡ d0999142-7dec-4ca7-95be-cd32770b1e25
letters = 'a':'z';

# ╔═╡ 954aa134-3a4e-40f9-a7d4-ff471bb8c164
function count_letters(df::DataFrame, years::Vector{String})
	letter_counts = DataFrame()
	for year in Symbol.(years)
		
		!(year in Symbol.(names(df))) && begin
			@warn "The year $(year) is not present in df."
			continue
		end
		
		tmpdf = df[:, [:name, year]]
		
		yrcounts = zeros(Int, length(letters))
		for (ind, letter) in enumerate(letters)
			yrcounts[ind] = sum(filter(row -> row.name[end] == letter, tmpdf)[:, 2])
		end
		letter_counts[!, year] = 100 * yrcounts / sum(yrcounts)
	end
	letter_counts
end

# ╔═╡ 96d29ad3-088b-44a0-b6e3-ab1868658aee
letter_count = count_letters(df, ["X1906", "X1956", "X2006"])

# ╔═╡ 49c95070-1201-48fb-9659-f2d464ff252d
sum.(eachcol(letter_count))

# ╔═╡ 1e07d53d-5c23-4c64-a958-6b656dcc057e
let
	f = Figure()
	for (ind, year) in enumerate(["X1906", "X1956", "X2006"])
		ax = Axis(f[ind, 1], title="Last letters in boys' names in $(year[2:end])",
			ylabel="Perc of names")
		ax.xticks = (0:27, vcat(" ", string.(letters), " "))
		barplot!(f[ind, 1], 1:26, letter_count[:, Symbol(year)], width=0.8, gap=0.01)
	end
	f
end

# ╔═╡ 7acb36e2-5444-4926-9f65-d9e49c28c0a2
all_letter_count = count_letters(cleannames[cleannames.sex .== "M", :], names(cleannames[:, vcat(4:end)]))

# ╔═╡ db860d05-6b5a-428e-98d9-00fcb82bfe40
all_letter_count[:, "X1906"]

# ╔═╡ 9ab0cdf1-9779-46c3-ad9c-864cff5c4746
let
	f = Figure()
	ax = Axis(f[1, 1], title="Last letters in boys' names over time",
		ylabel="Perc of all boys' names that year")
	ax.xticks = (6:25:131, ["1886", "1906", "1931", "1956", "1981", "2006"])

	for l in 1:length(letters)
		col = :lightgrey
		if letters[l] == 'n'
			col = :darkblue
		elseif letters[l] == 'd'
			col = :darkred
		elseif letters[l] == 'y'
			col = :darkgreen
		end
		if maximum(Array(all_letter_count)[l,:]) > 1
			lines!(1:size(all_letter_count, 2), Array(all_letter_count)[l,:], color=col)
		end
		annotations!("n", position = (106, 25), textsize=15)
		annotations!("d", position = (56, 18), textsize=15)
		annotations!("y", position = (106, 11), textsize=15)

	end
	current_figure()
end

# ╔═╡ Cell order:
# ╟─617ec9f2-dde7-4467-a284-183bee62ca15
# ╟─957eb622-a1c2-4851-890c-7306abe2eea6
# ╠═6a7e952c-efd0-4e8d-92d6-be9b1302e7eb
# ╟─2ff8263d-c869-46dd-ab88-fb66a84604ee
# ╠═e6b9a944-9070-4f7e-a8d8-4952382ce776
# ╠═0cbcd8d3-d49a-45c9-8691-3053a3e4b9a6
# ╠═011b3870-cc26-4d10-8ea1-5c1acdadc47c
# ╠═d3875ea5-5bab-4174-8dcd-7936125e47c6
# ╠═6dbde335-ab1c-44e6-92a4-accc65be8376
# ╠═e0ae9e62-93f6-4abb-8411-da82f32ae489
# ╠═d0999142-7dec-4ca7-95be-cd32770b1e25
# ╠═954aa134-3a4e-40f9-a7d4-ff471bb8c164
# ╠═96d29ad3-088b-44a0-b6e3-ab1868658aee
# ╠═49c95070-1201-48fb-9659-f2d464ff252d
# ╠═1e07d53d-5c23-4c64-a958-6b656dcc057e
# ╠═7acb36e2-5444-4926-9f65-d9e49c28c0a2
# ╠═db860d05-6b5a-428e-98d9-00fcb82bfe40
# ╠═9ab0cdf1-9779-46c3-ad9c-864cff5c4746
