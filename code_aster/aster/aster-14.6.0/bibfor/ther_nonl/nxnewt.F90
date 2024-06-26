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
subroutine nxnewt(model    , mate       , cara_elem  , list_load, nume_dof  ,&
                  solver   , tpsthe     , time       , matass   , cn2mbr    ,&
                  maprec   , cnchci     , varc_curr  , temp_prev, temp_iter ,&
                  vtempp   , vec2nd     , mediri     , conver   , hydr_prev ,&
                  hydr_curr, dry_prev   , dry_curr   , compor   , cnvabt    ,&
                  cnresi   , ther_crit_i, ther_crit_r, reasma   , ds_algorom,&
                  ds_print , sddisc    , iter_newt )
!
use NonLin_Datastructure_type
use Rom_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/asasve.h"
#include "asterfort/ascova.h"
#include "asterfort/asmatr.h"
#include "asterfort/copisd.h"
#include "asterfort/nxreso.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jeexin.h"
#include "asterfort/merxth.h"
#include "asterfort/nxresi.h"
#include "asterfort/romAlgoNLTherResidual.h"
#include "asterfort/romAlgoNLSystemSolve.h"
#include "asterfort/romAlgoNLCorrEFTherResidual.h"
#include "asterfort/romAlgoNLCorrEFMatrixModify.h"
#include "asterfort/romAlgoNLCorrEFResiduModify.h"
#include "asterfort/mtdscr.h"
#include "asterfort/preres.h"
#include "asterfort/verstp.h"
#include "asterfort/vethbt.h"
#include "asterfort/nxconv.h"
#include "asterfort/nmlere.h"
#include "asterfort/nmimci.h"
#include "asterfort/SetTableColumn.h"
#include "asterfort/nmimcr.h"
#include "asterfort/nmimck.h"
#include "asterfort/impcmp.h"
!
character(len=24), intent(in) :: model
character(len=24), intent(in) :: mate
character(len=24), intent(in) :: cara_elem
character(len=19), intent(in) :: list_load
character(len=24), intent(in) :: nume_dof
character(len=19), intent(in) :: solver
real(kind=8) :: tpsthe(6)
character(len=24), intent(in) :: time
character(len=19), intent(in) :: varc_curr, sddisc
integer, intent(in) :: iter_newt
aster_logical, intent(out) :: conver
aster_logical :: reasma
character(len=19) :: maprec
character(len=24) :: matass, cnchci, cnresi, temp_prev, temp_iter, vtempp, vec2nd, cn2mbr
character(len=24) :: hydr_prev, hydr_curr, compor, dry_prev, dry_curr
integer :: ther_crit_i(*)
real(kind=8) :: ther_crit_r(*)
type(ROM_DS_AlgoPara), intent(in) :: ds_algorom
type(NL_DS_Print), intent(inout) :: ds_print
!
! --------------------------------------------------------------------------------------------------
!
! THER_NON_LINE - Algorithm
!
! Solve current Newton iteration
!
! --------------------------------------------------------------------------------------------------
!
!     VAR temp_iter : ITERE PRECEDENT DU CHAMP DE TEMPERATURE
!     OUT VTEMPP : ITERE COURANT   DU CHAMP DE TEMPERATURE
!     OUT VHYDRP : ITERE COURANT   DU CHAMP D HYDRATATION
!
! --------------------------------------------------------------------------------------------------
!
    integer :: ibid, ieq_rela, ieq_maxi
    integer :: jmed, jmer, nbmat, ierr, iret
    real(kind=8) :: r8bid
    character(len=1) :: typres
    character(len=19) :: chsol
    character(len=24) :: bidon, veresi, varesi, vabtla, vebtla
    character(len=24) :: tlimat(2), mediri, merigi, cnvabt
    real(kind=8) :: time_curr
    character(len=24) :: lload_name, lload_info
    real(kind=8) :: resi_rela, resi_maxi
    character(len=16) :: name_dof_rela, name_dof_maxi
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
    varesi = '&&VARESI'
    vabtla = '&&VATBTL'
    cnresi = ' '
    cnvabt = ' '
    typres = 'R'
    chsol  = '&&NXNEWT.SOLUTION'
    bidon  = '&&FOMULT.BIDON'
    veresi = '&&VERESI'
    vebtla = '&&VETBTL           .RELR'
    merigi = '&&METRIG           .RELR'
    time_curr = tpsthe(1)
    lload_name = list_load(1:19)//'.LCHA'
    lload_info = list_load(1:19)//'.INFC'
    name_dof_rela = ' '
    name_dof_maxi = ' '
!
! - Neumann loads elementary vectors (residuals)
!
    call verstp(model    , lload_name, lload_info, mate     , time_curr,&
                time     , compor    , temp_prev , temp_iter, varc_curr,&
                veresi   , 'V'       ,&
                hydr_prev, hydr_curr , dry_prev  , dry_curr )
!
! - Neumann loads vector (residuals)
!
    call asasve(veresi, nume_dof, typres, varesi)
    call ascova('D', varesi, bidon, 'INST', r8bid,&
                typres, cnresi)
!
! - Dirichlet - BT LAMBDA
!
    call vethbt(model, lload_name, lload_info, cara_elem, mate,&
                temp_iter, vebtla, 'V')
    call asasve(vebtla, nume_dof, typres, vabtla)
    call ascova('D', vabtla, bidon, 'INST', r8bid,&
                typres, cnvabt)
