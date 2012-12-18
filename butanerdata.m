%% Load data
clear classes;
reset(RandStream.getDefaultStream,sum(100*clock))

%root = 'c:\dave\apoly\msqc\dataz';
%dataroot = 'c:/dave/apoly/msqc/dataz/ch4r';
root = 'C:\Users\Matteus\Research\msqc\datasets';
filename = 'butaner-orig';
dataroot = [root,'\',filename];

loadResults = 1;
tplName = 'Butane';
if (~exist(dataroot,'dir'))
    mkdir(dataroot,'s');
    copyfile('templates/propane.tpl',[dataroot,'/propane.tpl']);
    copyfile('templates/propane-gen.tpl',[dataroot,'/propane-gen.tpl']);
    copyfile('datasets/envprop.mat',[dataroot,'/envprop.mat']);
end

% Copying the
load(['datasets/envprop.mat']);
envOrig = env;
envs1 = 1:10; %[6     7     8    13    16    24];
envs2 = 11:20;%[5    10    14    17    20    25];
envsJ = [envs1,envs2];
env={envOrig{envsJ} };
nenv = length(env);


r1 = 1.54 - 0.15;
r2 = 1.54 + 0.15;
r3  = 1.10 - 0.10;
r4 = 1.10 + 0.10;
t1 = 109.5 + 9.0;
t2 = 109.5 - 9.0;
p1 = 180.0 - 9.0;
p2 = 180.0 + 9.0;
p3 = 60 - 9.0;
p4 = 60 + 9.0;

pars = cell(0,0);
maxpars =20;
HLbasis = {'6-31G'};% '6-31G*' '6-31G**'};
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
if (exist('ethane/propaner-orig.mat','file'))
    disp('loading existing data');
    load('ethane/propaner-orig.mat');
else
    for ipar = 1:maxpars
        if (loadResults)
            par = parsIn{ipar};
        else
            bonds = [rr1(r1,r2) rr1(r1,r2) rr1(r3,r4)...
                rr1(r3,r4) rr1(r3,r4) rr1(r3,r4) rr1(r3,r4) rr1(r3,r4)];
            
            angles = [rr1(t1,t2) rr1(t1,t2) rr1(t1,t2)...
                rr1(t1,t2) rr1(t1,t2) rr1(t1,t2)];
            
            dihedrals = [ -rr1(p3,p4) rr1(p1,p2) rr1(p3,p4) rr1(p1,p2)...
                rr1(p3,p4) -rr1(p3,p4) rr1(p1,p2) rr1(p3,p4)];
            
            par = [bonds,angles,dihedrals];
            
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
        config.template = ([tplName,'-gen']);
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
        config.template = ([tplName,'-gen']);
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
end
% since even loading all the files will take time, we'll dave everything
save([dataroot,'\',filename,'.mat'],'LL','HL');



