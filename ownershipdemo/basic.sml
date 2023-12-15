fun cp [] = []
  | cp (x::xs') = let
    (* ensures that the return value is not in the same region as argument *)
    oval xs = xs'
  in
    x::cp(xs)
  end

fun exo_append ([], []) = []
  | exo_append ([], x::xs') = 
    let
      (* ensures that the return value is not in the same region as both arguments *)
      oval xs = xs'
    in
      x::exo_append([], xs)
    end
  | exo_append (x::xs', ys') = 
    let
      (* ensures that the return value is not in the same region as both arguments *)
      oval xs = xs'
      oval ys = ys'
    in
      x::exo_append(xs, ys)
    end

local
  oval x = [1, 2, 3]
  oval y = [2, 3, length(x)]
  val z = exo_append(x, y)
  val repre = foldl (fn (item, cur) => cur ^ " " ^ Int.toString(item)) "" z
in
  val _ = print repre
end
