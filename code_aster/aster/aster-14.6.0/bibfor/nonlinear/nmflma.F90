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
subroutine nmflma(typmat, mod45 , l_hpp  , ds_algopara, modelz,&
                  ds_material, carele, sddisc, sddyna     , fonact,&
                  numins, valinc, solalg, lischa     ,&
                  numedd     , numfix, ds_system,&
                  ds_constitutive, ds_measure, meelem,&
                  measse, nddle , ds_posttimestep, modrig,&
                  ldccvg, matass, matgeo)
!
use NonLin_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/ascoma.h"
#include "asterfort/asmama.h"
#include "asterfort/asmari.h"
#include "asterfort/asmatr.h"
#include "asterfort/assert.h"
#include "asterfort/dismoi.h"
#include "asterfort/infdbg.h"
#include "asterfort/isfonc.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/matide.h"
#include "asterfort/ndynlo.h"
#include "asterfort/nmcha0.h"
#include "asterfort/nmchai.h"
#include "asterfort/nmchcp.h"
#include "asterfort/nmchex.h"
#include "asterfort/nmrigi.h"
#include "asterfort/nmcmat.h"
#include "asterfort/nmxmat.h"
#include "asterfort/utmess.h"
!
character(len=16) :: typmat, modrig
character(len=4) :: mod45
aster_logical, intent(in) :: l_hpp
type(NL_DS_AlgoPara), intent(in) :: ds_algopara
integer :: fonact(*)
character(len=*) :: modelz
character(len=24) :: carele
type(NL_DS_Material), intent(in) :: ds_material
type(NL_DS_Constitutive), intent(in) :: ds_constitutive
type(NL_DS_Measure), intent(inout) :: ds_measure
integer :: numins, ldccvg, nddle
character(len=19) :: sddisc, sddyna, lischa
character(len=24) :: numedd, numfix
character(len=19) :: meelem(*), measse(*)
type(NL_DS_System), intent(in) :: ds_system
character(len=19) :: solalg(*), valinc(*)
character(len=19) :: matass, matgeo
type(NL_DS_PostTimeStep), intent(in) :: ds_posttimestep
!
! --------------------------------------------------------------------------------------------------
!
! ROUTINE MECA_NON_LINE (CALCUL - UTILITAIRE)
!
! CALCUL DE LA MATRICE GLOBALE POUR FLAMBEMENT/MODES VIBRATOIRES
!
! --------------------------------------------------------------------------------------------------
!
! IN  TYPMAT : TYPE DE MATRICE DE RIGIDITE A UTILISER
!                'ELASTIQUE/TANGENTE/SECANTE'
! IN  MOD45  : TYPE DE CALCUL DE MODES PROPRES
!              'VIBR'     MODES VIBRATOIRES
!              'FLAM'     MODES DE FLAMBEMENT
! IN  l_hpp   : TYPE DE DEFORMATIONS
!                0        PETITES DEFORMATIONS (MATR. GEOM.)
!                1        GRANDES DEFORMATIONS (PAS DE MATR. GEOM.)
! IN  MODELE : MODELE
! IN  NUMEDD : NUME_DDL (VARIABLE AU COURS DU CALCUL)
! IN  NUMFIX : NUME_DDL (FIXE AU COURS DU CALCUL)
! In  ds_material      : datastructure for material parameters
! IN  CARELE : CARACTERISTIQUES DES ELEMENTS DE STRUCTURE
! In  ds_constitutive  : datastructure for constitutive laws management
! IN  LISCHA : LISTE DES CHARGES
! IO  ds_measure       : datastructure for measure and statistics management
! IN  SDDYNA : SD POUR LA DYNAMIQUE
! In  ds_algopara      : datastructure for algorithm parameters
! In  ds_system        : datastructure for non-linear system management
! IN  SDDISC : SD DISC_INST
! IN  PREMIE : SI PREMIER INSTANT DE CALCUL
! IN  NUMINS : NUMERO D'INSTANT
! IN  VALINC : VARIABLE CHAPEAU POUR INCREMENTS VARIABLES
! IN  SOLALG : VARIABLE CHAPEAU POUR INCREMENTS SOLUTIONS
! IN  MEELEM : MATRICES ELEMENTAIRES
! IN  MEASSE : MATRICE ASSEMBLEE
! IN  NDDLE  : NOMBRE DE DDL A EXCLURE
! In  ds_posttimestep  : datastructure for post-treatment at each time step
! IN  MODRIG : MODIFICATION OU NON DE LA RAIDEUR
! OUT LDCCVG : CODE RETOUR INTEGRATION DU COMPORTEMENT
!                0 - OK
!                1 - ECHEC DANS L'INTEGRATION : PAS DE RESULTATS
!                2 - ERREUR DANS LES LDC SUR LA NON VERIFICATION DE
!                    CRITERES PHYSIQUES
!                3 - SIZZ NON NUL (DEBORST) ON CONTINUE A ITERER
! OUT MATASS : MATRICE DE RAIDEUR ASSEMBLEE GLOBALE
! OUT MATGEO : DEUXIEME MATRICE ASSEMBLEE POUR LE PROBLEME AUX VP :
!              - MATRICE GEOMETRIQUE GLOBALE (CAS FLAMBEMENT)
!              - MATRICE DE RAIDEUR ASSEMBLEE GLOBALE (CAS FLAMBEMENT)
!              - MATRICE DE MASSE (CAS MODES DYNAMIQUES)
!
! --------------------------------------------------------------------------------------------------
!
    integer, parameter :: zvalin = 28
    aster_logical :: reasma
    aster_logical :: lcrigi, lmacr
    aster_logical :: l_neum_undead
    character(len=16) :: optrig
    integer :: reincr, iterat
    character(len=8) :: tdiag, syme
    character(len=19) :: rigi2, masse, memass, megeom
    character(len=19) :: depplu, vitplu, accplu, sigplu, varplu, valin2(zvalin)
    integer :: nmax
    integer :: nb_matr
    character(len=6) :: list_matr_type(20)
    character(len=16) :: list_calc_opti(20), list_asse_opti(20), modlag
    aster_logical :: list_l_asse(20), list_l_calc(20)
    integer :: ifm, niv
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
    call infdbg('MECANONLINE', ifm, niv)
    if (niv .ge. 2) then
        call utmess('I', 'MECANONLINE13_69')
    endif
