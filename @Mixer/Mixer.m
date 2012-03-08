classdef Mixer < handle
   
   properties
      mixType % 0 for sigmoidal, 1 for linear, 2 for charge dependent
      par     % (1,npar) current parameters
      desc    % string description
      fixed   % (1,npar) 0 if parameter should be fit, 1 if fixed
   end
   
   methods
      function obj = Mixer(parIn,mixType)
          if (nargin < 1)
             parIn = [0];
          end
          if (nargin < 2)
             mixType = 0;
          end
          obj.par = parIn;
          obj.mixType = mixType;
          obj.fixed = zeros(size(parIn));
      end
      function res = npar(obj)
         res = sum(obj.fixed == 0);
      end
      function res = setPars(obj, pars)
         ic = find(obj.fixed == 0);
         if (size(ic,2) > 0)
            obj.par(ic) = pars;
         end
      end
      function res = mix(obj, v1, v2, model, ii, jj, ienv)
         if (obj.mixType == 0)
               x = obj.par(1);
            % mix objects v1 and v2, using parameter x.
            %   for x << 0, we get v1, and x>>0 we get v2, with the
            %   switch from v1 to v2 occuring mostly as x=-1..1
            c1 = (tanh(x)+1)/2.0;
            c2 = 1-c1;
            res = c2 * v1 + c1 * v2;
         elseif (obj.mixType == 1)
            x = obj.par(1);
            % want linear mix, with (v1+v2)/2 when x=0
            % res = (v1+v2)/2 + x (v2-v1)/2
            % The bounds are: res = v1 at x = -1;
            %                 res = v2 at x = 1;
            % potentially faster (since v's are matrices while x is scalar)
            res = ((1.0-x)/2.0) * v1 + ((1.0+x)/2.0) * v2;
         elseif (obj.mixType == 2)
            iatom = model.basisAtom(ii(1));
            ch = model.charges(iatom,ienv+1);
            x0 = obj.par(1);
            xslope = obj.par(2);
            x = x0 + xslope*ch;
            res = ((1.0-x)/2.0) * v1 + ((1.0+x)/2.0) * v2;
         elseif (obj.mixType == 3)
             x = obj.par(1);
             y = obj.par(2);
             %input of a constant y
            c1 = (tanh(x)+1)/2.0;
            c2 = 1-c1;
            res = c2 * v1 + c1 * v2 + y*diag(ones(size(v1,1),1)); % try it :)
         elseif (obj.mixType == 4)
            error('still working on mixType 4');
            x0 = obj.par(1);
            xslope = obj.par(2);
            density = model.density(ienv);
            % get matrix with only diagonal elements
            occupancy = trace(density(ii,jj));
            v1d = diag(diag(v1d));
            v2d = diag(diag(v2d));
            v1o = v1-v1d;
            v2o = v2-v2d;
            res = ((1.0-x)/2.0) * v1 + ((1.0+x)/2.0) * v2;
         else
            error(['unknown mix type in Mixer: ',num2str(obj.mixType)]);
         end
      end
   end
   
end

