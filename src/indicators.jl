"""
    vaporpressure(surface_pressure::ClimGrid, specific_humidity::ClimGrid)

Returns the vapor pressure (vp) (Pa) based on the surface pressure (sp) (Pa) and the specific humidity (q).

``vp = \\frac{q * sp}{q+0.622}``

"""
function vaporpressure(specific_humidity::ClimGrid, surface_pressure::ClimGrid)
  @argcheck surface_pressure[9] == "ps"
  @argcheck specific_humidity[9] == "huss"

  # Calculate vapor pressure
  vp_arraytmp = (specific_humidity.data .* surface_pressure.data) ./ (specific_humidity.data .+ 0.622)
  vp_array = buildarrayinterface(vp_arraytmp, surface_pressure)

  # Build dictionary for the variable vp
  vp_dict = surface_pressure.varattribs
  vp_dict["standard_name"] = "water_vapor_pressure"
  vp_dict["units"] = "Pa"
  vp_dict["history"] = "Water vapor pressure calculated by a function of surface_pressure and specific humidity"

  # Build ClimGrid object
  return ClimGrid(vp_array, longrid=surface_pressure.longrid, latgrid=surface_pressure.latgrid, msk=surface_pressure.msk, grid_mapping=surface_pressure.grid_mapping, dimension_dict=surface_pressure.dimension_dict, model=surface_pressure.model, frequency=surface_pressure.frequency, experiment=surface_pressure.experiment, run=surface_pressure.run, project=surface_pressure.project, institute=surface_pressure.institute, filename=surface_pressure.filename, dataunits="Pa", latunits=surface_pressure.latunits, lonunits=surface_pressure.lonunits, variable="vp", typeofvar="vp", typeofcal=surface_pressure.typeofcal, varattribs=vp_dict, globalattribs=surface_pressure.globalattribs)
end


"""
    vaporpressure(specific_humidity::ClimGrid, sealevel_pressure::ClimGrid, orography::ClimGrid, daily_temperature::ClimGrid)

Returns the vapor pressure (vp) (Pa) estimated with the specific humidity (q), the sea level pressure (psl) (Pa), the orography (orog) (m) and the daily mean temperature (tas) (K). An approximation of the surface pressure is first computed by using the sea level pressure, orography and the daily mean temperature (see [`approx_surfacepressure`](@ref)). Then, vapor pressure is calculated by:

``vp = \\frac{q * sp}{q+0.622}``

"""
function vaporpressure(specific_humidity::ClimGrid, sealevel_pressure::ClimGrid, orography::ClimGrid, daily_temperature::ClimGrid)
  @argcheck specific_humidity[9] == "huss"
  @argcheck sealevel_pressure[9] == "psl"
  @argcheck orography[9] == "orog"
  @argcheck daily_temperature[9] == "tas"

  # Calculate the estimated surface pressure
  surface_pressure = approx_surfacepressure(sealevel_pressure, orography, daily_temperature)

  # Calculate vapor pressure
  vapor_pressure = vaporpressure(specific_humidity, surface_pressure)

  # Return ClimGrid type containing the vapor pressure
  return vapor_pressure
end

  """
      approx_surfacepressure(sealevel_pressure::ClimGrid, orography::ClimGrid, daily_temperature::ClimGrid)

Returns the approximated surface pressure (*sp*) (Pa) using sea level pressure (*psl*) (Pa), orography (*orog*) (m), and daily mean temperature (*tas*) (K).

``sp = psl * 10^{x}``

where ``x = \\frac{-orog}{18400 * tas / 273.15} ``

"""
function approx_surfacepressure(sealevel_pressure::ClimGrid, orography::ClimGrid, daily_temperature::ClimGrid)
  @argcheck sealevel_pressure[9] == "psl"
  @argcheck orography[9] == "orog"
  @argcheck daily_temperature[9] == "tas"

  # Calculate the estimated surface pressure
  exponent = (-1.0 .* orography.data) ./ (18400.0 .* daily_temperature.data ./ 273.15)
  ps_arraytmp = sealevel_pressure.data .* (10.^exponent)
  ps_array = buildarrayinterface(ps_arraytmp, sealevel_pressure)

  # Build dictionary for the variable vp
  ps_dict = sealevel_pressure.varattribs
  ps_dict["standard_name"] = "surface_pressure"
  ps_dict["units"] = "Pa"
  ps_dict["history"] = "Surface pressure estimated with the sealevel pressure, the orography and the daily temperature"

  # Build ClimGrid object
  return ClimGrid(ps_array, longrid=sealevel_pressure.longrid, latgrid=sealevel_pressure.latgrid, msk=sealevel_pressure.msk, grid_mapping=sealevel_pressure.grid_mapping, dimension_dict=sealevel_pressure.dimension_dict, model=sealevel_pressure.model, frequency=sealevel_pressure.frequency, experiment=sealevel_pressure.experiment, run=sealevel_pressure.run, project=sealevel_pressure.project, institute=sealevel_pressure.institute, filename=sealevel_pressure.filename, dataunits="Pa", latunits=sealevel_pressure.latunits, lonunits=sealevel_pressure.lonunits, variable="ps", typeofvar="ps", typeofcal=sealevel_pressure.typeofcal, varattribs=ps_dict, globalattribs=sealevel_pressure.globalattribs)
end

"""
    wbgt(diurnal_temperature::ClimGrid, vapor_pressure::ClimGrid)

Returns the simplified wet-bulb global temperature (*wbgt*) (Celsius) calculated using the vapor pressure (Pa) of the day and the estimated mean diurnal temperature (Celsius; temperature between 7:00 (7am) and 17:00 (5pm)).

``wbgt = 0.567 * Tday + 0.00393 * vp + 3.94``

"""
function wbgt(diurnal_temperature::ClimGrid, vapor_pressure::ClimGrid)
  @argcheck diurnal_temperature[9] == "tdiu"
  @argcheck vapor_pressure[9] == "vp"

  # Calculate the wbgt
  wbgt_arraytmp = (0.567 .* diurnal_temperature.data) + (0.00393 .* vapor_pressure.data) .+ 3.94
  wbgt_array = buildarrayinterface(wbgt_arraytmp, diurnal_temperature)

  # Build dictionary for the variable wbgt
  wbgt_dict = diurnal_temperature.varattribs
  wbgt_dict["standard_name"] = "simplified_wetbulb_globe_temperature"
  wbgt_dict["units"] = "Celsius"
  wbgt_dict["history"] = "Wet-bulb globe temperature estimated with the vapor pressure and the diurnal temperature"

  # Build ClimGrid object
  return ClimGrid(wbgt_array, longrid=diurnal_temperature.longrid, latgrid=diurnal_temperature.latgrid, msk=diurnal_temperature.msk, grid_mapping=diurnal_temperature.grid_mapping, dimension_dict=diurnal_temperature.dimension_dict, model=diurnal_temperature.model, frequency=diurnal_temperature.frequency, experiment=diurnal_temperature.experiment, run=diurnal_temperature.run, project=diurnal_temperature.project, institute=diurnal_temperature.institute, filename=diurnal_temperature.filename, dataunits="Celsius", latunits=diurnal_temperature.latunits, lonunits=diurnal_temperature.lonunits, variable="wbgt", typeofvar="wbgt", typeofcal=diurnal_temperature.typeofcal, varattribs=wbgt_dict, globalattribs=diurnal_temperature.globalattribs)
end
