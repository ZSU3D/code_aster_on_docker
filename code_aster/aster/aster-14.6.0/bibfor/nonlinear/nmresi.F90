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
subroutine nmresi(mesh       , list_func_acti, ds_material,&
                  nume_dof   , sdnume        , sddyna     ,&
                  ds_conv    , ds_print      , ds_contact ,&
                  ds_inout   , ds_algorom    , ds_system  ,&
                  matass     , nume_inst     , eta        ,&
                  hval_incr  , hval_algo     ,&
                  hval_veasse, hval_measse   ,&
                  r_equi_vale, r_char_vale)
!
use NonLin_Datastructure_type
use Rom_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "asterc/r8vide.h"
#include "asterfort/assert.h"
#include "asterfort/dismoi.h"
#include "asterfort/infdbg.h"
#include "asterfort/isfonc.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/mmconv.h"
#include "asterfort/ndynlo.h"
#include "asterfort/nmchex.h"
#include "asterfort/nmfext.h"
#include "asterfort/nmimre.h"
#include "asterfort/nmimre_dof.h"
#include "asterfort/GetResi.h"
#include "asterfort/nmpcin.h"
#include "asterfort/nmrede.h"
#include "asterfort/nmvcmx.h"
#include "asterfort/rescmp.h"
#include "asterfort/romAlgoNLMecaResidual.h"
#include "asterfort/romAlgoNLCorrEFMecaResidual.h"
#include "asterfort/nmequi.h"
#include "asterfort/utmess.h"
!
character(len=8), intent(in) :: mesh
integer, intent(in) :: list_func_acti(*)
type(NL_DS_Material), intent(in) :: ds_material
character(len=24), intent(in) :: nume_dof
character(len=19), intent(in) :: sddyna, sdnume
type(NL_DS_Conv), intent(inout) :: ds_conv
type(NL_DS_Print), intent(inout) :: ds_print
type(NL_DS_Contact), intent(inout) :: ds_contact
type(NL_DS_InOut), intent(in) :: ds_inout
type(ROM_DS_AlgoPara), intent(in) :: ds_algorom
type(NL_DS_System), intent(in) :: ds_system
character(len=19), intent(in) :: matass
integer, intent(in) :: nume_inst
real(kind=8), intent(in) :: eta
character(len=19), intent(in) :: hval_incr(*), hval_algo(*)
character(len=19), intent(in) :: hval_measse(*), hval_veasse(*)
real(kind=8), intent(out) :: r_char_vale, r_equi_vale
!
! --------------------------------------------------------------------------------------------------
!
! MECA_NON_LINE - Convergence management
!
! Compute residuals
!
! --------------------------------------------------------------------------------------------------
!
! In  mesh             : name of mesh
! In  list_func_acti   : list of active functionnalities
! In  ds_material      : datastructure for material parameters
! In  nume_dof         : name of numbering object (NUME_DDL)
! In  sdnume           : datastructure for dof positions
! In  sddyna           : datastructure for dynamic
! IO  ds_conv          : datastructure for convergence management
! IO  ds_print         : datastructure for printing parameters
! In  ds_contact       : datastructure for contact management
! In  ds_inout         : datastructure for input/output management
! In  ds_algorom       : datastructure for ROM parameters
! In  ds_system        : datastructure for non-linear system management
! In  matass           : matrix
! In  nume_inst        : index of current time step
! In  eta              : coefficient for pilotage (continuation)
! In  hval_incr        : hat-variable for incremental values fields
! In  hval_algo        : hat-variable for algorithms fields
! In  hval_veasse      : hat-variable for vectors (node fields)
! In  hval_measse      : hat-variable for matrix
! Out r_equi_vale      : norm for equilibrium residual
! Out r_char_vale      : norm for denominator of RESI_GLOB_RELA
!
! --------------------------------------------------------------------------------------------------
!
    integer :: ifm, niv
    integer, pointer :: v_ccid(:) => null()
    integer :: nb_equa, i_equa
    character(len=24) :: mate, varc_refe
    aster_logical :: l_stat, l_load_cine, l_cont_cont, l_cont_lac, l_rom, l_macr
    aster_logical :: l_resi_refe, l_varc_init, l_resi_comp, l_rela
    aster_logical :: l_no_disp, l_pilo, l_disp
    character(len=19) :: profch
    character(len=19) :: varc_prev, disp_prev
    character(len=19) :: cndiri, cnbudi, cnfext
    character(len=19) :: cnrefe
    character(len=19) :: cndfdo, cnequi, cndipi, cnsstr
    real(kind=8) :: vale_equi, vale_refe, vale_varc
    integer :: r_rela_indx, r_resi_indx, r_equi_indx
    integer :: r_refe_indx, r_char_indx, r_comp_indx
    real(kind=8) :: resi_glob_rela, resi_glob_maxi
    character(len=16) :: r_fric_name, r_geom_name, r_comp_name
    character(len=24) :: sdnuco
    integer, pointer :: v_sdnuco(:) => null()
    real(kind=8) :: r_rela_vale, r_refe_vale, r_varc_vale
    real(kind=8) :: r_comp_vale, r_fric_vale, r_geom_vale, r_pene_vale
    real(kind=8), pointer :: v_cnfext(:) => null()
    real(kind=8), pointer :: v_cnfint(:) => null()
    real(kind=8), pointer :: v_cnrefe(:) => null()
    real(kind=8), pointer :: v_cndiri(:) => null()
    real(kind=8), pointer :: v_fvarc_init(:) => null()
    integer, pointer :: v_deeq(:) => null()
    real(kind=8), pointer :: v_cnequi(:) => null()
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
    call infdbg('MECANONLINE', ifm, niv)
    if (niv .ge. 2) then
        call utmess('I', 'MECANONLINE13_65')
    endif
