! --------------------------------------------------------------------
! Copyright (C) 1991 - 2018 - EDF R&D - www.code-aster.org
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
subroutine nmarc0(result, modele        , ds_material    , carele   , fonact,&
                  sdcrit, sddyna        , ds_constitutive, sdcriq   ,&
                  sdpilo, list_load_resu, numarc         , time_curr)
!
use NonLin_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/assert.h"
#include "asterfort/isfonc.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/ndaram.h"
#include "asterfort/ndynlo.h"
#include "asterfort/ndynre.h"
#include "asterfort/rsadpa.h"
#include "asterfort/rssepa.h"
#include "asterfort/Behaviour_type.h"
!
character(len=8) :: result
integer :: numarc
integer :: fonact(*)
real(kind=8) :: time_curr
character(len=19) :: sddyna, sdpilo
character(len=19) :: list_load_resu, sdcrit
character(len=24) :: modele, carele, sdcriq
type(NL_DS_Material), intent(in) :: ds_material
type(NL_DS_Constitutive), intent(in) :: ds_constitutive
!
! ----------------------------------------------------------------------
!
! ROUTINE MECA_NON_LINE (ALGORITHME - ARCHIVAGE)
!
! ARCHIVAGE DES PARAMETRES
!
! ----------------------------------------------------------------------
!
! IN  RESULT : NOM UTILISATEUR DU CONCEPT RESULTAT
! IN  MODELE : NOM DU MODELE
! In  ds_material      : datastructure for material parameters
! IN  SDCRIT : VALEUR DES CRITERES DE CONVERGENCE
! IN  SDPILO : SD PILOTAGE
! In  ds_constitutive  : datastructure for constitutive laws management
! IN  SDCRIQ : SD CRITERE QUALITE
! IN  COMPOR : CARTE DECRIVANT LE TYPE DE COMPORTEMENT
! IN  CARELE : CARACTERISTIQUES DES ELEMENTS DE STRUCTURE
! IN  FONACT : FONCTIONNALITES ACTIVEES (VOIR NMFONC)
! IN  SDDYNA : SD DEDIEE A LA DYNAMIQUE
! In  list_load_resu : name of list of loads saved in results datastructure
! IN  NUMARC : NUMERO D'ARCHIVAGE
! IN  INSTAN : VALEUR DE L'INSTANT
!
! ----------------------------------------------------------------------
!
    character(len=16) :: valk
    character(len=19) :: k19bla
    aster_logical :: lerrt, lthm, lpilo, ldyna
    aster_logical :: lexge
    character(len=24) :: errthm, typsel, typpil
    real(kind=8) :: taberr(2), parm_theta, valr, coef, time_prev
    integer :: jv_para, jerrt
    real(kind=8), pointer :: v_carcri_valv(:) => null()
    real(kind=8), pointer :: plir(:) => null()
    real(kind=8), pointer :: crtr(:) => null()
    character(len=24), pointer :: pltk(:) => null()
    character(len=16), pointer :: crde(:) => null()
!
! ----------------------------------------------------------------------
!
    call jemarq()
!
! --- INITIALISATIONS
!
    k19bla = ' '
!
! --- FONCTIONNALITES ACTIVEES
!
    ldyna = ndynlo(sddyna,'DYNAMIQUE' )
    lexge = ndynlo(sddyna,'EXPL_GENE' )
    lerrt = isfonc(fonact,'ERRE_TEMPS_THM')
    lthm = isfonc(fonact,'THM' )
    lpilo = isfonc(fonact,'PILOTAGE' )
!
! --- ARCHIVAGE DE THETA EN THM
!
    if (lthm) then
        call jeveuo(ds_constitutive%carcri(1:19)//'.VALV', 'L', vr = v_carcri_valv)
        parm_theta = v_carcri_valv(PARM_THETA_THM)
        call rsadpa(result, 'E', 1, 'PARM_THETA', numarc, 0, sjv=jv_para)
        zr(jv_para) = parm_theta
    endif
!
! --- ARCHIVAGE DE L'INSTANT
!
    call rsadpa(result, 'E', 1, 'INST', numarc, 0, sjv=jv_para)
    zr(jv_para) = time_curr
!
! --- ARCHIVAGE DE L'INSTANT PRECEDENT
!
    if (ldyna) then
        time_prev = ndynre(sddyna,'INST_PREC')
        call rsadpa(result, 'E', 1, 'INST_PREC', numarc, 0, sjv=jv_para)
        zr(jv_para) = time_prev
    endif
!
! --- ARCHIVAGE DU MODELE, MATERIAU, CARA_ELEM ET DE LA SD CHARGE
!
    call rssepa(result, numarc, modele(1:8), ds_material%field_mate(1:8), carele(1:8),&
                list_load_resu)
!
! --- ARCHIVAGE DES CRITERES DE CONVERGENCE
!
    call jeveuo(sdcrit//'.CRTR', 'L', vr=crtr)
    call jeveuo(sdcrit//'.CRDE', 'L', vk16=crde)
    valr = crtr(1)
    valk = crde(1)
    call rsadpa(result, 'E', 1, valk, numarc, 0, sjv=jv_para)
    zi(jv_para) = nint(valr)
    valr = crtr(5)
    valk = crde(5)
    call rsadpa(result, 'E', 1, valk, numarc, 0, sjv=jv_para)
    zr(jv_para) = valr
    valr = crtr(6)
    valk = crde(6)
    call rsadpa(result, 'E', 1, valk, numarc, 0, sjv=jv_para)
    zr(jv_para) = valr
!
! --- ARCHIVAGE DES INDICATEURS D'ERREUR EN TEMPS EN THM UNIQUEMENT
!
    if (lerrt) then
        errthm = sdcriq(1:19)//'.ERRT'
        call jeveuo(errthm, 'L', jerrt)
        taberr(1) = zr(jerrt-1+1)
        taberr(2) = zr(jerrt-1+2)
        call rsadpa(result, 'E', 1, 'ERRE_TPS_LOC', numarc, 0, sjv=jv_para)
        zr(jv_para) = taberr(1)
        call rsadpa(result, 'E', 1, 'ERRE_TPS_GLOB', numarc, 0, sjv=jv_para)
        zr(jv_para) = taberr(2)
    endif
!
! --- ARCHIVAGE DE COEF_MULT SI PILOTAGE
!
    if (lpilo) then
        call jeveuo(sdpilo(1:19)//'.PLTK', 'L', vk24=pltk)
        typpil = pltk(1)
        typsel = pltk(6)
        if ((typpil.eq.'LONG_ARC'.or.typpil.eq.'SAUT_LONG_ARC') .and. typsel .eq.&
            'ANGL_INCR_DEPL') then
            call jeveuo(sdpilo(1:19)//'.PLIR', 'L', vr=plir)
            coef = plir(1)
            call rsadpa(result, 'E', 1, 'COEF_MULT', numarc, 0, sjv=jv_para)
            zr(jv_para) = coef
        endif
    endif
!
! --- ARCHIVAGE DEPL/VITE/ACCE GENERALISES
!
    if (lexge) then
        call ndaram(result, sddyna, numarc)
    endif
!
    call jedema()
end subroutine
