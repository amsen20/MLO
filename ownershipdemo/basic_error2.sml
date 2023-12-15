local
  val x = [1, 2, 3]
  oval y = [2, 3, length(x)]
  
  (* ERROR: allocates something in region of y *)
  val z = x @ y
  
  val repre = foldl (fn (item, cur) => cur ^ " " ^ Int.toString(item)) "" z
in
  val _ = print repre
end
