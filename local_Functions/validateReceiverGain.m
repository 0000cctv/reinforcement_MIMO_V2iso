function rxGain = validateReceiverGain(p, numTx)

try
    rxGain = p.Results.ReceiverGain;
    if ~isempty(rxGain)
        validateattributes(rxGain,{'numeric'}, ...
            {'real','finite','nonnan','nonsparse','nonempty'}, 'sigstrength', 'ReceiverGain');
        
        % Expand scalar gain to match length of tx
        if isscalar(rxGain)
            rxGain = repmat(rxGain,1,numTx);
        end
    end
catch e
    throwAsCaller(e);
end
end
