classdef MSet < handle
   properties
      models   % cell array of current models
      envs    % cell array of the envs to include for each model
      pnum    % number used to specify plot, or printEdetails
      HLfrag  % cell array of high level frags corresponding to model
   end
   methods (Static)
   end
   methods
      function obj = MSet
         obj.models  = cell(0,0);
         obj.envs   = cell(0,0);
         obj.HLfrag = cell(0,0);
         obj.pnum = [];
      end
      function addData(obj,fileName,modelsIn,envs,ihl,pnum)
         load(fileName,'LL','HL');
         for i = modelsIn
            obj.models{end+1} = Model3(LL{i,1},LL{i,1},LL{i,1});
            obj.HLfrag{end+1} = HL{i,ihl};
            if (iscell(envs))
               obj.envs{1,end+1} = envs(i);
            else
               obj.envs{1,end+1} = envs;
            end
            obj.pnum(end+1,1) = pnum;
         end
      end
      function res = atomTypes(obj)
         allTypes = [];
         for i=1:length(obj.models)
            allTypes = [allTypes,obj.models{i}.aType];
         end
         res = unique(allTypes);
      end
   end
end