!
! - Evaluate residuals
!
    ieq_rela = 0
    ieq_maxi = 0
    if (ds_algorom%l_rom) then
        if (ds_algorom%phase .eq. 'HROM') then
            call romAlgoNLTherResidual(ds_algorom, vec2nd   , cnvabt, cnresi, cn2mbr,&
                                       resi_rela , resi_maxi)
        else if (ds_algorom%phase .eq. 'CORR_EF') then
            call romAlgoNLCorrEFTherResidual(ds_algorom, vec2nd   , cnvabt, cnresi, cn2mbr,&
                                             resi_rela , resi_maxi)
        endif
    else
        call nxresi(vec2nd   , cnvabt   , cnresi  , cn2mbr,&
                    resi_rela, resi_maxi, ieq_rela, ieq_maxi)
    endif
    call impcmp(ieq_rela, nume_dof, name_dof_rela)
    call impcmp(ieq_maxi, nume_dof, name_dof_maxi)
!
! - Evaluate convergence
!
    call nxconv(ther_crit_i, ther_crit_r, resi_rela, resi_maxi, conver)
    call nmimci(ds_print, 'ITER_NUME', iter_newt, l_affe = ASTER_TRUE)
    call SetTableColumn(ds_print%table_cvg, name_ = 'RESI_RELA', mark_ = ' ')
    call SetTableColumn(ds_print%table_cvg, name_ = 'RESI_MAXI', mark_ = ' ')
    call nmimcr(ds_print, 'RESI_RELA', resi_rela, l_affe = ASTER_TRUE)
    call nmimcr(ds_print, 'RESI_MAXI', resi_maxi, l_affe = ASTER_TRUE)
    call nmimck(ds_print, 'RELA_NOEU', name_dof_rela, l_affe = ASTER_TRUE)
    call nmimck(ds_print, 'MAXI_NOEU', name_dof_maxi, l_affe = ASTER_TRUE)
    if (.not. conver) then
        if (ther_crit_i(1) .eq. 0) then
            call SetTableColumn(ds_print%table_cvg, name_ = 'RESI_RELA', mark_ = 'X')
        else
            call SetTableColumn(ds_print%table_cvg, name_ = 'RESI_MAXI', mark_ = 'X')
        endif
    endif
!
! - Save residuals for Newton-Krylov solver
!
    call nmlere(sddisc, 'E', 'VRELA', iter_newt, [resi_rela])
    call nmlere(sddisc, 'E', 'VMAXI', iter_newt, [resi_maxi])
!
! - Convergence
!
    if (conver) then
        call copisd('CHAMP_GD', 'V', temp_iter, vtempp)
        goto 999
    endif
!
! - New matrix if necessary
!
    if (reasma) then
! ----- Compute tangent matrix (non-linear) - Volumic and surfacic terms
        call merxth(model    , lload_name, lload_info, cara_elem, mate     ,&
                    time_curr, time      , temp_iter , compor   , varc_curr,&
                    merigi   , 'V',&
                    dry_prev , dry_curr)

        nbmat = 0
        call jeexin(merigi(1:19)//'.RELR', iret)
        if (iret .ne. 0) then
            call jeveuo(merigi(1:19)//'.RELR', 'L', jmer)
            if (zk24(jmer)(1:8) .ne. '        ') then
                nbmat = nbmat + 1
                tlimat(nbmat) =merigi(1:19)
            endif
        endif
        call jeexin(mediri(1:19)//'.RELR', iret)
        if (iret .ne. 0) then
            call jeveuo(mediri(1:19)//'.RELR', 'L', jmed)
            if (zk24(jmed)(1:8) .ne. '        ') then
                nbmat = nbmat + 1
                tlimat(nbmat) =mediri(1:19)
            endif
        endif
! ----- Assemble tangent matrix
        call asmatr(nbmat, tlimat, ' ', nume_dof, &
                    list_load, 'ZERO', 'V', 1, matass)
! ----- Factorize tangent matrix
        if (ds_algorom%l_rom .and. ds_algorom%phase .eq. 'HROM') then
            call mtdscr(matass)
        else
            call preres(solver, 'V', ierr, maprec, matass,ibid, -9999)
        endif
!
    endif
!
! - Solve linear system
!
    if (ds_algorom%l_rom .and. ds_algorom%phase .eq. 'HROM') then
        call copisd('CHAMP_GD', 'V', temp_prev, chsol)
        call romAlgoNLSystemSolve(matass, cn2mbr, cnchci, ds_algorom, chsol)
    else if (ds_algorom%l_rom .and. ds_algorom%phase .eq. 'CORR_EF') then
        call romAlgoNLCorrEFMatrixModify(nume_dof, matass, ds_algorom)
        call romAlgoNLCorrEFResiduModify(cn2mbr, ds_algorom)
        call nxreso(matass, maprec, solver, cnchci, cn2mbr, chsol)
    else
        call nxreso(matass, maprec, solver, cnchci, cn2mbr, chsol)
    endif
!
! - RECOPIE DANS VTEMPP DU CHAMP SOLUTION CHSOL, INCREMENT DE TEMPERATURE
!
    call copisd('CHAMP_GD', 'V', chsol, vtempp(1:19))
!
999 continue
    call jedema()
end subroutine
