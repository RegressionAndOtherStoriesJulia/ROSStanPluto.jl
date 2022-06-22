### A Pluto.jl notebook ###
# v0.19.8

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ be6b0ea9-d8d2-43fe-b33b-c5d136939468
using Pkg, DrWatson

# ╔═╡ 7cb960bc-cc80-47ca-8814-926be641b74d
begin
	# Specific to this notebook
    using GLM
	using PlutoUI

	# Specific to ROSStanPluto
    using StanSample
	
	# Graphics related
    using GLMakie
    using Makie

	# Common data files and functions
	using RegressionAndOtherStories
end

# ╔═╡ e1fb3340-fa2d-42a0-b45a-91d8049aa373
md"#### See Chapter 5 in Regression and Other Stories."

# ╔═╡ 2aa720d8-717c-4fbd-9dfc-a50872c30b0b
md" ###### Widen the notebook."

# ╔═╡ a107a87f-dc67-4aa8-8f17-4ae25bc2785b
# ed172871-fa4d-4111-ac0a-341898917948
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

# ╔═╡ d955bd3e-eeb1-4c52-b01d-2577a4af2a88
md"###### A typical set of Julia packages to include in notebooks."

# ╔═╡ 0d55b83b-cea9-432d-8750-9796c0ef7c77
md" ### 5.1 Simulations of discrete events."

# ╔═╡ 8d3093a3-ee6d-49d3-bf3f-1271d4eab4e1
@bind nsim PlutoUI.Slider(2:5, default=3)

# ╔═╡ 32a81ce8-dbd3-4fb0-84cd-a121dedeb3ce
nsim

# ╔═╡ 0d6ac50d-19d8-45b5-b3e8-f4d838eea0a9
let
	n_girls = rand(Binomial(400, 0.488), 10^nsim)
	hist(n_girls; strokewidth = 1, strokecolor = :black)
end

# ╔═╡ 6580cb29-1bf8-4c61-8619-d2822ac71ac3
function prob_girls(bt) 
	res = if bt == :single_birth
		rand(Binomial(1, 0.488), 1)
	elseif bt == :fraternal_twin
		2rand(Binomial(1, 0.495), 1)
	else
		rand(Binomial(2, 0.495), 1)
	end
	return res[1]
end

# ╔═╡ 8ecfe5aa-e8c2-42c7-b249-2ead81db1e78
function girls(no_of_births = 400;
		birth_types = [:fraternal_twin, :identical_twin, :single_birth],
		probabilities = [1/125, 1/300, 1 - 1/125 - 1/300])
	
	return prob_girls.(sample(birth_types, Weights(probabilities), no_of_births))
end

# ╔═╡ 4f4cbe49-cde1-400a-a16b-b152f814b2f8
girls()

# ╔═╡ 8f330ec4-1e08-4137-ab9d-7840486ff708
sum(girls())

# ╔═╡ c7506bc7-f978-45ab-a5f0-41142b0a45d5
let
	#Random.seed!(1)
	girls_sim = [sum(girls()) for i in 1:1000]
	hist(girls_sim; strokewidth = 1, strokecolor = :black)
end	

# ╔═╡ 9f3d53be-5b0c-4ae2-a05a-8be752d3a7c2
md" ### 5.2 Simulation of continuous and mixed/continuous models."

# ╔═╡ Cell order:
# ╟─e1fb3340-fa2d-42a0-b45a-91d8049aa373
# ╠═2aa720d8-717c-4fbd-9dfc-a50872c30b0b
# ╠═a107a87f-dc67-4aa8-8f17-4ae25bc2785b
# ╠═be6b0ea9-d8d2-43fe-b33b-c5d136939468
# ╟─d955bd3e-eeb1-4c52-b01d-2577a4af2a88
# ╠═7cb960bc-cc80-47ca-8814-926be641b74d
# ╟─0d55b83b-cea9-432d-8750-9796c0ef7c77
# ╠═8d3093a3-ee6d-49d3-bf3f-1271d4eab4e1
# ╠═32a81ce8-dbd3-4fb0-84cd-a121dedeb3ce
# ╠═0d6ac50d-19d8-45b5-b3e8-f4d838eea0a9
# ╠═6580cb29-1bf8-4c61-8619-d2822ac71ac3
# ╠═8ecfe5aa-e8c2-42c7-b249-2ead81db1e78
# ╠═4f4cbe49-cde1-400a-a16b-b152f814b2f8
# ╠═8f330ec4-1e08-4137-ab9d-7840486ff708
# ╠═c7506bc7-f978-45ab-a5f0-41142b0a45d5
# ╠═9f3d53be-5b0c-4ae2-a05a-8be752d3a7c2
