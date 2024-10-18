	clear all
	set more off
	capture log close

	*ssc install estout, replace
	*ssc install lassopack, replace

	cd R:\
	log using Covid_reg, t replace

	************************************************************************	
	* File name: Covid_repro
	* Author: Karsten Albæk 
	* Reproduces tables in paper "The importance etc."
	* Data for reproduction: Trust_COVID_Europe.dta 
	* 18-10-2024 Karsten Albæk
	************************************************************************/

	
	cd R:\Projekts\Covid19\CountryComp\Work_2023\Analysis\Log\Repro\
	cd 

	import excel "Trust_COVID_Europe.xlsx", firstrow
	
		
	ge lodead1 = log(dead1) 
	su lodead1 
	ge ldead1 = lodead1 - r(mean)
	drop lodead1 
	
* normalization of variables - confidence public institutions: 
* government, civil service, courts, police
* variables measured on 4-level scale 

local Conf = "TrGov TrCSer TrCourts TrPolice"

quietly foreach v of varlist `Conf'{
		su `v' 
		ge n`v'= -(`v'- r(mean))/r(sd)
	}

* normalization of variables - membership of organizations:
* religious, cultural, labour union, political party, envoronmental, 
* professional, sport, other

local Memb = "M_Church M_Cultur M_LabUni M_PolPar M_Enviro M_ProfAs M_SportA M_OtherG"

* normalization of other variables

replace T_Deaths = -T_Deaths  

local Other = "TrOtherA pop_dens age_65 gdp_per_cap Health_P LiPare T_Deaths"

quietly foreach v of varlist `Memb' `Other' {
		su `v' 
		ge n`v'= (`v'- r(mean))/r(sd)
	}

* principal component for confidence public institutions 

pca nTrGov nTrCSer nTrCourts nTrPolice 
predict pc1_pub, score

* principal component for membership variables 

pca nM_Church nM_Cultur nM_LabUni nM_PolPar nM_Enviro nM_ProfAs nM_SportA nM_OtherG 
predict pc1_mem, score

* principal component for health, housing and health efficiency variables

gen mnLiParent = -nLiParent 
gen mnHealth_P = -nHealth_P 
pca mnLiParent mnHealth_P nT_Deaths 
predict pc1_LHT, score

* normalization of principal components

foreach v of varlist pc1_pub pc1_LHT pc1_mem {
	su `v' 
	ge n`v'= (`v'- r(mean))/r(sd)
}


* Table 1 

regress ldead1 nTrOther npop_dens nage_65 , robust 
estimates store e1

regress ldead1 npc1_pub npop_dens nage_65 , robust 
estimates store e2

regress ldead1 nTrOther npc1_pub npop_dens nage_65 , robust 
estimates store e3

regress ldead1 npc1_mem npop_dens nage_65 , robust 
estimates store e4

regress ldead1 nTrOther npc1_mem npop_dens nage_65 , robust 
estimates store e5

estout e1 e2 e3 e4 e5, cells(b(star fmt(3)) se(par)) ///
	stats(r2 rmse aic bic N, fmt(3 2)) starlevels(* 0.10 ** 0.05 *** 0.01)

* Table 2 

regress ngdp_per_cap nTrOther , robust 
estimates store e1

regress nHealth_P ngdp_per_cap, robust 	
estimates store e2

regress nLiParent ngdp_per_cap, robust 	
estimates store e3

regress nT_Deaths ngdp_per_cap, robust 	
estimates store e4

regress ldead1 nHealth_P npop_dens nage_65 , robust 
estimates store e5

regress ldead1 nLiParent npop_dens nage_65 , robust 
estimates store e6

regress ldead1 nT_Deaths npop_dens nage_65 , robust 
estimates store e7

estout e1 e2 e3 e4 e5 e6 e7 , cells(b(star fmt(3)) se(par)) ///
	stats(r2 rmse aic bic N, fmt(3 2)) starlevels(* 0.10 ** 0.05 *** 0.01)

* Table 3 

regress ldead1 nTrOther nLiParent nT_Deaths npop_dens nage_65 , robust 
estimates store e1

regress ldead1 nTrOther nLiParent nHealth_P npop_dens nage_65 , robust 
estimates store e2

regress ldead1 nTrOther nHealth_P nT_Deaths npop_dens nage_65 , robust 
estimates store e3

regress ldead1 nTrOther nLiParent nHealth_P nT_Deaths npop_dens nage_65 , robust 
estimates store e4

regress ldead1 nTrOther npc1_LHT npop_dens nage_65 , robust 
estimates store e6

regress ldead1 nTrOther ngdp_per_cap npop_dens nage_65 , robust 
estimates store e7

estout e1 e2 e3 e4 e6 e7 , cells(b(star fmt(3)) se(par)) ///
	stats(r2 rmse aic bic N, fmt(3 2)) starlevels(* 0.10 ** 0.05 *** 0.01)
	
* ridge regression (column 5 in Table 3)

lasso2 ldead1 nTrOther nLiParent nT_Deaths nHealth_P npop_dens nage_65 , alpha(0) 
lasso2, lic(ebic)

* Table 4. growth regressions 

ge dead2_1000 = dead2/1000 

regress gnp_g dead2 , robust 
estimates store e0
regress gnp_g dead2_1000, robust 
estimates store e1
regress gnp_g dead2_1000 if Weu == 0 , robust 
estimates store e5
regress gnp_g dead2_1000 if Weu == 1 , robust 
estimates store e6
regress gnp_g dead2_1000 Weu , robust 
estimates store e7

estout e1 e7 e5 e6, cells(b(star fmt(3)) se(par)) ///
	stats(r2 rmse aic bic N, fmt(3 2)) starlevels(* 0.10 ** 0.05 *** 0.01)

* Table 5. specification tests

regress nHealth_P ngdp_per_cap nTrOther , robust 	
estimates store e1
regress nLiParent ngdp_per_cap nTrOther , robust 	
estimates store e2
regress nT_Deaths ngdp_per_cap nTrOther , robust 	
estimates store e3

estout e1 e2 e3 , cells(b(star fmt(3)) se(par)) ///
	stats(r2 rmse aic bic N, fmt(3 2)) starlevels(* 0.10 ** 0.05 *** 0.01)


