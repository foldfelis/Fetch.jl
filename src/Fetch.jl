module Fetch
    using Random: randstring
    using HTTP

    include("gdrive.jl")
    include("kaggle.jl")
end
