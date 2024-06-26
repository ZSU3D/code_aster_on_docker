! --------------------------------------------------------------------
! Copyright (C) 1991 - 2019 - EDF R&D - www.code-aster.org
! This file is part of code_aster.
!
! code_aster is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! code_aster is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with code_aster.  If not, see <http://www.gnu.org/licenses/>.
! --------------------------------------------------------------------
! person_in_charge: mickael.abbas at edf.fr
! aslint: disable=W1504
!
subroutine ndxprm(modelz, ds_material, carele    , ds_constitutive, ds_algopara,&
                  lischa, numedd     , numfix    , solveu         , ds_system  ,&
                  sddisc, sddyna     , ds_measure, numins         , fonact     ,&
                  valinc, solalg     , meelem    , measse     ,&
                  maprec, matass     , faccvg    , ldccvg)
!
use NonLin_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/infdbg.h"
#include "asterfort/isfonc.h"
#include "asterfort/ndxmat.h"
#include "asterfort/ndynlo.h"
#include "asterfort/nmchra.h"
#include "asterfort/nmcmat.h"
#include "asterfort/nmrinc.h"
#include "asterfort/nmtime.h"
#include "asterfort/nmxmat.h"
#include "asterfort/preres.h"
#include "asterfort/utmess.h"
#include "asterfort/nmrigi.h"
#include "asterfort/asmari.h"
#include "asterfort/nmchex.h"
!
type(NL_DS_AlgoPara), intent(in) :: ds_algopara
integer :: fonact(*)
character(len=*) :: modelz
type(NL_DS_Material), intent(in) :: ds_material
character(len=24) :: carele
type(NL_DS_Measure), intent(inout) :: ds_measure
character(len=24) :: numedd, numfix
type(NL_DS_Constitutive), intent(in) :: ds_constitutive
type(NL_DS_System), intent(in) :: ds_system
character(len=19) :: sddisc, sddyna, lischa, solveu
character(len=19) :: solalg(*), valinc(*)
character(len=19) :: meelem(*), measse(*)
integer :: numins
character(len=19) :: maprec, matass
integer :: faccvg, ldccvg
!
! --------------------------------------------------------------------------------------------------
!
! ROUTINE MECA_NON_LINE (CALCUL - UTILITAIRE)
!
! CALCUL DE LA MATRICE GLOBALE EN PREDICTION - CAS EXPLICITE
!
! --------------------------------------------------------------------------------------------------
!
! IN  MODELE : MODELE
! IN  NUMEDD : NUME_DDL (VARIABLE AU COURS DU CALCUL)
! IN  NUMFIX : NUME_DDL (FIXE AU COURS DU CALCUL)
! In  ds_material      : datastructure for material parameters
! IN  CARELE : CARACTERISTIQUES DES ELEMENTS DE STRUCTURE
! In  ds_constitutive  : datastructure for constitutive laws management
! IN  LISCHA : LISTE DES CHARGES
! IN  SDDYNA : SD POUR LA DYNAMIQUE
! IO  ds_measure       : datastructure for measure and statistics management
! In  ds_algopara      : datastructure for algorithm parameters
! IN  SOLVEU : SOLVEUR
! In  ds_system        : datastructure for non-linear system management
! IN  SDDISC : SD DISCRETISATION TEMPORELLE
! IN  NUMINS : NUMERO D'INSTANT
! IN  ITERAT : NUMERO D'ITERATION
! IN  VALINC : VARIABLE CHAPEAU POUR INCREMENTS VARIABLES
! IN  SOLALG : VARIABLE CHAPEAU POUR INCREMENTS SOLUTIONS
! IN  MEASSE : VARIABLE CHAPEAU POUR NOM DES MATR_ASSE
! IN  MEELEM : VARIABLE CHAPEAU POUR NOM DES MATR_ELEM
! OUT MATASS : MATRICE DE RESOLUTION ASSEMBLEE
! OUT MAPREC : MATRICE DE RESOLUTION ASSEMBLEE - PRECONDITIONNEMENT
! OUT FACCVG : CODE RETOUR FACTORISATION MATRICE GLOBALE
!                -1 : PAS DE FACTORISATION
!                 0 : CAS DU FONCTIONNEMENT NORMAL
!                 1 : MATRICE SINGULIERE
!                 2 : ERREUR LORS DE LA FACTORISATION
!                 3 : ON NE SAIT PAS SI SINGULIERE
! OUT LDCCVG : CODE RETOUR DE L'INTEGRATION DU COMPORTEMENT
!                -1 : PAS D'INTEGRATION DU COMPORTEMENT
!                 0 : CAS DU FONCTIONNEMENT NORMAL
!                 1 : ECHEC DE L'INTEGRATION DE LA LDC
!                 2 : ERREUR SUR LA NON VERIF. DE CRITERES PHYSIQUES
!                 3 : SIZZ PAS NUL POUR C_PLAN DEBORST
!
! --------------------------------------------------------------------------------------------------
!
    aster_logical :: reasma
    aster_logical :: lcrigi, lcfint, lcamor, larigi, lprem
    aster_logical :: lamor, l_neum_undead, lshima, lprmo
    character(len=16) :: metpre
    character(len=16) :: optrig, optamo
    integer :: ifm, niv, ibid
    integer :: iterat
    integer :: nb_matr
    character(len=19) :: rigid
    character(len=6) :: list_matr_type(20)
    character(len=16) :: list_calc_opti(20), list_asse_opti(20)
    aster_logical :: list_l_asse(20), list_l_calc(20)
