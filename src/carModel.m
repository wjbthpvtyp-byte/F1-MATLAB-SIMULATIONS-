function car = carModel(era)
%CARMODEL  Mass and front crush behaviour of an F1 car of a given era.
%   car = carModel('2020s'), carModel('2000s') or carModel('1994')
%
%   The crush curve is piecewise linear: force car.F(i) is reached at
%   crush depth car.d(i). Beyond the last point the survival cell is
%   treated as almost rigid (stiffness car.kEnd).
%
%   ALL CRUSH VALUES ARE ENGINEERING ESTIMATES (not FIA homologation data)
%   and are tuned in the calibration step against recorded crash g-forces.

    switch lower(era)
        case {'2020s','modern'}
            % 2020s cars: long homologated nose impact structure.
            car.name = '2020s F1 car';
            car.mass = 798;                     % FIA minimum incl. driver [kg]
            car.massNote = 'FIA minimum weight incl. driver (2020s regulations)';
            car.d = [0     0.10   0.46];        % crush depth [m]  (tapered nose:
            car.F = [0     300e3  420e3];       % force [N]         force builds over 10 cm)
            car.kEnd = 1e7;                     % survival cell [N/m]

        case '1994'
            % 1994 cars: shorter, weaker nose; no rear/side impact tests yet.
            car.name = '1994 F1 car (Williams FW16 class)';
            % 500 kg minimum car weight WITHOUT driver (RaceFans, min-weight
            % history) + ~70 kg driver + ~40 kg fuel early in a refuelling race.
            car.mass = 610;
            car.massNote = '500 kg car (1994 min, excl. driver) + ~70 kg driver + ~40 kg fuel (estimate)';
            car.d = [0     0.08   0.36];
            car.F = [0     220e3  300e3];
            car.kEnd = 1e7;

        case '2000s'
            % 1999-2010 cars: homologated nose, lighter than today.
            car.name = '1999-2010 F1 car';
            car.mass = 600;                     % ~600 kg incl. driver (1995-2007 era rules)
            car.massNote = '~600 kg minimum incl. driver (estimate for the era)';
            car.d = [0     0.10   0.40];
            car.F = [0     260e3  360e3];
            car.kEnd = 1e7;

        otherwise
            error('carModel: unknown era "%s"', era);
    end
end
