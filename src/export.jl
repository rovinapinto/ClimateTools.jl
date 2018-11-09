"""
    write(C::ClimGrid, filename::String)

Write to disk ClimGrid C to netCDF file.
"""
function write(C::ClimGrid, filename::String)

    # Test extension

    if extension(filename) .!= ".nc"
        filename = string(filename, ".nc")
    end

    timevec = get_timevec(C)

    # This creates a new NetCDF file
    # The mode "c" stands for creating a new file (clobber)
    ds = Dataset(filename, "c")

    # Define the dimension "lon" and "lat" with the size 100 and 110 resp.

    latsymbol, lonsymbol = ClimateTools.getsymbols(C)


    defDim(ds, string(lonsymbol), length(C[1][Axis{lonsymbol}][:]))
    defDim(ds, string(latsymbol), length(C[1][Axis{latsymbol}][:]))
    defDim(ds, "time", length(get_timevec(C)))

    if C.grid_mapping[mapping_name(C)] == "Regular_longitude_latitude"

        nclat = defVar(ds,"lat", Float64, (string(latsymbol),))
        nclat.attrib["units"] = C.latunits#"degrees_north"
        nclat.attrib["long_name"] = "latitude"
        nclat.attrib["standard_name"] = "latitude"
        nclat.attrib["actual_range"] = [minimum(C.latgrid), maximum(C.latgrid)]

        nclon = defVar(ds,"lon", Float64, (string(lonsymbol),))
        nclon.attrib["units"] = C.lonunits#"degrees_east"
        nclon.attrib["long_name"] = "longitude"
        nclon.attrib["standard_name"] = "longitude"
        nclon.attrib["actual_range"] = [minimum(C.longrid), maximum(C.longrid)]

    else # i.e. latitude and longitude are on a grid.

        nclat = defVar(ds,"lat", Float64, (string(lonsymbol), string(latsymbol)))
        nclat.attrib["units"] = C.latunits#"degrees_north"
        nclat.attrib["long_name"] = "latitude"
        nclat.attrib["standard_name"] = "latitude"
        nclat.attrib["actual_range"] = [minimum(C.latgrid), maximum(C.latgrid)]

        nclon = defVar(ds,"lon", Float64, (string(lonsymbol), string(latsymbol)))
        nclon.attrib["units"] = C.lonunits#"degrees_east"
        nclon.attrib["long_name"] = "longitude"
        nclon.attrib["standard_name"] = "longitude"
        nclon.attrib["actual_range"] = [minimum(C.longrid), maximum(C.longrid)]

    end


    if C.grid_mapping[mapping_name(C)] != "Regular_longitude_latitude"

        # Dimensions

        ncrlat = defVar(ds,string(latsymbol), Float64, (string(latsymbol),))
        ncrlat.attrib["long_name"] = "latitude in rotated pole grid"
        ncrlat.attrib["units"] = "degrees"
        ncrlat.attrib["standard_name"] = "grid_latitude"
        ncrlat.attrib["axis"] = "Y"
        ncrlat.attrib["coordinate_defines"] = "point"
        ncrlat.attrib["actual_range"] = [minimum(C[1][Axis{latsymbol}][:]), maximum(C[1][Axis{latsymbol}][:])]

        ncrlon = defVar(ds,string(lonsymbol), Float64, (string(lonsymbol),))
        ncrlon.attrib["long_name"] = "longitude in rotated pole grid"
        ncrlon.attrib["units"] = "degrees"
        ncrlon.attrib["standard_name"] = "grid_longitude"
        ncrlon.attrib["axis"] = "X"
        ncrlon.attrib["coordinate_defines"] = "point"
        ncrlon.attrib["actual_range"] = [minimum(C[1][Axis{lonsymbol}][:]), maximum(C[1][Axis{lonsymbol}][:])]
    end

    ncmapping = defVar(ds, C.grid_mapping[mapping_name(C)], Char, ())

    for iattr in keys(C.grid_mapping)
        ncmapping.attrib[iattr] = C.grid_mapping[iattr]
    end

    # time
    timeout = Array{Float64, 1}(undef, length(timevec))
    for itime = 1:length(timevec)
        timeout[itime] = NCDatasets.timeencode([timevec[itime]], C.timeattrib["units"], C.timeattrib["calendar"])[1]
    end


    # daysfrom = string("days since ", string(timevec[1] - Dates.Day(1))[1:10], " ", string(timevec[1])[12:end])

    nctime = defVar(ds,"time", Float64, ("time",))
    nctime.attrib["long_name"] = "time"
    nctime.attrib["standard_name"] = "time"
    nctime.attrib["axis"] = "T"
    nctime.attrib["calendar"] = C.typeofcal#"365_day"
    nctime.attrib["units"] = C.timeattrib["units"]#daysfrom
    # nctime.attrib["bounds"] = "time_bnds"
    nctime.attrib["coordinate_defines"] = "point"



    # Define the variables contained in ClimGrid C
    v = defVar(ds, C.variable, Float32, (string(lonsymbol),string(latsymbol), "time"))

    # ===========
    # DATA
    # Variable


    # write attributes
    for iattr in keys(C.varattribs)
        v.attrib[iattr] = C.varattribs[iattr]
    end

    # Define global attributes
    for iattr in keys(C.globalattribs)
        ds.attrib[iattr] = C.globalattribs[iattr]
    end

    v[:] = C[1].data

    # Time vector
    nctime[:] = timeout#Float64.(Dates.days.(Dates.DateTime.(timevec) - timevec[1] + Dates.DateTime(Dates.Day(1))))

    # Longitude/latitude
    if C.grid_mapping[mapping_name(C)] == "Regular_longitude_latitude"
        nclon[:] = C[1][Axis{lonsymbol}][:]
        nclat[:] = C[1][Axis{latsymbol}][:]
    elseif C.grid_mapping[mapping_name(C)] != "Regular_longitude_latitude"
        nclon[:] = C.longrid
        nclat[:] = C.latgrid
        ncrlon[:] = C[1][Axis{lonsymbol}][:]
        ncrlat[:] = C[1][Axis{latsymbol}][:]
    end

    # Close file
    close(ds)

end

function extension(url::String)
    try
        return match(r"\.[A-Za-z0-9]+$", url).match
    catch
        return ""
    end
end

function mapping_name(C::ClimGrid)

    K = collect(keys(C.grid_mapping))

    if sum(K .== "grid_mapping") == 1
        return "grid_mapping"
    elseif sum(K .== "grid_mapping_name") == 1
        return "grid_mapping_name"
    # elseif sum(keys(C.grid_mapping) .== "y") == 1
    #     return "y"
    # elseif sum(keys(C.grid_mapping) .== "yc") == 1
    #     return "yc"
    else
        throw(error("Mapping attributes seems wrong."))
    end



end
