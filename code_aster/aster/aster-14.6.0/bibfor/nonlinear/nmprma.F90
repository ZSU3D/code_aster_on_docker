! --------------------------------------------------------------------
! Copyright (C) 1991 - 2020 - EDF R&D - www.code-aster.org
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
subroutine nmprma(mesh       , modelz     , ds_material, carele    , ds_constitutive,&
                  ds_algopara, lischa     , numedd    , numfix         , solveu, ds_system,&
                  ds_print   , ds_measure , ds_algorom, sddisc         ,&
                  sddyna     , numins     , fonact    , ds_contact     ,&
                  valinc     , solalg     , meelem    , measse,&
                  maprec     , matass     , faccvg    , ldccvg)
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
#include "asterfort/nmelcm.h"
#include "asterfort/nmchoi.h"
#include "asterfort/nmchra.h"
#include "asterfort/nmchrm.h"
#include "asterfort/nmcmat.h"
#include "asterfort/nmimck.h"
#include "asterfort/nmmatr.h"
#include "asterfort/echmat.h"
#include "asterfort/nmrenu.h"
#include "asterfort/nmrinc.h"
#include "asterfort/nmtime.h"
#include "asterfort/nmxmat.h"
#include "asterfort/preres.h"
#include "asterfort/mtdscr.h"
#include "asterfort/cfdisl.h"
#include "asterfort/sdmpic.h"
#include "asterfort/dismoi.h"
#include "asterfort/nmchex.h"
#include "asterfort/utmess.h"
#include "asterfort/asmari.h"
#include "asterfort/nmrigi.h"
#include "asterfort/romAlgoNLCorrEFMatrixModify.h"
!
type(NL_DS_AlgoPara), intent(in) :: ds_algopara
integer :: fonact(*)
character(len=8), intent(in) :: mesh
character(len=*) :: modelz
character(len=24) :: carele
type(NL_DS_Material), intent(in) :: ds_material
type(NL_DS_Constitutive), intent(in) :: ds_constitutive
type(NL_DS_Measure), intent(inout) :: ds_measure
type(NL_DS_Print), intent(inout) :: ds_print
type(ROM_DS_AlgoPara), intent(in) :: ds_algorom
character(len=24) :: numedd, numfix
character(len=19) :: sddisc, sddyna, lischa, solveu
character(len=19) :: solalg(*), valinc(*)
character(len=19) :: meelem(*), measse(*)
type(NL_DS_System), intent(in) :: ds_system
integer :: numins
type(NL_DS_Contact), intent(inout) :: ds_contact
character(len=19) :: maprec, matass
character(len=8) :: partit
aster_logical :: ldist
integer :: faccvg, ldccvg
!
! --------------------------------------------------------------------------------------------------
!
! ROUTINE MECA_NON_LINE (CALCUL - UTILITAIRE)
!
! CALCUL DE LA MATRICE GLOBALE EN PREDICTION
!
! --------------------------------------------------------------------------------------------------
!
! IN  MODELE : MODELE
! IN  NUMEDD : NUME_DDL (VARIABLE AU COURS DU CALCUL)
! IN  NUMFIX : NUME_DDL (FIXE AU COURS DU CALCUL)
! IN  CARELE : CARACTERISTIQUES DES ELEMENTS DE STRUCTURE
! In  ds_constitutive  : datastructure for constitutive laws management
! In  ds_material      : datastructure for material parameters
! IN  LISCHA : LISTE DES CHARGES
! IO  ds_contact       : datastructure for contact management
! IO  ds_print         : datastructure for printing parameters
! IN  SDDYNA : SD POUR LA DYNAMIQUE
! IO  ds_measure       : datastructure for measure and statistics management
! In  ds_algopara      : datastructure for algorithm parameters
! In  ds_algorom       : datastructure for ROM parameters
! In  ds_system        : datastructure for non-linear system management
! IN  SOLVEU : SOLVEUR
! IN  SDDISC : SD DISCRETISATION TEMPORELLE
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
    aster_logical :: reasma, renume
    aster_logical :: lcrigi, lcfint, lcamor, larigi
    aster_logical :: ldyna, lamor, l_neum_undead, l_diri_undead, l_rom, l_cont_elem
    character(len=16) :: metcor, metpre
    character(len=16) :: optrig, optamo
    character(len=19) :: matr_elem, rigid
    integer :: ifm, niv, ibid
    integer :: iterat
    integer :: nb_matr
    character(len=6) :: list_matr_type(20)
    character(len=16) :: list_calc_opti(20), list_asse_opti(20)
    aster_logical :: list_l_asse(20), list_l_calc(20)
    aster_logical :: l_contact_adapt,l_cont_cont
    real(kind=8) ::  minmat, maxmat,exponent_val
