const LARGE_GFILE = "https://drive.google.com/file/d/1OiX6gEWRm57kb1H8L0K_HWN_pzc-sk8y/view?usp=sharing"
const SMALL_GDRIVE = "https://drive.google.com/file/d/1BENwlCOlGEMF8zsM4rC-SYVxyL7f8xw0/view?usp=sharing"
const GFILE_NAME = "FetchTest"

@testset "large file" begin
    f = gdownload(LARGE_GFILE, pwd())
    unpack(f)

    open(joinpath(pwd(), GFILE_NAME, "$GFILE_NAME.txt"), "r") do file
        @test readline(file) == "Test"
    end

    rm(GFILE_NAME, recursive=true, force=true)
end

@testset "small file" begin
    gdownload(SMALL_GDRIVE, pwd())
    open(joinpath(pwd(), "$GFILE_NAME.txt"), "r") do file
        @test readline(file) == "Test"
    end

    rm("$GFILE_NAME.txt", recursive=true, force=true)
end

const GSHEET = "https://docs.google.com/spreadsheets/d/1rwoDt5HrcP6TTgBe3BWxp7kPdVMWuS1cGVZp7BXhPwc/edit?usp=sharing"
const GSHEET_NAME = "FetchTest"

@testset "sheet" begin
    gdownload(GSHEET, pwd())
    open(joinpath(pwd(), "$GSHEET_NAME-1.csv"), "r") do file
        @test readline(file) == "Test,1"
    end

    rm("$GSHEET_NAME-1.csv", recursive=true, force=true)
end

@testset "unshortlink" begin
    @test Fetch.unshortlink("https://bit.ly/3ir0gYu") == LARGE_GFILE
    @test Fetch.unshortlink("https://bit.ly/3yqqdwK") == SMALL_GDRIVE
    @test Fetch.unshortlink("https://bit.ly/3yDDi69") == GSHEET
end
