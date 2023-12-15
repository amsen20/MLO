fun endo_append ([], xs') = 
    let
      (* ensures that the return value is not in the same region as both arguments *)
      oval xs = xs'
    in
      xs
    end
  | endo_append (x::xs', ys') = 
    let
      (* ensures that the return value is not in the same region as both arguments *)
      oval xs = xs'
      oval ys = ys'
    in
      (* ERROR: because has a put effect on ys's region *)
      x::endo_append(xs, ys)
    end

local
  val x = [1, 2, 3]
  val y = [2, 3, length(x)]
  val z = endo_append(x, y)
  val repre = foldl (fn (item, cur) => cur ^ " " ^ Int.toString(item)) "" z
in
  val _ = print repre
end
