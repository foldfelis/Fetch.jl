# Fetch

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://foldfelis.github.io/Fetch.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://foldfelis.github.io/Fetch.jl/dev)
[![Build Status](https://github.com/foldfelis/Fetch.jl/workflows/CI/badge.svg)](https://github.com/foldfelis/Fetch.jl/actions)
[![Coverage](https://codecov.io/gh/foldfelis/Fetch.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/foldfelis/Fetch.jl)

## Quick start

The package can be installed with the Julia package manager.
From the Julia REPL, type ] to enter the Pkg REPL mode and run:

```julia
pkg> add https://github.com/foldfelis/Fetch.jl
```

## Download file from Google drive

Download file or Google Sheet from Google drive via the share link:

```julia
using Fetch
gdownload("https://drive.google.com/file/d/1OiX6gEWRm57kb1H8L0K_HWN_pzc-sk8y/view?usp=sharing", pwd())
```

## Intergrate with DataDeps.jl

According to [DataDeps.jl](https://github.com/oxinabox/DataDeps.jl), `DataDep` can be construct as following:

```julia
DataDep(
    name::String,
    message::String,
    remote_path::Union{String,Vector{String}...},
    [checksum::Union{String,Vector{String}...},];
    fetch_method=fetch_default
    post_fetch_method=identity
)
```

By using `Fetch.jl`, one can upload their dataset to Google drive,
and construct `DataDep` by setting `fetch_method=gdownload`.

```julia
using DataDeps
using Fetch

register(DataDep(
    "FetchTest",
    """Test dataset""",
    "https://drive.google.com/file/d/1OiX6gEWRm57kb1H8L0K_HWN_pzc-sk8y/view?usp=sharing",
    fetch_method=gdownload,
    post_fetch_method=unpack
))

datadep"FetchTest"
```
