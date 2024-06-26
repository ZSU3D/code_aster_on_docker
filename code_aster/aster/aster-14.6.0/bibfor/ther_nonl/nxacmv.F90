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
subroutine nxacmv(model      , mate     , cara_elem, list_load, nume_dof   ,&
                  solver     , l_stat   , time     , tpsthe   , temp_iter  ,&
                  vhydr      , varc_curr, dry_prev , dry_curr , cn2mbr_stat,&
                  cn2mbr_tran, matass   , maprec   , cndiri   , cncine     ,&
                  mediri     , compor   , ds_algorom_)
!
use Rom_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/vtaxpy.h"
#include "asterfort/vtzero.h"
#include "asterfort/asasve.h"
#include "asterfort/ascavc.h"
#include "asterfort/ascova.h"
#include "asterfort/asmatr.h"
#include "asterfort/assert.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/mecact.h"
#include "asterfort/memsth.h"
#include "asterfort/mergth.h"
#include "asterfort/merxth.h"
#include "asterfort/mtdscr.h"
#include "asterfort/preres.h"
#include "asterfort/vechnl.h"
#include "asterfort/vechth.h"
#include "asterfort/vedith.h"
#include "asterfort/vetnth.h"
#include "asterfort/vetnth_nonl.h"
#include "asterfort/vrcins.h"
!
character(len=24), intent(in) :: model
character(len=24), intent(in) :: mate
character(len=24), intent(in) :: cara_elem
character(len=19), intent(in) :: list_load
character(len=24), intent(in) :: nume_dof
character(len=19), intent(in) :: solver
character(len=24), intent(in) :: time
character(len=19), intent(in) :: varc_curr
aster_logical, intent(in) :: l_stat
real(kind=8), intent(in) :: tpsthe(6)
character(len=24), intent(in) :: temp_iter
character(len=24), intent(in) :: vhydr
character(len=24), intent(in) :: dry_prev
character(len=24), intent(in) :: dry_curr
character(len=24), intent(in) :: cn2mbr_stat
character(len=24), intent(in) :: cn2mbr_tran
character(len=24), intent(in) :: matass
character(len=19), intent(in) :: maprec
character(len=24), intent(in) :: cndiri
character(len=24), intent(out) :: cncine
character(len=24), intent(in) :: mediri
character(len=24), intent(in) :: compor
type(ROM_DS_AlgoPara), optional, intent(in) :: ds_algorom_
!
! --------------------------------------------------------------------------------------------------
!
! THER_NON_LINE - Algorithm
!
! Compute second members and tangent matrix
!
! --------------------------------------------------------------------------------------------------
!
! In  model            : name of model
! In  mate             : name of material characteristics (field)
! In  cara_elem        : name of elementary characteristics (field)
! In  list_load        : name of datastructure for list of loads
!
! --------------------------------------------------------------------------------------------------
!
    integer :: ibid, ierr, iret
    integer :: jtn, i_vect
    character(len=2) :: codret
    real(kind=8) :: time_curr
    character(len=8), parameter :: nomcmp(6) = (/'INST    ','DELTAT  ',&
                                                 'THETA   ','KHI     ',&
                                                 'R       ','RHO     '/)
    character(len=24) :: ligrmo
    character(len=24) :: vadiri, vachtp, vatntp, vatnti, vachtn
    character(len=24), parameter  :: merigi = '&&METRIG           .RELR'
    character(len=24), parameter  :: memass = '&&METMAS           .RELR'
    character(len=24) :: vediri
    character(len=24) :: vechtp
    character(len=24), parameter  :: vetntp = '&&VETNTP           .RELR'
    character(len=24), parameter  :: vetnti = '&&VETNTI           .RELR'
    character(len=24), parameter  :: vechtn = '&&VECHTN           .RELR'
    character(len=24) :: cntntp
    character(len=24) :: cnchtp
    character(len=24) :: cnchnl
    character(len=24) :: cntnti

    character(len=24) :: lload_name, lload_info, lload_func
    character(len=24), pointer :: v_resu_elem(:) => null()
    integer, parameter :: nb_max = 9
    integer :: nb_vect, nb_matr
    real(kind=8) :: vect_coef(nb_max)
    character(len=19) :: vect_name(nb_max), matr_name(nb_max)
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
!
! - Initializations
!
    vect_coef(:) = 0.d0
    vect_name(:) = ' '
    matr_name(:) = ' '
    cntntp       = ' '
    cnchtp       = ' '
    cnchnl       = ' '
    cntnti       = ' '
    ligrmo       = model(1:8)//'.MODELE'
    vediri       = '&&VEDIRI           .RELR'
    vechtp       = '&&VECHTP           .RELR'
    vadiri       = '&&NTACMV.VADIRI'
    vachtp       = '&&NTACMV.VACHTP'
    vatntp       = '&&NTACMV.VATNTP'
    vatnti       = '&&NTACMV.VATNTI'
    vachtn       = '&&NTACMV.VACHTN'
    time_curr    = tpsthe(1)
    lload_name   = list_load(1:19)//'.LCHA'
    lload_info   = list_load(1:19)//'.INFC'
    lload_func   = list_load(1:19)//'.FCHA'
!
! - Construct command variables fields
!
    call vrcins(model , mate, cara_elem, tpsthe(1), varc_curr,&
                codret)
!
! - Update <CARTE> for time
!
    call mecact('V', time, 'MODELE', ligrmo, 'INST_R',&
                ncmp=6, lnomcmp=nomcmp, vr=tpsthe)
