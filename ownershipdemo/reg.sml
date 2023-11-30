fun exo_append ([], []) = []
  | exo_append ([], y::ys) = (y+1)::exo_append([], ys)
  | exo_append(x::xs, ys) = (x+1)::exo_append(xs, ys);

fun endo_append ([], ys) = ys
  | endo_append(x::xs, ys) = x::endo_append(xs, ys);

val _ = let val f = fn n => 
let
  val x = [1, 2, 3, n]
  val y = [10] @ x
in
  print (foldl (fn (cur, b) => cur^b) "" (map (Int.toString) x) ^ "\n");
  exo_append (y, y)
  (* endo_append (x, x) *)
end
in
  foldl (fn (cur, b) => cur^b) "" (map (Int.toString) ((f 10)))
end
