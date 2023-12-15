
(* Random -- Moscow ML library 1995-04-23 *)

structure Random =
  struct

    (* Generating random numbers.  Paulson, page 96 *)

    fun getrealtime() : {sec : int, usec : int} =
      prim("sml_getrealtime", ())

    type generator = {seedref : real ref}

    val a = 16807.0
    val m = 2147483647.0
    fun nextrand seed = let val t = a*seed
			in t - m * real(floor(t/m))
			end

    fun newgenseed seed = {seedref = ref (nextrand seed)}

    fun newgen () =
      let val {sec, usec} = getrealtime ()
      in newgenseed (real sec + real usec)
      end

(*
    fun newgen () =
      let (*val {sec, usec} = Time.now ()*)
	val now = Time.now ()
      in (*newgenseed (real sec + real usec) *)
(*	newgenseed (real(Time.toMicroseconds now)) *)  (* raises Overflow; ME 1998-10-20*)
	newgenseed (Time.toReal now)
      end
*)
    fun random {seedref as ref seed} = (seedref := nextrand seed; seed / m)

    fun randomlist (n, {seedref as ref seed0}) =
      let fun h 0 seed res = (seedref := seed; res)
	    | h i seed res = h (i-1) (nextrand seed) (seed / m :: res)
      in h n seed0 []
      end

    exception Random_range

    fun range (min, max) =
      if min >= max then raise Random_range
      else fn {seedref as ref seed} =>
	   (seedref := nextrand seed; min + (floor(real(max-min) * seed / m)))

    fun rangelist (min, max) =
      if min >= max then raise Random_range
      else fn (n, {seedref as ref seed0}) =>
	   let fun h 0 seed res = (seedref := seed; res)
		 | h i seed res = h (i-1) (nextrand seed)
	                    (min + floor(real(max-min) * seed / m) :: res)
	   in h n seed0 []
	   end
  end

open Random

type binTerm = int * int * int
type uniTerm = int * int
datatype mathPoly = END 
                  | BISUM of binTerm * mathPoly
                  | UNISUM of uniTerm * mathPoly

fun eval(END, _) = 0
  | eval(BISUM((coeff, i1, i2), rem_poly), values) = coeff * (
      (List.nth (values, i1)) +
        (List.nth (values, i2)) +
          eval(rem_poly, values)
    )
  | eval(UNISUM((coeff, i), rem_poly), values) = coeff * (
      (List.nth (values, i)) +
        eval(rem_poly, values)
    )

val rndState = Random.newgenseed 3.14
val SAMPLES = 10000
val GENERATIONS = 200

fun noise x = let
  val new_x = Random.range(0 - 10, 10) rndState + x
  val new_x =  Int.min(new_x, 100)
  val new_x = Int.max(new_x, 0-100)
in
  new_x
end

fun change [] = []
  | change (x::xs) = (noise x)::change xs

fun generate_samples(values, 0) = [change(values)]
  | generate_samples(values, num) = (change values)::generate_samples(values, num-1)

fun zeros 0 = []
  | zeros num = 0::zeros(num-1)

fun findMax'(_, cur, 0) = cur
  | findMax'(poly, cur, iterations) = let
    val samples = generate_samples(cur, SAMPLES)
    val maximum_values = foldl (
        fn (a, b) => if eval(poly, a) > eval(poly, b) then a else b
      ) cur samples
    val final_values = maximum_values
    val _ = resetRegions maximum_values
  in
    findMax'(poly, final_values, iterations-1)
  end

fun findMax(poly, len) = let
  val values = findMax'(poly, zeros len, GENERATIONS)
  val values_str = foldl (fn (item, cur) => (Int.toString item) ^ ", " ^ cur) "" values
  val result = eval (poly, values)
in
  print ("found:\n" ^ values_str ^ "\nwhich result in: " ^ (Int.toString result) ^ "\n")
end

local
    val poly = BISUM((0 - 1, 0, 1), 
               BISUM((0 - 1, 2, 3),
               BISUM((2, 0, 3), 
               BISUM((0 - 2, 4, 4),
               UNISUM((0 - 1000, 1),
               UNISUM((1, 1),
               END))))))
in
    val _ = findMax(poly, 5)
end
