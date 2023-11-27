fun foldl f b xs = 
  case xs of 
       [] => b
     | x::xs' => foldl f (f x b) xs'

val _ = let val xs = [1, 2, 3] in
  (foldl (fn x => fn b => x+b) 0 xs) + 1
        end;

