! --------------------------------------------------------------------
! Copyright (C) 1991 - 2017 - EDF R&D - www.code-aster.org
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
!
subroutine op0009()
!
implicit none
!
#include "asterf_types.h"
#include "asterc/getres.h"
#include "asterfort/as_deallocate.h"
#include "asterfort/assert.h"
#include "asterfort/infmaj.h"
#include "asterfort/jedema.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jemarq.h"
#include "asterfort/dismoi.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/meamac.h"
#include "asterfort/meamgy.h"
#include "asterfort/meamme.h"
#include "asterfort/cme_prep.h"
#include "asterfort/medith.h"
#include "asterfort/meimme.h"
#include "asterfort/memaac.h"
#include "asterfort/memame.h"
#include "asterfort/memsth.h"
#include "asterfort/meonme.h"
#include "asterfort/meriac.h"
#include "asterfort/merifs.h"
#include "asterfort/merige.h"
#include "asterfort/merigy.h"
#include "asterfort/merime.h"
#include "asterfort/meriro.h"
#include "asterfort/mergth.h"
#include "asterfort/redetr.h"
#include "asterfort/ntdoch.h"
#include "asterfort/sdmpic.h"
#include "asterfort/cme_getpara.h"
!
! --------------------------------------------------------------------------------------------------
!
!                       COMMANDE:  CALC_MATR_ELEM
!
! --------------------------------------------------------------------------------------------------
!

!
! --------------------------------------------------------------------------------------------------
!
    integer :: nb_load, nbresu, iresu, iexi, nh
    character(len=1) :: base
    character(len=4) :: kmpic
    character(len=8) :: model, cara_elem, sigm, strx, disp
    character(len=16) :: k8dummy, option
    character(len=19) :: matr_elem, rigi_meca, mass_meca, resuel, list_load
    character(len=24) :: chtime, mate, compor_mult, matr_elem24
    character(len=8), pointer :: v_list_load8(:) => null()
    character(len=24), pointer :: relr(:) => null()
    real(kind=8) :: time_curr, time_incr
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
    call infmaj()
!
! - Initializations
!
    base      = 'G'
    list_load = '&&OP0009.LISCHA'
!
! - Get results
!
    call getres(matr_elem, k8dummy, k8dummy)
!
! - Get parameters
!
    call cme_getpara(option      ,&
                     model       , cara_elem, mate, compor_mult,&
                     v_list_load8, nb_load  ,&
                     rigi_meca   , mass_meca,&
                     time_curr   , time_incr, nh       ,&
                     sigm        , strx     , disp)
!
! - Preparation
!
    call cme_prep(option, model, time_curr, time_incr, chtime)
!
! - Compute
!
    if (option .eq. 'RIGI_MECA') then
        call merime(model, nb_load     , v_list_load8, mate, cara_elem,&
                    time_curr , compor_mult , matr_elem   , nh  , base)
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'RIGI_FLUI_STRU') then
        call merifs(model, nb_load  , v_list_load8, mate, cara_elem,&
                    time_curr , matr_elem, nh)
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'RIGI_GEOM') then
        call merige(model, cara_elem, sigm      , strx      , matr_elem,&
                    base , nh       , deplr=disp, mater=mate)
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'RIGI_ROTA') then
        call meriro(model, cara_elem  , nb_load  , v_list_load8, mate,&
                    time_curr , compor_mult, matr_elem)
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'MECA_GYRO') then
        call meamgy(model  , mate        , cara_elem, compor_mult, matr_elem,&
                    nb_load, v_list_load8)
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'RIGI_GYRO') then
        call merigy(model  , mate        , cara_elem, compor_mult, matr_elem,&
                    nb_load, v_list_load8)
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'MASS_MECA') then
        call memame(option     , model    , mate, cara_elem, time_curr,&
                    compor_mult, matr_elem, base)
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'MASS_FLUI_STRU') then
        call memame(option     , model    , mate, cara_elem, time_curr,&
                    compor_mult, matr_elem, base)
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'MASS_MECA_DIAG') then
        call memame(option     , model    , mate, cara_elem, time_curr,&
                    compor_mult, matr_elem, base)
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'AMOR_MECA') then
        call meamme(option   , model, nb_load, v_list_load8, mate     ,&
                    cara_elem, time_curr , base   , rigi_meca   , mass_meca,&
                    matr_elem, ' ')
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'IMPE_MECA') then
        call meimme(model, nb_load, v_list_load8, mate, matr_elem)
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'ONDE_FLUI') then
        call meonme(model, nb_load, v_list_load8, mate, matr_elem)
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'RIGI_MECA_HYST') then
        call meamme(option   , model, nb_load, v_list_load8, mate     ,&
                    cara_elem, time_curr , base   , rigi_meca   , mass_meca,&
                    matr_elem, ' ')
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'RIGI_THER') then
        call ntdoch(list_load, l_load_user_ = .true._1)
        matr_elem24 = matr_elem
        call mergth(model      , list_load, cara_elem, mate, chtime,&
                    matr_elem24, base,&
                    time_curr  , nh_ = nh)
        call medith(base, 'CUMU', model, list_load, matr_elem24)
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'MASS_THER') then
        call memsth(model, cara_elem, mate, chtime, matr_elem, base, time_curr_ = time_curr)
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'RIGI_ACOU') then
        call meriac(model, nb_load, v_list_load8, mate, matr_elem, base)
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'MASS_ACOU') then
        call memaac(model, mate, matr_elem)
!
! --------------------------------------------------------------------------------------------------
    else if (option.eq.'AMOR_ACOU') then
        call meamac(model, nb_load, v_list_load8, mate, matr_elem, base)
!
! --------------------------------------------------------------------------------------------------
    else
        ASSERT(.false.)
    endif
!
! --------------------------------------------------------------------------------------------------
!   si MATEL n'est pas MPI_COMPLET, on le complete :
    call jeexin(matr_elem//'.RELR', iexi)
    if (iexi .gt. 0) then
        call jelira(matr_elem//'.RELR', 'LONMAX', nbresu)
        call jeveuo(matr_elem//'.RELR', 'L', vk24=relr)
        do iresu = 1, nbresu
            resuel=relr(iresu)(1:19)
            call jeexin(resuel//'.RESL', iexi)
            if (iexi .eq. 0) cycle
            call dismoi('MPI_COMPLET', resuel, 'RESUELEM', repk=kmpic)
            ASSERT((kmpic.eq.'OUI').or.(kmpic.eq.'NON'))
            if (kmpic .eq. 'NON') call sdmpic('RESUELEM', resuel)
        end do
    endif
!
! - DESTRUCTION DES RESUELEM NULS
!
    call redetr(matr_elem)

    AS_DEALLOCATE(vk8 = v_list_load8)
    call jedetr('&MERITH1           .RELR')
    call jedetr('&MERITH2           .RELR')
    call jedetr('&MERITH3           .RELR')
    call jedetr('&MERITH1           .RERR')
    call jedetr('&MERITH2           .RERR')
    call jedetr('&MERITH3           .RERR')
!
    call jedema()
end subroutine
