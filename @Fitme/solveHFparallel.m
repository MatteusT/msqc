function solveHFparallel(obj)

% Want a parallel version of the following:
%for imod = 1:obj.nmodels
%   obj.models{imod}.solveHF(obj.envs{1,imod});
%end

% Will call external function:
%[P,orb,Eorb,Ehf,failed ] = ...
%   HFsolve(H1, H2, S, Enuc, Nelec, guessDensity, ...
%   eps,maxIter,minIter)

% We will save all of these inputs in arrays. 
ncalcs = 0;
for imod = 1:obj.nmodels
   ncalcs = ncalcs + length(obj.envs{1,imod});
end
H1 = cell(ncalcs,1);
H2 = cell(ncalcs,1);
S  = cell(ncalcs,1);
Enuc = zeros(ncalcs,1);
Nelec = zeros(ncalcs,1);
guessDensity = cell(ncalcs,1);
modNumber = zeros(ncalcs,1);
envNumber = zeros(ncalcs,1);
icalc = 0;
for imod = 1:obj.nmodels
   mod = obj.models{imod};
   for ienv = obj.envs{1,imod}
      icalc = icalc + 1;
      modNumber(icalc) = imod;
      envNumber(icalc) = ienv;
      H1{icalc} = mod.H1(ienv);
      H2{icalc} = mod.H2(ienv);
      S{icalc}  = mod.S; % could be optimized since no ienv dependence
      Enuc(icalc) = mod.Hnuc(ienv);
      Nelec(icalc) = mod.nelec;
      if ((size(mod.densitySave{ienv+1},1) == 0) && ...
            (size(mod.densitySave{1},1) == 0))
        guessDensity{icalc} = mod.frag.density(ienv);
      elseif (size(mod.densitySave{ienv+1},1) == 0)
        guessDensity{icalc} = mod.densitySave{1};
      else
        guessDensity{icalc} = mod.densitySave{ienv+1};
      end
   end
end

% do the calculations and save output in cell arrays
P = cell(ncalcs,1);
orb = cell(ncalcs,1);
Eorb = cell(ncalcs,1);
Ehf = zeros(ncalcs,1);
failed = zeros(ncalcs,1);
tic;
parfor icalc = 1:ncalcs
[P{icalc},orb{icalc},Eorb{icalc},Ehf(icalc),failed(icalc) ] = ...
   HFsolve(H1{icalc}, H2{icalc}, S{icalc}, Enuc(icalc), Nelec(icalc), ...
   guessDensity{icalc});
end
obj.hftime = toc;
% copy results back into the model
for icalc = 1:ncalcs
   mod = obj.models{modNumber(icalc)};
   ienv = envNumber(icalc);
   if (ienv == 0)
      mod.orb  = orb{icalc};
      mod.Eorb = Eorb{icalc};
      mod.Ehf  = Ehf(icalc);
   else
      mod.orbEnv(:,:,ienv) = orb{icalc};
      mod.EorbEnv(:,ienv)  = Eorb{icalc};
      mod.EhfEnv(1,ienv)   = Ehf(icalc);
   end
   mod.densitySave{ienv+1} = P{icalc};
end


end