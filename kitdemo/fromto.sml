fun fromto(a, b) = if a>b then []
                   else a :: fromto(a+1, b)
val _ = let val l = #1(fromto(1,10), fromto(100,110)) in 1 end;

