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

subroutine debcal(nin, lchin, lpain, nout, lchout)

use calcul_module, only : ca_iachii_, ca_iachik_, ca_iachix_, &
    ca_iactif_, ca_iaobtr_, ca_iaopds_, ca_iaoppa_, ca_nbobtr_,&
    ca_ligrel_, ca_option_

implicit none


! person_in_charge: jacques.pellet at edf.fr

#include "jeveux.h"
#include "asterc/indik8.h"
#include "asterc/isnnem.h"
#include "asterfort/assert.h"
#include "asterfort/chlici.h"
#include "asterfort/chligr.h"
#include "asterfort/codent.h"
#include "asterfort/dismoi.h"
#include "asterfort/etenca.h"
#include "asterfort/grdeur.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jenonu.h"
#include "asterfort/jenuno.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnom.h"
#include "asterfort/jexnum.h"
#include "asterfort/nbec.h"
#include "asterfort/scalai.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"

    integer :: nin, nout
    character(len=19) :: lchin(nin), lchout(nout)
    character(len=8) :: lpain(nin)
!----------------------------------------------------------------------
!
!  but :
!   1. verifier les "entrees" de calcul.
!   2. initialiser certains objets pour le calcul.
!   3. calculer certaines variables de calcul_module
!
!  entrees:
!     nin    :  nombre de champs parametres "in"
!     nout   :  nombre de champs parametres "out"
!     lchin  :  liste des noms des champs "in"
!     lchout :  liste des noms des champs "out"
!     lpain  :  liste des noms des parametres "in"
!
!  sorties:
!    allocation d'objets de travail
!
!----------------------------------------------------------------------
    integer :: desc
    integer :: i
    integer :: ibid, nbpara, iret, j
    integer :: jpar, igd, nec, ncmpmx, iii, num
    integer ::   jproli, ianueq, iret1
    integer :: iret2
    character(len=8) :: k8bi, typsca
    character(len=4) :: knum, tych
    character(len=8) :: nompar, ma, ma2, k8bi1, k8bi2
    character(len=19) :: chin, chou, ligre2
    character(len=24) :: noprno, objdes, valk(5)
    character(len=24), pointer :: refe(:) => null()
    integer, pointer :: nbno(:) => null()
!-----------------------------------------------------------------------

!   -- Remarque : cette routine ne fait pas appel a jemarq / jedema
!      car elle stocke des adresses jeveux.

    call dismoi('NOM_MAILLA', ca_ligrel_, 'LIGREL', repk=ma)


!   -- verification que les champs "in" ont des noms licites:
!   ---------------------------------------------------------
    do i = 1, nin
        nompar=lpain(i)
        call chlici(nompar, 8)
        if (nompar .ne. ' ') then
            call chlici(lchin(i), 19)
        endif
    end do


