function sinr=Sinr(sigstrength)
power = 10.^(sigstrength./10-3);
noise = 1.9953e-14;
sinr = 10*log10(max(power,[],1)./(sum(power,1)-max(power,[],1)+noise));
end