!
! - Initializations
!
    nb_matr              = 0
    list_matr_type(1:20) = ' '
    iterat = 0
!
! --- RECOPIE DU VECTEUR CHAPEAU
!
    call nmchai('VALINC', 'LONMAX', nmax)
    ASSERT(nmax.eq.zvalin)
    call nmcha0('VALINC', 'ALLINI', ' ', valin2)
    call nmchcp('VALINC', valinc, valin2)
!
! --- FONCTIONNALITES ACTIVEES
!
    l_neum_undead = isfonc(fonact,'NEUM_UNDEAD')
    lmacr         = isfonc(fonact,'MACR_ELEM_STAT')
!
! --- DECOMPACTION DES VARIABLES CHAPEAUX
!
    call nmchex(measse, 'MEASSE', 'MEMASS', masse)
    call nmchex(meelem, 'MEELEM', 'MEMASS', memass)
    call nmchex(meelem, 'MEELEM', 'MEGEOM', megeom)
!
! --- ON UTILISE CHAMP EN T+ PAS T- CAR DEPDEL=0 ET
! --- MATRICE = RIGI_MECA_TANG (VOIR FICHE 18779)
! --- SAUF VARI. COMM.
!
    call nmchex(valinc, 'VALINC', 'DEPPLU', depplu)
    call nmchex(valinc, 'VALINC', 'SIGPLU', sigplu)
    call nmchex(valinc, 'VALINC', 'VARPLU', varplu)
    call nmchex(valinc, 'VALINC', 'VITPLU', vitplu)
    call nmchex(valinc, 'VALINC', 'ACCPLU', accplu)
!
    call nmcha0('VALINC', 'DEPMOI', depplu, valin2)
    call nmcha0('VALINC', 'VITMOI', vitplu, valin2)
    call nmcha0('VALINC', 'VARMOI', varplu, valin2)
    call nmcha0('VALINC', 'ACCMOI', accplu, valin2)
    call nmcha0('VALINC', 'SIGMOI', sigplu, valin2)
!
! --- OBJET POUR RECONSTRUCTION RIGIDITE TOUJOURS SYMETRIQUE
!
    rigi2 = '&&NMFLMA.RIGISYME'
!
! - Get parameter
!
    reincr = ds_algopara%reac_incr
!
! --- REASSEMBLAGE DE LA MATRICE GLOBALE
!
    if ((reincr.eq.0) .and. (numins.ne.1)) then
        reasma = .false.
    endif
    if (numins .eq. 1) then
        reasma = .true.
    endif
    if ((reincr.ne.0) .and. (numins.ne.1)) then
        reasma = mod(numins-1,reincr) .eq. 0
    endif
!
! --- OPTION DE CALCUL DE MERIMO
!
    if (typmat .eq. 'TANGENTE') then
        optrig = 'RIGI_MECA_TANG'
    else if (typmat.eq.'SECANTE') then
        optrig = 'RIGI_MECA_ELAS'
    else if (typmat.eq.'ELASTIQUE') then
        optrig = 'RIGI_MECA'
    else
        optrig = 'RIGI_MECA_TANG'
    endif
