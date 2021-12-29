%%%read json file
function p = readJson(jsonFile)

fid = fopen(jsonFile, 'r');
str = fread(fid,'*char').';
fclose(fid);
p = jsondecode(str);


end