!
! - Initialisations
!
    profch    = ' '
    varc_prev = ' '
    disp_prev = ' '
    cndiri    = ' '
    cnbudi    = ' '
    cnfext    = ' '
    cnrefe    = ' '
    cndfdo    = ' '
    cnequi    = ' '
    cndipi    = ' '
    cnsstr    = ' '
    mate      = ds_material%field_mate
    varc_refe = ds_material%varc_refe
    call dismoi('NB_EQUA', nume_dof, 'NUME_DDL', repi=nb_equa)
    r_rela_vale = 0.d0
    r_refe_vale = 0.d0
    r_char_vale = 0.d0
    r_equi_vale = 0.d0
    r_comp_vale = 0.d0
    r_varc_vale = 0.d0
    r_fric_vale = 0.d0
    r_geom_vale = 0.d0
    r_rela_indx = 0.d0
    r_refe_indx = 0.d0
    r_resi_indx = 0.d0
    r_char_indx = 0.d0
    r_comp_indx = 0.d0
    r_equi_indx = 0.d0
    r_fric_name = ' '
    r_geom_name = ' '
    r_comp_name = ' '
    sdnuco      = ' '
    vale_equi   = 0.d0
    vale_refe   = 0.d0
    vale_varc   = 0.d0
!
! - Active functionnalities
!
    l_stat      = ndynlo(sddyna,'STATIQUE')
    l_resi_refe = isfonc(list_func_acti,'RESI_REFE')
    l_resi_comp = isfonc(list_func_acti,'RESI_COMP')
    l_pilo      = isfonc(list_func_acti,'PILOTAGE')
    l_load_cine = isfonc(list_func_acti,'DIRI_CINE')
    l_cont_cont = isfonc(list_func_acti,'CONT_CONTINU')
    l_cont_lac  = isfonc(list_func_acti,'CONT_LAC')
    l_rom       = isfonc(list_func_acti,'ROM')
    l_macr      = isfonc(list_func_acti, 'MACR_ELEM_STAT')
    l_varc_init = (nume_inst .eq. 1) .and. (.not.ds_inout%l_state_init)
    l_no_disp   = .not.(ndynlo(sddyna,'FORMUL_DEPL').or.l_stat)
    l_disp      = ASTER_TRUE
