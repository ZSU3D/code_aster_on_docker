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
subroutine nmcoma(mesh          , modelz         , ds_material,&
                  cara_elem     , ds_constitutive, ds_algopara,&
                  lischa        , numedd         , numfix     ,&
                  solveu        , ds_system      , sddisc     ,&
                  sddyna        , ds_print       , ds_measure ,&
                  ds_algorom    , numins         , iter_newt  ,&
                  list_func_acti, ds_contact     , hval_incr  ,&
                  hval_algo     , meelem         , measse     ,&
                  maprec        , matass         , faccvg     ,&
                  ldccvg        , sdnume)
!
use NonLin_Datastructure_type
use Rom_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/assert.h"
#include "asterfort/infdbg.h"
#include "asterfort/isfonc.h"
#include "asterfort/ndynlo.h"
#include "asterfort/nmaint.h"
#include "asterfort/nmelcm.h"
#include "asterfort/nmchex.h"
#include "asterfort/nmchoi.h"
#include "asterfort/nmchra.h"
#include "asterfort/nmchrm.h"
#include "asterfort/nmcmat.h"
#include "asterfort/nmfint.h"
#include "asterfort/nmimck.h"
#include "asterfort/nmmatr.h"
#include "asterfort/nmrenu.h"
#include "asterfort/nmrinc.h"
#include "asterfort/nmtime.h"
#include "asterfort/nmxmat.h"
#include "asterfort/preres.h"
#include "asterfort/mtdscr.h"
#include "asterfort/romAlgoNLCorrEFMatrixModify.h"
#include "asterfort/asmari.h"
#include "asterfort/nmrigi.h"
#include "asterfort/utmess.h"
!
type(NL_DS_AlgoPara), intent(in) :: ds_algopara
integer :: list_func_acti(*)
character(len=*) :: modelz
character(len=8), intent(in) :: mesh
character(len=24) :: cara_elem
type(NL_DS_Measure), intent(inout) :: ds_measure
character(len=24) :: numedd, numfix
type(NL_DS_Constitutive), intent(in) :: ds_constitutive
type(ROM_DS_AlgoPara), intent(in) :: ds_algorom
type(NL_DS_Material), intent(in) :: ds_material
type(NL_DS_System), intent(in) :: ds_system
character(len=19) :: sddisc, sddyna, lischa, solveu, sdnume
type(NL_DS_Print), intent(inout) :: ds_print
character(len=19) :: meelem(*)
character(len=19) :: hval_algo(*), hval_incr(*)
character(len=19) :: measse(*)
integer :: numins, iter_newt
type(NL_DS_Contact), intent(inout) :: ds_contact
character(len=19) :: maprec, matass
integer :: faccvg, ldccvg
!
! --------------------------------------------------------------------------------------------------
!
! ROUTINE MECA_NON_LINE (CALCUL - UTILITAIRE)
!
! CALCUL DE LA MATRICE GLOBALE EN CORRECTION
!
! --------------------------------------------------------------------------------------------------
!
! IN  MODELE : MODELE
! IN  NUMEDD : NUME_DDL (VARIABLE AU COURS DU CALCUL)
! IN  NUMFIX : NUME_DDL (FIXE AU COURS DU CALCUL)
! IN  CARELE : CARACTERISTIQUES DES ELEMENTS DE STRUCTURE
! In  ds_material      : datastructure for material parameters
! In  ds_constitutive  : datastructure for constitutive laws management
! IN  LISCHA : LISTE DES CHARGES
! IO  ds_contact       : datastructure for contact management
! IN  SDDYNA : SD POUR LA DYNAMIQUE
! In  ds_algopara      : datastructure for algorithm parameters
! IN  SOLVEU : SOLVEUR
! IN  SDDISC : SD DISCRETISATION TEMPORELLE
! IO  ds_print         : datastructure for printing parameters
! IO  ds_measure       : datastructure for measure and statistics management
! In  ds_algorom       : datastructure for ROM parameters
! In  ds_system        : datastructure for non-linear system management
! IN  NUMINS : NUMERO D'INSTANT
! IN  ITERAT : NUMERO D'ITERATION
! IN  VALINC : VARIABLE CHAPEAU POUR INCREMENTS VARIABLES
! IN  SOLALG : VARIABLE CHAPEAU POUR INCREMENTS SOLUTIONS
! IN  MEASSE : VARIABLE CHAPEAU POUR NOM DES MATR_ASSE
! IN  MEELEM : VARIABLE CHAPEAU POUR NOM DES MATR_ELEM
! OUT LFINT  : .TRUE. SI FORCES INTERNES CALCULEES
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
    aster_logical :: reasma, lcamor, l_diri_undead, l_rom, l_cont_elem
    aster_logical :: ldyna, lamor, l_neum_undead, lcrigi, lcfint, larigi
    character(len=16) :: metcor, metpre
    character(len=16) :: optrig, optamo
    character(len=19) :: matr_elem, rigid
    character(len=24) :: model
    aster_logical :: renume
    integer :: ifm, niv
    integer :: nb_matr, ibid
    character(len=6) :: list_matr_type(20)
    character(len=16) :: list_calc_opti(20), list_asse_opti(20)
    aster_logical :: list_l_asse(20), list_l_calc(20)
!
! --------------------------------------------------------------------------------------------------
!
    call infdbg('MECANONLINE', ifm, niv)
    if (niv .ge. 2) then
        call utmess('I', 'MECANONLINE13_68')
    endif
!
! - Initializations
!
    call nmchex(measse, 'MEASSE', 'MERIGI', rigid)
    nb_matr              = 0
    list_matr_type(1:20) = ' '
    model = modelz
    faccvg = -1
    ldccvg = -1
    renume = ASTER_FALSE
    lcamor = ASTER_FALSE
