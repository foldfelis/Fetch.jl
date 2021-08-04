using DataDeps
using HTTP

const GFILE = "https://drive.google.com/file/d/1OiX6gEWRm57kb1H8L0K_HWN_pzc-sk8y/view?usp=sharing"
const GFILE_NAME = "FetchTest"

@testset "gdrive" begin
    f = maybegoogle_download(GFILE, pwd())
    DataDeps.unpack(f)

    open(joinpath(pwd(), GFILE_NAME, "$GFILE_NAME.txt"), "r") do file
        @test readline(file) == "Test"
    end

    rm(GFILE_NAME, recursive=true, force=true)
end
