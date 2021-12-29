function p=jason2p(jsonFile)
  % Extract data from json file
    data = readJson(fullfile(pwd,jsonFile));
    % parameters for siteviewer
    p.terrain = data{4}.terrainName;
    p.dt1File = fullfile(pwd,data{4}.terrainFile);
    p.osmFile = fullfile(pwd,data{4}.buildingFile);
    p.cellNames =string(data{2}.eci(1)');
    p.cellLats = data{2}.lat(1)';
    p.cellLons = data{2}.lon(1)';
    p.cellAngles = data{2}.bore(1)' + data{2}.azimuth_original(1)';
    p.bore=data{2}.bore(1)';
    p.cellDowntilt = data{2}.tilt(1)' + data{2}.tilt_original(1)';
    p.tilt=data{2}.tilt(1)';
    p.cellPowers = data{2}.cell_power(1)';
    p.cellAntHeights = data{2}.height(1)';
    p.patterns= data{2}.cov_scene_original(1)';
    p.tx_rows= data{2}.txrxmode(:,1)'; p.tx_rows=p.tx_rows(1);
    p.tx_cols= data{2}.txrxmode(:,2)'; p.tx_cols=p.tx_cols(1);
    for i=1:length(data{3})
        p.ueLons(i)=(data{3}(i,1));
        p.ueLats(i)=(data{3}(i,2));
        p.ueHeight(i)=(data{3}(i,3));
        p.ueRSRP(i)=(data{3}(i,4));
    end
    p.channelModel = "longley-rice";
    p.outputPath = './simulation_results/';
    [p.cellAntenna,p.cellFrequencies] = huaweiBeams(p.patterns,p.tx_rows,p.tx_cols);
    
    % isGPU=true use GPU,false use CPU 
    p.isGPU=false;

    % number of workers
    p.parcluster= 1;

    % write file every 10 records
    p.n=10;
    
    % current count
    p.cn=1;
end