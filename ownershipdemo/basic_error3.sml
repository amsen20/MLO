val f = fn a => fn b => (* the condition forces the arguments to be in the same region  *) if (length a) > (length b) then a else b

local
  oval a = [1, 2, 3]
  (* ERROR: will allocate b in region of a *)
  val b = [2, 3, 4]
  val res = f a b
  val repre = foldl (fn (item, cur) => cur ^ " " ^ Int.toString(item)) "" res
in
  val _ = print repre
end
