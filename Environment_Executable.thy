theory Environment_Executable
imports
  Main Physical_Trace Overtaking_Aux
  "$AFP/Affine_Arithmetic/Polygon"
begin

section "Lanelets"

definition points_path2 :: "(real2 \<times> real2) list \<Rightarrow> (real \<Rightarrow> real2) list" where
  "points_path2 points \<equiv> map (\<lambda>p. linepath (fst p) (snd p)) points"
    
fun curve_eq3 :: "(real \<Rightarrow> real2) list \<Rightarrow> real \<Rightarrow> real2" where
  "curve_eq3 [x] = x" | 
  "curve_eq3 (x # xs) = x +++ curve_eq3 xs"
    
theorem pathstart_curve_eq:
  "pathstart (curve_eq3 (x # xs)) = pathstart x"  
  by (metis (no_types, lifting) curve_eq3.elims list.discI list.sel(1) pathstart_join)    
      
theorem curve_eq_cont:
  fixes points :: "(real2 \<times> real2) list"
  assumes "points \<noteq> []"
  assumes "polychain points"
  assumes "points_path2 points = paths"    
  shows "continuous_on {0..1} (curve_eq3 paths)"
  using assms
proof (induction paths arbitrary:points rule:curve_eq3.induct)
  case (1 x)
  then show ?case unfolding points_path2_def 
    by (auto simp add:continuous_on_linepath)
next
  case (2 x v va)
  note case_two = this    
  from case_two(4) obtain x' v' va' where "points = x' # v' # va'" and
    "linepath (fst x') (snd x') = x" and "linepath (fst v') (snd v') = v"
    and 0: "points_path2 (v' # va') = v # va"
    unfolding points_path2_def
    by auto
  with case_two(3) have "polychain (v' # va')" by (simp add: polychain_Cons)  
  from case_two(1)[OF _ this 0] have 1:"continuous_on {0..1} (curve_eq3 (v # va))" by auto
  then show ?case unfolding curve_eq3.simps(2)
  proof (intro continuous_on_joinpaths)      
    from \<open>linepath (fst x') (snd x') = x\<close> show "continuous_on {0..1} x" 
      using continuous_on_linepath by auto
  next
    from 1 show "continuous_on {0..1} (curve_eq3 (v # va))" .
  next
    have 0: "pathstart (curve_eq3 (v # va)) = pathstart v" using pathstart_curve_eq by auto  
    from \<open>polychain points\<close> and \<open>points = x' # v' # va'\<close> have "snd x' = fst v'" 
      unfolding polychain_def by auto
    moreover have "pathfinish x = snd x'" using \<open>linepath (fst x') (snd x') = x\<close> 
      using pathfinish_linepath by auto
    moreover have "pathstart v = fst v'" using \<open>linepath (fst v') (snd v') = v\<close>        
      using pathstart_linepath by auto
    ultimately show "pathfinish x = pathstart (curve_eq3 (v # va))" using 0 by auto       
  qed
next
  case 3
  then show ?case unfolding points_path2_def by auto
qed    
  
subsection "Lanelet curve"  
            
locale lanelet_curve = 
  fixes points :: "(real2 \<times> real2) list" 
  assumes nonempty_points: "points \<noteq> []"  
  assumes poly_points: "polychain points"    
begin
abbreviation points_path :: "(real \<Rightarrow> real2) list" where
  "points_path \<equiv> points_path2 points"  
  
abbreviation curve_eq :: "real \<Rightarrow> real2" where
  "curve_eq \<equiv> curve_eq3 points_path"        

text 
  \<open>Proof that lanelent curve is a refinement of a curve. The proof is obtained via sublocale proof.\<close>       
  
interpretation lc: curve "curve_eq" "{0..1}" 
proof (unfold_locales)
  show "convex {(0::real)..1}" by auto
next      
  show "compact {(0::real)..1}" by auto        
next
  show "continuous_on {0..1} curve_eq"
    using curve_eq_cont[OF nonempty_points poly_points] by auto      
qed 
end
     
subsection "Lanelet's simple boundary"
  
text \<open>One of the most important property for the polychain is monotonicity. This property is 
similar to the property that each curve equation in Physical_Trace.thy must be a graph. A graph 
here means that @{term "y"} is a function of @{term "x"}. This mean that a curve which looks like 
letter "S" cannot be a graph.\<close>
  
definition "monotone_polychain xs \<longleftrightarrow>  
            polychain (xs :: (real2 \<times> real2) list) \<and> (\<forall>i < length xs. fst (fst (xs ! i)) < fst (snd (xs ! i)))"  
   
lemma monotone_polychain_ConsD:
  assumes "monotone_polychain (x # xs)"
  shows "monotone_polychain xs"
  using assms polychain_Cons[of "x" "xs"] unfolding monotone_polychain_def
  by (metis Suc_mono length_Cons nth_Cons_Suc polychain_Nil)
    
lemma monotone_polychainD:
  assumes "monotone_polychain xs"
  shows "polychain xs"
  using assms unfolding monotone_polychain_def by auto
          
lemma strict_mono_in_joinpaths:
  assumes "strict_mono_in f {0..1}"
  assumes "strict_mono_in g {0..1}"
  assumes "pathfinish f = pathstart g"  
  shows "strict_mono_in (f +++ g) {0..1}"
proof
  fix x y :: real
  assume xr: "x \<in> {0..1}"
  assume yr: "y \<in> {0..1}"
  assume "x < y"  
  consider "x \<le> 0.5 \<and> y \<le> 0.5"
         | "x \<le> 0.5 \<and> y > 0.5"
         | "x > 0.5 \<and> y \<le> 0.5"
         | "x > 0.5 \<and> y > 0.5" by fastforce  
  thus "(f +++ g) x < (f +++ g) y"
  proof (cases)
    case 1
    note case_one = this
    hence l: "(f +++ g) x = f (2 * x)" and r: "(f +++ g) y = f (2 * y)" unfolding joinpaths_def 
      by auto
    from \<open>x < y\<close> have "2 * x < 2 * y" by auto
    from case_one xr yr have "0 \<le> 2 * x \<and> 2 * x \<le> 1" and "0 \<le> 2 * y \<and> 2 * y \<le> 1" by auto
    with \<open>2 * x < 2 * y\<close> and assms(1) have "f (2 * x) < f (2 * y)" unfolding strict_mono_in_def 
      by auto        
    then show ?thesis using l r by auto
  next
    case 2
    note case_two = this
    hence l:"(f +++ g) x = f (2 * x)" and r: "(f +++ g) y = g (2 * y - 1)"
      unfolding joinpaths_def by auto
    from assms(1) have "mono_in f {0..1}" using strict_mono_in_mono_in by auto        
    from case_two have "0 \<le> 2 * x \<and> 2 * x \<le> 1" using xr and yr by auto
    with \<open>mono_in f {0..1}\<close> have "f (2 * x) \<le> f 1" unfolding mono_in_def by auto          
    also have "... = g 0" using assms(3) unfolding pathfinish_def pathstart_def by auto
    finally have "f (2 * x) \<le> g 0" by auto
    from case_two have "0 < 2 * y - 1 \<and> 2 * y - 1 \<le> 1" using xr and yr by auto
    with assms(2) have "g 0 < g (2 * y - 1)" unfolding strict_mono_in_def by auto
    with \<open>f (2 * x) \<le> g 0\<close> have "f (2 * x) < g (2 * y - 1)" by auto        
    then show ?thesis using l and r by auto
  next
    case 3
    with \<open>x < y\<close> have "False" by auto  
    then show ?thesis by auto
  next
    case 4
    note case_four = this
    hence l: "(f +++ g) x = g (2 * x - 1)" and r: "(f +++ g) y = g (2 * y - 1)" unfolding joinpaths_def
      by auto
    from \<open>x < y\<close> have "2 * x < 2 * y" by auto
    from case_four xr yr have "0 \<le> 2 * x - 1 \<and> 2 * x - 1 \<le> 1" and "0 \<le> 2 * y - 1 \<and> 2 * y - 1 \<le> 1"
      by auto
    with \<open>2 * x < 2 * y\<close> and assms(2) have "g (2 * x - 1) < g (2 * y - 1)" 
      unfolding strict_mono_in_def  by auto    
    then show ?thesis using l r by auto
  qed    
