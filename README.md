# Fetch

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://foldfelis.github.io/Fetch.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://foldfelis.github.io/Fetch.jl/dev)
[![Build Status](https://github.com/foldfelis/Fetch.jl/workflows/CI/badge.svg)](https://github.com/foldfelis/Fetch.jl/actions)
[![Coverage](https://codecov.io/gh/foldfelis/Fetch.jl/branch/main/graph/badge.svg?token=G08KQ7K4U2)](https://codecov.io/gh/foldfelis/Fetch.jl)

## Quick start

The package can be installed with the Julia package manager.
From the Julia REPL, type ] to enter the Pkg REPL mode and run:

```julia
pkg> add Fetch
```

## Download file from Google drive

Download file or Google Sheet from Google drive via the share link:

```julia
using Fetch
link = "https://drive.google.com/file/d/1OiX6gEWRm57kb1H8L0K_HWN_pzc-sk8y/view?usp=sharing"
gdownload(link, pwd())
```

## Download dataset from Kaggle

Download dataset from Kaggle via the name:

```julia
using Fetch
dataset = "ningjingyu/fetchtest"
kdownload(dataset, pwd())
```

And via url as well

```julia
using Fetch
url = "https://www.kaggle.com/ningjingyu/fetchtest"
kdownload(url, pwd())
```

## Intergrate with DataDeps.jl

According to [DataDeps.jl](https://github.com/oxinabox/DataDeps.jl),
`DataDep` can be construct as following:

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
    "b083597a25bec4c82c2060651be40c0bb71075b472d3b0fabd85af92cc4a7076",
    fetch_method=gdownload,
    post_fetch_method=unpack
))

datadep"FetchTest"
```

Or to Kaggle

```julia
using DataDeps
using Fetch

register(DataDep(
    "FetchTest",
    """Test dataset""",
    "ningjingyu/fetchtest",
    "65492e1f4c6affb7955125e5e4cece2bb547e482627f3af9812c06448dae40a9",
    fetch_method=kdownload,
    post_fetch_method=unpack
))

datadep"FetchTest"
```

According to the document of [Kaggle-api](https://github.com/Kaggle/kaggle-api#api-credentials)
one needs to set their environment variables `KAGGLE_USERNAME` and `KAGGLE_KEY`,
or simply download the api token from Kaggle, and place this file in the location `~/.kaggle/kaggle.json`
(on Windows in the location `C:\Users\<Windows-username>\.kaggle\kaggle.json`).
