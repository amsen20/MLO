fun println msg = print (msg ^ "\n")

val x = "1";
oval y = "2";
val _ = println (x ^ y);

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
