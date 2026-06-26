%%% function to convert dissolved oxygen concentration to % saturation

function DO_sat = O2_umolL_to_sat(DO_umolL, temp_C, salinity_psu)
    % Compute O2 saturation concentration (umol/L) using Garcia & Gordon (1992)
    % Inputs:
    %   DO_umolL     - measured dissolved oxygen in umol/L
    %   temp_C       - temperature in degrees Celsius
    %   salinity_psu - salinity in PSU (use 0 for freshwater)

    Ts = log((298.15 - temp_C) ./ (273.15 + temp_C));

    % Coefficients for umol/L output
    A0 = 5.80871;
    A1 = 3.20291;
    A2 = 4.17887;
    A3 = 5.10006;
    A4 = -9.86643e-2;
    A5 = 3.80369;
    B0 = -7.01577e-3;
    B1 = -7.70028e-3;
    B2 = -1.13864e-2;
    B3 = -9.51519e-3;
    C0 = -2.75915e-7;

    lnO2sat = A0 + A1.*Ts + A2.*Ts.^2 + A3.*Ts.^3 + A4.*Ts.^4 + A5.*Ts.^5 ...
            + salinity_psu .* (B0 + B1.*Ts + B2.*Ts.^2 + B3.*Ts.^3) ...
            + C0 .* salinity_psu.^2;

    O2_eq = exp(lnO2sat);  % equilibrium O2 in umol/L

    DO_sat = (DO_umolL ./ O2_eq) .* 100;  % % saturation
end