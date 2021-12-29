function  [cellAntenna,fq] = huaweiBeams(patterns,tx_rows,tx_cols)
cellAntenna = {};
fq = zeros(1,length(patterns));
for i=1:length(patterns)
    switch patterns(i)
        case 0
            fq(i) = 2.565e9;
            azimuth3dB = 105;
            elevation3dB = 6;
            amplifierGain = 25;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 1
            fq(i) = 2.565e9;
            azimuth3dB = 110;
            elevation3dB = 6;
            amplifierGain = 25;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 2
            fq(i) = 2.565e9;
            azimuth3dB = 90;
            elevation3dB = 6;
            amplifierGain = 25;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 3
            fq(i) = 2.565e9;
            azimuth3dB = 65;
            elevation3dB = 6;
            amplifierGain = 25;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 4
            fq(i) = 2.565e9;
            azimuth3dB = 45;
            elevation3dB = 6;
            amplifierGain = 25;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 5
            fq(i) = 2.565e9;
            azimuth3dB = 25;
            elevation3dB = 6;
            amplifierGain = 25;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 6
            fq(i) = 2.565e9;
            azimuth3dB = 110;
            elevation3dB = 12;
            amplifierGain = 21;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 7
            fq(i) = 2.565e9;
            azimuth3dB = 90;
            elevation3dB = 12;
            amplifierGain = 21;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 8
            fq(i) = 2.565e9;
            azimuth3dB = 65;
            elevation3dB = 12;
            amplifierGain = 21;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 9
            fq(i) = 2.565e9;
            azimuth3dB = 45;
            elevation3dB = 12;
            amplifierGain = 25;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 10
            fq(i) = 2.565e9;
            azimuth3dB = 25;
            elevation3dB = 12;
            amplifierGain = 25;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 11
            fq(i) = 2.565e9;
            azimuth3dB = 15;
            elevation3dB = 12;
            amplifierGain = 25;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 12
            fq(i) = 2.565e9;
            azimuth3dB = 110;
            elevation3dB = 25;
            amplifierGain = 20;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 13
            fq(i) = 2.565e9;
            azimuth3dB = 65;
            elevation3dB = 25;
            amplifierGain = 20;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 14
            fq(i) = 2.565e9;
            azimuth3dB = 45;
            elevation3dB = 25;
            amplifierGain = 20;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 15
            fq(i) = 2.565e9;
            azimuth3dB = 25;
            elevation3dB = 25;
            amplifierGain = 25;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        case 16
            fq(i) = 2.565e9;
            azimuth3dB = 15;
            elevation3dB = 25;
            amplifierGain = 25;
            arraySize_Row = tx_rows(i);
            arraySize_column = tx_cols(i);
            sidelobeAttenuation_z = 10;
            sidelobeAttenuation_y = 0;
        otherwise
            error("Please choose Antenna Pattern from DEFAULT,SCENARIO_1 to SCENARIO_16.")
    end
    
    cellAntenna{i} = M2412PhasedArray(fq(i),amplifierGain,0,azimuth3dB,...
        elevation3dB,arraySize_Row,arraySize_column,sidelobeAttenuation_z,...
        sidelobeAttenuation_y);
    %         M2412PhasedArray(fq(i),amplifierGain,0,azimuth3dB,...
    %             elevation3dB,arraySize_Row,arraySize_column,sidelobeAttenuation_z,...
    %             sidelobeAttenuation_y);
end

