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

subroutine noligr(ligrz, igrel, numel, nunoeu,&
                  code, inema, nbno, typlaz,jlgns,&
                  rapide, jliel0, jlielc, jnema0, jnemac, l_lag1)
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/jecroc.h"
#include "asterfort/jelira.h"
#include "asterfort/jeecra.h"
#include "asterfort/jenonu.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnom.h"
#include "asterfort/jexnum.h"
#include "asterfort/jexatr.h"
#include "asterfort/jeimpo.h"
#include "asterfort/poslag.h"
#include "asterfort/utmess.h"
#include "asterfort/assert.h"
!
    character(len=*),intent(in) :: ligrz
    integer,intent(in) :: igrel
    integer,intent(in) :: numel
    integer,intent(in) :: nunoeu
    integer,intent(in) :: code
    integer,intent(inout) :: inema
    integer,intent(inout) :: nbno
    character(len=*),intent(in) :: typlaz
    integer,intent(in) :: jlgns

!   -- arguments optionnels pour gagner du temps CPU :
    character(len=3), intent(in), optional ::  rapide
    integer, intent(in), optional ::  jliel0
    integer, intent(in), optional ::  jlielc
    integer, intent(in), optional ::  jnema0
    integer, intent(in), optional ::  jnemac
    aster_logical, intent(in), optional :: l_lag1


!
! but: remplir le ligrel ligr
!  1.  adjonction du grel dans le ligrel
!  2.  stockage des mailles et noeuds supplementaires:
!    2.1 stockage des mailles supplementaires dans .nema
!    2.2 stockage des numeros des mailles supplementaires dans .liel
!
! arguments d'entree:
!      ligr : nom du ligrel
!      igrel: numero du grel
!      numel:numero du type_element
!      nunoeu   : numero d'un noeud
!      code : 1 ==> une maille "poi1" par noeud
!                   (typiquement: force_nodale)
!           : 3 ==> une maille "seg3" par noeud, et 2 noeuds tardifs
!                   par liaison
!                   son numero est incremente par la routine appelante
!                   (typiquement: liaison_ddl )
!      inema:numero  de la derniere maille tardive dans ligr
!      nbno : numero du dernier noeud tardif dans ligr
!      typlag:type des multiplicateurs de lagrange associes a la
!             relation
!          : '12'  ==>  le premier lagrange est avant le noeud physique
!                       le second lagrange est apres
!          : '22'  ==>  le premier lagrange est apres le noeud physique
!                       le second lagrange est apres
!
!     Les arguments suivants sont facultatifs :
!     ---------------------------------------------
!     Ils ne sont pas documentes. Il ne doivent etre renseignes que dans le
!     cas ou la routine noligr est appelee de (trop) nombreuses fois.
!     Exemple d'utilisation : aflrch.F90
!
!     rapide: 'OUI' / 'NON'
!     jliel0, jlielc : adresses pour l'objet l'objet ligrel.LIEL
!     jnema0, jnemac : adresses pour l'objet l'objet ligrel.NEMA
!
!     Attention : si rapide='OUI', il faut que l'appelant fasse appel a
!                 jeecra / NUTIOC apres le denier appel a noligr
!                 (objets .LIEL et .NEMA)
!
! arguments de sortie:
!        on enrichit le contenu du ligrel
!------------------------------------------------------------------------
    character(len=8) :: typlag
    character(len=19) :: ligr
    character(len=24) :: liel, nema
    integer :: ilag1, ilag2,jnema, jnema02, jnemac2
    integer :: jliel, jliel02, jlielc2
    integer :: kligr, lonigr, lgnema
    aster_logical :: lrapid, l_lag1c
    integer, save :: iprem=0 , numpoi, numse3
!-----------------------------------------------------------------------
    if( present(l_lag1) ) then
        l_lag1c = l_lag1
    else
        l_lag1c = .false.
    endif
    iprem=iprem+1
    if (iprem.eq.1) then
        call jenonu(jexnom('&CATA.TM.NBNO', 'POI1'), numpoi)
        if(l_lag1c) then
            call jenonu(jexnom('&CATA.TM.NBNO', 'SEG2'), numse3)
        else
            call jenonu(jexnom('&CATA.TM.NBNO', 'SEG3'), numse3)
        endif
    endif

    typlag = typlaz
    call poslag(typlag, ilag1, ilag2)

    ligr=ligrz
    liel=ligr//'.LIEL'
    nema=ligr//'.NEMA'


!   -- gestion des derniers arguments facultatifs (pour gains CPU) :
!   ----------------------------------------------------------------
    lrapid=.false.
    if (present(rapide)) then
        if (rapide.eq.'OUI') lrapid=.true.
    endif

    if (.not.lrapid) then
        call jeveuo(liel, 'E', jliel02)
        call jeveuo(jexatr(liel, 'LONCUM'), 'E', jlielc2)
        call jeveuo(nema, 'E', jnema02)
        call jeveuo(jexatr(nema, 'LONCUM'), 'E', jnemac2)
    else
        ASSERT(present(jliel0))
        ASSERT(present(jlielc))
        ASSERT(present(jnema0))
        ASSERT(present(jnemac))
        jliel02=jliel0
        jlielc2=jlielc
        jnema02=jnema0
        jnemac2=jnemac
    endif

    ASSERT(code.ge.1 .and. code.le.4)

!   -- lgnema : longueur d'un objet de la collection .NEMA :
    if (code .eq. 1) then
        lgnema=2
    else
        if(l_lag1c) then
            lgnema=3
        else
            lgnema=4
        endif
    endif


    lonigr = 2
    if (.not.lrapid) then
        call jeecra(jexnum(liel,igrel), 'LONMAX', ival=lonigr)
        call jecroc(jexnum(liel,igrel))
    else
        if (igrel.eq.1) zi(jlielc2)=1
        if (inema.eq.1) zi(jnemac2)=1
        zi(jlielc2-1+igrel+1)=zi(jlielc2-1+igrel)+lonigr
    endif


    kligr = 0
    jliel=jliel02-1+zi(jlielc2-1+igrel)

    kligr = kligr + 1
    inema = inema + 1
    zi(jliel-1+kligr) = -inema

    jnema=jnema02-1+zi(jnemac2-1+inema)
    if (.not.lrapid) then
        call jeecra(jexnum(nema,inema), 'LONMAX', ival=lgnema)
        call jecroc(jexnum(nema,inema))
    else
        zi(jnemac2-1+inema+1)=zi(jnemac2-1+inema)+lgnema
    endif

    if (code .eq. 1) then
        zi(jnema-1+1) = nunoeu
        zi(jnema-1+2) = numpoi

    else if (code.eq.3) then
        zi(jnema-1+1) = nunoeu
        ASSERT(jlgns.ne.1)
        if(l_lag1c) then
            zi(jnema-1+2) = -nbno
            zi(jnema-1+3) = numse3
            zi(jlgns+nbno-1) = ilag1
        else
            zi(jnema-1+2) = -nbno+1
            zi(jnema-1+3) = -nbno
            zi(jnema-1+4) = numse3
            zi(jlgns+nbno-2) = ilag1
            zi(jlgns+nbno-1) = ilag2
        endif
    else
        ASSERT(.false.)
    endif
     zi(jliel-1+kligr+1) = numel

end subroutine
