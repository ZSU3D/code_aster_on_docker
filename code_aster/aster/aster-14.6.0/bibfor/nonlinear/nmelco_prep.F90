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
!
subroutine nmelco_prep(calc_type,&
                       mesh     , model    , ds_material, ds_contact,&
                       disp_prev, vite_prev, acce_prev, vite_curr , disp_cumu_inst,&
                       nbin     , lpain    , lchin    ,&
                       option   , time_prev, time_curr , ds_constitutive,&
                       ccohes_  , xcohes_  )
!
use NonLin_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/assert.h"
#include "asterfort/cfdisl.h"
#include "asterfort/isfonc.h"
#include "asterfort/megeom.h"
#include "asterfort/jeveuo.h"
#include "asterfort/xmchex.h"
!
character(len=4), intent(in) :: calc_type
character(len=8), intent(in) :: mesh
character(len=24), intent(in) :: model
type(NL_DS_Material), intent(in) :: ds_material
type(NL_DS_Contact), intent(in) :: ds_contact
character(len=19), intent(in) :: disp_prev
character(len=19), intent(in) :: vite_prev
character(len=19), intent(in) :: acce_prev
character(len=19), intent(in) :: vite_curr
character(len=19), intent(in) :: disp_cumu_inst
integer, intent(in) :: nbin
character(len=8), intent(out) :: lpain(nbin)
character(len=19), intent(out) :: lchin(nbin)
character(len=16), intent(out) :: option
character(len=19), intent(in) :: time_prev
character(len=19), intent(in) :: time_curr
type(NL_DS_Constitutive), intent(in) :: ds_constitutive
character(len=19), optional, intent(out) :: ccohes_
character(len=19), optional, intent(out) :: xcohes_
!
! --------------------------------------------------------------------------------------------------
!
! Contact - Solve
!
! Continue/XFEM/LAC methods - Prepare input fields for vector and matrix computation
!
! --------------------------------------------------------------------------------------------------
!
! In  calc_type        : type of computation (vector or matrix)
! In  mesh             : name of mesh
! In  model            : name of model
! In  ds_material      : datastructure for material parameters
! In  ds_contact       : datastructure for contact management
! In  disp_prev        : displacement at beginning of current time
! In  vite_prev        : speed at beginning of current time
! In  vite_curr        : speed at current time
! In  acce_prev        : acceleration at beginning of current time
! In  disp_cumu_inst   : displacement increment from beginning of current time
! In  nbin             : number of input fields
! In  time_prev        : previous time
! In  time_curr        : current time
! In  ds_constitutive  : datastructure for constitutive laws management
! Out lpain            : list of parameters for input fields
! Out lchin            : list of input fields
! Out option           : name of option
! Out ccohes           : name of output field if XFEM/CZM
! Out ccohes           : name of output field if XFEM/CZM
!
! --------------------------------------------------------------------------------------------------
!
    character(len=19) :: chgeom, chmlcf, sdappa_psno, sdappa
    character(len=19) :: cpoint, cpinte, cainte, ccface
    character(len=19) :: lnno  , ltno  , stano , fissno
    character(len=19) :: heavno, hea_no, hea_fa
    character(len=19) :: pinter, ainter, cface , faclon, baseco
    character(len=19) :: xdonco, xindco, xseuco, xcohes, basefo
    character(len=19) :: fisco
    aster_logical :: l_cont_cont, l_cont_xfem, l_cont_xfem_gg, l_cont_lac, l_xfem_czm
    integer, pointer :: v_model_xfemcont(:) => null()
!
! --------------------------------------------------------------------------------------------------
!
    chgeom = '&&NMELCO.CHGEOM'
    option = ' '
    chmlcf=' '
    sdappa_psno=' '
    sdappa = ' '
    cpoint=' '
    cpinte=' '
    cainte=' '
    ccface=' '
    lnno  =' '
    ltno  =' '
    stano =' '
    fissno=' '
    heavno=' '
    hea_no=' '
    hea_fa=' '
    pinter=' '
    ainter=' '
    cface =' '
    faclon=' '
    baseco=' '
    xdonco=' '
    xindco=' '
    xseuco=' '
    xcohes=' '
    basefo=' '
    fisco =' '