qed
  
lemma mono_in_joinpaths:
  assumes "mono_in f {0..1}"
  assumes "mono_in g {0..1}"
  assumes "pathfinish f = pathstart g"  
  shows "mono_in (f +++ g) {0..1}"    
proof
  fix x y :: real
  assume xr: "x \<in> {0..1}"
  assume yr: "y \<in> {0..1}"
  assume "x \<le> y"  
  consider "x \<le> 0.5 \<and> y \<le> 0.5"
         | "x \<le> 0.5 \<and> y > 0.5"
         | "x > 0.5 \<and> y \<le> 0.5"
         | "x > 0.5 \<and> y > 0.5" by fastforce  
  thus "(f +++ g) x \<le> (f +++ g) y"
  proof (cases)
    case 1
    note case_one = this
    hence l: "(f +++ g) x = f (2 * x)" and r: "(f +++ g) y = f (2 * y)" unfolding joinpaths_def 
      by auto
    from \<open>x \<le> y\<close> have "2 * x \<le> 2 * y" by auto
    from case_one xr yr have "0 \<le> 2 * x \<and> 2 * x \<le> 1" and "0 \<le> 2 * y \<and> 2 * y \<le> 1" by auto
    with \<open>2 * x \<le> 2 * y\<close> and assms(1) have "f (2 * x) \<le> f (2 * y)" unfolding mono_in_def by auto        
    then show ?thesis using l r by auto
  next
    case 2
    note case_two = this
    hence l:"(f +++ g) x = f (2 * x)" and r: "(f +++ g) y = g (2 * y - 1)"
      unfolding joinpaths_def by auto
    from case_two have "0 \<le> 2 * x \<and> 2 * x \<le> 1" using xr and yr by auto
    with assms(1) have "f (2 * x) \<le> f 1" unfolding mono_in_def by auto
    also have "... = g 0" using assms(3) unfolding pathfinish_def pathstart_def by auto
    finally have "f (2 * x) \<le> g 0" by auto
    from case_two have "0 \<le> 2 * y - 1 \<and> 2 * y - 1 \<le> 1" using xr and yr by auto
    with assms(2) have "g 0 \<le> g (2 * y - 1)" unfolding mono_in_def by auto
    with \<open>f (2 * x) \<le> g 0\<close> have "f (2 * x) \<le> g (2 * y - 1)" by auto        
    then show ?thesis using l and r by auto
  next
    case 3
    with \<open>x \<le> y\<close> have "False" by auto  
    then show ?thesis by auto
  next
    case 4
    note case_four = this
    hence l: "(f +++ g) x = g (2 * x - 1)" and r: "(f +++ g) y = g (2 * y - 1)" unfolding joinpaths_def
      by auto
    from \<open>x \<le> y\<close> have "2 * x \<le> 2 * y" by auto
    from case_four xr yr have "0 \<le> 2 * x - 1 \<and> 2 * x - 1 \<le> 1" and "0 \<le> 2 * y - 1 \<and> 2 * y - 1 \<le> 1"
      by auto
    with \<open>2 * x \<le> 2 * y\<close> and assms(2) have "g (2 * x - 1) \<le> g (2 * y - 1)" unfolding mono_in_def 
      by auto    
    then show ?thesis using l r by auto
  qed    
qed
  
theorem strict_mono_in_curve_eq3:
  assumes "monotone_polychain points"
  assumes "points_path2 points = paths"
  assumes "points \<noteq> []"
  shows "strict_mono_in (fst \<circ> curve_eq3 paths) {0..1}"
  using assms
