
### Tag version notes

1. git commit -m "Tag v0.0.1: changes"
2. git tag v0.0.1
3. git push origin main --tags

### Cloning the repository

```
# Cd to where you would like to clone to
$ git clone https://github.com/StanJulia/ROSStanPluto.jl ROSStanPluto
$ cd ROSStanPluto/notebooks
$ julia
```
and in the Julia REPL:

```
julia> using Pluto
julia> Pluto.run()
julia>
```

### Extract .jl from Jupyter notebook (`jupytext` needs to be installed)

# jupytext --to jl "./ch7.ipynb"


### Creating pdf files (cd to notebooks/chapters)

```
import PlutoPDF
PlutoPDF.pluto_to_pdf("notebook.jl")
```