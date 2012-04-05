function fitme = makeFitme(varargin)
% Create a fitme object, using data on H2, CH4 and ethane
% Change default parameters by passing list of key, value pairs, e.g.
%   fitme('datadir','./mydir','plot',0);
% keys and default values are:
%  datadir  "./datasets"     directory with *.mat data files
%  nhl      1                high level theory (1..3)
%  plot     1                fitme will plot results when parameters change
%                            (figure numbers are H2:800 ch4:801 ethane:802
%  envs     0:20             range of environments to include in the fits
%  h2       2:7              range of h2 geometries to include (1..7)
%  ch4      []               range of ch4 geometries to include (1..19)
%  ethane   []               range of ethane geometries to include (1..7)
%  kemods   1                include mixers to modify kinetic energy
%  enmods   1                include mixers to modify elec-nuc interaction
%  deltarho 1                based charge dependence on charges induced
%                            by field

% To test parsing of input, use:
%makeFitme('datadir','./mydata','nhl',2,'plot',0,'envs',1:3,'h2',1:3, ...
%   'ch4',1:4,'ethane',1:2,'kemods',0,'enmods',0,'deltarho',1)

% location of the data sets
dataDir = checkForInput(varargin,'datadir','./datasets');
% The high level theory to fit to (second index on the HL's read from data
% directory
nhl = checkForInput(varargin,'nhl',1);
% plot results as fitting occurs
doPlot = checkForInput(varargin,'plot',1);
% environments to include in the fit
envs = checkForInput(varargin,'envs',0:20); 
geomsH2 = checkForInput(varargin,'h2',2:7); % allowed range is 1:7
geomsCH4 = checkForInput(varargin,'ch4',[]); % allowed range is 1:19
geomsEthane = checkForInput(varargin,'ethane',[]); % allowed range is 1:7
includeKEmods = checkForInput(varargin,'kemods',1);
includeENmods = checkForInput(varargin,'enmods',1);
useDeltaCharges = checkForInput(varargin,'deltarho',1);


% Load data
LL1 = cell(0,0);
HL1 = cell(0,0);
ic = 0;
plotNumber = [];
for i = geomsCH4
   load([dataDir,'/ch4Dat.mat']);
   ic = ic+1;
   plotNumber(1,ic) = 801;
   for j = 1:size(LL,2)
      LL1{ic,j} = LL{i,j};
   end
   HL1{ic,1} = HL{i,nhl};
end
for i = geomsH2
   load([dataDir,'/h2Dat.mat']);
   ic = ic+1;
   plotNumber(1,ic) = 800;
   for j = 1:size(LL,2)
      LL1{ic,j} = LL{i,j};
   end
   HL1{ic,1} = HL{i,nhl};
end
for i = geomsEthane
   load([dataDir,'/ethaneDat.mat']);
   ic = ic+1;
   plotNumber(1,ic) = 802;
   for j = 1:size(LL,2)
      LL1{ic,j} = LL{i,j};
   end
   HL1{ic,1} = HL{i,nhl};
end
params = 1:ic;
LL = LL1;
HL = HL1;

% build models
%disp('building models');
m = cell(1,size(params,2));
for ipar = params
   m{ipar} = Model3(LL{ipar,1},LL{ipar,2},LL{ipar,3});
end
if (includeKEmods)
   mixKEdiagH = Mixer([0 0],2,'KEdiagH');
   mixKEdiagC = Mixer([0 0],2,'KEdiagC');
   mixKEdiagCp = Mixer([0 0],2,'KEdiagCp');
   mixKEbondHH = Mixer(0,1,'KEbondHH');
   mixKEbondCH  = Mixer(0,1,'KEbondCH');
   mixKEbondCHp  = Mixer(0,1,'KEbondCHp');
   mixKEbondCC  = Mixer(0,1,'KEbondCC');
   for ipar = params
      m{ipar}.addKEmodDiag(1,1,mixKEdiagH);
      m{ipar}.addKEmodDiag(6,1,mixKEdiagC);
      m{ipar}.addKEmodDiag(6,2,mixKEdiagCp);
      m{ipar}.addKEmodBonded(1,1,1,1,mixKEbondHH);
      m{ipar}.addKEmodBonded(1,6,1,1,mixKEbondCH);
      m{ipar}.addKEmodBonded(1,6,1,2,mixKEbondCHp);
      m{ipar}.addKEmodBonded(6,6,[1 2],[1 2],mixKEbondCC);
   end
end
if (includeENmods)
   mixENdiagH = Mixer([0 0],2,'ENdiagH');
   mixENdiagC = Mixer([0 0],2,'ENdiagC');
   mixENdiagCp = Mixer([0 0],2,'ENdiagCp');
   mixENbondHH = Mixer(0,1,'ENbondHH');
   mixENbondCH  = Mixer(0,1,'ENbondCH');
   mixENbondCHp  = Mixer(0,1,'ENbondCHp');
   mixENbondCC  = Mixer(0,1,'ENbondCC');
   for ipar = params
      m{ipar}.addENmodDiag(1,1,mixENdiagH);
      m{ipar}.addENmodDiag(6,1,mixENdiagC);
      m{ipar}.addENmodDiag(6,2,mixENdiagCp);
      m{ipar}.addENmodBonded(1,1,1,1,mixENbondHH);
      m{ipar}.addENmodBonded(1,6,1,1,mixENbondCH);
      m{ipar}.addENmodBonded(1,6,1,2,mixENbondCHp);
      m{ipar}.addENmodBonded(6,6,[1 2],[1 2],mixENbondCC);
   end
end
if (useDeltaCharges)
   for ipar = params
      for ienv = 1:m{ipar}.nenv
         m{ipar}.charges(:,ienv+1) = m{ipar}.charges(:,ienv+1) - m{ipar}.charges(:,1);
      end
      m{ipar}.charges(:,1) = m{ipar}.charges(:,1) - m{ipar}.charges(:,1);
   end
end

fitme = Fitme;
for ipar = params
   fitme.addFrag(m{ipar},HL{ipar,1},plotNumber(ipar));
end
fitme.includeKE = includeKEmods;
fitme.includeEN = includeENmods * ones(1,6);
fitme.setEnvs(envs);

end

function res = checkForInput(varargin,inputName,default)
idx = find(cellfun(@(x)isequal(lower(x),inputName), varargin));
if (~isempty(idx))
   res = varargin{idx+1};
else
   res = default;
end
end