!
! - Get contact parameters
!
    l_cont_cont    = cfdisl(ds_contact%sdcont_defi,'FORMUL_CONTINUE')
    l_cont_xfem    = cfdisl(ds_contact%sdcont_defi,'FORMUL_XFEM')
    l_cont_lac     = cfdisl(ds_contact%sdcont_defi,'FORMUL_LAC')
    l_cont_xfem_gg = cfdisl(ds_contact%sdcont_defi,'CONT_XFEM_GG')
    l_xfem_czm     = cfdisl(ds_contact%sdcont_defi,'EXIS_XFEM_CZM')
!
! - Select option
!
    if (calc_type.eq.'VECT') then
        option = 'CHAR_MECA_CONT'
        if (l_cont_xfem) then
            call jeveuo(model(1:8)//'.XFEM_CONT', 'L', vi = v_model_xfemcont)
            if (v_model_xfemcont(1) .eq. 2) then
                option = 'CHAR_MECA_CONT_M'
            endif
        endif
    elseif (calc_type.eq.'MATR') then
        option = 'RIGI_CONT'
        if (l_cont_xfem) then
            call jeveuo(model(1:8)//'.XFEM_CONT', 'L', vi = v_model_xfemcont)
            if (v_model_xfemcont(1) .eq. 2) then
                option = 'RIGI_CONT_M'
            endif
        endif
    else
        ASSERT(ASTER_FALSE)
    endif
!
! - Geometry field
!
    call megeom(model, chgeom)
!
! - <CHELEM> for input field
!
    if (l_cont_cont) then
        chmlcf = ds_contact%field_input
    endif
!
! - Special input fields for XFEM
!
    if (l_cont_xfem) then
        xindco = ds_contact%sdcont_solv(1:14)//'.XFIN'
        xdonco = ds_contact%sdcont_solv(1:14)//'.XFDO'
        xseuco = ds_contact%sdcont_solv(1:14)//'.XFSE'
        xcohes = ds_contact%sdcont_solv(1:14)//'.XCOH'
        lnno   = model(1:8)//'.LNNO'
        ltno   = model(1:8)//'.LTNO'
        pinter = model(1:8)//'.TOPOFAC.OE'
        ainter = model(1:8)//'.TOPOFAC.AI'
        cface  = model(1:8)//'.TOPOFAC.CF'
        faclon = model(1:8)//'.TOPOFAC.LO'
        baseco = model(1:8)//'.TOPOFAC.BA'
        stano  = model(1:8)//'.STNO'
        fissno = model(1:8)//'.FISSNO'
        heavno = model(1:8)//'.HEAVNO'
        hea_no = model(1:8)//'.TOPONO.HNO'
        hea_fa = model(1:8)//'.TOPONO.HFA'
        basefo = model(1:8)//'.BASLOC'
        fisco  = model(1:8)//'.FISSCO'
        if (l_cont_xfem_gg) then
            cpoint = ds_contact%sdcont_solv(1:14)//'.XFPO'
            stano  = ds_contact%sdcont_solv(1:14)//'.XFST'
            cpinte = ds_contact%sdcont_solv(1:14)//'.XFPI'
            cainte = ds_contact%sdcont_solv(1:14)//'.XFAI'
            ccface = ds_contact%sdcont_solv(1:14)//'.XFCF'
            heavno = ds_contact%sdcont_solv(1:14)//'.XFPL'
            hea_fa = ds_contact%sdcont_solv(1:14)//'.XFHF'
            hea_no = ds_contact%sdcont_solv(1:14)//'.XFHN'
            basefo = ds_contact%sdcont_solv(1:14)//'.XFBS'
            lnno   = ds_contact%sdcont_solv(1:14)//'.XFLN'
        endif
    endif
!
! - Special input fields for LAC
!
    if (l_cont_lac) then
        sdappa      = ds_contact%sdcont_solv(1:14)//'.APPA'
        chmlcf      = ds_contact%field_input
        sdappa_psno = sdappa(1:14)//'.PSNO'
    endif
!
! - Input field
!
    lpain(1)  = 'PGEOMER'
    lchin(1)  = chgeom(1:19)
    lpain(2)  = 'PDEPL_M'
    lchin(2)  = disp_prev(1:19)
    lpain(3)  = 'PDEPL_P'
    lchin(3)  = disp_cumu_inst(1:19)
    lpain(4)  = 'PVITE_M'
    lchin(4)  = vite_prev(1:19)
    lpain(5)  = 'PACCE_M'
    lchin(5)  = acce_prev(1:19)
    lpain(6)  = 'PVITE_P'
    lchin(6)  = vite_curr(1:19)
    lpain(7)  = 'PMATERC'
    lchin(7)  = ds_material%field_mate(1:19)
    lpain(8)  = 'PCONFR'
    lchin(8)  = chmlcf
    lpain(9)  = 'PCAR_PT'
    lchin(9)  = cpoint
    lpain(10) = 'PCAR_PI'
    lchin(10) = cpinte
    lpain(11) = 'PCAR_AI'
    lchin(11) = cainte
    lpain(12) = 'PCAR_CF'
    lchin(12) = ccface
    lpain(13) = 'PINDCOI'
    lchin(13) = xindco
    lpain(14) = 'PDONCO'
    lchin(14) = xdonco
    lpain(16) = 'PLST'
    lchin(16) = ltno
    lpain(17) = 'PPINTER'
    lchin(17) = pinter
    lpain(18) = 'PAINTER'
    lchin(18) = ainter
    lpain(19) = 'PCFACE'
    lchin(19) = cface
    lpain(20) = 'PLONGCO'
    lchin(20) = faclon
    lpain(21) = 'PBASECO'
    lchin(21) = baseco
    lpain(22) = 'PSEUIL'
    lchin(22) = xseuco
    lpain(23) = 'PSTANO'
    lchin(23) = stano
    lpain(24) = 'PCOHES'
    lchin(24) = xcohes
    lpain(25) = 'PFISNO'
    lchin(25) = fissno
    lpain(26) = 'PHEAVNO'
    lchin(26) = heavno
    lpain(27) = 'PHEA_NO'
    lchin(27) = hea_no
    lpain(28) = 'PHEA_FA'
    lchin(28) = hea_fa
    lpain(29) = 'PSNO'
    lchin(29) = sdappa_psno
    if (l_cont_xfem .and. l_cont_xfem_gg) then
      lpain(15) = 'PLSNGG'
      lchin(15) = lnno
      lpain(30) = 'PBASLOC'
      lchin(30) =  basefo
    else
      lpain(15) = 'PLSN'
      lchin(15) = lnno
      lpain(30) = 'PBASLOR'
      lchin(30) =  basefo
    endif
    lpain(31) = 'PINSTMR'
    lchin(31) = time_prev
    lpain(32) = 'PINSTPR'
    lchin(32) = time_curr
    lpain(33) = 'PCARCRI'
    lchin(33) = ds_constitutive%carcri(1:19)
    lpain(34) = 'PCOMPOR'
    lchin(34) = ds_constitutive%compor(1:19)
    lpain(35) = 'PFISCO'
    lchin(35) = fisco
    ASSERT(35.le.nbin)
!
! - Prepare output field for XFEM/CZM
!
    if (present(ccohes_)) then
        if (l_xfem_czm) then
            call jeveuo(model(1:8)//'.XFEM_CONT', 'L', vi = v_model_xfemcont)
            ccohes_ = '&&NMELCM.CCOHES'
            xcohes_ = xcohes
            if (v_model_xfemcont(1).eq.1 .or.&
                v_model_xfemcont(1).eq.3) then
                call xmchex(mesh, xcohes, ccohes_)
            endif
        endif
    endif
!
end subroutine
