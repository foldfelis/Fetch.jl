module Fetch
    using Random: randstring
    using HTTP
    using JSON3
    using StructTypes
    using Base64

    include("gdrive.jl")
    include("kaggle.jl")
end
