function res = sym_hash(a,b)
if a>b 
    res = ((a*(a+1))/2)+ b-1;
else
    res = ((b*(b+1))/2)+ a-1;
end
end                 