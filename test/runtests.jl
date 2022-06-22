using Fetch
using Test

include(joinpath(@__DIR__, "unpack.jl"))

@testset "Fetch.jl" begin
    include("gdrive.jl")
    include("kaggle.jl")
end
