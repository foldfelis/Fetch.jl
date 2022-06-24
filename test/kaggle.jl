@testset "kaggle dataset" begin
    dataset = "ningjingyu/fetchtest"

    f = kdownload(dataset, pwd())
    unpack(f)

    open(joinpath(pwd(), "FetchTest", "FetchTest.txt"), "r") do file
        @test readline(file) == "Test"
    end

    rm(joinpath(pwd(), "FetchTest"), recursive=true, force=true)
end

@testset "kaggle url" begin
    urls = [
        "https://www.kaggle.com/ningjingyu/fetchtest",
        "https://www.kaggle.com/ningjingyu/fetchtest/tasks",
        "https://www.kaggle.com/ningjingyu/fetchtest/code",
        "https://www.kaggle.com/ningjingyu/fetchtest/discussion",
        "https://www.kaggle.com/ningjingyu/fetchtest/activity",
        "https://www.kaggle.com/ningjingyu/fetchtest/metadata",
        "https://www.kaggle.com/ningjingyu/fetchtest/settings",
    ]

    for url in urls
        f = kdownload(url, pwd())
        unpack(f)

        open(joinpath(pwd(), "FetchTest", "FetchTest.txt"), "r") do file
            @test readline(file) == "Test"
        end

        rm(joinpath(pwd(), "FetchTest"), recursive=true, force=true)
    end
end
