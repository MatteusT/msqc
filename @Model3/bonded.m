function [ bonding ] = bonded( objIn,iatom,jatom, maxbond )
% Find atoms that are close enough to be counted as bonded
obj = objIn.frag;
if (nargin < 4)
   z1 = obj.Z(iatom);
   z2 = obj.Z(jatom);
   if ((z1 == 1) && (z2 == 1))
      maxbond = 0.95;
      minbond = 0.2;
   elseif (((z1 == 1) && (z2 == 6)) || ((z1 == 6) && (z2 == 1)))
      maxbond = 1.3;
      minbond = 0.2;
   else % C and C
      maxbond = 1.75;
      minbond = 0.2;
   end
end

% distAtom = zeros(obj.natom,obj.natom);
cart = obj.rcart;
distAtom = norm(cart(:,iatom)-cart(:,jatom));


if distAtom == 0
    bonding = 0;
elseif (distAtom < maxbond && distAtom > minbond)
    bonding = 1;
else
    bonding = 0;
end


end

