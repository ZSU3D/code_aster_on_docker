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
!
subroutine nminmc(fonact, lischa     , sddyna     , modele, ds_constitutive,&
                  numedd, numfix     , solalg     ,&
                  valinc, ds_material, carele     , sddisc, ds_measure     ,&
                  meelem, measse     , ds_system)
!
use NonLin_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/infdbg.h"
#include "asterfort/isfonc.h"
#include "asterfort/ndynlo.h"
#include "asterfort/nmcmat.h"
#include "asterfort/nmxmat.h"
#include "asterfort/utmess.h"
#include "asterfort/nmrigi.h"
!
integer :: fonact(*)
character(len=19) :: lischa, sddyna
character(len=24) :: numedd, numfix
type(NL_DS_Constitutive), intent(in) :: ds_constitutive
type(NL_DS_Material), intent(in) :: ds_material
character(len=24) :: modele
character(len=24) :: carele
character(len=19) :: meelem(*), measse(*)
type(NL_DS_System), intent(in) :: ds_system
character(len=19) :: solalg(*), valinc(*)
character(len=19) :: sddisc
type(NL_DS_Measure), intent(inout) :: ds_measure
!
! ----------------------------------------------------------------------
!
! ROUTINE MECA_NON_LINE (CALCUL)
!
! PRE-CALCUL DES MATRICES ELEMENTAIRES CONSTANTES AU COURS DU CALCUL
!
! ----------------------------------------------------------------------
!
! IN  FONACT : FONCTIONNALITES ACTIVEES (VOIR NMFONC)
! IN  SDDYNA : SD DYNAMIQUE
! IN  MODELE : NOM DU MODELE
! IN  NUMEDD : NUME_DDL (VARIABLE AU COURS DU CALCUL)
! IN  NUMFIX : NUME_DDL (FIXE AU COURS DU CALCUL)
! IN  LISCHA : LISTE DES CHARGEMENTS
! IN  VALINC : VARIABLE CHAPEAU POUR INCREMENTS VARIABLES
! IN  SOLALG : VARIABLE CHAPEAU POUR DEPLACEMENTS
! In  ds_constitutive  : datastructure for constitutive laws management
! In  ds_material      : datastructure for material parameters
! IN  CARELE : CARACTERISTIQUES DES ELEMENTS DE STRUCTURE
! IN  SDDISC : SD DISCRETISATION TEMPORELLE
! IO  ds_measure       : datastructure for measure and statistics management
! OUT MEELEM : MATRICES ELEMENTAIRES
! In  ds_system        : datastructure for non-linear system management
! OUT MEASSE : MATRICES ASSEMBLEES
!
! ----------------------------------------------------------------------
!
    character(len=16) :: opmass, oprigi
    aster_logical :: lmacr, ldyna, lexpl
    aster_logical :: lamor, lktan, lelas, lvarc, lcfint, lamra
    integer :: ifm, niv
    integer :: numins, iterat, ldccvg
    integer :: nb_matr
    character(len=16) :: optrig, optamo
    character(len=6) :: list_matr_type(20)
    character(len=16) :: list_calc_opti(20), list_asse_opti(20)
    aster_logical :: list_l_asse(20), list_l_calc(20)
!
! ----------------------------------------------------------------------
!
    call infdbg('MECANONLINE', ifm, niv)
    if (niv .ge. 2) then
        call utmess('I','MECANONLINE13_18')
    endif
!
! --- FONCTIONNALITES ACTIVEES
!
    lmacr = isfonc(fonact,'MACR_ELEM_STAT')
    ldyna = ndynlo(sddyna,'DYNAMIQUE')
    lexpl = ndynlo(sddyna,'EXPLICITE')
    lvarc = isfonc(fonact,'EXI_VARC' )
    lamor = ndynlo(sddyna,'MAT_AMORT')
    lktan = ndynlo(sddyna,'RAYLEIGH_KTAN')
    lamra = ndynlo(sddyna,'AMOR_RAYLEIGH')
!
! - Initializations
!
    nb_matr              = 0
    list_matr_type(1:20) = ' '
    lelas                = ASTER_FALSE
    lcfint               = ASTER_FALSE
    ldccvg               = -1
    if (lamra .and. .not.lktan) then
        lelas = ASTER_TRUE
    endif
!
! --- INSTANT INITIAL
!
    numins = 1
!
! --- MATRICE DE RIGIDITE ASSOCIEE AUX LAGRANGE
!
    if (niv .ge. 2) then
        call utmess('I','MECANONLINE13_19')
    endif
    call nmcmat('MEDIRI', ' ', ' ', ASTER_TRUE,&
                ASTER_FALSE, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                list_l_calc, list_l_asse)
!
! --- MATRICE DE MASSE
!
    if (ldyna) then
        if (niv .ge. 2) then
            call utmess('I','MECANONLINE13_20')
        endif
        if (lexpl) then
            if (ndynlo(sddyna,'MASS_DIAG')) then
                opmass = 'MASS_MECA_EXPLI'
            else
                opmass = 'MASS_MECA'
            endif
        else
            opmass = 'MASS_MECA'
        endif
        call nmcmat('MEMASS', opmass, ' ', ASTER_TRUE,&
                    ASTER_FALSE, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                    list_l_calc, list_l_asse)
!
    endif
!
! --- MATRICES DES MACRO-ELEMENTS
! --- ON DOIT ASSEMBLER _AVANT_ ACCEL0
!
    if (lmacr) then
        if (niv .ge. 2) then
            call utmess('I','MECANONLINE13_21')
        endif
        oprigi = 'RIGI_MECA'
        call nmcmat('MESSTR', oprigi, ' ', ASTER_TRUE,&
                    ASTER_TRUE, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                    list_l_calc, list_l_asse)
    endif
!
! --- AJOUT DE LA MATRICE ELASTIQUE DANS LA LISTE
!
    if (lelas) then
        optrig = 'RIGI_MECA'
        iterat = 0
        call nmrigi(modele     , carele         ,&
                    ds_material, ds_constitutive,&
                    fonact     , iterat         , sddyna, ds_measure, ds_system,&
                    valinc     , solalg,&
                    optrig     , ldccvg)
        if (lvarc) then
            call utmess('A', 'MECANONLINE3_2')
        endif
    endif
!
! --- AJOUT DE LA MATRICE AMORTISSEMENT DANS LA LISTE
!
    if (lamor .and. .not.lktan) then
        optamo = 'AMOR_MECA'
        call nmcmat('MEAMOR', optamo, ' ', ASTER_TRUE,&
                    ASTER_FALSE, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                    list_l_calc, list_l_asse)
!
    endif
!
! --- CALCUL ET ASSEMBLAGE DES MATR_ELEM DE LA LISTE
!
    if (nb_matr .gt. 0) then
        call nmxmat(modele         , ds_material   , carele        ,&
                    ds_constitutive, sddisc        , numins        ,&
                    valinc         , solalg        , lischa        ,&
                    numedd         , numfix        , ds_measure    ,&
                    nb_matr        , list_matr_type, list_calc_opti,&
                    list_asse_opti , list_l_calc   , list_l_asse   ,&
                    meelem         , measse        , ds_system)
        if (ldccvg .gt. 0) then
            call utmess('F', 'MECANONLINE_1')
        endif
    endif
!
end subroutine