!
! --- A RECALCULER
!
    lcrigi = reasma
!
! --- CALCUL DES MATR-ELEM DE RIGIDITE
!
    if (lcrigi) then
        call nmrigi(modelz     , carele         ,&
                    ds_material, ds_constitutive,&
                    fonact     , iterat         ,&
                    sddyna     , ds_measure     ,ds_system,&
                    valin2     , solalg,&
                    optrig     , ldccvg)
    endif
!
! --- CALCUL DES MATR-ELEM DES CHARGEMENTS SUIVEURS
!
    if (l_neum_undead) then
        call nmcmat('MESUIV', ' ', ' ', ASTER_TRUE,&
                    ASTER_FALSE, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                    list_l_calc, list_l_asse)
    endif
!
! --- CALCUL DE LA RIGIDITE GEOMETRIQUE DANS LE CAS HPP
!
    if (mod45 .eq. 'FLAM') then
        if (l_hpp) then
            call nmcmat('MEGEOM', ' ', ' ', ASTER_TRUE,&
                        ASTER_FALSE, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                        list_l_calc, list_l_asse)
        endif
    endif
!
! --- CALCUL DES MATR-ELEM DES SOUS-STRUCTURES
!
    if (lmacr) then
        call nmcmat('MESSTR', ' ', ' ', ASTER_TRUE,&
                    ASTER_FALSE, nb_matr, list_matr_type, list_calc_opti, list_asse_opti,&
                    list_l_calc, list_l_asse)
    endif
!
! --- CALCUL ET ASSEMBLAGE DES MATR_ELEM DE LA LISTE
!
    if (nb_matr .gt. 0) then
        call nmxmat(modelz         , ds_material   , carele        ,&
                    ds_constitutive, sddisc        , numins        ,&
                    valin2         , solalg        , lischa        ,&
                    numedd         , numfix        , ds_measure    ,&
                    nb_matr        , list_matr_type, list_calc_opti,&
                    list_asse_opti , list_l_calc   , list_l_asse   ,&
                    meelem         , measse        ,  ds_system)
    endif
!
! --- ON RECONSTRUIT RIGI2 TOUJOURS SYMETRIQUE
!
    call asmari(fonact, meelem, ds_system, numedd, lischa, ds_algopara,&
                rigi2)
    matass = rigi2
!
! --- PRISE EN COMPTE DE LA MATRICE TANGENTE DES FORCES SUIVEUSES
!
    if (reasma) then
        if (l_neum_undead) then
            call ascoma(meelem, numedd, lischa, matass)
        endif
    endif
!
!  --- MODIFICATION EVENTUELLE DE LA MATRICE DE RAIDEUR
!
    modlag = 'MODI_LAGR_OUI'
    tdiag = 'MAX_ABS'
    if ((nddle.ne.0) .and. (modrig(1:13).eq.'MODI_RIGI_OUI')) then
        call matide(matass, nddle, ds_posttimestep%stab_para%list_dof_excl, modlag, tdiag,&
                    10.d0)
    endif
!
! --- CALCUL DE LA RIGIDITE GEOMETRIQUE DANS LE CAS HPP
!
    if (mod45 .eq. 'FLAM') then
        if (l_hpp) then
            call asmatr(1, megeom, ' ', numedd, &
                        lischa, 'ZERO', 'V', 1, matgeo)
            if ((nddle.ne.0) .and. (modrig(1:13).eq.'MODI_RIGI_OUI')) then
                call matide(matgeo, nddle, ds_posttimestep%stab_para%list_dof_excl, modlag, tdiag,&
                            10.d0)
            endif
        else
            matgeo = matass
        endif
    else if (mod45 .eq. 'VIBR') then
        call asmama(memass, ' ', numedd, lischa,&
                    matgeo)
    endif
!
! --- VERIFICATION POUR MODE_VIBR QUE LES DEUX MATRICES SONT SYMETRIQUES
!
    if (mod45 .eq. 'VIBR') then
        call dismoi('TYPE_MATRICE', matass, 'MATR_ASSE', repk=syme)
        if (syme .eq. 'NON_SYM') then
            call utmess('F', 'MECANONLINE5_56')
        else
            call dismoi('TYPE_MATRICE', matgeo, 'MATR_ASSE', repk=syme)
            if (syme .eq. 'NON_SYM') then
                call utmess('F', 'MECANONLINE5_56')
            endif
        endif
    endif
!
    call jedema()
!
end subroutine
