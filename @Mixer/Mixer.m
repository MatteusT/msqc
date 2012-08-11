classdef Mixer < handle
   
   properties
      mixType % 0 for sigmoidal, 1 for linear, 2 for charge dependent
      par     % (1,npar) current parameters
      desc    % string description
      fixed   % (1,npar) 0 if parameter should be fit, 1 if fixed
      hybrid  % 0 = no hybridization, 1 = sigma mods, 2 = pi mods
      funcType % 1 = interp 2 = scale 3 = scale with const 
               % 4 = iterp with const
      index   % field that can be used to store an external unique ID
              % index is not used internally in this class
   end
   
   methods
      function obj = Mixer(parIn,mixType,desc,funcType)
         if (nargin < 1)
            parIn = [0];
         end
         if (nargin < 2)
            mixType = 1;
         end
         if (nargin < 3)
            desc = ' ';
         end
         if (nargin < 4)
            funcType = 1;
         end
         obj.par = parIn;
         obj.mixType = mixType;
         obj.fixed = zeros(size(parIn));
         obj.desc = desc;
         obj.funcType = funcType;
         obj.hybrid = 0;
      end
      function res = deepCopy(obj)
         res = Mixer(obj.par,obj.mixType,obj.desc,obj.funcType);
         res.fixed = obj.fixed;
         res.hybrid = obj.hybrid;
      end
      function res = constructionData(obj)
         % data needed to reconstruct this mixer
         res.mixType = obj.mixType;
         res.par = obj.par;
         res.desc = obj.desc;
         res.fixed = obj.fixed;
         res.hybrid = obj.hybrid;
         res.funcType = obj.funcType;
      end
   end
   methods (Static)
      function res = createFromData(dat)
         res = Mixer(dat.par,dat.mixType,dat.desc,dat.funcType);
         res.hybrid = dat.hybrid;
         res.fixed = dat.fixed;
      end
   end
   methods
      function res = npar(obj)
         res = sum(obj.fixed == 0);
      end
      function res = setPars(obj, pars)
         ic = find(obj.fixed == 0);
         if (size(ic,2) > 0)
            obj.par(ic) = pars;
         end
      end
      function res = getPars(obj)
         ic = find(obj.fixed == 0);
         if (length(ic) > 0)
            res = obj.par(ic);
         else
            res = [];
         end
      end
      function res = mixFunction(obj,x,v0,v1,v2, model, ii, jj)
         if (obj.hybrid)
            % mixFunctionHybrid rotates to hybrid orbitals
            % and then call mixFunctionNormal on these rotated orbitals
            res = obj.mixFunctionHybrid(x,v0,v1,v2, model, ii, jj);
         else
            res = obj.mixFunctionNormal(x,v0,v1,v2);
         end
      end
      function res = mixFunctionNormal(obj,x,v0,v1,v2)
         if (obj.funcType == 1)
            res = ((1.0-x)/2.0) * v1 + ((1.0+x)/2.0) * v2;
         elseif (obj.funcType == 2)
            res = x * v0;
         elseif (obj.funcType == 3)
            res = x * v0 + obj.par(end) * eye(size(v0));
         elseif (obj.funcType == 4)
            res = ((1.0-x)/2.0) * v1 + ((1.0+x)/2.0) * v2 ...
               + obj.par(end) * eye(size(v0));
         end
      end
      function res = mix(obj, v0, v1, v2, model, ii, jj, ienv)
         x = obj.par(1);
         if (obj.mixType == 0)
            % mix objects v1 and v2, using parameter x.
            %   for x << 0, we get v1, and x>>0 we get v2, with the
            %   switch from v1 to v2 occuring mostly as x=-1..1
            c1 = (tanh(x)+1)/2.0;
            c2 = 1-c1;
            res = c2 * v1 + c1 * v2;
         elseif (obj.mixType == 1)
            % want linear mix, with (v1+v2)/2 when x=0
            % res = (v1+v2)/2 + x (v2-v1)/2
            % The bounds are: res = v1 at x = -1;
            %                 res = v2 at x = 1;
            % potentially faster (since v's are matrices while x is scalar)
            %res = ((1.0-x)/2.0) * v1 + ((1.0+x)/2.0) * v2;
            res = obj.mixFunction(x,v0,v1,v2,model, ii, jj);
         elseif (obj.mixType == 2)
            % charge dependent mixing
            iatom = model.basisAtom(ii(1));
            ch = model.charges(iatom,ienv+1);
            x0 = obj.par(1);
            xslope = obj.par(2);
            x = x0 + xslope*ch;
            %res = ((1.0-x)/2.0) * v1 + ((1.0+x)/2.0) * v2;
            res = obj.mixFunction(x,v0,v1,v2,model, ii, jj);
         elseif (obj.mixType == 22)
            % charge dependent mixing quadratic
            iatom = model.basisAtom(ii(1));
            ch = model.charges(iatom,ienv+1);
            x0 = obj.par(1);
            xslope = obj.par(2);
            xquad = obj.par(3);
            x = x0 + xslope*ch + xquad*ch*ch;
            res = obj.mixFunction(x,v0,v1,v2,model, ii, jj);
         elseif (obj.mixType == 3)
            % bond order dependent mixing
            iatom = model.basisAtom(ii(1));
            jatom = model.basisAtom(jj(1));
            bo = model.bondOrders(iatom,jatom,ienv+1);
            x0 = obj.par(1);
            xslope = obj.par(2);
            x = x0 + xslope*(bo-1);
            %res = ((1.0-x)/2.0) * v1 + ((1.0+x)/2.0) * v2;
            res = obj.mixFunction(x,v0,v1,v2,model, ii, jj);
         elseif (obj.mixType == 4)
            % bond length dependent mixing
            iatom = model.basisAtom(ii(1));
            jatom = model.basisAtom(jj(1));
            Zs = zeros(1,2);
            Zs(1) = model.Z(iatom);
            Zs(2) = model.Z(jatom);
            Zs = sort(Zs);
            bl = norm(model.rcart(:,iatom)-model.rcart(:,jatom));
            if (Zs(1) == 1 && Zs(2) == 1)
               bl = bl - 0.74;
            elseif (Zs(1) == 1 && Zs(2) == 6)
               bl = bl - 1.1;
            else
               bl = bl - 1.5;
            end
            x0 = obj.par(1);
            xslope = obj.par(2);
            x = x0 + xslope*bl;
            %res = ((1.0-x)/2.0) * v1 + ((1.0+x)/2.0) * v2;
            res = obj.mixFunction(x,v0,v1,v2,model, ii, jj);
         elseif (obj.mixType == 5)
            % bond order and bond length dependent mixing
            iatom = model.basisAtom(ii(1));
            jatom = model.basisAtom(jj(1));
            bo = model.bondOrders(iatom,jatom,ienv+1);
            Zs = zeros(1,2);
            Zs(1) = model.Z(iatom);
            Zs(2) = model.Z(jatom);
            Zs = sort(Zs);
            bl = norm(model.rcart(:,iatom)-model.rcart(:,jatom));
            if (Zs(1) == 1 && Zs(2) == 1)
               bl = bl - 0.74;
            elseif (Zs(1) == 1 && Zs(2) == 6)
               bl = bl - 1.1;
            else
               bl = bl - 1.5;
            end
            x0 = obj.par(1);
            xslopebo = obj.par(2);
            xslopebl = obj.par(3);
            x = x0 + xslopebo*(bo-1) + xslopebl*bl;
            %res = ((1.0-x)/2.0) * v1 + ((1.0+x)/2.0) * v2;
            res = obj.mixFunction(x,v0,v1,v2,model, ii, jj);
         elseif (obj.mixType == 11)
            % context dependent, diagonal
            iatom = model.basisAtom(ii(1));
            xcontext = model.atomContext(iatom,ienv);
            nx = length(xcontext);
            x = obj.par(1) + sum(obj.par(2:(1+nx)).*xcontext');
            res = obj.mixFunction(x,v0,v1,v2,model, ii, jj);
         elseif (obj.mixType == 12)
            % context dependent, diagonal
            iatom = model.basisAtom(ii(1));
            jatom = model.basisAtom(jj(1));
            xcontext = model.bondContext(iatom,jatom,ienv);
            nx = length(xcontext);
            x = obj.par(1) + sum(obj.par(2:(1+nx)).*xcontext');
            res = obj.mixFunction(x,v0,v1,v2,model, ii, jj);
         else
            error(['unknown mix type in Mixer: ',num2str(obj.mixType)]);
         end
      end
      function res = print(obj)
         types = {'sigmoid','linear','ch-dep','bo-dep','bl-dep','bo-bl-dep'};
         types{23} = 'ch-dep-quad';
         types{11} = 'context-atom';
         types{12} = 'context-bond';
         ftypes = {' ','mult','mult-c','mix-c'};
         res = [obj.desc,' ',types{obj.mixType+1},' ',...
            ftypes{obj.funcType}];
         for i = 1:size(obj.par,2)
            res = [res,' ',num2str(obj.par(i))];
         end
         disp(res);
      end
   end
end

