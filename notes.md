
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


### Creating pdf files (cd to notebooks/Chapters)

```Julis
import PlutoPDF
#cd("path_to_chapters")
files = readdir(pwd(); join=true)
for file in files
    if !(file[end-8:end] == ".DS_Store")
        fin = split(file, '/')[end]
        print(fin)
        print(" => ")
        fout = "../../pdfs/" * fin[1:end-3] * ".pdf"
        println(fout)
        PlutoPDF.pluto_to_pdf(fin, fout)
    end
end
```