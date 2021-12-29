function ss = sigstrength_GPU(rxs, txs, parcluster, varargin)
%sigstrength   Signal strength due to transmitter
% Allocate output matrix
numTx = numel(txs);
numRx = numel(rxs);
ss = zeros(numTx, numRx,'gpuArray');

% Process optional inputs
p = inputParser;
p.addOptional('PropagationModel', [], @(x)ischar(x)||isstring(x)||isa(x,'rfprop.PropagationModel'));
p.addParameter('Type', 'power');
p.addParameter('ReceiverGain', []);
p.addParameter('Map', []);
p.addParameter('TransmitterAntennaSiteCoordinates', []);
p.addParameter('ReceiverAntennaSiteCoordinates', []);
p.addParameter('TerrainProfiles', []);
p.parse(varargin{:});

map = rfprop.internal.Validators.validateMapTerrainSource(p, 'sigstrength');
pm = rfprop.internal.Validators.validateGeographicPropagationModel(p, map, 'sigstrength');
rxGain = validateReceiverGain(p, numTx);

% Get site antenna coordinates
txsCoords = rfprop.internal.Validators.validateAntennaSiteCoordinates(...
    p.Results.TransmitterAntennaSiteCoordinates, txs, map, 'sigstrength');
rxsCoords = rfprop.internal.Validators.validateAntennaSiteCoordinates(...
    p.Results.ReceiverAntennaSiteCoordinates, rxs, map, 'sigstrength');

% Get path loss and propagation path info
[Lpls_db, info] = pm.pathloss(rxs, txs, 'Map', map, ...
    'TransmitterAntennaSiteCoordinates', txsCoords, ...
    'ReceiverAntennaSiteCoordinates', rxsCoords, ...
    'ComputeAngleOfArrival', isempty(rxGain), ...
    'TerrainProfiles', p.Results.TerrainProfiles);

Lpls_db = gpuArray(single(Lpls_db));
% Use faster (but lower resolution) algorithm when there are many receivers
useFastGain = numRx >= 100;
fqs = [txs.TransmitterFrequency];
Ptxs = [txs.TransmitterPower];
Ptx_dbs = 10 * log10(Ptxs)+30;
Ltxsys_dbs = [txs.SystemLoss]';
%when numTx/2 < number of workers, for loop is faster; otherwise parallel is
%faster
 if parcluster==1
    for txInd = 1:numTx
        tx = txs(txInd);
%         % Compute transmitter constants
%         fq = tx.TransmitterFrequency;
%         Ptx = tx.TransmitterPower;
%         Ptx_db = 10 * log10(Ptx)+30; % Convert W to dBm (db with reference to mW)
%         Ltxsys_db = tx.SystemLoss;
        info_tx = info(txInd,:);

        txAods = gpuArray([info_tx.AngleOfDeparture]);
        txAz = txAods(1,:);
        txEl = txAods(2,:);
        if useFastGain
            Gtx_db = gain(tx, fqs(txInd), txAz, txEl, 'fast') - Ltxsys_dbs(txInd);
        else
            Gtx_db = gain(tx, fqs(txInd), txAz, txEl) - Ltxsys_dbs(txInd);
        end
        Lpl_db = Lpls_db(txInd, :)';
        
        % Compute signal strength in dBm, using link budget form of
        % Friis equation:
        %
        %  Received Power (dB) = Transmitted Power (dB) + Gains (dB) - Losses (dB))
        %
        % Applied to tx/rx, this yields:
        %
        %  Prx_db = Ptx_db + Gtx_db + Grx_db - Lpl_db
        %
        % where:
        %  * Prx_db is received power in dBm at receiver input
        %  * Ptx_db is transmitter output power in dBm
        %  * Gtx_db is transmitter gain in dBi (antenna gain - system loss)
        %  * Grx_db is receiver gain in dBi (antenna gain - system loss)
        %  * Lpl_db is path loss (dB) as given by propagation model
        
        % Compute receiver gain, including system losses
        rxAoas = gpuArray([info_tx.AngleOfArrival]);
        rxAz = rxAoas(1,:);
        rxEl = rxAoas(2,:);
        Grx_db = gain(rxs, fqs(txInd), rxAz, rxEl) - [rxs.SystemLoss]';
        % Compute signal strength in dBm (Friis equation)
        ss(txInd,:) = (Ptx_dbs(txInd) + Gtx_db + Grx_db - Lpl_db)';
        % Sum power of all propagation paths. A sum of powers is used based
        % on the assumption that phase shifts of the different paths should
        % be treated as random on a uniform distribution. Reference:
        % Theodore Rappaport, Wireless Communications: Principles and
        % Practice, 2nd Ed, Prentice Hall, 2002
    end
 else
    try
        parpool(parcluster);
    catch
        if gcp().NumWorkers~=parcluster
        delete(gcp());
        parpool(parcluster);
        end
    end
    parfor txInd = 1:numTx
        tx = txs(txInd);
%         % Compute transmitter constants
%         fq = tx.TransmitterFrequency;
%         Ptx = tx.TransmitterPower;
%         Ptx_db = 10 * log10(Ptx)+30; % Convert W to dBm (db with reference to mW)
%         Ltxsys_db = tx.SystemLoss;
        info_tx = info(txInd,:);

        txAods = gpuArray([info_tx.AngleOfDeparture]);
        txAz = txAods(1,:);
        txEl = txAods(2,:);
        if useFastGain
            Gtx_db = gain(tx, fqs(txInd), txAz, txEl, 'fast') - Ltxsys_dbs(txInd);
        else
            Gtx_db = gain(tx, fqs(txInd), txAz, txEl) - Ltxsys_dbs(txInd);
        end
        Lpl_db = Lpls_db(txInd, :)';
        
        % Compute signal strength in dBm, using link budget form of
        % Friis equation:
        %
        %  Received Power (dB) = Transmitted Power (dB) + Gains (dB) - Losses (dB))
        %
        % Applied to tx/rx, this yields:
        %
        %  Prx_db = Ptx_db + Gtx_db + Grx_db - Lpl_db
        %
        % where:
        %  * Prx_db is received power in dBm at receiver input
        %  * Ptx_db is transmitter output power in dBm
        %  * Gtx_db is transmitter gain in dBi (antenna gain - system loss)
        %  * Grx_db is receiver gain in dBi (antenna gain - system loss)
        %  * Lpl_db is path loss (dB) as given by propagation model
        
        % Compute receiver gain, including system losses
        rxAoas = gpuArray([info_tx.AngleOfArrival]);
        rxAz = rxAoas(1,:);
        rxEl = rxAoas(2,:);
        Grx_db = gain(rxs, fqs(txInd), rxAz, rxEl) - [rxs.SystemLoss]';
        % Compute signal strength in dBm (Friis equation)
        ss(txInd,:) = (Ptx_dbs(txInd) + Gtx_db + Grx_db - Lpl_db)';
        % Sum power of all propagation paths. A sum of powers is used based
        % on the assumption that phase shifts of the different paths should
        % be treated as random on a uniform distribution. Reference:
        % Theodore Rappaport, Wireless Communications: Principles and
        % Practice, 2nd Ed, Prentice Hall, 2002
    end
 end
end
