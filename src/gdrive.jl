using DataDeps
using Dates
using Random: randstring
using HTTP

export
    download_gdrive,
    maybegoogle_download

"""
    unshortlink(url)

return unshorten url or the url if it is not a short link
"""
function unshortlink(url; kw...)
    rq = HTTP.request("HEAD", url; redirect=false, status_exception=false, kw...)
    while rq.status ÷ 100 == 3
        url = HTTP.header(rq, "Location")
        rq = HTTP.request("HEAD", url; redirect=false, status_exception=false, kw...)
    end

    return url
end

is_gsheet(url) = occursin("docs.google.com/spreadsheets", url)
is_gdoc(url) = occursin("docs.google.com", url)
is_gfile(url) = occursin("drive.google.com/file/d", url)

function gsheet_handler(url; format=:csv)
    link, expo = splitdir(url)
    if startswith(expo, "edit") || expo == ""
        url = link * "/export?format=$format"
    elseif startswith(expo, "export")
        url = replace(url, r"format=([a-zA-Z]*)(.*)"=>SubstitutionString("format=$format\\2"))
    end

    return url
end

function gfile_handler(url)
    # pattern of file path in google drive:
    # https://drive.google.com/file/d/<hash>/view?usp=sharing
    p, ｈ = splitdir(url)
    while splitdir(p)[2] != "d"
        p, ｈ = splitdir(p)
    end
    url = "https://docs.google.com/uc?export=download&id=" * ｈ

    return url
end

function find_gcode(ckj)
    for cookie ∈ ckj
        if match(r"download_warning_", cookie.name) !== nothing
            return cookie.value
        end
    end

    return
end

function download_gdrive(url, localdir; retry=true, retries=4)
    gcode = nothing
    try_time = 0
    ckjar = Dict{String, Set{HTTP.Cookies.Cookie}}()
    while isnothing(gcode) && retry && try_time < retries
        if try_time > 0
            @info "retrying..."
        end
        try_time += 1
        rq = HTTP.request("HEAD", url; cookies=true, cookiejar=ckjar)
        ckj = ckjar["docs.google.com"]
        gcode = find_gcode(ckj)
        if isnothing(gcode)
            @warn "gcode not found." rq
            sleep(3)
        end
    end

    if isnothing(gcode)
        error("download failed")
    end


    format_progress(x) = round(x, digits=4)
    format_bytes(x) = !isfinite(x) ? "∞ B" : Base.format_bytes(x)
    format_seconds(x) = "$(round(x; digits=2)) s"
    format_bytes_per_second(x) = format_bytes(x) * "/s"

    local filepath
    # newurl = unshortlink("$url&confirm=$gcode"; cookies=true, cookiejar=ckjar)
    newurl = "$url&confirm=$gcode"

    #part of codes are from https://github.com/JuliaWeb/HTTP.jl/blob/master/src/download.jl
    HTTP.open("GET", newurl, ["Range"=>"bytes=0-"]; cookies=true, cookiejar=ckjar, redirect_limit=10) do stream
        resp = HTTP.startread(stream)
        hcd = HTTP.header(resp, "Content-Disposition")
        isempty(hcd) && return

        m = match(r"filename=\\\"(.*)\\\"", hcd)
        if m === nothing
            filename = "gdrive_downloaded-$(randstring())"
        else
            filename = m.captures[]
        end

        filepath = joinpath(localdir, filename)

        total_bytes = tryparse(Float64, split(HTTP.header(resp, "Content-Range"), '/')[end])
        total_bytes === nothing && (total_bytes = NaN)
        downloaded_bytes = 0
        start_time = now()
        prev_time = now()
        period = DataDeps.progress_update_period()

        function report_callback()
            prev_time = now()
            taken_time = (prev_time - start_time).value / 1000 # in seconds
            average_speed = downloaded_bytes / taken_time
            remaining_bytes = total_bytes - downloaded_bytes
            remaining_time = remaining_bytes / average_speed
            completion_progress = downloaded_bytes / total_bytes

            @info("Downloading",
                  source=url,
                  dest = filepath,
                  progress = completion_progress |> format_progress,
                  time_taken = taken_time |> format_seconds,
                  time_remaining = remaining_time |> format_seconds,
                  average_speed = average_speed |> format_bytes_per_second,
                  downloaded = downloaded_bytes |> format_bytes,
                  remaining = remaining_bytes |> format_bytes,
                  total = total_bytes |> format_bytes,
                  )
        end

        Base.open(filepath, "w") do fh
            while(!eof(stream))
                downloaded_bytes += write(fh, readavailable(stream))
                if !isinf(period)
                  if now() - prev_time > Millisecond(1000*period)
                    report_callback()
                  end
                end
            end
        end
        report_callback()
    end

    return filepath
end

function maybegoogle_download(url, localdir)
    long_url = unshortlink(url)
    is_gsheet(long_url) && (long_url = gsheet_handler(long_url))
    is_gfile(long_url) && (long_url = gfile_handler(long_url))

    if is_gdoc(long_url)
        download_gdrive(long_url, localdir)
    else
        DataDeps.fetch_http(long_url, localdir)
    end
end
