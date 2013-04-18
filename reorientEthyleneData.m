%% Load data
clear classes;
reset(RandStream.getDefaultStream,sum(100*clock))

%root = 'c:\dave\apoly\msqc\dataz';
%dataroot = 'c:/dave/apoly/msqc/dataz/ch4r';
root = 'C:\Users\mtanha\MSQC\msqc\datasets';
filename = 'EthyleneReorientDat';
dataroot = [root,'\',filename];


tplName = {'ethyleneOrient1' 'ethyleneOrient2'};
if (~exist(dataroot,'dir'))
    mkdir(dataroot,'s');
    copyfile('templates/ethyleneOrient1.tpl',[dataroot,'/ethyleneOrient1.tpl']);
    copyfile('templates/ethyleneOrient2.tpl',[dataroot,'/ethyleneOrient2.tpl']);
end

HLbasis = {'6-31G'};% '6-31G*' '6-31G**'};
HL = cell(0,0);
LL = cell(0,0);
% Load data into a *.mat file


%%

config = Fragment.defaultConfig();
config.method = 'HF';

% HL
for itemp = 1:length(tplName)

config.template = tplName{itemp};
config.basisSet = HLbasis{1};
frag1 = Fragment(dataroot, config);
HL{itemp,1} = frag1;

% LL 1
config.basisSet = 'STO-3G';
config.template = tplName{itemp};
frag2 = Fragment(dataroot, config);
LL{itemp,1} = frag2;
LL{itemp,2} = frag2;
LL{itemp,3} = frag2;

end


% since even loading all the files will take time, we'll dave everything
save([dataroot,'\',filename,'.mat'],'LL','HL');



