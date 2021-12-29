%%%calculate sigstrength table for each txs and each rxs
function obj=Sigstrength_detail(p,pm,VIEWER)
txs = txsite("Name",p.cellNames,...
    "Latitude",p.cellLats,...
    "Longitude",p.cellLons,...
    "Antenna",p.cellAntenna,...
    "AntennaAngle",[p.cellAngles; p.cellDowntilt],...
    "SystemLoss",0,...
    "TransmitterFrequency",p.cellFrequencies,...
    "TransmitterPower",p.cellPowers,...
    "AntennaHeight",p.cellAntHeights)';
rxs = rxsite('Latitude', p.ueLats,'Longitude', p.ueLons, 'AntennaHeight', p.ueHeight)';
    if p.isGPU
        obj = gather(sigstrength_GPU(rxs,txs,p.parcluster,pm,'Map',VIEWER));
    else
        obj = sigstrength_CPU(rxs,txs,p.parcluster, pm,'Map',VIEWER);
    end
end