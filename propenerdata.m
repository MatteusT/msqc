%% Load data
clear classes;
reset(RandStream.getDefaultStream,sum(100*clock))

%root = 'c:\matdl\ethylener';
dataroot = 'c:\matdl\data\propener';
if (~exist(dataroot,'dir'))
   mkdir(dataroot);
   copyfile('templates/propener.tpl',[dataroot,'/propener.tpl']);
   copyfile('templates/proplener-gen.tpl',[dataroot,'/propener-gen.tpl']);
   copyfile('ethane4mp2/env2.mat',[dataroot,'/env2.mat']);
end

load([dataroot,'/env2.mat']);
nenv = 0;

% structure will hold the characteristics of each of the parameters
randPars = {};
% first one is C-C bond
t1.type = 'CC bond';
t1.low = 1.54 - 0.15;
t1.high = 1.54 + 0.15;
randPars{end+1} = t1;
        
% second one is C=C bond
t1.type = 'CC bond';
t1.low = 1.36 - 0.15;
t1.high = 1.36 + 0.15;
randPars{end+1} = t1;

% next 5 are c-H bonds
t1.type = 'CH bond';
t1.low = 1.1 - 0.15;
t1.high = 1.1 + 0.15;
for i1 = 1:5
   randPars{end+1} = t1;
end

% next is C-C-C bond angles
t1.type = 'CCC angle';
t1.low = 120 - 6;
t1.high = 120 + 6;
randPars{end+1} = t1;

% next 3 are C-C-H bond angles
t1.type = 'CCH angle';
t1.low = 109 - 6;
t1.high = 109 + 6;
for i1 = 1:3
   randPars{end+1} = t1;
end
% next is H-C-C bond angles
t1.type = 'HCC angle';
t1.low = 120 - 6;
t1.high = 120 + 6;
for i1 = 1:3
   randPars{end+1} = t1;
end

% next parameter is constrained dihedral
t1.type = 'constrained dihedral1';
t1.low = 60-7;
t1.high = 60+7;
randPars{end+1} = t1;
t1.type = 'constrained dihedral2';
t1.low = 180-7;
t1.high = 180+7;
randPars{end+1} = t1;
t1.type = 'constrained dihedral3';
t1.low = -60-7;
t1.high = -60+7;
randPars{end+1} = t1;
t1.type = 'constrained dihedral4';
t1.low = -120-7;
t1.high = -120;
randPars{end+1} = t1;
t1.type = 'constrained dihedral5';
t1.low = 0-7;
t1.high = 0+7;
randPars{end+1} = t1;
t1.type = 'constrained dihedral6';
t1.low = 180-7;
t1.high = 180+7;
randPars{end+1} = t1;

pars = cell(0,0);
maxpars = 100;
HLbasis = {'6-31G'};% '6-31G*' '6-31G**'};
HL = cell(0,0);
LL = cell(0,0);
loadResults = 1;
% Find all pars for which a calculation exists
if (loadResults)
   lfiles = dir([dataroot,'/*_cfg.mat']);
   parsIn = {};
   for i = 1:length(lfiles)
      % disp(lfiles(i).name);
      load([dataroot,'/',lfiles(i).name]);
      % disp([Cfile.template,' ',Cfile.basisSet]);
      if (strcmpi(Cfile.basisSet,HLbasis{1}))
         parsIn{end+1} = Cfile.par;
      end
   end
   maxpars = length(parsIn)-1; % contrl-C'd job, so last one not done
end
maxpars = 30;
%%
for ipar = 1:maxpars
   if (loadResults)
      par = parsIn{ipar};
   else
      par = [];
      for i1 = 1:length(randPars)
         par = [par rr1(randPars{i1}.low,randPars{i1}.high)];
      end
      pars{ipar} = par;
   end
   disp([num2str(ipar),' par = ',num2str(par)]);
   
   config = Fragment.defaultConfig();
   config.method = 'HF';
   config.par = par;
   
   % HL
   for ihl = 1:size(HLbasis,2)
      config.template = 'propener';
      config.basisSet = HLbasis{ihl};
      disp(['ipar ',num2str(ipar),' loading HL ',num2str(ihl)]);
      frag1 = Fragment(dataroot, config);
      for ienv = 1:nenv
         display(['HL env ',num2str(ienv)]);
         frag1.addEnv(env{ienv});
      end
      HL{ipar,ihl} = frag1;
   end
   % LL 1
   config.basisSet = 'STO-3G';
   frag2 = Fragment(dataroot, config);
   disp(['ipar ',num2str(ipar),' loading LL 1']);
   for ienv = 1:nenv
      display(['LL env ',num2str(ienv)]);
      frag2.addEnv(env{ienv});
   end
   LL{ipar,1} = frag2;
   
   % LL 2
   config.template = 'propener-gen';
   config.basisSet = 'GEN';
   config.par = [par 0.9 0.9 0.9 0.9 0.9];
   frag3 = Fragment(dataroot, config);
   disp(['ipar ',num2str(ipar),' loading LL 2']);
   for ienv = 1:nenv
      display(['LL env ',num2str(ienv)]);
      frag3.addEnv(env{ienv});
   end
   LL{ipar,2} = frag3;
   % LL 3
   %config.template = 'ethane1r-gen';
   %config.basisSet = 'GEN';
   config.par = [par 1.05 1.05 1.05 1.05 1.05];
   disp(['ipar ',num2str(ipar),' loading LL 3']);
   frag4 = Fragment(dataroot, config);
   for ienv = 1:nenv
      display(['LL env ',num2str(ienv)]);
      frag4.addEnv(env{ienv});
   end
   LL{ipar,3} = frag4;
end

% since even loading all the files will take time, we'll save everything
save([dataroot,'/propenerGeomDat.mat'],'LL','HL');




