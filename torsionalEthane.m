% generating Ethane with rotating torsion
%% Load data
clear classes;
reset(RandStream.getDefaultStream,sum(100*clock))

%root = 'c:\dave\apoly\msqc\dataz';
%dataroot = 'c:/dave/apoly/msqc/dataz/ch4r';
root = 'C:\Users\Matteus\Research\msqc\datasets';
filename = 'ethanetor-orig';
dataroot = [root,'\',filename];

loadResults = 0;
      tplName = 'ethane';
if (~exist(dataroot,'dir'))
   mkdir(dataroot,'s');
      tplName = 'ethane';
      copyfile('templates/ethane1.tpl',[dataroot,'/ethane11.tpl']);
      copyfile('templates/ethane1-gen.tpl',[dataroot,'/ethane1-gen.tpl']);
   copyfile('datasets/env2.mat',[dataroot,'/env2.mat']);
end

% Copying the 
load(['datasets/env2.mat']);
envOrig = env;
envs1 = [6     7     8    13    16    24];
envs2 = [5    10    14    17    20    25];
envsJ = [envs1,envs2];
env={envOrig{envsJ} };
nenv = length(env);
maxpars = 18;
step = 20;


pars = cell(0,0);
HLbasis = {'6-31G'}
HL = cell(0,0);
LL = cell(0,0);
% Load data into a *.mat file
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
   maxpars = length(parsIn);
end

%%

  DHangle = 0;

for ipar = 1:maxpars
   if (loadResults)
      par = parsIn{ipar};
   else
      par = [1.54 1.07 DHangle];
      DHangle = DHangle + step;
   end
   pars{ipar} = par;
   disp([num2str(ipar),' par = ',num2str(par)]);
   
   config = Fragment.defaultConfig();
   config.method = 'HF';
   config.par = par;
   
   % HL
   for ihl = 1:size(HLbasis,2)
      config.template = tplName;
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
      config.template = 'ch4-gen';
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
      config.template = 'ch4-gen';
      config.basisSet = 'GEN';
      config.par = [par 1.05 1.05 1.05 1.05 1.05];
      disp(['ipar ',num2str(ipar),' loading LL 3']);
      frag4 = Fragment(dataroot, config);
      for ienv = 1:nenv
         display(['LL env ',num2str(ienv)]);
         frag4.addEnv(env{ienv});
      end
      LL{ipar,3} = frag4;
   end

% since even loading all the files will take time, we'll dave everything
save([dataroot,'\',filename,'.mat'],'LL','HL');

%% evaluate the change in error

bondext = 0.85:0.03:1.42;
for i = 1:length(HL)
diff(i) = HL{i}.Ehf-LL{i,1}.Ehf;
end
figure(111)
plot(bondext,diff,'bx')


%Environments
color = {'rx','bx','kx','bo','gx', }
nevn = Hl{1}.nenv;
for ienv = 1:nenv
    for i = 1:length(HL)
        diff(i) = HL{i}.EhfEnv(ienv)-LL{i,1}.EhfEnv(ienv);
    end

figure(333)
plot(bondext,diff,color{ienv})
hold on 
end

%%
dataf = {'ch4ext-orig','ch4asym-orig'};
dsets = cell(1,1);
fitme = cell(1,2);
for idata = 1:length(dataf);
    dfile = ['datasets/',dataf{idata},'.mat'];
    % test data
    mf = MFactory;
    ms = MSet;
    if idata == 1
        ms.addData(dfile, 1:15, 1:6,1,791);
    elseif idata == 2
        ms.addData(dfile, 6:15, 1:6,1,791);
    end
    dsets{idata} = ms;
end
fct = cell(0,0);
load(['C:\Users\Matteus\Research\msqc\dec12a\hybridslater\ch4rDat\all-3.mat'],'fact');
for i= 1:length(fact.mixer)
    fact.mixer{i}.bonded = 1;
end
fact.mixer{end}.bonded= 0;
fct{1} = fact;
for idata = 1:length(dataf);
    f1{idata} = fct{1}.makeFitme(dsets{idata});
    [err(idata,:) pnum etype(idata,:)] = f1{idata}.err(f1{idata}.getPars);
    
    
    etot(idata,:) = err{idata,:}(etype == 3);
    nmb =[];
    if idata == 1
        range= 1:90;
        ngeom = 15;
    elseif idata == 2
        range= 1:60;
        ngeom = 10;
    end
    step2 = 0;
    estep = 5;
    for in = 1:ngeom
        step1 = step2+1;
        step2 = step1 + estep;
        nmb = [nmb; range(step1:step2)];
    end
ext = 0.85:0.03:1.42;
for i = 1:6
    ic = 0;
    for i2 = 1:ngeom
    ic = ic+1;
    etotEnv(ic) =etot(nmb(i2,i));
    end
    figure(idata*100+i)
    plot(ext(1:15),etotEnv,'r-');
end
end    

