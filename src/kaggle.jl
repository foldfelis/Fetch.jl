export kdownload

struct Auth
    username::String
    key::String
end

StructTypes.StructType(::Type{Auth}) = StructTypes.Struct()

function gen_auth_key()
    auth_file = joinpath(homedir(), ".kaggle", "kaggle.json")

    f = open(auth_file, "r")
    auth = JSON3.read(f, Auth)
    close(f)

    auth_str = Base64.base64encode("$(auth.username):$(auth.key)")

    return "Basic $(auth_str)"
end

function gen_kaggle_url(dataset)
    return "https://www.kaggle.com/api/v1/datasets/download/$dataset"
end

function kdownload(dataset, localdir)
    url = gen_kaggle_url(dataset)
    filepath = joinpath(localdir, "$(replace(dataset, '/'=>'_')).zip")

    HTTP.open("GET", url, ["Authorization"=>gen_auth_key()]) do stream
        eof(stream) && return

        total_bytes = tryparse(Int64, HTTP.header(stream, "Content-Length"))
        (total_bytes === nothing) && (total_bytes = NaN)
        println("Total: $total_bytes bytes")

        downloaded_bytes = progress = 0
        print("Downloaded:\e[s")
        Base.open(filepath, "w") do f
            while !eof(stream)
                downloaded_bytes += write(f, readavailable(stream))
                new_progress = 100downloaded_bytes ÷ total_bytes
                (new_progress > progress) && print("\e[u $downloaded_bytes bytes ($new_progress%)")
                progress = new_progress
            end
        end
    end

    return filepath
end
