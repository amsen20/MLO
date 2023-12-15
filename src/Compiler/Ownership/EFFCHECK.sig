(*$EFFCHECK:*)
(* Check effects to ensure owner variables own their regions. *)
signature EFFCHECK =
  sig
    type cone
    type rse
    type place
    type ('a,'b)trip

    val checkEffects : (string -> unit) -> cone * rse * (place,unit)trip -> unit
  end