!
! --------------------------------------------------------------------------------------------------
!
    call infdbg('MECANONLINE', ifm, niv)
    if (niv .ge. 2) then
        write (ifm,*) '<MECANONLINE> ... CALCUL MATRICE'
    endif
!
! - Initializations
!
    nb_matr              = 0
    list_matr_type(1:20) = ' '
    faccvg = -1
    ldccvg = -1
    iterat = 0
    lcamor = .false.
!
! - Active functionnalities
!
    lamor         = ndynlo(sddyna,'MAT_AMORT')
    lprmo         = ndynlo(sddyna,'PROJ_MODAL')
    l_neum_undead = isfonc(fonact,'NEUM_UNDEAD')
    lshima        = ndynlo(sddyna,'COEF_MASS_SHIFT')
    call nmchex(measse, 'MEASSE', 'MERIGI', rigid)
!
! - First step ?
!
    lprem = numins.le.1
!
! --- PARAMETRES
!
    metpre = ds_algopara%matrix_pred
    if (metpre .ne. 'TANGENTE') then
        call utmess('F', 'MECANONLINE5_1')
    endif
!
! --- CHOIX DE REASSEMBLAGE DE LA MATRICE GLOBALE
!
    reasma = .false.
    if (lprem) then
        if (lprmo) then
            reasma = .false.
        else
            reasma = .true.
        endif
    endif
!
! --- CHOIX DE REASSEMBLAGE DE L'AMORTISSEMENT
!
    if (lamor) then
        call nmchra(sddyna, .false._1, optamo, lcamor)
    endif
!
! --- OPTION DE CALCUL POUR MERIMO
!
    optrig = 'RIGI_MECA_TANG'
    lcfint = .false.
    lcrigi = .false.
    larigi = .false.
!
! --- SI ON DOIT RECALCULER L'AMORTISSEMENT DE RAYLEIGH
!
    if (lcamor) then
        lcrigi = .true.
    endif
!
! --- DECALAGE COEF_MASS_SHIFT AU PREMIER PAS DE TEMPS -> ON A BESOIN
! --- DE LA MATRICE DE RIGIDITE
!
    if (lshima .and. lprem) then
        lcrigi = .true.
        larigi = .true.
    endif
!
! --- CALCUL DES MATR-ELEM DE RIGIDITE
!
    if (lcrigi) then
        call nmrigi(modelz     , carele,&
                    ds_material, ds_constitutive,&
                    fonact     , iterat         , sddyna, ds_measure, ds_system,&
                    valinc     , solalg         ,&
                    optrig     , ldccvg)
    endif
!
! - Assembly internal forces/rigidity matrix
!
    if (larigi) then
        call asmari(fonact, meelem, ds_system, numedd, lischa, ds_algopara,&
                    rigid)
    endif
!
! --- CALCUL ET ASSEMBLAGE DES MATR-ELEM D'AMORTISSEMENT DE RAYLEIGH
!
    if (lcamor) then
        call nmcmat('MEAMOR', optamo, ' ', .true._1,&
                    .true._1, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                    list_l_calc, list_l_asse)
    endif
!
! --- CALCUL DES MATR-ELEM DES CHARGEMENTS
!
    if (l_neum_undead) then
        call nmcmat('MESUIV', ' ', ' ', .true._1,&
                    .false._1, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                    list_l_calc, list_l_asse)
    endif
!
! --- CALCUL ET ASSEMBLAGE DES MATR_ELEM DE LA LISTE
!
    if (nb_matr .gt. 0) then
        call nmxmat(modelz         , ds_material   , carele        ,&
                    ds_constitutive, sddisc        , numins        ,&
                    valinc         , solalg        , lischa        ,&
                    numedd         , numfix        , ds_measure    ,&
                    nb_matr        , list_matr_type, list_calc_opti,&
                    list_asse_opti , list_l_calc   , list_l_asse   ,&
                    meelem         , measse        , ds_system)
    endif
!
! --- ERREUR SANS POSSIBILITE DE CONTINUER
!
    if (ldccvg .eq. 1) then
        goto 999
    endif
!
! --- CALCUL DE LA MATRICE ASSEMBLEE GLOBALE
!
    if (reasma) then
        call ndxmat(fonact, lischa, numedd, sddyna, numins,&
                    meelem, measse, matass)
    endif
!
! --- FACTORISATION DE LA MATRICE ASSEMBLEE GLOBALE
!
    if (reasma) then
        call nmtime(ds_measure, 'Init'  , 'Factor')
        call nmtime(ds_measure, 'Launch', 'Factor')
        call preres(solveu, 'V', faccvg, maprec, matass,&
                    ibid, -9999)
        call nmtime(ds_measure, 'Stop', 'Factor')
        call nmrinc(ds_measure, 'Factor')
    endif
!
999 continue
!
end subroutine
