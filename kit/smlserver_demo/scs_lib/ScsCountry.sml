(* $Id$ *)

signature SCS_COUNTRY =
  sig

    val selectCountry : string -> int option -> quot

    val valOfCountry : int option -> string

    val countryName : int -> ScsLang.lang -> string

  end (* of SCS_COUNTRY *)

structure ScsCountry :> SCS_COUNTRY =
  struct

    fun selectCountry fv v_opt =
      let
        val sql = `
	  select country_id, scs_text.getText(
	           country_name_tid, ^(
	           Db.qqq ( ScsLang.toString (ScsLogin.user_lang()) ) ) 
	         ) as name 
	    from scs_country_codes
	   order by name`
	val g_fn = (fn g => (g "name", g "country_id"))
	fun v_default() = SOME ( 
	  Db.oneRow' (fn g => ScsData.gToInt g "country_id") `
	    select country_id
	      from scs_country_codes
	     where abbr_iso2 = 'DK'
	  ` )
          handle _ => (ScsError.log "country1" ; NONE)

      in
        ScsData.mk_selectBoxFromDb sql g_fn fv
	  ( if Option.isSome v_opt then v_opt else (ScsError.log "country2" ; v_default() ) )
      end

    fun countryName country_id lang = Db.oneField `
      select scs_text.getText(cc.country_name_tid,
			      ^(Db.qqq (ScsLang.toString lang)))
        from scs_country_codes cc
       where cc.country_id = '^(Int.toString country_id)'`

    fun valOfCountry NONE = ""
      | valOfCountry (SOME country_id) = countryName country_id (ScsLogin.user_lang())

  end