!
! - Active functionnalites
!
    ldyna         = ndynlo(sddyna,'DYNAMIQUE')
    lamor         = ndynlo(sddyna,'MAT_AMORT')
    l_rom         = isfonc(list_func_acti,'ROM')
    l_neum_undead = isfonc(list_func_acti,'NEUM_UNDEAD')
    l_diri_undead = isfonc(list_func_acti,'DIRI_UNDEAD')
    l_cont_elem   = isfonc(list_func_acti,'ELT_CONTACT')
!
! --- RE-CREATION DU NUME_DDL OU PAS
!
    call nmrenu(modelz, list_func_acti, lischa, ds_contact, numedd, renume)
!
! --- CHOIX DE REASSEMBLAGE DE LA MATRICE GLOBALE
!
    call nmchrm('CORRECTION', ds_algopara, list_func_acti, sddisc, sddyna,&
                numins      , iter_newt  , ds_contact    , metpre, metcor,&
                reasma)
!
! --- CHOIX DE REASSEMBLAGE DE L'AMORTISSEMENT
!
    if (lamor) then
        call nmchra(sddyna, renume, optamo, lcamor)
    endif
!
! --- OPTION DE CALCUL POUR MERIMO
!
    call nmchoi('CORRECTION', sddyna, numins, list_func_acti, metpre,&
                metcor      , reasma, lcamor, optrig        , lcrigi,&
                larigi      , lcfint)
!
! - Compute internal forces
!
    if (lcfint) then
        call nmfint(model         , cara_elem      ,&
                    ds_material   , ds_constitutive,&
                    list_func_acti, iter_newt      , ds_measure, ds_system,&
                    hval_incr     , hval_algo      ,&
                    ldccvg        , sddyna)
    endif
!
! --- ERREUR SANS POSSIBILITE DE CONTINUER
!
    if (ldccvg .eq. 1) then
        goto 999
    endif
!
! - Assemble internal forces
!
    if (lcfint) then
        lcfint = ASTER_FALSE
        call nmaint(numedd, list_func_acti, sdnume, ds_system)
    endif
!
! - Compute matrices for contact
!
    if (l_cont_elem) then
        call nmchex(meelem, 'MEELEM', 'MEELTC', matr_elem)
        call nmelcm(mesh           , model     ,&
                    ds_material    , ds_contact,&
                    ds_constitutive, ds_measure,&
                    hval_incr      , hval_algo ,&
                    matr_elem)
    endif
!
! - Update dualized matrix for non-linear Dirichlet boundary conditions (undead)
!
    if (l_neum_undead) then
        call nmcmat('MESUIV', ' ', ' ', ASTER_TRUE,&
                    ASTER_FALSE, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                    list_l_calc, list_l_asse)
    endif
!
! --- ASSEMBLAGE DES MATR-ELEM DE RIGIDITE
!
    if (larigi) then
        call asmari(list_func_acti, meelem, ds_system, numedd, lischa, ds_algopara,&
                    rigid)
    endif
!
! --- CALCUL DES MATR-ELEM D'AMORTISSEMENT DE RAYLEIGH A CALCULER
! --- NECESSAIRE SI MATR_ELEM RIGIDITE CHANGE !
!
    if (lcamor) then
        call nmcmat('MEAMOR', optamo, ' ', ASTER_TRUE,&
                    ASTER_TRUE, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                    list_l_calc, list_l_asse)
    endif
!
! - Update dualized relations for non-linear Dirichlet boundary conditions (undead)
!
    if (l_diri_undead) then
        call nmcmat('MEDIRI', ' ', ' ', ASTER_TRUE,&
                    ASTER_FALSE, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                    list_l_calc, list_l_asse)
    endif
!
! --- RE-CREATION MATRICE MASSE SI NECESSAIRE (NOUVEAU NUME_DDL)
!
    if (renume) then
        if (ldyna) then
            call nmcmat('MEMASS', ' ', ' ', ASTER_FALSE,&
                        ASTER_TRUE, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                        list_l_calc, list_l_asse)
        endif
        ASSERT(reasma)
    endif
!
! --- CALCUL ET ASSEMBLAGE DES MATR_ELEM DE LA LISTE
!
    if (nb_matr .gt. 0) then
        call nmxmat(modelz         , ds_material   , cara_elem     ,&
                    ds_constitutive, sddisc        , numins        ,&
                    hval_incr      , hval_algo     , lischa        ,&
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
        call nmmatr('CORRECTION', list_func_acti, lischa, numedd, sddyna,&
                    numins      , ds_contact    , meelem, measse, matass)
    endif
!
! - Set matrix type in convergence table
!
    if (reasma) then
        call nmimck(ds_print, 'MATR_ASSE', metcor, ASTER_TRUE)
    else
        call nmimck(ds_print, 'MATR_ASSE', metcor, ASTER_FALSE)
    endif
!
! --- FACTORISATION DE LA MATRICE ASSEMBLEE GLOBALE
!
    if (reasma) then
        call nmtime(ds_measure, 'Init', 'Factor')
        call nmtime(ds_measure, 'Launch', 'Factor')
        if (l_rom .and. ds_algorom%phase .eq. 'HROM') then
            call mtdscr(matass)
        elseif (l_rom .and. ds_algorom%phase .eq. 'CORR_EF') then
            call mtdscr(matass)
            call romAlgoNLCorrEFMatrixModify(numedd, matass, ds_algorom)
            call preres(solveu, 'V', faccvg, maprec, matass, ibid, -9999)
        else
            call preres(solveu, 'V', faccvg, maprec, matass, ibid, -9999)
        endif
        call nmtime(ds_measure, 'Stop', 'Factor')
        call nmrinc(ds_measure, 'Factor')
    endif
!
999 continue
!
end subroutine
