%% Load data
clear classes;
reset(RandStream.getDefaultStream,sum(100*clock))

root = 'C:/Users/Matteus/Research/msqc/';
% Generate environments for production runs
if (exist('ethane/env2.mat','file'))
   disp('loading existing environments');
   load('ethane/env2.mat');
else
   mag = 15.0;
   nenv = 100;
   cubSize = [6,6,6];
   cent = [0.77; 0; 0];
   for ienv = 1:nenv
      temp = Environment.newCube(cubSize,mag);
      temp.displace(cent);
      env{ienv} = temp;
   end
   save('ethane/env2.mat','env');
end
nenv = 25;

r1 = 1.54 - 0.15;
r2 = 1.54 + 0.15;
r3 = 1.12 - 0.15;
r4 = 1.12 + 0.15;
t1 = 110.0 + 9.0;
t2 = 110.0 - 9.0;
p1 = 120.0 - 9.0;
p2 = 120.0 + 9.0;
p3 = 60 - 9.0;
p4 = 60 + 9.0;

pars = cell(0,0);
maxpars = 1000;
HLbasis = {'6-31G' '6-31G*'};% '6-31G**'};
HL = cell(0,0);
LL = cell(0,0);
%%
if (exist('ethane/ethanerDat.mat','file'))
   disp('loading existing data');
   load('ethane/ethanerDat.mat');
else
   for ipar = 1:maxpars
      %pars{1} = [1.12 1.12 1.12 1.12 109.47 109.47 109.47 120.0 -120.0];
      par = [rr1(r1,r2) rr1(r3,r4) rr1(r3,r4) rr1(r3,r4) rr1(r3,r4) rr1(r3,r4) rr1(r3,r4) ...
         rr1(t1,t2) rr1(t1,t2) rr1(t1,t2) rr1(t1,t2) rr1(t1,t2) rr1(t1,t2)...
         rr1(p1,p2) -rr1(p1,p2) rr1(p3,p4) rr1(p1,p2) -rr1(p1,p2)];
      pars{ipar} = par;
      disp([num2str(ipar),' par = ',num2str(par)]);
      
      config = Fragment.defaultConfig();
      config.method = 'MP2';
      config.par = par;
      
%       % HL
      for ihl = 1:size(HLbasis,2)
         config.template = 'ethane';
         config.basisSet = HLbasis{ihl};
         disp(['ipar ',num2str(ipar),' loading HL ',num2str(ihl)]);
         frag1 = Fragment([root,'ethane'], config);
         for ienv = 1:nenv
            display(['HL env ',num2str(ienv)]);
            frag1.addEnv(env{ienv});
         end
         HL{ipar,ihl} = frag1;
      end
      % LL 1
      config.basisSet = 'STO-3G';
      frag2 = Fragment([root,'ethane'], config);
      disp(['ipar ',num2str(ipar),' loading LL 1']);
      for ienv = 1:nenv
         display(['LL env ',num2str(ienv)]);
         frag2.addEnv(env{ienv});
      end
      LL{ipar,1} = frag2;
      
      % LL 2
      config.template = 'ethane-gen';
      config.basisSet = 'GEN';
      config.par = [par 0.9 0.9 0.9 0.9 0.9];
      frag3 = Fragment([root,'ethane'], config);
      disp(['ipar ',num2str(ipar),' loading LL 2']);
      for ienv = 1:nenv
         display(['LL env ',num2str(ienv)]);
         frag3.addEnv(env{ienv});
      end
      LL{ipar,2} = frag3;
      % LL 3
      config.template = 'ethane-gen';
      config.basisSet = 'GEN';
      config.par = [par 1.05 1.05 1.05 1.05 1.05];
      disp(['ipar ',num2str(ipar),' loading LL 3']);
      frag4 = Fragment([root,'ethane'], config);
      for ienv = 1:nenv
         display(['LL env ',num2str(ienv)]);
         frag4.addEnv(env{ienv});
      end
      LL{ipar,3} = frag4;
   end
   
   % since even loading all the files will take time, we'll dave everything
   save('ethane/ethanerDat.mat');
end
