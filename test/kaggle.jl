@testset "kaggle" begin
    dataset = "ningjingyu/fetchtest"

    f = kdownload(dataset, pwd())
    DataDeps.unpack(f)

    open(joinpath(pwd(), "FetchTest", "FetchTest.txt"), "r") do file
        @test readline(file) == "Test"
    end

    rm(joinpath(pwd(), "FetchTest"), recursive=true, force=true)
end
