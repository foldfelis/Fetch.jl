using DataDeps
using Dates
using Random: randstring
using HTTP

export gdownload

is_gsheet(url) = occursin("docs.google.com/spreadsheets", url)
is_gfile(url) = occursin("drive.google.com/file/d", url)
is_gdoc(url) = occursin("docs.google.com", url)

"""
    unshortlink(url)

return unshorten url or the url if it is not a short link
"""
function unshortlink(url; kw...)
    rq = HTTP.request("HEAD", url; redirect=false, status_exception=false, kw...)
    while !is_gdoc(url) && (rq.status ÷ 100 == 3)
        url = HTTP.header(rq, "Location")
        rq = HTTP.request("HEAD", url; redirect=false, status_exception=false, kw...)
    end

    return url
end

function gsheet_handler(url; format=:csv)
    link, expo = splitdir(url)
    if startswith(expo, "edit") || (expo == "")
        url = link * "/export?format=$format"
    elseif startswith(expo, "export")
        url = replace(url, r"format=([a-zA-Z]*)(.*)"=>SubstitutionString("format=$format\\2"))
    end

    return url
end

function gfile_handler(url)
    # pattern of file path in google drive:
    # https://drive.google.com/file/d/<hash>/view?usp=sharing
    h = match(r"/file/d/([^\/]+)/", url)
    (h === nothing) && throw("Can't find goole drive file ID in the url")

    return "https://docs.google.com/uc?export=download&id=$(h.captures[])"
end

function find_gcode(cookies)
    for cookie in cookies
        (match(r"download_warning_", cookie.name) !== nothing) && (return cookie.value)
    end

    return
end

function find_filename(header)
    m = match(r"filename=\\\"(.*)\\\"", header)
    if m === nothing
        filename = "gdrive_downloaded-$(randstring())"
    else
        filename = m.captures[]
    end

    return filename
end

function download_gdrive(url, localdir)
    cookiejars = Dict{String, Set{HTTP.Cookies.Cookie}}()
    HTTP.request("GET", url; cookies=true, cookiejar=cookiejars)
    gcode = Fetch.find_gcode(cookiejars["docs.google.com"])

    !isnothing(gcode) && (url = "$url&confirm=$gcode")

    local filepath
    HTTP.open(
        "GET", url, ["Range"=>"bytes=0-"],
        cookies=true, cookiejar=cookiejars, redirect_limit=10
    ) do stream
        response = HTTP.startread(stream)
        header = HTTP.header(response, "Content-Disposition")
        isempty(header) && return

        filepath = joinpath(localdir, find_filename(header))

        total_bytes = tryparse(Int64, split(HTTP.header(response, "Content-Range"), '/')[end])
        (total_bytes === nothing) && (total_bytes = NaN)
        println("Total: $total_bytes bytes")

        downloaded_bytes = progress = 0
        print("Downloaded:\e[s")
        Base.open(filepath, "w") do fh
            while(!eof(stream))
                downloaded_bytes += write(fh, readavailable(stream))
                new_progress = 100downloaded_bytes ÷ total_bytes
                (new_progress > progress) && print("\e[u $downloaded_bytes bytes ($new_progress%)")
                progress = new_progress
            end
            println()
        end
    end

    return filepath
end

function gdownload(url, localdir)
    url = unshortlink(url)

    if is_gfile(url)
        url = gfile_handler(url)
    elseif is_gsheet(url)
        url = gsheet_handler(url)
    end

    is_gdoc(url) || throw("invalid url")
    download_gdrive(url, localdir)
end