!
! - Compute Dirichlet loads (AFFE_CHAR_THER)
!
    call vedith(model, list_load, time, vediri)
    call asasve(vediri, nume_dof, 'R', vadiri)
    call ascova('D', vadiri, lload_func, 'INST', tpsthe(1),&
                'R', cndiri)
!
! - Compute Dirichlet loads (AFFE_CHAR_CINE)
!
    cncine = ' '
    call ascavc(lload_name, lload_info, lload_func, nume_dof, tpsthe(1),&
                cncine)
!
! - Compute CHAR_THER_EVOLNI
!
    if (.not.l_stat) then
        call vetnth_nonl(model    , cara_elem, mate    , time , compor,&
                         temp_iter, varc_curr,&
                         vetntp   , vetnti   , 'V',&
                         dry_prev , dry_curr , vhydr)
        call asasve(vetnti, nume_dof, 'R', vatnti)
        call jeveuo(vatnti, 'L', jtn)
        cntnti = zk24(jtn)
        call asasve(vetntp, nume_dof, 'R', vatntp)
        call jeveuo(vatntp, 'L', jtn)
        cntntp = zk24(jtn)
    endif
!
! - Compute Neumann loads (second member) - Linear part
!
    call vechth('STAT', model    , lload_name, lload_info, cara_elem,&
                mate  , time_curr, time      , temp_iter , vechtp   ,&
                varc_curr_ = varc_curr)
    call asasve(vechtp, nume_dof, 'R', vachtp)
    call ascova('D', vachtp, lload_func, 'INST', tpsthe(1),&
                'R', cnchtp)
    if (l_stat) then
        call jedetr(vechtp)
    endif
!
! - Compute Neumann loads (second member) - Nonlinear part
!
    call vechnl(model    , lload_name, lload_info, time,&
                temp_iter, vechtn    , 'V')
    call asasve(vechtn, nume_dof, 'R', vachtn)
    call ascova('D', vachtn, ' ', 'INST', tpsthe(1),&
                'R', cnchnl)
    if (l_stat) then
        call jedetr(vechtn)
    endif
!
! - Compute second members
!
    call vtzero(cn2mbr_stat)
    call vtzero(cn2mbr_tran)
    if (l_stat) then
        nb_vect      = 2
        vect_coef(1) = 1.d0
        vect_coef(2) = 1.d0
        vect_name(1) = cnchtp(1:19)
        vect_name(2) = cnchnl(1:19)
        do i_vect = 1, nb_vect
            call vtaxpy(vect_coef(i_vect), vect_name(i_vect), cn2mbr_stat)
        end do
    else
        nb_vect      = 3
        vect_coef(1) = 1.d0
        vect_coef(2) = 1.d0
        vect_coef(3) = 1.d0
        vect_name(1) = cnchtp(1:19)
        vect_name(2) = cnchnl(1:19)
        vect_name(3) = cntntp(1:19)
        do i_vect = 1, nb_vect
            call vtaxpy(vect_coef(i_vect), vect_name(i_vect), cn2mbr_stat)
        end do
        vect_name(1) = cnchtp(1:19)
        vect_name(2) = cnchnl(1:19)
        vect_name(3) = cntnti(1:19)
        do i_vect = 1, nb_vect
            call vtaxpy(vect_coef(i_vect), vect_name(i_vect), cn2mbr_tran)
        end do
    endif
!
! - Tangent matrix (non-linear) - Volumic and surfacic terms
!
    call merxth(model    , lload_name, lload_info, cara_elem, mate     ,&
                time_curr, time      , temp_iter , compor   , varc_curr,&
                merigi   , 'V',&
                dry_prev , dry_curr)
    nb_matr = 0
    call jeexin(merigi(1:8)//'           .RELR', iret)
    if (iret .gt. 0) then
        call jeveuo(merigi(1:8)//'           .RELR', 'L', vk24 = v_resu_elem)
        if (v_resu_elem(1) .ne. ' ') then
            nb_matr = nb_matr + 1
            matr_name(nb_matr) = merigi(1:19)
        endif
    endif
    call jeexin(mediri(1:8)//'           .RELR', iret)
    if (iret .gt. 0) then
        call jeveuo(mediri(1:8)//'           .RELR', 'L', vk24 = v_resu_elem)
        if (v_resu_elem(1) .ne. ' ') then
            nb_matr = nb_matr + 1
            matr_name(nb_matr) = mediri(1:19)
        endif
    endif
    call jeexin(memass(1:8)//'           .RELR', iret)
    if (iret .gt. 0) then
        call jeveuo(memass(1:8)//'           .RELR', 'L', vk24 = v_resu_elem)
        if (v_resu_elem(1) .ne. ' ') then
            nb_matr = nb_matr + 1
            matr_name(nb_matr) = memass(1:19)
        endif
    endif
    call asmatr(nb_matr, matr_name, ' ', nume_dof, &
                lload_info, 'ZERO', 'V', 1, matass)
!
! - Factorization of matrix
!
    if (present(ds_algorom_)) then
        if (ds_algorom_%l_rom) then
            call mtdscr(matass)
        else
            call preres(solver, 'V', ierr, maprec, matass,&
                    ibid, -9999)
        endif
    else
        call preres(solver, 'V', ierr, maprec, matass,&
                    ibid, -9999)
    endif
!
    call jedema()
end subroutine
