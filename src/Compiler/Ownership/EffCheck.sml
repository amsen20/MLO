structure EffCheck : EFFCHECK =
struct
  structure RSE = RegionStatEnv
  structure Exp = RegionExp
  structure Lvar = Lvars
  structure PP = PrettyPrint
  structure G = DiGraph

  open RegInf

  (* basic util functions *)
  fun die msg = Crash.impossible ("EffCheck." ^ msg)
  fun say s = TextIO.output(TextIO.stdOut, s)
  fun flatten lss = foldl (fn (a, b) => a@b) [] lss
  fun flatten_strs strs between = foldl (fn (a, b) => a ^ between ^ b) "" strs

  (* the exception for compile error *)
  exception PUT_TO_FROZED

  fun checkEffects (device: string -> unit) : cone * rse * (place,unit)Exp.trip -> unit = let
    
    (* functions useful in debugging and displaying stuff *)
    fun sayCone B = PP.outputTree(device,Effect.layoutCone B,!Flags.colwidth)
    fun sayLayer B = PP.outputTree(device,Effect.layoutLayer B,!Flags.colwidth)
    fun sayEtas B = map (fn tr => PP.outputTree(device,tr,!Flags.colwidth)) (Effect.layoutEtas B)
    fun sayRSE B = PP.outputTree(device,RegionStatEnv.layout B,!Flags.colwidth)

    val layoutExp = Exp.layoutLambdaExp'
    
    fun sayExp B = PP.outputTree(device,layoutExp B,!Flags.colwidth)
    fun sayEffect B = PP.outputTree(device,Effect.layout_effect B,!Flags.colwidth)

    (* Traverses the region exp with having owned regions in a list. *)
    fun traverse_region_exp (tr0 as RegionExp.TR(e, mu, effect_node), owned_regions) = 
    let
      fun traverse_region_curried tr = traverse_region_exp (tr, owned_regions)

      fun traverse_switch (RegionExp.SWITCH(t0, choices, else_opt), owned_regions) = (
        traverse_region_exp(t0, owned_regions);
        map (traverse_region_curried o #2) choices;
        case else_opt of
          NONE => ()
          | SOME t => traverse_region_exp(t, owned_regions)
      )
      
      fun traverse_functions(functions, owned_regions) = case functions of
        {lvar,occ,tyvars,rhos,epss,Type,formal_regions,bind}::rem_functions => let
          val _ = traverse_region_exp(bind, owned_regions)
          val _ = traverse_functions(rem_functions, owned_regions)
        in
          ()
        end
        | [] => ()
      
      fun is_in_owned_regions p = 
        List.exists (fn fr => Effect.eq_effect (p, fr)) owned_regions
    in
    case e of
      (* possible allocation in left-side of a function application *)
      RegionExp.VAR{lvar, il_r, fix_bound} => 
        let
          (* extracting effect nodes *)
          val (rhos,eff_nodes,_) =  RType.un_il(#1(!il_r))
          (* preparing effect nodes *)
          val _ = (
            map Effect.is_put eff_nodes;
            Effect.eval_phis eff_nodes
          )
          val effect_str = foldl (fn (a, b) => (a^", "^b)) "" (map Effect.pp_eff eff_nodes)
          (* pre-searching the region flow graph *)
          val _ = map Effect.represents eff_nodes
          (* phis are: PUT, GET, MUT or some other effect node *)
          val phis = flatten (map Effect.mk_phi eff_nodes)
          (* Search from effect nodes and check if they reach PUT nodes which are reachable from owned_regions *)
          val _ = if Effect.do_put (eff_nodes, owned_regions) then (
              say ("the effect(s) " ^ effect_str ^ " has a put effect in one of owned regions\n");
              say "The owned regions are:\n";
              map sayEffect owned_regions;
              say "\n";
              say "The expression is:\n";
              sayExp e;
              say "\n";
              raise PUT_TO_FROZED
            )else
              ()
        in
          ()
        end
      
      (* possible allocation in some constructor *)
      | RegionExp.CON0 (c) =>
        let
          val {con, il, aux_regions,alloc} = c
          val _ = case alloc of
            (* checking if allocated anything and the region it allocates in *)
            SOME p => if is_in_owned_regions p then (
              say "A constructor is being called in an owned region\n";
              say "The region is:\n";
              sayEffect p;
              say "\n";
              say "The constructor expression is:\n";
              sayExp e;
              say "\n";
              raise PUT_TO_FROZED
            ) else
              ()
            | NONE => ()
        in
          ()
        end
      
      (* possible allocation in some constructor *)
      | RegionExp.CON1 (c,tr) =>
        let
          val {con, il, alloc} = c
          val _ = case alloc of
            (* checking if allocated anything and the region it allocates in *)
            SOME p => if is_in_owned_regions p then (
              say "A constructor is being called in an owned region\n";
              say "The region is:\n";
              sayEffect p;
              say "\n";
              say "The constructor expression is:\n";
              sayExp e;
              say "\n";
              raise PUT_TO_FROZED
            )
            else
              ()
            | NONE => ()
          val _ = traverse_region_exp(tr, owned_regions)
        in
          ()
        end
      
      (* possible allocation in some constructor *)
      | RegionExp.RECORD (p,trs) =>
        let
          val _ = case p of
            (* checking the region it allocates in *)
            SOME place => if is_in_owned_regions place then (
              say "A record is being created in an owned region\n";
              say "The region is:\n";
              sayEffect place;
              say "\n";
              say "The record expression is:\n";
              sayExp e;
              say "\n";
              raise PUT_TO_FROZED
            )
            else
              ()
            | NONE => ()

          val _ = map traverse_region_curried trs
        in
          ()
        end
      
      (* new owned regions *)
      | RegionExp.LET{pat,owns=owns,bind,scope} =>
        let
          val new_owned_regions = case pat of 
                              ((lvar, mus, ty, rho)::_) => let
                                (* extracting free region variables of the lvar's type *)
                                val free_reg_vars = RType.frv_mu ty
                              in
                                if owns then free_reg_vars else []
                              end
                              | _ => []
          
          val _ = traverse_region_exp(bind, owned_regions)
          (* travse the let scope with new owned regions *)
          val _ = traverse_region_exp(scope, new_owned_regions @ owned_regions)
        in
          ()
        end
      
      (* The following are nodes that should be used only for data transformation and traversing the tree *)
      | RegionExp.FN{pat,body,alloc,free} => traverse_region_exp (body, owned_regions)
      | RegionExp.LETREGION_B{B, discharged_phi, body} => traverse_region_exp (body, owned_regions)
      | RegionExp.FIX{shared_clos,functions,scope} => (
        traverse_functions(functions, owned_regions);
        traverse_region_exp(scope, owned_regions)
      )
      | RegionExp.APP(tr1, tr2) => (
        traverse_region_exp(tr1, owned_regions);
        traverse_region_exp(tr2, owned_regions)
      )
      | RegionExp.EXCEPTION(excon,b,mu,alloc,tr) => traverse_region_exp(tr, owned_regions)
      | RegionExp.RAISE(tr) => traverse_region_exp(tr, owned_regions)
      | RegionExp.HANDLE(tr1, tr2) => (
        traverse_region_exp(tr1, owned_regions);
        traverse_region_exp(tr2, owned_regions)
      )
      | RegionExp.SWITCH_I {switch,precision} => traverse_switch(switch, owned_regions)
      | RegionExp.SWITCH_W {switch,precision} => traverse_switch(switch, owned_regions)
      | RegionExp.SWITCH_S sw => traverse_switch(sw, owned_regions)
      | RegionExp.SWITCH_C sw => traverse_switch(sw, owned_regions)
      | RegionExp.SWITCH_E sw => traverse_switch(sw, owned_regions)
      | RegionExp.DECON(c,tr) => traverse_region_exp(tr, owned_regions)
      | RegionExp.EXCON(excon,SOME(p,tr)) => traverse_region_exp(tr, owned_regions)
      | RegionExp.DEEXCON(excon,tr) => traverse_region_exp(tr, owned_regions)
      | RegionExp.SELECT(i,tr) => traverse_region_exp(tr, owned_regions)
      | RegionExp.DEREF tr => traverse_region_exp(tr, owned_regions)
      | RegionExp.REF (p, tr) => traverse_region_exp(tr, owned_regions)
      | RegionExp.ASSIGN(tr1,tr2) => (
        traverse_region_exp(tr1, owned_regions);
        traverse_region_exp(tr2, owned_regions)
      )
      | RegionExp.DROP (tr) => traverse_region_exp(tr, owned_regions)
      | RegionExp.EQUAL(c,tr1,tr2) => (
        traverse_region_exp(tr1, owned_regions);
        traverse_region_exp(tr2, owned_regions)
      )
      | RegionExp.CCALL(c,trs) => (map traverse_region_curried trs; ())
      | RegionExp.BLOCKF64 (p,trs) => (map traverse_region_curried trs; ())
      | RegionExp.EXPORT(c,tr) => traverse_region_exp(tr, owned_regions)
      | RegionExp.RESET_REGIONS({force,regions_for_resetting},tr) => traverse_region_exp(tr, owned_regions)
      | RegionExp.FRAME{declared_lvars, declared_excons} => ()
      | RegionExp.INTEGER(i,t,a) => ()
      | RegionExp.WORD(i,t,a) => ()
      | RegionExp.STRING(s,a) => ()
      | RegionExp.REAL(r,a) => ()
      | RegionExp.F64 r => ()
      | RegionExp.UB_RECORD(ts) => (map traverse_region_curried ts; ())
      | _ => ()

    end


    fun unwrap (B:cone,rse:rse,tr : (place,unit)Exp.trip) : unit =
      traverse_region_exp (tr, []) 
        handle PUT_TO_FROZED => die "tried to allocate memory in a owned region"
              | _ => ()
  in
    unwrap
  end
end
