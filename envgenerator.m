% creating enviorments
   mag = 15.0;
   nenv = 20;
   cubSize = [7,7,7];
   cent = [0.77; 0; 0];
   for ienv = 1:nenv
      temp = Environment.newCube(cubSize,mag);
      temp.displace(cent);
      env{ienv} = temp;
   end
   save('datasets/envprop.mat','env');