!
! - Get hat variables
!
    call nmchex(hval_incr, 'VALINC', 'DEPMOI', disp_prev)
    call nmchex(hval_incr, 'VALINC', 'COMMOI', varc_prev)
    call nmchex(hval_veasse, 'VEASSE', 'CNDIPI', cndipi)
    call nmchex(hval_veasse, 'VEASSE', 'CNDIRI', cndiri)
    call nmchex(hval_veasse, 'VEASSE', 'CNBUDI', cnbudi)
    call nmchex(hval_veasse, 'VEASSE', 'CNREFE', cnrefe)
    call nmchex(hval_veasse, 'VEASSE', 'CNFEXT', cnfext)
    call nmchex(hval_veasse, 'VEASSE', 'CNSSTR', cnsstr)
    cndfdo = '&&CNCHAR.DFDO'
!
! - Compute external forces
!
    call nmfext(eta, list_func_acti, hval_veasse, cnfext, ds_contact, sddyna)
!
! - For kinematic loads
!
    if (l_load_cine) then
        call nmpcin(matass)
        call jeveuo(matass(1:19)//'.CCID', 'L', vi = v_ccid)
    endif
    call dismoi('PROF_CHNO', disp_prev, 'CHAM_NO', repk=profch)
    call jeveuo(profch(1:19)//'.DEEQ', 'L', vi=v_deeq)
!
! - For contact dof
!
    if (l_cont_cont .or. l_cont_lac) then
        sdnuco = sdnume(1:19)//'.NUCO'
        call jeveuo(sdnuco, 'L', vi = v_sdnuco)
    endif
!
! - Compute force for denominator of RESI_GLOB_RELA
!
    call nmrede(list_func_acti, sddyna    ,&
                sdnume        , nb_equa   , matass,&
                ds_material   , ds_contact,&
                cnfext        , ds_system%cnfint, cndiri, cnsstr,&
                hval_measse   , hval_incr ,&
                r_char_vale   , r_char_indx)
!
! - Compute lack of balance forces
!
    cnequi = '&&CNCHAR.DONN'
    call nmequi(l_disp     , l_pilo, l_macr, cnequi,&
                ds_system%cnfint     , cnfext, cndiri, cnsstr,&
                ds_contact,&
                cnbudi     , cndfdo,&
                cndipi     , eta)
!
! - Compute RESI_COMP_RELA
!
    if (l_resi_comp) then
        call rescmp(ds_system%cnfnod, cnequi,&
                    r_comp_vale, r_comp_name, r_comp_indx)
    endif
!
! - Access to fields
!
    call jeveuo(ds_system%cnfint(1:19)//'.VALE', 'L', vr=v_cnfint)
    call jeveuo(cndiri(1:19)//'.VALE', 'L', vr=v_cndiri)
    call jeveuo(cnfext(1:19)//'.VALE', 'L', vr=v_cnfext)
    if (l_varc_init) then
        call jeveuo(ds_material%fvarc_init(1:19)//'.VALE', 'L', vr=v_fvarc_init)
    endif
    if (l_resi_refe) then
        call jeveuo(cnrefe(1:19)//'.VALE', 'L', vr=v_cnrefe)
    endif
    call jeveuo(cnequi(1:19)//'.VALE', 'L', vr=v_cnequi)
!
! - Compute
!
    do i_equa = 1, nb_equa
        if (l_no_disp) then
            if (v_cndiri(i_equa) .ne. 0.d0) then
                cycle
            endif
        endif
        if (l_load_cine) then
            if (v_ccid(i_equa) .eq. 1) then
                cycle
            endif
        endif
        if (l_cont_cont .or. l_cont_lac) then
            if (v_sdnuco(i_equa) .eq. 1) then
                cycle
            endif
        endif
! ----- Lack of equilibrium (RESI_GLOB_MAXI)
        vale_equi = abs(v_cnequi(i_equa))
        if (r_equi_vale .le. vale_equi) then
            r_equi_vale = vale_equi
            r_equi_indx = i_equa
        endif
! ----- For RESI_REFE_RELA
        if (l_resi_refe) then
            if (v_deeq(2*i_equa) .gt. 0) then
                vale_refe = abs(v_cnequi(i_equa))/v_cnrefe(i_equa)
                if (r_refe_vale .le. vale_refe) then
                    r_refe_vale = vale_refe
                    r_refe_indx = i_equa
                endif
            endif
        endif
! ----- Initial external state variables
        if (l_varc_init) then
            vale_varc = abs(v_fvarc_init(i_equa))
            if (r_varc_vale .le. vale_varc) then
                r_varc_vale = vale_varc
            endif
        endif
    end do
!
! - Evaluate residuals in applying HYPER-REDUCTION
!
    if (l_rom) then
        if (ds_algorom%phase .eq. 'HROM') then
            call romAlgoNLMecaResidual(v_cnfint, v_cnfext, ds_algorom, l_load_cine, v_ccid,&
                                       r_equi_vale)
        elseif (ds_algorom%phase .eq. 'CORR_EF') then
            call romAlgoNLCorrEFMecaResidual(v_cnfint, v_cnfext, ds_algorom, l_load_cine, v_ccid,&
                                             r_equi_vale)
        else
            ASSERT(ASTER_FALSE)
        endif
    endif
!
! - Results
!
    if (r_char_vale .gt. 0.d0) then
        r_rela_vale = r_equi_vale/r_char_vale
        r_rela_indx = r_equi_indx
    else
        r_rela_vale = -1.d0
        r_rela_indx = 0
    endif
!
! - Contact with generalized Newton
!
    if (l_cont_cont .or. l_cont_lac) then
        call mmconv(mesh       , ds_contact ,&
                    hval_incr  , hval_algo  ,&
                    r_fric_vale, r_fric_name,&
                    r_geom_vale, r_geom_name,&
                    r_pene_vale)
        if (nint(ds_contact%continue_pene) .eq. 3 .or. &
            nint(ds_contact%continue_pene) .eq. 4 ) then
            ds_conv%l_stop_pene = ASTER_FALSE
        endif
    endif
!
! - Save informations about residuals into convergence datastructure
!
    call nmimre_dof(nume_dof   , ds_conv,&
                    r_rela_vale, r_equi_vale, r_refe_vale, r_comp_vale , r_fric_vale, r_geom_vale,&
                    r_rela_indx, r_equi_indx, r_refe_indx, r_comp_name , r_comp_indx, r_fric_name,&
                    r_geom_name, r_pene_vale)
!
! - Set value of residuals informations in convergence table
!
    call nmimre(ds_conv, ds_print)
!
! - Get convergence parmeters
!
    call GetResi(ds_conv, type = 'RESI_GLOB_RELA' , user_para_ = resi_glob_rela,&
                 l_resi_test_ = l_rela)
    call GetResi(ds_conv, type = 'RESI_GLOB_MAXI' , user_para_ = resi_glob_maxi)
!
! --- VERIFICATION QUE LES VARIABLES DE COMMANDE INITIALES CONDUISENT
! --- A DES FORCES NODALES NULLES
!
    if (l_varc_init) then
        if (l_rela) then
            if (r_char_vale .gt. resi_glob_rela) then
                r_varc_vale = r_varc_vale/r_char_vale
                if (r_varc_vale .gt. resi_glob_rela) then
                    call nmvcmx(mate, mesh, varc_refe, varc_prev)
                endif
            endif
        else
            if (r_varc_vale .gt. resi_glob_maxi) then
                call nmvcmx(mate, mesh, varc_refe, varc_prev)
            endif
        endif
    endif
!
    call jedema()
end subroutine