!   -- verification de l'existence des champs "in"
!   ---------------------------------------------------
    call wkvect('&&CALCUL.LCHIN_EXI', 'V V L', max(1, nin), ca_iachix_)
    ca_nbobtr_=ca_nbobtr_+1
    zk24(ca_iaobtr_-1+ca_nbobtr_)='&&CALCUL.LCHIN_EXI'
    do i = 1, nin
        chin=lchin(i)
        zl(ca_iachix_-1+i)=.true.
        if (lpain(i)(1:1) .eq. ' ') then
            zl(ca_iachix_-1+i)=.false.
        else if (chin(1:1).eq.' ') then
            zl(ca_iachix_-1+i)=.false.
        else
            call jeexin(chin//'.DESC', iret1)
            call jeexin(chin//'.CELD', iret2)
            if ((iret1+iret2) .eq. 0) zl(ca_iachix_-1+i)=.false.
        endif
    end do


!   -- on verifie que les champs "in" ont un maillage sous-jacent
!      identique au maillage associe a ca_ligrel_ :
!   -------------------------------------------------------------
    do i = 1, nin
        chin=lchin(i)
        if (.not.(zl(ca_iachix_-1+i))) cycle
        call dismoi('NOM_MAILLA', chin, 'CHAMP', repk=ma2)
        if (ma2 .ne. ma) then
            valk(1)=chin
            valk(2)=ca_ligrel_
            valk(3)=ma2
            valk(4)=ma
            call utmess('F', 'CALCUL_3', nk=4, valk=valk)
        endif
    end do


!   -- verification que les champs "out" sont differents
!      des champs "in"
!   ---------------------------------------------------
    do i = 1, nout
        chou=lchout(i)
        do j = 1, nin
            chin=lchin(j)
            if (.not.zl(ca_iachix_-1+j)) cycle
            if (chin .eq. chou) then
                call utmess('F', 'CALCUL_4', sk=chou)
            endif
        end do
    end do


    call wkvect('&&CALCUL.LCHIN_I', 'V V I', max(1, 11*nin), ca_iachii_)
    ca_nbobtr_=ca_nbobtr_+1
    zk24(ca_iaobtr_-1+ca_nbobtr_)='&&CALCUL.LCHIN_I'
    call wkvect('&&CALCUL.LCHIN_K8', 'V V K8', max(1, 2*nin), ca_iachik_)
    ca_nbobtr_=ca_nbobtr_+1
    zk24(ca_iaobtr_-1+ca_nbobtr_)='&&CALCUL.LCHIN_K8'
    nbpara = zi(ca_iaopds_-1+2) + zi(ca_iaopds_-1+3)
    do i = 1, nin
        chin=lchin(i)
        ASSERT(chin.ne.' ')
        call jeexin(chin//'.DESC', iret1)
        if (iret1 .gt. 0) objdes=chin//'.DESC'
        call jeexin(chin//'.CELD', iret2)
        if (iret2 .gt. 0) objdes=chin//'.CELD'
        ASSERT((iret1+iret2).gt.0)
        nompar=lpain(i)
        jpar=indik8(zk8(ca_iaoppa_),nompar,1,nbpara)
        ASSERT(jpar.ne.0)

        call dismoi('TYPE_CHAMP', chin, 'CHAMP', repk=tych)

!        -- si le champ est un cham_elem( ou un resuelem)
!           et qu'il n'a pas ete calcule avec le ligrel de calcul,
!           on le transporte sur ce ligrel
!           (et on modifie son nom dans lchin)
        if ((tych(1:2).eq.'EL') .or. (tych.eq.'RESL')) then
            call dismoi('NOM_LIGREL', chin, 'CHAMP', repk=ligre2)
            if (ligre2 .ne. ca_ligrel_) then
                call codent(i, 'G', knum)
                lchin(i)='&&CALCUL.CHML.'//knum
                ASSERT(ca_iactif_.eq.0)
                call chligr(chin, ca_ligrel_, ca_option_, nompar, 'V',&
                            lchin(i))

                call jeexin(lchin(i)(1:19)//'.CELD', ibid)
                chin=lchin(i)
                objdes(1:19)=chin
                ca_nbobtr_=ca_nbobtr_+1
                zk24(ca_iaobtr_-1+ca_nbobtr_)=lchin(i)//'.CELD'
                ca_nbobtr_=ca_nbobtr_+1
                if (tych(1:2) .eq. 'EL') then
                    zk24(ca_iaobtr_-1+ca_nbobtr_)=lchin(i)//'.CELK'
                else
                    zk24(ca_iaobtr_-1+ca_nbobtr_)=lchin(i)//'.NOLI'
                endif
                ca_nbobtr_=ca_nbobtr_+1
                zk24(ca_iaobtr_-1+ca_nbobtr_)=lchin(i)//'.CELV'
            endif
        endif


        igd=grdeur(nompar)
        zi(ca_iachii_-1+11*(i-1)+1)=igd

        nec=nbec(igd)
        zi(ca_iachii_-1+11*(i-1)+2)=nec

        typsca=scalai(igd)
        zk8(ca_iachik_-1+2*(i-1)+2)=typsca

        call jelira(jexnum('&CATA.GD.NOMCMP', igd), 'LONMAX', ncmpmx)
        zi(ca_iachii_-1+11*(i-1)+3)=ncmpmx

        call jelira(objdes, 'DOCU', cval=k8bi)
        zk8(ca_iachik_-1+2*(i-1)+1)=k8bi

        call jeveuo(objdes, 'L', desc)
        zi(ca_iachii_-1+11*(i-1)+4)=desc

!         -- si la grandeur associee au champ n'est pas celle associee
!            au parametre, on arrete tout :
        if (igd .ne. zi(desc)) then
            call jenuno(jexnum('&CATA.GD.NOMGD', igd), k8bi1)
            call jenuno(jexnum('&CATA.GD.NOMGD', zi(desc)), k8bi2)
            valk(1)=chin
            valk(2)=k8bi2
            valk(3)=nompar
            valk(4)=k8bi1
            valk(5)=ca_option_
            call utmess('F', 'CALCUL_5', nk=5, valk=valk)
        endif

        call jeexin(chin//'.VALE', iret)
        if (iret .gt. 0) then
            call jeveuo(chin//'.VALE', 'L', iii)
            zi(ca_iachii_-1+11*(i-1)+5)=iii
        endif

        call jeexin(chin//'.CELV', iret)
        if (iret .gt. 0) then
            call jeveuo(chin//'.CELV', 'L', iii)
            zi(ca_iachii_-1+11*(i-1)+5)=iii
        endif

!        -- pour les cartes :
        if (zk8(ca_iachik_-1+2*(i-1)+1)(1:4) .eq. 'CART') then

!           -- si la carte n'est pas constante, on l'etend:
            if (.not.(zi(desc-1+2).eq.1.and.zi(desc-1+4).eq.1)) then
                call etenca(chin, ca_ligrel_, iret)
                if (iret .gt. 0) goto 998
                call jeexin(chin//'.PTMA', iret)
                if (iret .gt. 0) then
                    call jeveuo(chin//'.PTMA', 'L', iii)
                    zi(ca_iachii_-1+11*(i-1)+6)=iii
                    ca_nbobtr_=ca_nbobtr_+1
                    zk24(ca_iaobtr_-1+ca_nbobtr_)=chin//'.PTMA'
                endif
                call jeexin(chin//'.PTMS', iret)
                if (iret .gt. 0) then
                    call jeveuo(chin//'.PTMS', 'L', iii)
                    zi(ca_iachii_-1+11*(i-1)+7)=iii
                    ca_nbobtr_=ca_nbobtr_+1
                    zk24(ca_iaobtr_-1+ca_nbobtr_)=chin//'.PTMS'
                endif
            endif
        endif

!        -- pour les cham_no a profil_noeud:
        if (zk8(ca_iachik_-1+2*(i-1)+1)(1:4) .eq. 'CHNO') then
            num=zi(desc-1+2)
            if (num .gt. 0) then
                call jeveuo(chin//'.REFE', 'L', vk24=refe)
                noprno=refe(2)(1:19)//'.PRNO'
                call jeveuo(jexnum(noprno, 1), 'L', iii)
                zi(ca_iachii_-1+11*(i-1)+8)=iii
                call jeveuo(ca_ligrel_//'.NBNO', 'L', vi=nbno)
                if (nbno(1) .gt. 0) then
                    call jenonu(jexnom(noprno(1:19)//'.LILI', ca_ligrel_//'      '), jproli)
                    if (jproli .eq. 0) then
                        zi(ca_iachii_-1+11*(i-1)+9)=isnnem()
                    else
                        call jeveuo(jexnum(noprno, jproli), 'L', iii)
                        zi(ca_iachii_-1+11*(i-1)+9)=iii
                    endif
                endif
                call jeveuo(noprno(1:19)//'.NUEQ', 'L', ianueq)
                zi(ca_iachii_-1+11*(i-1)+10)=ianueq
                zi(ca_iachii_-1+11*(i-1)+11)=1
            endif
        endif
    enddo

    goto 999

!     -- sortie erreur:
998 continue
    chin=lchin(i)
    call utmess('F', 'CALCUL_6', sk=chin)

!     -- sortie normale:
999 continue

end subroutine
