function c = weatherScenario(key, airTempC)
%WEATHERSCENARIO  External conditions that can affect the crash and our system.
%   c = weatherScenario(key)            key: 'dry','light_rain','heavy_rain',
%                                            'cold','hot','sun_glare','night','worst'
%   c = weatherScenario(key, airTempC)  override the air temperature
%
%   What each condition changes (see docs/external_factors.md):
%     grip      run-off/track grip relative to dry -> changes impact speed
%     airTemp   foam stiffness and hydraulic oil viscosity (valve speed)
%     cameraOK  false = camera cannot see the car (spray, glare, smoke)
%     v_err     camera speed-estimate error (+ = predicts too fast)
%
%   The size of every effect is an ENGINEERING ASSUMPTION for this study,
%   chosen to be on the cautious side, and should be refined with tests.

    c.key = key;  c.grip = 1.0;  c.airTemp = 20;
    c.cameraOK = true;  c.v_err = 0.0;
    switch key
        case 'dry'
            c.name = 'Dry, sunny';
        case 'light_rain'
            c.name = 'Light rain';    c.grip = 0.75; c.airTemp = 15; c.v_err = 0.10;
        case 'heavy_rain'
            c.name = 'Heavy rain + spray (camera blind)';
            c.grip = 0.55; c.airTemp = 12; c.cameraOK = false;
        case 'cold'
            c.name = 'Cold (5 °C)';   c.airTemp = 5;
        case 'hot'
            c.name = 'Hot (40 °C air)'; c.airTemp = 40;
        case 'sun_glare'
            c.name = 'Low sun glare (camera +20 % error)'; c.v_err = 0.20;
        case 'night'
            c.name = 'Night race, floodlights (camera +10 % error)'; c.v_err = 0.10; c.airTemp = 22;
        case 'worst'
            c.name = 'Worst case: cold heavy rain, camera blind';
            c.grip = 0.55; c.airTemp = 5; c.cameraOK = false;
        otherwise
            error('weatherScenario: unknown key "%s"', key);
    end
    if nargin > 1 && ~isempty(airTempC), c.airTemp = airTempC; end

    % --- temperature effects (assumed, linear around 20 °C) --------------
    % Polyethylene foam gets stiffer when cold, softer when hot: ~0.6 %/°C.
    c.foamScale = 1 - 0.006*(c.airTemp - 20);
    % Hydraulic oil gets thicker when cold -> valves react more slowly.
    c.tau = 0.002*(1 + 0.04*max(0, 20 - c.airTemp));
end