proof (induction paths arbitrary:points rule:curve_eq3.induct)
  case (1 x)
  note case_one = this
  then obtain x' where "points = [x']" and "linepath (fst x') (snd x') = x" 
    unfolding points_path2_def by auto
  with \<open>monotone_polychain points\<close> have 0: "fst (fst x') < fst (snd x')" unfolding monotone_polychain_def
    by auto
  from \<open>linepath (fst x') (snd x') = x\<close> have "x = (\<lambda>x. (1 - x) *\<^sub>R (fst x') + x *\<^sub>R (snd x'))"
    unfolding linepath_def by auto
  hence "fst \<circ> x = (\<lambda>x. (1 - x) * fst (fst x') + x * fst (snd x'))" by auto
  with 0 have "strict_mono_in (fst \<circ> x) {0..1}" unfolding strict_mono_in_def 
    by (smt left_diff_distrib' real_mult_le_cancel_iff2)
  then show ?case unfolding curve_eq3.simps .
next
  case (2 x v va)
  note case_two = this
  then obtain x' and v' and va' where "points = x' # v' # va'" and ppt: "points_path2 (v' # va') = v # va"
    and lpx: "linepath (fst x') (snd x') = x" and lpv: "linepath (fst v') (snd v') = v"
    unfolding points_path2_def by auto
  with \<open>monotone_polychain points\<close> have "monotone_polychain (v' # va')" 
    using monotone_polychain_ConsD by auto
  from case_two(1)[OF this ppt] have "strict_mono_in (fst \<circ> curve_eq3 (v # va)) {0..1}" by blast
  from \<open>monotone_polychain points\<close> and \<open>points = x' # v' # va'\<close> have 0: "fst (fst x') < fst (snd x')"
    unfolding monotone_polychain_def by auto
  from lpx have "x = (\<lambda>x. (1 - x) *\<^sub>R (fst x') + x *\<^sub>R (snd x'))" unfolding linepath_def by auto  
  hence "fst \<circ> x = (\<lambda>x. (1 - x) * fst (fst x') + x * fst (snd x'))" by auto
  with 0 have "strict_mono_in (fst \<circ> x) {0..1}" unfolding strict_mono_in_def 
    by (smt mult_diff_mult mult_strict_right_mono)   
  have "fst \<circ> curve_eq3 (x # v # va) = fst \<circ> (x +++ curve_eq3 (v # va))" by auto
  also have "... = (fst \<circ> x) +++ (fst \<circ> curve_eq3 (v # va))" by (simp add: path_compose_join)      
  finally have helper:"fst \<circ> curve_eq3 (x # v # va) = (fst \<circ> x) +++ (fst \<circ> curve_eq3 (v # va))" by auto
  have "strict_mono_in ((fst \<circ> x) +++ (fst \<circ> curve_eq3 (v # va))) {0..1}"
  proof (rule strict_mono_in_joinpaths)
    from \<open>strict_mono_in (fst \<circ> x) {0..1}\<close> show "strict_mono_in (fst \<circ> x) {0..1}" .   
  next
    from \<open>strict_mono_in (fst \<circ> curve_eq3 (v # va)) {0..1}\<close> 
      show "strict_mono_in (fst \<circ> curve_eq3 (v # va)) {0..1}" .
  next
    from \<open>monotone_polychain points\<close> have "polychain points" using monotone_polychainD by auto
    with \<open>points = x' # v' # va'\<close> have "snd x' = fst v'" unfolding polychain_def by auto
    hence 1: "fst (snd x') = fst (fst v')" by auto
    from lpx and lpv have "pathfinish x = snd x'" and "pathstart v = fst v'" by auto            
    with 1 show "pathfinish (fst \<circ> x) = pathstart (fst \<circ> curve_eq3 (v # va))" 
      by (simp add: pathfinish_compose pathstart_compose pathstart_curve_eq)
  qed        
  then show ?case using helper by auto
next
  case 3
  then show ?case unfolding points_path2_def by auto
qed
        
theorem mono_in_curve_eq3:
  assumes "monotone_polychain points"
  assumes "points_path2 points = paths"
  assumes "points \<noteq> []"
  shows "mono_in (fst \<circ> curve_eq3 paths) {0..1}"
  using assms
proof (induction paths arbitrary:points rule:curve_eq3.induct)
  case (1 x)
  note case_one = this
  then obtain x' where "points = [x']" and "linepath (fst x') (snd x') = x" 
    unfolding points_path2_def by auto
  with \<open>monotone_polychain points\<close> have 0: "fst (fst x') < fst (snd x')" unfolding monotone_polychain_def
    by auto
  from \<open>linepath (fst x') (snd x') = x\<close> have "x = (\<lambda>x. (1 - x) *\<^sub>R (fst x') + x *\<^sub>R (snd x'))"
    unfolding linepath_def by auto
  hence "fst \<circ> x = (\<lambda>x. (1 - x) * fst (fst x') + x * fst (snd x'))" by auto
  with 0 have "mono_in (fst \<circ> x) {0..1}" unfolding mono_in_def 
    by (smt left_diff_distrib' mult_left_mono)    
  then show ?case unfolding curve_eq3.simps .
next
  case (2 x v va)
  note case_two = this
  then obtain x' and v' and va' where "points = x' # v' # va'" and ppt: "points_path2 (v' # va') = v # va"
    and lpx: "linepath (fst x') (snd x') = x" and lpv: "linepath (fst v') (snd v') = v"
    unfolding points_path2_def by auto
  with \<open>monotone_polychain points\<close> have "monotone_polychain (v' # va')" 
    using monotone_polychain_ConsD by auto
  from case_two(1)[OF this ppt] have "mono_in (fst \<circ> curve_eq3 (v # va)) {0..1}" by blast
  from \<open>monotone_polychain points\<close> and \<open>points = x' # v' # va'\<close> have 0: "fst (fst x') < fst (snd x')"
    unfolding monotone_polychain_def by auto
  from lpx have "x = (\<lambda>x. (1 - x) *\<^sub>R (fst x') + x *\<^sub>R (snd x'))" unfolding linepath_def by auto  
  hence "fst \<circ> x = (\<lambda>x. (1 - x) * fst (fst x') + x * fst (snd x'))" by auto
  with 0 have "mono_in (fst \<circ> x) {0..1}" unfolding mono_in_def 
    by (smt left_diff_distrib' mult_left_mono)   
  have "fst \<circ> curve_eq3 (x # v # va) = fst \<circ> (x +++ curve_eq3 (v # va))" by auto
  also have "... = (fst \<circ> x) +++ (fst \<circ> curve_eq3 (v # va))" by (simp add: path_compose_join)      
  finally have helper:"fst \<circ> curve_eq3 (x # v # va) = (fst \<circ> x) +++ (fst \<circ> curve_eq3 (v # va))" by auto
  have "mono_in ((fst \<circ> x) +++ (fst \<circ> curve_eq3 (v # va))) {0..1}"
  proof (rule mono_in_joinpaths)
    from \<open>mono_in (fst \<circ> x) {0..1}\<close> show "mono_in (fst \<circ> x) {0..1}" .   
  next
    from \<open>mono_in (fst \<circ> curve_eq3 (v # va)) {0..1}\<close> show "mono_in (fst \<circ> curve_eq3 (v # va)) {0..1}" .
  next
    from \<open>monotone_polychain points\<close> have "polychain points" using monotone_polychainD by auto
    with \<open>points = x' # v' # va'\<close> have "snd x' = fst v'" unfolding polychain_def by auto
    hence 1: "fst (snd x') = fst (fst v')" by auto
    from lpx and lpv have "pathfinish x = snd x'" and "pathstart v = fst v'" by auto            
    with 1 show "pathfinish (fst \<circ> x) = pathstart (fst \<circ> curve_eq3 (v # va))" 
      by (simp add: pathfinish_compose pathstart_compose pathstart_curve_eq)
  qed        
  then show ?case using helper by auto
next
  case 3
  then show ?case unfolding points_path2_def by auto
qed    

lemma inj_scale_2:
  "inj_on (op * (2::real)) s"
  using injective_scaleR[of "2"] 
  by (simp add: inj_onI)
        
lemma inj_scale2_shift1: 
  "inj_on (op + (-1 :: real) \<circ> op * (2 :: real)) s"
  using inj_scale_2 comp_inj_on[of "op * (2::real)" _ "op + (-1::real)"]
  by (simp add: inj_onI)
        
theorem inj_on_curve_eq:
  assumes "monotone_polychain points"
  assumes "points_path2 points = paths"
  assumes "points \<noteq> []"
  assumes "curve_eq3 paths = curve_eq"
  shows "inj_on curve_eq {0..1}"
proof -
  from assms have "strict_mono_in (fst \<circ> curve_eq3 paths) {0..1}" using strict_mono_in_curve_eq3
    by auto
  hence "inj_on (fst \<circ> curve_eq) {0..1}" using strict_imp_inj_on assms by auto    
  thus ?thesis  using inj_on_imageI2 by blast    
qed
        
locale lanelet_simple_boundary = lanelet_curve +
  assumes monotone: "monotone_polychain xs"  
begin
  
lemma curve_eq_is_curve: 
  "curve curve_eq {0..1}"
proof (unfold_locales)
  show "convex {(0::real)..1}" by auto
next      
  show "compact {(0::real)..1}" by auto        
next
  show "continuous_on {0..1} curve_eq"
    using curve_eq_cont[OF nonempty_points poly_points] by auto
qed  
  
interpretation lsc: simple_boundary "curve_eq" "{0..1}"
proof (unfold_locales)
  show "convex {(0::real)..1}" by auto
next      
  show "compact {(0::real)..1}" by auto        
next
  show "continuous_on {0..1} curve_eq"
    using curve_eq_cont[OF nonempty_points poly_points] by auto  
next
  show "inj_on curve_eq {0..1}"
    using inj_on_curve_eq[OF monotone _ nonempty_points] by auto 
next
  have eq:"curve.curve_eq_x curve_eq = (fst \<circ> curve_eq)" 
    unfolding curve.curve_eq_x_def[OF curve_eq_is_curve] by auto    
  show "bij_betw (curve.curve_eq_x curve_eq) {0..1} (curve.setX curve_eq {0..1})"
    unfolding bij_betw_def
  proof 
    from strict_mono_in_curve_eq3[OF monotone _ nonempty_points]
      have "strict_mono_in (fst \<circ> curve_eq) {0..1}" by auto
    hence "inj_on (fst \<circ> curve_eq) {0..1}" using strict_imp_inj_on by auto
    with eq show "inj_on (curve.curve_eq_x curve_eq) {0..1}" by auto
  next
    show "curve.curve_eq_x curve_eq ` {0..1} = curve.setX curve_eq {0..1}"
      unfolding eq curve.setX_def[OF curve_eq_is_curve] by auto
  qed    
qed  
end
  
subsection "Lanelet"  
  
text \<open>The direction of a lanelet is defined according to the relative position of the left polychain
with respect to the right polychain. In order to determine the direction, we first construct a 
polygon from these two polychains, and then find the vertex (point) which is guaranteed to be
the point in its convex hull. To find this vertex, we only need to find the points with the smallest
@{term "x"} value, and if there are more than one, we choose the one with the smallest @{term "y"}
values. The following function min2D does this job.\<close> 
 
definition min2D :: "real2 \<Rightarrow> real2 \<Rightarrow> real2" where
  "min2D z1 z2 = (let x1 = fst z1; x2 = fst z2; y1 = snd z1; y2 = snd z2 in
                    if x1 < x2 then z1 else
                    if x1 = x2 then (if y1 \<le> y2 then z1 else z2) else
                    (* x1 > x2 *)   z2)"
  
theorem min2D_D:
  assumes "min2D x y = z"
  shows "fst z \<le> fst x \<and> fst z \<le> fst y"
  using assms unfolding min2D_def by smt
    
theorem min2D_D2:
  assumes "min2D x y = z"
  shows "z = x \<or> z = y"
  using assms unfolding min2D_def by presburger

theorem min2D_D3:
  assumes "min2D x y = x"
  shows "fst x < fst y \<or> (fst x = fst y \<and> snd x \<le> snd y)"
  using assms unfolding min2D_def by smt  
    
theorem min2D_D4:
  assumes "min2D x y = y"
  shows "fst y < fst x \<or> (fst x = fst y \<and> snd y \<le> snd x)"
  using assms unfolding min2D_def by smt 
      
definition
  "polygon xs \<longleftrightarrow> (polychain xs \<and> (xs \<noteq> [] \<longrightarrow> fst (hd xs) = snd (last xs)))"
     
text "A function for finding the smallest (in x and y dimension) vertex of the convex hull of
  a (not necessarily convex) polygon."  
    
fun convex_hull_vertex2 :: "(real2 \<times>  real2) list \<Rightarrow> real2 option" where
 "convex_hull_vertex2 [] = None" | 
 "convex_hull_vertex2 (z # zs) = 
      (case convex_hull_vertex2 zs of
         None \<Rightarrow> Some (min2D (fst z) (snd z))
       | Some z' \<Rightarrow> Some (min2D (fst z) z'))"

lemma cons_convex_hull_vertex_some':
  "\<exists>x. convex_hull_vertex2 (z # zs) = Some x"
  by (simp add: option.case_eq_if)  
    
fun convex_hull_vertex3 :: "(real2 \<times>  real2) list \<Rightarrow> real2 option" where
 "convex_hull_vertex3 [] = None" |
 "convex_hull_vertex3 [z] = Some (min2D (fst z) (snd z))" |  
 "convex_hull_vertex3 (z1 # z2 # zs) = 
      (case convex_hull_vertex3 (z2 # zs) of Some z' \<Rightarrow> Some (min2D (fst z1) z'))"
     
lemma cons_convex_hull_vertex_some:
  "\<exists>x. convex_hull_vertex3 (z # zs) = Some x"
proof (induction zs arbitrary:z)
  case Nil
  then show ?case by auto
next
  case (Cons a zs)
  then obtain x where "convex_hull_vertex3 (a # zs) = Some x" by blast
  hence "convex_hull_vertex3 (z # a # zs) = Some (min2D (fst z) x)" by auto     
  then show ?case by auto
qed
  
text \<open>Function @{term "convex_hull_vertex3"} is the same with @{term "convex_hull_vertex2"}. It is 
nicer to have the former when we are doing induction.\<close>  
 
theorem chv3_eq_chv2:
  "convex_hull_vertex3 zs = convex_hull_vertex2 zs" 
proof (induction zs rule:convex_hull_vertex3.induct)
  case 1
  then show ?case by auto
next
  case (2 z)
  then show ?case by auto
next
  case (3 z1 z2 zs)
  note case_three = this  
  obtain x where "convex_hull_vertex2 (z2 # zs) = Some x" using cons_convex_hull_vertex_some' 
    by blast
  hence "convex_hull_vertex2 (z1 # z2 # zs) = Some (min2D (fst z1) x)" by auto      
  then show ?case using case_three by (auto split:option.split)
qed
  
text \<open>This function is to test the membership of a point in a polychain.\<close>  
    
definition element_of_polychain :: "real2 \<Rightarrow> (real2 \<times> real2) list \<Rightarrow> bool" where
  "element_of_polychain x xs \<equiv> \<exists>y. (x, y) \<in> set xs \<or> (y, x) \<in> set xs" 
  
lemma element_of_polychain_cons:
  assumes "element_of_polychain x xs"
  shows "element_of_polychain x (y # xs)"
  using assms unfolding element_of_polychain_def by auto
    
lemma element_of_polychainD:
  assumes "element_of_polychain x (y # ys)"
  shows "element_of_polychain x [y] \<or> element_of_polychain x ys"
  using assms unfolding element_of_polychain_def by auto
  
lemma el_of_polychain1:    
  assumes "polychain zs" 
  assumes "convex_hull_vertex2 zs = Some z"
  shows "element_of_polychain z zs"
  using assms 
proof (induction zs arbitrary:z)
  case Nil
  then show ?case by auto
next
  case (Cons a zs)
  note case_cons = this
  obtain z' and zs' where "zs = [] \<or> zs = z' # zs'" by (metis hd_Cons_tl)  
  moreover
  { assume empty: "zs = []"
    with case_cons have "convex_hull_vertex2 (a # zs) = Some (min2D (fst a) (snd a))" by auto
    with case_cons have "min2D (fst a) (snd a) = z" by auto
    hence "z = (fst a) \<or> z = (snd a)" unfolding min2D_def by presburger        
    hence "element_of_polychain z (a # zs)" unfolding empty element_of_polychain_def
      apply (cases "z = fst a")      
      apply (metis list.set_intros(1) prod.collapse)  
      by (metis \<open>z = fst a \<or> z = snd a\<close> list.set_intros(1) prod.collapse) }
  moreover 
  { assume cons: "zs = z' # zs'"
    hence "convex_hull_vertex2 zs \<noteq> None" by (simp add: option.case_eq_if)
    then obtain b where "convex_hull_vertex2 zs = Some b" by auto
    hence "convex_hull_vertex2 (a # zs) = Some (min2D (fst a) b)" by auto
    with case_cons have "z = min2D (fst a) b" by auto
    from case_cons have "polychain zs"
      by (metis \<open>convex_hull_vertex2 zs \<noteq> None\<close> convex_hull_vertex2.simps(1) polychain_Cons)
    with case_cons and \<open>convex_hull_vertex2 zs = Some b\<close> have "element_of_polychain b zs"
      by auto
    with \<open>z = min2D (fst a) b\<close> have "element_of_polychain z (a # zs)" 
    (* Isar proofs found by sledgehammer *)
    proof -
      have f1: "\<forall>x0 x1. (snd (x1::real \<times> real) \<le> snd (x0::real \<times> _)) = (0 \<le> snd x0 + - 1 * snd x1)"
        by auto
      have "\<forall>x0 x1. (fst (x1::real \<times> real) < fst (x0::_ \<times> real)) = (\<not> fst x0 + - 1 * fst x1 \<le> 0)"
        by auto
      then have f2: "\<forall>p pa. min2D p pa = (if fst pa + - 1 * fst p \<le> 0 then if fst p = fst pa then if 0 \<le> snd pa + - 1 * snd p then p else pa else pa else p)"
        using f1 min2D_def by presburger
      { assume "\<not> (if 0 \<le> snd b + - 1 * snd (fst a) then min2D (fst a) b = fst a else min2D (fst a) b = b)"
        moreover
        { assume "\<not> (if fst (fst a) = fst b then if 0 \<le> snd b + - 1 * snd (fst a) then min2D (fst a) b = fst a else min2D (fst a) b = b else min2D (fst a) b = b)"
          then have "min2D (fst a) b = fst a"
       using f2 by meson
     then have "fst (min2D (fst a) b, fst z') = fst a"
            by (metis prod.sel(1)) }
        ultimately have "min2D (fst a) b = b \<or> fst (min2D (fst a) b, fst z') = fst a"
          by (metis (no_types)) }
      moreover
      { assume "fst (min2D (fst a) b, fst z') = fst a"
        moreover
        { assume aaa1: "fst (min2D (fst a) b, fst z') = fst a \<and> (min2D (fst a) b, fst z') \<noteq> a"
          obtain pp :: "(real \<times> real) \<times> real \<times> real" and pps :: "((real \<times> real) \<times> real \<times> real) list" where
            "(\<exists>v0 v1. zs = v0 # v1) = (zs = pp # pps)"
            by blast
          moreover
          { assume "snd ((a # zs) ! 0) \<noteq> fst ((a # zs) ! Suc 0)"
            then have "\<not> Suc 0 < length (a # zs)"
              by (meson case_cons(2) polychain_def)
            then have "zs \<noteq> pp # pps"
              by auto }
          ultimately have ?thesis
            using aaa1 by (metis (no_types) cons nth_Cons_0 nth_Cons_Suc prod.sel(2) prod_eqI) }
        ultimately have ?thesis
          by (metis (no_types) \<open>z = min2D (fst a) b\<close> element_of_polychain_def insert_iff list.set(2)) }
      moreover
      { assume "min2D (fst a) b = b"
        then have "element_of_polychain (min2D (fst a) b) zs"
          by (metis Cons.IH \<open>convex_hull_vertex2 zs = Some b\<close> \<open>polychain zs\<close>)
        then have ?thesis
          by (metis \<open>z = min2D (fst a) b\<close> element_of_polychain_cons) }
      ultimately show ?thesis
        by (metis (no_types) prod.sel(1))
    qed }                              
  ultimately show ?case by auto  
qed
         
theorem el_of_polychain2:    
  assumes "polygon zs" 
  assumes "convex_hull_vertex2 zs = Some z"
  shows "element_of_polychain z zs"  
proof -
  from assms(1) have "polychain zs" unfolding polygon_def by auto
  with el_of_polychain1[OF this assms(2)] show ?thesis by auto      
qed  
    
theorem convex_hull_vertex_smallest_x:
  assumes "polychain zs"
  assumes "convex_hull_vertex2 zs = Some x"
  shows "\<forall>z \<in> set zs. fst x \<le> fst (fst z) \<and> fst x \<le> fst (snd z)"
  using assms  
proof (induction zs arbitrary:x)
  case Nil
  then show ?case by auto
next
  case (Cons a zs)
  note case_cons = this  
  obtain x' where "convex_hull_vertex2 zs = None \<or> convex_hull_vertex2 zs = Some x'"
    by fastforce
  moreover
  { assume none: "convex_hull_vertex2 zs = None"
    with case_cons(3) have x_min2d: "x = min2D (fst a) (snd a)" by auto
    from none have "zs = []" 
      by (metis (no_types, lifting) convex_hull_vertex2.simps(2) hd_Cons_tl option.case_eq_if 
                                                                                 option.distinct(1))        
    have " \<forall>z\<in>set (a # zs). fst x \<le> fst (fst z) \<and> fst x \<le> fst (snd z)"        
      unfolding \<open>zs = []\<close> using min2D_def x_min2d by force }
  moreover
  { assume some: "convex_hull_vertex2 zs = Some x'"      
    with case_cons(3) have "x = min2D (fst a) x'" by auto
    from case_cons(2) have "polychain zs" by (metis polychain_Cons polychain_Nil)
    from case_cons(1)[OF this some] have 0: "\<forall>z\<in>set zs. fst x' \<le> fst (fst z) \<and> fst x' \<le> fst (snd z)" .
    from \<open>x = min2D (fst a) x'\<close> have "fst x \<le> fst x'" and "fst x \<le> fst (fst a)"
      using min2D_D by auto
    with 0 have 1: "\<forall>z \<in>set zs. fst x \<le> fst (fst z) \<and> fst x \<le> fst (snd z)" by auto
    from some have "zs \<noteq> []" by auto    
    with \<open>polychain (a # zs)\<close> and hd_conv_nth[OF this] have "snd a = fst (hd zs)" 
      unfolding polychain_def by auto
    with \<open>zs \<noteq> []\<close> and 1 have "fst x \<le> fst (snd a)" by auto            
    with 1 \<open>fst x \<le> fst (fst a)\<close>  have "\<forall>z\<in>set (a # zs). fst x \<le> fst (fst z) \<and> fst x \<le> fst (snd z)"
      by auto }
  ultimately show "\<forall>z\<in>set (a # zs). fst x \<le> fst (fst z) \<and> fst x \<le> fst (snd z)" by auto  
qed
  
theorem convex_hull_vertex_smallest_x2:
  assumes "polychain zs"
  assumes "convex_hull_vertex2 zs = Some x"
  assumes "element_of_polychain z zs"    
  shows "fst x \<le> fst z"
  using convex_hull_vertex_smallest_x[OF assms(1) assms(2)] assms(3)
  unfolding element_of_polychain_def by auto
        
theorem convex_hull_vertex_smallest_y:
  assumes "polychain zs"
  assumes "convex_hull_vertex3 zs = Some x"
  assumes "element_of_polychain y zs \<and> fst x = fst y"
  shows "snd x \<le> snd y"    
  using assms
proof (induction zs arbitrary:x y rule:convex_hull_vertex3.induct)
  case 1
  then show ?case by auto
next
  case (2 z)
  note case_two = this  
  hence 0: "x = min2D (fst z) (snd z)" by auto  
  from case_two obtain y' where "(y, y') = z \<or> (y', y) = z" unfolding element_of_polychain_def 
    by auto
  with 0 case_two show "snd x \<le> snd y" 
    by (smt case_two(3) fst_conv min2D_def snd_conv)    
next
  case (3 z1 z2 zs)
  note case_three = this                
  then obtain x' where 1: "convex_hull_vertex3 (z2 # zs) = Some x'" using cons_convex_hull_vertex_some
    by blast
  from case_three(2) have "polychain (z2 # zs)" by (auto simp add:polychain_Cons)     
  with 1 case_three have "x = min2D (fst z1) x'" by auto  
  from case_three(4) have "element_of_polychain y [z1] \<or> element_of_polychain y (z2 # zs)"
    using element_of_polychainD by auto
  moreover
  { assume "element_of_polychain y (z2 # zs)"
    with case_three(1)[OF \<open>polychain (z2 # zs)\<close> 1] have 2: "fst x' = fst y \<longrightarrow> snd x' \<le> snd y"
      by auto                                                           
    from \<open>x = min2D (fst z1) x'\<close> have "x = (fst z1) \<or> x = x'" using min2D_D2 by auto
    moreover
    { assume "x = x'"
      with 2 and case_three have "snd x \<le> snd y" by auto }
    moreover
    { assume "x = fst z1"
      with \<open>x = min2D (fst z1) x'\<close> have 3: "fst (fst z1) < fst x' \<or> 
                                           (fst (fst z1) = fst x'\<and> snd (fst z1) \<le> snd x')" 
        using min2D_D3 by auto
      from 1 and \<open>element_of_polychain y (z2 # zs)\<close> have "fst x' \<le> fst y" 
        using convex_hull_vertex_smallest_x2[OF \<open>polychain (z2 # zs)\<close>] chv3_eq_chv2 by auto  
      with case_three(4) and 3 \<open>x = fst z1\<close> have "(fst x = fst x'\<and> snd x \<le> snd x')"
        by auto
      moreover with case_three(4) and 2 have "snd x' \<le> snd y" by auto
      ultimately have "snd x \<le> snd y" by auto }
    ultimately have "snd x \<le> snd y" by auto }
  moreover
  { assume 4: "element_of_polychain y [z1]"
    from \<open>x = min2D (fst z1) x'\<close> have "x = (fst z1) \<or> x = x'" using min2D_D2 by auto
    moreover
    { assume "x = fst z1"
      with \<open>x = min2D (fst z1) x'\<close> have  5: "fst (fst z1) < fst x' \<or> 
                                            (fst (fst z1) = fst x'\<and> snd (fst z1) \<le> snd x')" 
        using min2D_D3 by auto
      from 4 have "y = fst z1 \<or> y = snd z1" unfolding element_of_polychain_def by auto  
      moreover
      { assume "y = fst z1"
        hence "x = y" using \<open>x = fst z1\<close> by auto
        hence "snd x \<le> snd y" by auto }
      moreover
      { assume "y = snd z1"
        hence "element_of_polychain y (z2 # zs)" using \<open>polychain (z1 # z2 # zs)\<close> 
          by (metis element_of_polychain_def list.set_intros(1) list.simps(3) nth_Cons_0 
                                                                       polychain_Cons prod.collapse)  
        with case_three(1)[OF \<open>polychain (z2 # zs)\<close> 1] have 6: "fst x' = fst y \<longrightarrow> snd x' \<le> snd y"
          by auto  
        from 1 and \<open>element_of_polychain y (z2 # zs)\<close> have "fst x' \<le> fst y" 
          using convex_hull_vertex_smallest_x2[OF \<open>polychain (z2 # zs)\<close>] chv3_eq_chv2 by auto  
        with case_three(4) and 5  \<open>x = fst z1\<close> have "(fst x = fst x'\<and> snd x \<le> snd x')"
          by auto 
        moreover with case_three(4) and 6 have "snd x' \<le> snd y" by auto
        ultimately have "snd x \<le> snd y" by auto }
      ultimately have "snd x \<le> snd y" by auto }
    moreover
    { assume "x = x'"
      with \<open>x = min2D (fst z1) x'\<close> have  7: "fst (fst z1) > fst x' \<or> 
                                            (fst (fst z1) = fst x'\<and> snd (fst z1) \<ge> snd x')" 
        using min2D_D4 by auto
      from 4 have "y = fst z1 \<or> y = snd z1" unfolding element_of_polychain_def by auto  
      moreover
      { assume "y = fst z1"
        hence "fst y = fst (fst z1)" by auto
        with case_three(4) and \<open>x = x'\<close> and 7 and \<open>y = fst z1\<close> have "snd x \<le> snd y" by auto }
      moreover
      { assume "y = snd z1"
        hence "element_of_polychain y (z2 # zs)" using \<open>polychain (z1 # z2 # zs)\<close> 
          by (metis element_of_polychain_def list.set_intros(1) list.simps(3) nth_Cons_0 
                                                                       polychain_Cons prod.collapse)  
        with case_three(1)[OF \<open>polychain (z2 # zs)\<close> 1] have 6: "fst x' = fst y \<longrightarrow> snd x' \<le> snd y"
          by auto  
        from 1 and \<open>element_of_polychain y (z2 # zs)\<close> have "fst x' \<le> fst y" 
          using convex_hull_vertex_smallest_x2[OF \<open>polychain (z2 # zs)\<close>] chv3_eq_chv2 by auto  
        with case_three(4) and 7  \<open>x = x'\<close> have "(fst x = fst x'\<and> snd x \<le> snd x')" by auto 
        moreover with case_three(4) and 6 have "snd x' \<le> snd y" by auto
        ultimately have "snd x \<le> snd y" by auto }
      ultimately have "snd x \<le> snd y" by auto }
    ultimately have "snd x \<le> snd y" by auto }
  ultimately show "snd x \<le> snd y" by auto
qed
      
(* TODO: prove that the result of convex_hull_vertex2 is an extreme point of the convex hull. *)  
  
text \<open>Function @{term "pre_and_post_betw"} and @{term "pre_and_post"} are the functions to find 
the point connected before and after a point in the polychain. The former is the tail recursive 
part of the latter.\<close>  
  
fun pre_and_post_betw :: "(real2 \<times> real2) list \<Rightarrow> real2 \<Rightarrow> (real2 \<times> real2) option" where
  "pre_and_post_betw [] x = None" | 
  "pre_and_post_betw [z] x = None" | 
  "pre_and_post_betw (z1 # z2 # zs) x = (if snd z1 = x then Some (fst z1, snd z2) else 
                                                            pre_and_post_betw (z2 # zs) x)"  

lemma min_length_pre_post_betw_some:
  assumes "pre_and_post_betw zs x = Some pp"  
  shows "2 \<le> length zs"
  using assms 
  by (induction arbitrary:x pp rule:pre_and_post_betw.induct) (auto)

lemma pre_post_betw_component:
  assumes "pre_and_post_betw zs x = Some pp"
  shows  "\<exists>z1 z2 zs'. zs = z1 # z2 # zs'"
proof -
  from assms and min_length_pre_post_betw_some have "2 \<le> length zs" by auto    
  then obtain z1 and z2 and zs' where "zs = z1 # z2 # zs'" 
    by (metis assms option.distinct(1) pre_and_post_betw.elims)
  thus ?thesis by blast    
qed

theorem pre_post_betw_correctness:
  assumes "pre_and_post_betw zs x = Some pp"
  shows "\<exists>i. fst (zs ! i) = fst pp \<and> snd (zs ! i) = x \<and> snd (zs ! (i+1)) = snd pp"
  using assms
proof (induction arbitrary:pp rule:pre_and_post_betw.induct)
  case (1 x)
  then show ?case by auto
next
  case (2 z x)
  then show ?case by auto
next
  case (3 z1 z2 zs x)
  note case_three = this    
  consider "x = snd z1" | "x \<noteq> snd z1" by auto      
  then show ?case 
  proof (cases)
    case 1
    with case_three show ?thesis 
      by (metis add_gr_0 diff_add_inverse2 fst_conv less_one nth_Cons_0 nth_Cons_pos option.inject 
                                                                pre_and_post_betw.simps(3) snd_conv)
  next
    case 2
    note subcase_two = \<open>x \<noteq> snd z1\<close>
    with case_three have "pre_and_post_betw (z1 # z2 # zs) x = pre_and_post_betw (z2 # zs) x"
      and 0: "pre_and_post_betw (z2 # zs) x = Some pp"
      by auto
    with \<open>pre_and_post_betw (z1 # z2 # zs) x = Some pp\<close> obtain z3 and zs' where "zs = z3 # zs'"
      using pre_post_betw_component[of "z2 # zs" "x" "pp"] by auto
    with case_three(1)[OF not_sym[OF subcase_two] 0] obtain i where 
      "fst ((z2 # zs) ! i) = fst pp \<and> snd ((z2 # zs) ! i) = x \<and> snd ((z2 # zs) ! (i + 1)) = snd pp"
      by blast
    hence 1: "fst ((z1 # z2 # zs) ! (i+1)) = fst pp \<and> snd ((z1#z2#zs) ! (i+1)) = x \<and> 
                                                                     snd ((z1#z2#zs) !(i+2))=snd pp"
      by auto
    thus ?thesis  by (metis (no_types, lifting) ab_semigroup_add_class.add_ac(1) one_add_one)
  qed
qed    

(* This function is not necessarily recursive. Avoid using pre_and_post.induct! *)
  
fun pre_and_post :: "(real2 \<times> real2) list \<Rightarrow> real2 \<Rightarrow> (real2 \<times> real2) option" where
  "pre_and_post [] x = None" | 
  "pre_and_post [z] x = None" | 
  "pre_and_post (z1 # z2 # zs) x = (if fst z1 = x then Some (fst (last (z2 # zs)), snd z1) else 
                                                       pre_and_post_betw (z1 # z2 # zs) x)"

lemma min_length_pre_post_some:
  assumes "pre_and_post zs x = Some pp"  
  shows "2 \<le> length zs"
  using assms 
  by (induction arbitrary:x pp rule:pre_and_post.induct) (auto)

lemma pre_post_component:
  assumes "pre_and_post zs x = Some pp"
  shows  "\<exists>z1 z2 zs'. zs = z1 # z2 # zs'"
proof -
  from assms and min_length_pre_post_some have "2 \<le> length zs" by auto    
  then obtain z1 and z2 and zs' where "zs = z1 # z2 # zs'" 
    by (metis assms option.distinct(1) pre_and_post.elims)
  thus ?thesis by blast    
qed

text \<open>We prove the correctness of the @{term "pre_and_post"} here.\<close>
  
theorem pre_and_post_correctness1:
  assumes "pre_and_post zs x = Some pp"
  assumes "x \<noteq> fst (hd zs)"  
  shows "\<exists>i. fst (zs ! i) = fst pp \<and> snd (zs ! i) = x \<and> snd (zs ! (i + 1)) = snd pp"
  using assms
proof (induction zs arbitrary: x pp)
  case Nil
  then show ?case by auto
next
  case (Cons a zs)
  note case_cons = this
  from \<open>pre_and_post (a # zs) x = Some pp\<close> obtain z and zs' where "zs = z # zs'" 
    using pre_post_component by blast
  with \<open>x \<noteq> fst (hd (a #zs))\<close>  have "pre_and_post (a # zs) x = pre_and_post_betw (a # zs) x" by auto
  with \<open>pre_and_post (a # zs) x = Some pp\<close> obtain i where
    "fst ((a#zs) ! i) = fst pp \<and> snd ((a#zs) ! i) = x \<and> snd ((a#zs) ! (i+1)) = snd pp"
    using pre_post_betw_correctness by presburger
  then show ?case by auto
qed

theorem pre_and_post_correctness2:
  assumes "pre_and_post zs x = Some pp"
  assumes "x = fst (hd zs)"  
  shows "fst (last zs) = fst pp \<and> snd (hd zs) = snd pp"
  using assms
  by (metis (no_types, lifting) fst_conv last_ConsR list.sel(1) list.simps(3) option.inject 
                                                  pre_and_post.simps(3) pre_post_component snd_conv)    

theorem pre_post_betw_convex_hull_vertex:
  assumes "2 \<le> length zs"
  assumes "polychain zs"    
  assumes "convex_hull_vertex3 zs = Some x"   
  assumes "x \<noteq> fst (hd zs)"
  assumes "x \<noteq> snd (last zs)"  
  shows "\<exists>pp. pre_and_post_betw zs x = Some pp"
  using assms
proof (induction zs arbitrary:x rule:convex_hull_vertex3.induct)
  case 1
  then show ?case by auto
next
  case (2 z)
  then show ?case by auto
next
  case (3 z1 z2 zs)
  note case_three = this  
  obtain x' where "convex_hull_vertex3 (z2 # zs) = Some x'" using cons_convex_hull_vertex_some
    by blast
  with \<open>convex_hull_vertex3 (z1 # z2 # zs) = Some x\<close> have "x = min2D (fst z1) x'" by auto
  with \<open> x \<noteq> fst (hd (z1 # z2 # zs))\<close> have "x = x'" using min2D_D2 by fastforce    
  consider "x' = fst z2" | "x'\<noteq> fst z2" by blast  
  then show ?case 
  proof (cases)
    case 1
    with \<open>polychain (z1 # z2 # zs)\<close> have "x = snd z1" unfolding polychain_def using \<open>x = x'\<close> by auto  
    hence "pre_and_post_betw (z1 # z2 # zs) x = Some (fst z1, snd z2)" by auto                
    thus ?thesis by auto
  next
    case 2
    hence "x \<noteq> snd z1" using \<open>polychain (z1 # z2 # zs)\<close> unfolding polychain_def
      using \<open>x = x'\<close> by auto  
    obtain z3 and zs' where disj:"zs = z3 # zs' \<or> zs = []" by (meson last_in_set list.set_cases) 
    from \<open>x \<noteq> fst (hd (z1 # z2 # zs))\<close> \<open>x \<noteq> snd (last (z1 # z2 # zs))\<close> \<open>x \<noteq> snd z1\<close>
      have "zs \<noteq> []" 
        by (metis \<open>convex_hull_vertex3 (z2 # zs) = Some x'\<close> \<open>x = x'\<close> case_three(3) 
            convex_hull_vertex3.simps(2) last.simps last_ConsR list.simps(3) min2D_D2 nth_Cons_0 
            option.inject polychain_Cons)
    with disj have cons: "zs = z3 # zs'" by auto          
    from \<open>polychain (z1 # z2 # zs)\<close> have "polychain (z2 # zs)" by (simp add: polychain_Cons)
    from \<open>x \<noteq> snd (last (z1 # z2 # zs))\<close> and \<open>x = x'\<close> have neq: "x' \<noteq> snd (last (z2 # zs))" 
      by auto    
    from cons case_three(1)[OF _ \<open>polychain (z2 # zs)\<close> \<open>convex_hull_vertex3 (z2#zs) = Some x'\<close>] 2 neq
    obtain pp' where "pre_and_post_betw (z2 # zs) x' = Some pp'" by auto
    with \<open>x \<noteq> snd z1\<close> \<open>x = x'\<close> show ?thesis  by fastforce
  qed      
qed    
    
theorem pre_pos_convex_hull_vertex:
  assumes "2 \<le> length zs"
  assumes "polygon zs"    
  assumes "convex_hull_vertex3 zs = Some x"
  shows "\<exists>pp. pre_and_post zs x = Some pp"
proof (cases "x = fst (hd zs)")
  case False
  hence False':"x \<noteq> snd (last zs)" using \<open>polygon zs\<close> assms(1) unfolding polygon_def by auto  
  from assms(2) have "polychain zs" unfolding polygon_def by auto  
  from assms(1) obtain z1 and z2 and zs' where "zs = z1 # z2 # zs'" 
    by (metis (no_types, lifting) One_nat_def add.right_neutral add_Suc_right last_in_set 
        le_imp_less_Suc length_Cons less_Suc0 list.set_cases list.size(3) nat.simps(3) 
        one_add_one order_less_irrefl)  
  hence eq:"pre_and_post zs x = pre_and_post_betw zs x" using False by auto
  from pre_post_betw_convex_hull_vertex[OF assms(1) \<open>polychain zs\<close> assms(3)]
  obtain pp' where "pre_and_post_betw zs x = Some pp'" using False False' by auto
  with eq show ?thesis by fastforce
next
  case True
  from assms(1) obtain z1 and z2 and zs' where "zs = z1 # z2 # zs'" 
    by (metis (no_types, lifting) One_nat_def add.right_neutral add_Suc_right last_in_set 
        le_imp_less_Suc length_Cons less_Suc0 list.set_cases list.size(3) nat.simps(3) 
        one_add_one order_less_irrefl)   
  with True have "pre_and_post zs x = Some (fst (last (z2 # zs')), snd z1)" by auto      
  thus ?thesis by auto
qed    
  
text \<open>Two auxiliary lemmas for polychain.\<close>  

theorem polychain_snoc:
  assumes "polychain xs"
  assumes "snd (last xs) = fst a"
  shows "polychain (xs @ [a])"
  using assms by (simp add: polychain_appendI)  
      
theorem polychain_rev_map:
  assumes "polychain xs"
  shows "polychain (rev (map (\<lambda>(x,y). (y,x)) xs))"
  using assms  
proof (induction xs)
  case Nil
  then show ?case by auto
next
  case (Cons a xs)
  note case_cons = this
  hence "polychain xs" by (metis polychain_Cons polychain_Nil)
  with case_cons have 0: "polychain (rev (map (\<lambda>(x,y). (y,x)) xs))" by auto
  obtain x and xs' where "xs = [] \<or> xs = x # xs'" by (meson last_in_set list.set_cases)    
  moreover
  { assume "xs = []"
    hence ?case by auto }
  moreover
  { assume "xs = x # xs'"
    with \<open>polychain (a # xs)\<close> have "snd a = fst (hd xs)" unfolding polychain_def by auto      
    have 1: "rev (map (\<lambda>(x,y). (y,x)) (a # xs)) = rev (map (\<lambda>(x,y). (y,x)) xs) @ [(snd a, fst a)]"
      by (metis (no_types, lifting) case_prod_conv list.simps(9) prod.collapse rev_eq_Cons_iff 
                                                                                           rev_swap)
    have "polychain (rev (map (\<lambda>(x, y). (y, x)) xs) @ [(snd a, fst a)])" 
    proof (intro polychain_snoc)
      show "polychain (rev (map (\<lambda>(x, y). (y, x)) xs))" using 0 .
    next
      from \<open>xs = x # xs'\<close> have "xs \<noteq> []" by auto
      hence "snd (last (rev (map (\<lambda>(x,y). (y,x)) xs))) = fst (hd xs)"
        by (simp add: assms hd_map last_rev prod.case_eq_if)
      with \<open>snd a = fst (hd xs)\<close> 
        show " snd (last (rev (map (\<lambda>(x, y). (y, x)) xs))) = fst (snd a, fst a)"
        by auto
    qed 
    hence "polychain (rev (map (\<lambda>a. case a of (x, y) \<Rightarrow> (y, x)) (a # xs)))" 
      using 1 by auto
  }
  ultimately show ?case by auto   
qed   

text "Connecting two polychains"

(*
        xs
    *--<--*---<--*
    |
    | add a path
    |
    *-->--*--->--*
        ys
*)  
  
definition connect_polychain :: "(real2 \<times> real2) list \<Rightarrow> (real2 \<times> real2) list \<Rightarrow> (real2 \<times> real2) list"
  where 
  "connect_polychain xs ys \<equiv> (let end1 = snd (last xs); end2 = fst (hd ys) in 
                                         if end1 \<noteq> end2 then xs @ [(end1, end2)] @ ys else xs @ ys)"  

theorem length_connect_polychain:
  "length xs + length ys \<le> length (connect_polychain xs ys)"  
  unfolding connect_polychain_def Let_def 
  by (cases "snd (last xs) \<noteq> fst (hd ys)") (auto)    
  
theorem connect_polychain_preserve:
  assumes "polychain xs"
      and "polychain ys"
  assumes "xs \<noteq> []" 
      and "ys \<noteq> []"        
    shows "polychain (connect_polychain xs ys)"
  using assms 
proof (cases "snd (last xs) \<noteq> fst (hd ys)")
  case True
  hence "connect_polychain xs ys = xs @ [(snd (last xs), fst (hd ys))] @ ys" 
    unfolding connect_polychain_def by auto
  have "polychain ([(snd (last xs), fst (hd ys))] @ ys)" 
    by (rule polychain_appendI)(auto simp add:assms)
  hence "polychain (xs @ [(snd (last xs), fst (hd ys))] @ ys)" 
    by (auto intro:polychain_appendI simp add:assms)
  then show ?thesis unfolding connect_polychain_def Let_def using True by auto
next
  case False
  then show ?thesis unfolding connect_polychain_def Let_def using False 
    by (auto intro:polychain_appendI simp add:assms)
qed    
  
theorem connect_polychain_nonempty:
  assumes "polychain xs"
  assumes "polychain ys"
  assumes "xs \<noteq> []" 
  assumes "ys \<noteq> []"
  shows "connect_polychain xs ys \<noteq> []"
  using assms unfolding connect_polychain_def Let_def by auto
      
(*
        xs
    *--<--*---<---*
    |             |
    | make a loop |
    |             |
    *-->--*--->---*
        ys
*)  
  
definition close_polychain :: "(real2 \<times> real2) list \<Rightarrow> (real2 \<times> real2) list" where
  "close_polychain xs \<equiv> (let end1 = fst (hd xs); end2 = snd (last xs) in 
                                                   if end1 \<noteq> end2 then xs @ [(end2, end1)] else xs)"

theorem length_close_polychain:
  "length xs \<le> length (close_polychain xs)"
  unfolding close_polychain_def Let_def
  by (cases "fst (hd xs) \<noteq> snd (last xs)") (auto)  
        
theorem polychain_close_polychain: 
  assumes "xs \<noteq> []"
  assumes "polychain xs"  
  shows "polychain (close_polychain xs)"
  using assms
proof (induction xs)
  case Nil
  then show ?case by auto
next
  case (Cons a xs)
  note case_cons = this    
  show ?case unfolding close_polychain_def Let_def if_splits
  proof (rule conjI, rule_tac[!] impI)
    show "polychain ((a # xs) @ [(snd (last (a # xs)), fst (hd (a # xs)))])"      
      by (intro polychain_appendI)(auto simp add:case_cons)      
  next
    from case_cons show "polychain (a # xs)" by auto    
  qed    
qed
        
theorem polygon_close_polychain:
  assumes "xs \<noteq> []"
  assumes "polychain xs"
  shows "polygon (close_polychain xs)"
  using assms
proof (induction xs)
  case Nil
  then show ?case by auto
next
  case (Cons a xs)
  note case_cons = this  
  show ?case unfolding close_polychain_def Let_def if_splits
  proof (rule conjI, rule_tac[!] impI)
    assume True:"fst (hd (a # xs)) \<noteq> snd (last (a # xs))"
    from polychain_close_polychain[OF case_cons(2-3)] have "polychain (close_polychain (a # xs))" .
    thus " polygon ((a # xs) @ [(snd (last (a # xs)), fst (hd (a # xs)))])"
      unfolding close_polychain_def Let_def polygon_def using True by auto
  next
    assume "\<not> fst (hd (a # xs)) \<noteq> snd (last (a # xs))"
    thus "polygon (a # xs)" using \<open>polychain (a # xs)\<close> unfolding polygon_def using \<open>a # xs \<noteq> []\<close>
      by auto
  qed    
qed    
  
locale lanelet = le: lanelet_simple_boundary points_le + ri: lanelet_simple_boundary points_ri
  for points_le and points_ri +
  assumes non_intersecting: "\<forall>t \<in> {0..1}. le.curve_eq t \<noteq> ri.curve_eq t" 
begin  

text "Reversing the direction of the left polychain"  
  
definition reverse_le where
  "reverse_le \<equiv> rev (map (\<lambda>(x,y). (y,x)) points_le)"
  
theorem reverse_le_nonempty:
  "reverse_le \<noteq> []"  unfolding reverse_le_def using le.nonempty_points by auto

theorem polychain_reverse_le:
  "polychain reverse_le"
  unfolding reverse_le_def using polychain_rev_map le.poly_points by auto
           
definition lanelet_polygon where
  "lanelet_polygon \<equiv> close_polychain (connect_polychain reverse_le points_ri)"
  
theorem length_connect_polychain_reverse:
  "2 \<le> length (connect_polychain reverse_le points_ri)"
proof -
  from reverse_le_nonempty have 0: "1 \<le> length reverse_le"
    using linorder_le_less_linear by auto
  from ri.nonempty_points have "1 \<le> length points_ri"
    using linorder_le_less_linear by auto
  with 0 length_connect_polychain[of reverse_le points_ri] 
    show "2 \<le> length (connect_polychain reverse_le points_ri)" by auto
qed  
  
theorem min_length_lanelet_polygon:
  "2 \<le> length lanelet_polygon"
  unfolding lanelet_polygon_def using length_connect_polychain_reverse length_close_polychain
  order_trans by auto
    
theorem polychain_connect_polychain:
  "polychain (connect_polychain reverse_le points_ri)"
  using connect_polychain_preserve[OF polychain_reverse_le ri.poly_points reverse_le_nonempty 
    ri.nonempty_points] .
    
theorem connect_polychain_nonempty2:
  "connect_polychain reverse_le points_ri \<noteq> []"
  using connect_polychain_nonempty[OF polychain_reverse_le ri.poly_points reverse_le_nonempty 
    ri.nonempty_points] .
    
theorem polygon_lanelet_polygon:
  "polygon lanelet_polygon"
  using polygon_close_polychain[OF connect_polychain_nonempty2 polychain_connect_polychain] 
  unfolding lanelet_polygon_def .
      
theorem connect_reverse_le_points_ri_nonempty:
  "connect_polychain reverse_le points_ri \<noteq> []"
  using reverse_le_nonempty ri.nonempty_points
  unfolding connect_polychain_def Let_def by auto
    
theorem lanelet_polygon_nonempty:
  "lanelet_polygon \<noteq> []"
  using connect_reverse_le_points_ri_nonempty 
  unfolding lanelet_polygon_def close_polychain_def Let_def by auto

definition vertex_chain where
  "vertex_chain \<equiv> (case convex_hull_vertex3 lanelet_polygon of 
                    Some x \<Rightarrow> (case pre_and_post lanelet_polygon x of
                               Some (pre, post) \<Rightarrow> (pre, x, post)))"    
    
theorem chv_lanelet_polygon:
  "\<exists>x. convex_hull_vertex3 lanelet_polygon = Some x"
proof -
  obtain z and zs where "lanelet_polygon = z # zs" using lanelet_polygon_nonempty
    by (metis hd_Cons_tl)
  with cons_convex_hull_vertex_some show ?thesis by auto    
qed  
    
theorem pre_post_lanelet_polygon_chv:
  "\<exists>pre post. pre_and_post lanelet_polygon ((the \<circ> convex_hull_vertex3) lanelet_polygon) = 
                                                                                   Some (pre, post)"
  using chv_lanelet_polygon pre_pos_convex_hull_vertex[OF min_length_lanelet_polygon 
      polygon_lanelet_polygon] unfolding comp_def by auto
    
theorem 
  "\<exists>pre x post. vertex_chain = (pre, x, post)"
  unfolding vertex_chain_def using pre_post_lanelet_polygon_chv chv_lanelet_polygon by auto  
        
definition dir_right :: "bool" where
  "dir_right \<equiv> (case vertex_chain of (pre, x, post) \<Rightarrow> ccw' pre x post)"        
end
  


end