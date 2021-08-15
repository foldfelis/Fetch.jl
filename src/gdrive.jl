export gdownload

const SPREADSHEET_PATTERN = "docs.google.com/spreadsheets"
const DRIVE_PATTERN = "drive.google.com/file/d"
const DOCS_PATTERN = "docs.google.com"

is_gsheet(url) = occursin(SPREADSHEET_PATTERN, url)
is_gfile(url) = occursin(DRIVE_PATTERN, url)
is_gdoc(url) = occursin(DOCS_PATTERN, url)

"""
    unshortlink(url)

return unshorten url or the url if it is not a short link
"""
function unshortlink(url; kw...)
    rq = HTTP.request("HEAD", url; redirect=false, status_exception=false, kw...)
    while !(is_gdoc(url) || is_gfile(url)) && (rq.status ÷ 100 == 3)
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
    isnothing(h) && throw(ErrorException("Can't find google drive file ID in the url"))

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
    if isnothing(m)
        filename = "gdrive_downloaded-$(randstring())"
        @warn "File name not found, use `$filename`"
    else
        filename = m.captures[]
    end

    return filename
end

function download_gdrive(url, localdir)
    cookiejars = Dict{String, Set{HTTP.Cookies.Cookie}}()
    HTTP.request("GET", url; cookies=true, cookiejar=cookiejars)
    gcode = find_gcode(cookiejars["docs.google.com"])

    !isnothing(gcode) && (url = "$url&confirm=$gcode")

    filepath = Ref{String}("")
    HTTP.open(
        "GET", url, ["Range"=>"bytes=0-"],
        cookies=true, cookiejar=cookiejars, redirect_limit=10
    ) do stream
        response = HTTP.startread(stream)
        eof(stream) && return

        header = HTTP.header(response, "Content-Disposition")
        isempty(header) && return

        filepath[] = joinpath(localdir, find_filename(header))

        total_bytes = tryparse(Int64, rsplit(HTTP.header(response, "Content-Range"), '/'; limit=2)[end])
        isnothing(total_bytes) && (total_bytes = NaN)
        println("Total: $total_bytes bytes")

        downloaded_bytes = progress = 0
        print("Downloaded:\e[s")
        Base.open(filepath[], "w") do fh
            while !eof(stream)
                downloaded_bytes += write(fh, readavailable(stream))
                new_progress = 100downloaded_bytes ÷ total_bytes
                (new_progress > progress) && print("\e[u $downloaded_bytes bytes ($new_progress%)")
                progress = new_progress
            end
            println()
        end
    end

    return filepath[]
end

"""
    gdownload(url, localdir)

Download file or Google Sheet from Google drive.
"""
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
