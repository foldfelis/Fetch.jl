export kdownload

const KAGGLE_DOMAIN = "www.kaggle.com"
const KAGGLE_API = "https://www.kaggle.com/api/v1/datasets/download"

struct Auth
    username::String
    key::String
end

StructTypes.StructType(::Type{Auth}) = StructTypes.Struct()

function gen_auth_key()
    auth_file = joinpath(homedir(), ".kaggle", "kaggle.json")

    if isfile(auth_file)
        f = open(auth_file, "r")
        auth = JSON3.read(f, Auth)
        close(f)
    else
        auth = Auth(ENV["KAGGLE_USERNAME"], ENV["KAGGLE_KEY"])
    end

    auth_str = Base64.base64encode("$(auth.username):$(auth.key)")

    return "Basic $(auth_str)"
end

function gen_kaggle_url(dataset)
    return "$KAGGLE_API/$dataset"
end

function kaggle_url2dataset(url_or_dataset)
    if contains(url_or_dataset, KAGGLE_DOMAIN)
        user_name, dataset_name = match(Regex("$KAGGLE_DOMAIN/([^/]+)/([^/]+)"), url_or_dataset).captures
        dataset = "$user_name/$dataset_name"
    else
        dataset = url_or_dataset
    end

    @assert HTTP.request("HEAD", "https://$KAGGLE_DOMAIN/$dataset").status == 200

    return dataset
end

function kdownload(url_or_dataset, localdir)
    dataset = kaggle_url2dataset(url_or_dataset)

    url = gen_kaggle_url(dataset)
    filepath = joinpath(localdir, "$(replace(dataset, '/'=>'_')).zip")

    HTTP.open("GET", url, ["Authorization"=>gen_auth_key()]) do stream
        HTTP.startread(stream)
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
