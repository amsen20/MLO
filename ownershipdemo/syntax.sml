fun println msg = print (msg ^ "\n")

fun out [] = ()
    | out (hd::tl) = (print hd;out tl)

val x = "1";
oval y = x ^ "2";
val _ = println (x ^ y);

let
    val aa = ["1"];
    val bb = ["2"];
    val cc = aa @ bb;
in
    out cc
end;

local
    val a = "h";
    oval b = "i";
    oval c = "!";
in
    val _ = println (a ^ b ^ c)
end;

let
    oval hello_world = "hello_world";
in
    println (hello_world)
end;
