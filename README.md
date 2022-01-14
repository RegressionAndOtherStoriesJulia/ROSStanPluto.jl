# ROSStanPluto.jl

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->

## Purpose

This project will contain (work is in early stages of progress!!) a set of Pluto notebooks that contain Julia versions of the examples in the R project `ROS-Examples` based on the book ["Regression and Other Stories" by A Gelman, J Hill and A Vehtari](https://www.cambridge.org/highereducation/books/regression-and-other-stories/DD20DD6C9057118581076E54E40C372C#overview).

These notebooks are intended to be used in conjunction with above book.

## Prerequisites

To complete below steps and run the notebooks you need:

1. A functioning [cmdstan](https://mc-stan.org/users/interfaces/cmdstan.html).
2. A functioning [Julia](https://julialang.org/downloads/).
3. A downloaded version of [ROS-Examples](https://github.com/avehtari/ROS-Examples).
4. Setup an environment variable JULIA_ROS_HOME pointing to the ROS-Examples directory.
5. Access to some development tools, e.g. git and a C++ toolchain.
6. A Julia base environment containing `Pkg`, `DrWatson`, `Pluto` and `PlutoUI`.

## Setup the Pluto based ROSStanPluto notebooks

To (locally) use this project, do the following:

Select and download ROSStanPluto.jl from [StanJulia on Github](https://github.com/StanJulia/) .e.g.:
```Julia
$ git clone https://github.com/StanJulia/ROSStanPluto.jl # Or the Github site options.
$ cd ROSStanPluto.jl # Move to the downloaded directory
$ julia --project=ROSStanPluto # Available from Julia-1.7 onwards.
(ROSStanPluto) pkg> activate .
```

Still in the Julia REPL, start a Pluto notebook server.
```Julia
julia> using Pluto
julia> Pluto.run()
```

A Pluto page should open in a browser. See [this page](https://www.juliafordatascience.com/first-steps-5-pluto/) for a quick Pluto introduction.

## Usage

Select a notebook in the `open a file` entry box, e.g. type `./` and step to e.g. `./notebooks/01/02/hibbs.jl`, the first notebook from the book.

The code examples are organized in subdirectories according to  chapter/section/example, e.g. `01/02/hibbs.jl`.

See [TIPS](https://github.com/StanJulia/ROSStanPluto.jl/blob/master/TIPS.md) for some more details or file an [issue](https://github.com/StanJulia/ROSStanPluto.jl/issues) if any difficulties are encountered with above steps.
