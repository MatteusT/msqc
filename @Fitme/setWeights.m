function res = setWeights(obj,etotWeight,propToSD)
%  has fields KE, EN(1...Zmax), E2 and Etot
if (nargin < 3)
   propToSD = true;
end

if (propToSD)
   %HLKE    % {1,nmodels}(1,nenv) KE energy
   %HLEN    % {1,nmodels}(natom,nenv) electron-nuclear interaction
   %HLE2    % {1,nmodels}(1,nenv) two-elec enerty
   ke = [];
   e2 = [];
   etot = [];
   en = cell(20,1);  
   for imod = 1:obj.nmodels
      ke1 = obj.HLKE{imod}(:);
      ke = [ke ke1(:)'];
      etot1 = ke1(:);
      for iatom = 1:size(obj.HLEN{imod},1)
         ztype = obj.models{imod}.Z(iatom);
         enAtom = obj.HLEN{imod}(iatom,:);
         en{ztype} = [en{ztype} enAtom(:)'];
         etot1 = etot1 + enAtom(:);
      end
      e21  = obj.HLE2{imod}(:);
      e2 = [e2 e21'];
      etot1 = etot1 + e21(:);
      etot = [etot etot1(:)'];
   end
   res.KE = std(ke);
   enweights = zeros(20,1);
   for iz = 1:20
      if (~isempty(en{iz}))
         enweights(iz) = 1.0/std(en{iz});
      end
   end
   res.EN = enweights;
   res.E2 = 1.0/std(e2);
   res.Etot = 1.0/std(etot) * etotWeight;
else
   res.KE = 1.0;
   res.EN = ones(20);
   res.E2 = 1.0;
   res.Etot = etotWeight;
end

obj.operWeights = res;

end