!
! --------------------------------------------------------------------------------------------------
!
    call infdbg('MECANONLINE', ifm, niv)
    if (niv .ge. 2) then
        call utmess('I', 'MECANONLINE13_35')
    endif
!
! - Active functionnalites
!
    ldyna         = ndynlo(sddyna,'DYNAMIQUE')
    lamor         = ndynlo(sddyna,'MAT_AMORT')
    l_neum_undead = isfonc(fonact,'NEUM_UNDEAD')
    l_diri_undead = isfonc(fonact,'DIRI_UNDEAD')
    l_rom         = isfonc(fonact,'ROM')
    l_cont_elem   = isfonc(fonact,'ELT_CONTACT')
!
! - Initializations
!
    call nmchex(measse, 'MEASSE', 'MERIGI', rigid)
    nb_matr              = 0
    list_matr_type(1:20) = ' '
    faccvg = -1
    ldccvg = -1
    iterat = 0
    lcamor = ASTER_FALSE
!
! --- RE-CREATION DU NUME_DDL OU PAS
!
    call nmrenu(modelz, fonact, lischa, ds_contact, numedd,&
                renume)
!
! --- CHOIX DE REASSEMBLAGE DE LA MATRICE GLOBALE
!
    call nmchrm('PREDICTION', ds_algopara, fonact, sddisc, sddyna,&
                numins, iterat, ds_contact, metpre, metcor,&
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
    call nmchoi('PREDICTION', sddyna, numins, fonact, metpre,&
                metcor, reasma, lcamor, optrig, lcrigi,&
                larigi, lcfint)
!
    if (lcfint) then
        ASSERT(.false.)
    endif
!
! - Compute matrices for contact
!
    if (l_cont_elem) then
        call nmchex(meelem, 'MEELEM', 'MEELTC', matr_elem)
        call nmelcm(mesh       , modelz    ,&
                    ds_material, ds_contact, ds_constitutive, ds_measure,&
                    valinc     , solalg    ,&
                    matr_elem)
    endif
!
! - Compute rigidity matrix
!
    if (lcrigi) then
        call nmrigi(modelz     , carele         ,&
                    ds_material, ds_constitutive, &
                    fonact     , iterat         , sddyna, ds_measure, ds_system,&
                    valinc     , solalg,&
                    optrig     , ldccvg)
        if (larigi) then
            call asmari(fonact, meelem, ds_system, numedd, lischa, ds_algopara,&
                        rigid)
        endif
    endif
!
! - Update dualized matrix for non-linear Dirichlet boundary conditions (undead)
!
    if (l_diri_undead .and. (metpre.ne.'EXTRAPOLE')) then
        call nmcmat('MEDIRI', ' ', ' ', ASTER_TRUE,&
                    ASTER_FALSE, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                    list_l_calc, list_l_asse)
    endif
!
! --- CALCUL ET ASSEMBLAGE DES MATR-ELEM D'AMORTISSEMENT DE RAYLEIGH
!
    if (lcamor) then
        call nmcmat('MEAMOR', optamo, ' ', ASTER_TRUE,&
                    ASTER_TRUE, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                    list_l_calc, list_l_asse)
    endif
!
! --- CALCUL DES MATR-ELEM DES CHARGEMENTS
!
    if (l_neum_undead .and. (metpre.ne.'EXTRAPOLE')) then
        call nmcmat('MESUIV', ' ', ' ', ASTER_TRUE,&
                    ASTER_FALSE, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                    list_l_calc, list_l_asse)
    endif
!
! --- RE-CREATION MATRICE MASSE SI NECESSAIRE (NOUVEUA NUME_DDL
!
    if (renume) then
        if (ldyna) then
            call nmcmat('MEMASS', ' ', ' ', ASTER_FALSE,&
                        ASTER_TRUE, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                        list_l_calc, list_l_asse)
        endif
        if (.not.reasma) then
            ASSERT(.false.)
        endif
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
    if (ldccvg .eq. 1) goto 999
!
! --- CALCUL DE LA MATRICE ASSEMBLEE GLOBALE
!
    if (reasma) then
        call nmmatr('PREDICTION', fonact    , lischa, numedd, sddyna,&
                    numins      , ds_contact, meelem, measse, matass)
        call nmimck(ds_print, 'MATR_ASSE', metpre, ASTER_TRUE)
    else
        call nmimck(ds_print, 'MATR_ASSE', ' '   , ASTER_FALSE)
    endif
    l_cont_cont         = isfonc(fonact,'CONT_CONTINU')
    if (l_cont_cont) then
        minmat=0.0
        maxmat=0.0
        exponent_val=0.0
    !   -- Avant la factorisation et pour le cas ou il y a du contact continu avec adaptation de
    !      coefficient
    !   -- On cherche le coefficient optimal pour eviter une possible singularite de matrice
    !   -- La valeur est estimee une seule fois a la premiere prediction du premier pas de
    !      temps pour l'etape de calcul
    !   -- Cette valeur estimee est passee directement a mmchml_c sans passer par mmalgo car
    !   -- a la premiere iteration on ne passe pas par mmalgo
        l_contact_adapt = cfdisl(ds_contact%sdcont_defi,'EXIS_ADAP')
!            write (6,*) "l_contact_adapt", &
!                l_contact_adapt,ds_contact%update_init_coefficient
        if ((nint(ds_contact%update_init_coefficient) .eq. 0) .and. l_contact_adapt) then
            call dismoi('PARTITION', modelz, 'MODELE', repk=partit)
            ldist = partit .ne. ' '
            call echmat(matass, ldist, minmat, maxmat)
            ds_contact%max_coefficient = maxmat
            if (abs(log(minmat)) .ne. 0.0) then

                if (abs(log(maxmat))/abs(log(minmat)) .lt. 4.0) then
!                     Le rapport d'arete max/min est
!  un bon compromis pour initialiser le coefficient
                    ds_contact%estimated_coefficient =&
                    ((1.D3*ds_contact%arete_max)/(1.D-2*ds_contact%arete_min))
                    ds_contact%update_init_coefficient = 1.0
                else
                    exponent_val = min(abs(log(minmat)),abs(log(maxmat)))/10
                    ds_contact%estimated_coefficient = 10**(exponent_val)
                    ds_contact%update_init_coefficient = 1.0
                endif
            else
               ds_contact%estimated_coefficient = 1.d16*ds_contact%arete_min
                    ds_contact%update_init_coefficient = 1.0
            endif
!             write (6,*) "min,max,coef estime,abs(log(maxmat))/abs(log(minmat))", &
!                 minmat,maxmat,ds_contact%estimated_coefficient,abs(log(maxmat))/abs(log(minmat))
        endif
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
            if (niv .ge. 2) then
                call utmess('I', 'MECANONLINE13_42')
            endif
        else
            call preres(solveu, 'V', faccvg, maprec, matass, ibid, -9999)
            if (niv .ge. 2) then
                call utmess('I', 'MECANONLINE13_42')
            endif
        endif
        call nmtime(ds_measure, 'Stop', 'Factor')
        call nmrinc(ds_measure, 'Factor')
    endif
!
999 continue
!
end subroutine
