function RSRPandSINR = RSRPandSINR(p,pm,VIEWER,sigstrength_history)

% %initial sigstrength history table
if isempty(sigstrength_history)
    sigstrength_result = Sigstrength_detail(p,pm,VIEWER);
    sigstrength_history=[sigstrength_result,p.cellLats',p.cellLons',p.cellAngles',p.cellDowntilt',p.cellPowers',p.cellAntHeights',p.patterns',p.tx_rows',p.tx_cols'];
end

%find tx never calculated, strength_result is the sigstrength for the given
%txs, rxs
p_temp=[];
strength_result = zeros(length(p.cellLats),length(p.ueHeight)+9);
count_j=1;
for j=1:numel(p.cellLats)
[testcondition,location] = ismember([p.cellLats(j),p.cellLons(j),p.cellAngles(j),p.cellDowntilt(j),p.cellPowers(j),p.cellAntHeights(j),p.patterns(j),p.tx_rows(j),p.tx_cols(j)],sigstrength_history(:,end-8:end),'rows');
    if testcondition %condition=1 if calculated historically
    strength_result(count_j,:) = sigstrength_history(location,:);
    count_j=count_j+1;
    else
        if isempty(p_temp)
            p_temp.cellNames = p.cellNames(j);
            p_temp.cellLats = p.cellLats(j);
            p_temp.cellLons = p.cellLons(j);
            p_temp.cellAngles = p.cellAngles(j);
            p_temp.cellDowntilt = p.cellDowntilt(j);
            p_temp.cellPowers = p.cellPowers(j);
            p_temp.cellAntHeights = p.cellAntHeights(j);
            p_temp.patterns = p.patterns(j);
            p_temp.tx_rows= p.tx_rows(j);
            p_temp.tx_cols= p.tx_cols(j);
            p_temp.cellAntenna= p.cellAntenna(j);
            p_temp.cellFrequencies= p.cellFrequencies(j);
        else
            p_temp.cellNames = [p_temp.cellNames,p.cellNames(j)];
            p_temp.cellLats = [p_temp.cellLats,p.cellLats(j)];
            p_temp.cellLons = [p_temp.cellLons,p.cellLons(j)];
            p_temp.cellAngles = [p_temp.cellAngles,p.cellAngles(j)];
            p_temp.cellDowntilt = [p_temp.cellDowntilt,p.cellDowntilt(j)];
            p_temp.cellPowers = [p_temp.cellPowers,p.cellPowers(j)];
            p_temp.cellAntHeights = [p_temp.cellAntHeights,p.cellAntHeights(j)];
            p_temp.patterns = [p_temp.patterns,p.patterns(j)];
            p_temp.tx_rows= [p_temp.tx_rows,p.tx_rows(j)];
            p_temp.tx_cols= [p_temp.tx_cols,p.tx_cols(j)];
            p_temp.cellAntenna= [p_temp.cellAntenna,p.cellAntenna(j)];
            p_temp.cellFrequencies= [p_temp.cellFrequencies,p.cellFrequencies(j)];
        end
    end
end
if ~isempty(p_temp)
    p_temp.ueLats = p.ueLats;
    p_temp.ueLons = p.ueLons;
    p_temp.ueHeight = p.ueHeight;
    p_temp.isGPU=p.isGPU;
    p_temp.parcluster=p.parcluster;
    sigstrength_result = Sigstrength_detail(p_temp,pm,VIEWER);
    sigstrength_history=[sigstrength_history;[sigstrength_result,p_temp.cellLats',p_temp.cellLons',p_temp.cellAngles',p_temp.cellDowntilt',p_temp.cellPowers',p_temp.cellAntHeights',p_temp.patterns',p_temp.tx_rows',p_temp.tx_cols']];
    strength_result(nnz(any(strength_result,2))+1:end,:) = [sigstrength_result,p_temp.cellLats',p_temp.cellLons',p_temp.cellAngles',p_temp.cellDowntilt',p_temp.cellPowers',p_temp.cellAntHeights',p_temp.patterns',p_temp.tx_rows',p_temp.tx_cols'];
end
%%output
RSRPandSINR.RSRP = max(strength_result(:,1:end-9),[],1);
RSRPandSINR.SINR = Sinr(strength_result(:,1:end-9));
RSRPandSINR.sigstrength_history = sigstrength_history;
end
