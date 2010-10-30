////////////////////////////////////////////////////////////////////////////////

/**
 * Convert temperature values to K from the specified units.
 */
function convertTemperatureFrom(value, units) {
    if (units == 'K')       return value;
    else if (units == 'C')  return value + 273.15;
    else if (units == 'F')  return (value + 459.67) / 1.8;
    else if (units == 'R')  return value / 1.8;
}

/**
 * Convert temperature values from K to the specified units.
 */
function convertTemperatureTo(value, units) {
    if (units == 'K')       return value;
    else if (units == 'C')  return value - 273.15;
    else if (units == 'F')  return value * 1.8 - 459.67;
    else if (units == 'R')  return value * 1.8;
}

/**
 * Convert pressure values from Pa to the specified units.
 */
function convertPressureTo(value, units) {
    if (units == 'bar')        return value / 1.0e5;
    else if (units == 'atm')   return value / 101325.;
    else if (units == 'Pa')    return value;
    else if (units == 'psi')   return value / 6894.757;
    else if (units == 'torr')  return value / 101325. / 760.0;
}

/**
 * Convert energy values from J/mol to the specified units.
 */
function convertEnergyTo(value, units) {
    if (units == 'kJ/mol')         return value / 1000.;
    else if (units == 'kcal/mol')  return value / 4184.;
    else if (units == 'J/mol')     return value;
    else if (units == 'cal/mol')   return value / 4.184;
    else if (units == 'cm^-1')     return value / 2.9979e10 * 6.626e-34 * 6.022e23;
}

/**
 * Convert heat capacity values from J/mol*K to the specified units.
 */
function convertHeatCapacityTo(value, units) {
    if (units == 'J/mol*K')         return value;
    else if (units == 'cal/mol*K')  return value / 4.184;
}

////////////////////////////////////////////////////////////////////////////////

function wilhoit_getHeatCapacity(T, Cp0, CpInf, a0, a1, a2, a3, B, H0, S0) {
    var y = T / (T + B);
    return Cp0 + (CpInf - Cp0)*y*y*(1 + (y-1)*(a0 + y*(a1 + y*(a2 + y*a3))));
}

function wilhoit_getEnthalpy(T, Cp0, CpInf, a0, a1, a2, a3, B, H0, S0) {
    var y = T / (T + B);
    var y2 = y*y;
    var logBplust = Math.log(B + T);
    return H0 + Cp0*T - (CpInf-Cp0)*T*(y2*((3*a0 + a1 + a2 + a3)/6. + (4*a1 + a2 + a3)*y/12. + (5*a2 + a3)*y2/20. + a3*y2*y/5.) + (2 + a0 + a1 + a2 + a3)*( y/2. - 1 + (1/y-1)*logBplust)); 
}

function wilhoit_getEntropy(T, Cp0, CpInf, a0, a1, a2, a3, B, H0, S0) {
    var y = T / (T + B);
    var logt = Math.log(T);
    var logy = Math.log(y);
    return S0 + CpInf*logt-(CpInf-Cp0)*(logy+y*(1+y*(a0/2+y*(a1/3 + y*(a2/4 + y*a3/5)))));
}