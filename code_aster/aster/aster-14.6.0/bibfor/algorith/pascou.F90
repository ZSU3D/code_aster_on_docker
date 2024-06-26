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

subroutine pascou(mate, carele, sddyna, sddisc)
!
! person_in_charge: mickael.abbas at edf.fr
!
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/calcul.h"
#include "asterfort/celces.h"
#include "asterfort/cesexi.h"
#include "asterfort/diinst.h"
#include "asterfort/dismoi.h"
#include "asterfort/getvid.h"
#include "asterfort/getvtx.h"
#include "asterfort/jedema.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jenuno.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnum.h"
#include "asterfort/mecara.h"
#include "asterfort/megeom.h"
#include "asterfort/ndynlo.h"
#include "asterfort/ndynre.h"
#include "asterfort/utdidt.h"
#include "asterfort/utmess.h"
#include "asterfort/vrcins.h"
!
    character(len=24) :: mate, carele
    character(len=19) :: sddyna, sddisc
!
! ----------------------------------------------------------------------
!
! ROUTINE DYNA_NON_LINE (UTILITAIRE)
!
! EVALUATION DU PAS DE TEMPS DE COURANT POUR LE MODELE
!
! ----------------------------------------------------------------------
!
!
! IN  MATE   : CHAMP MATERIAU
! IN  CARELE : CARACTERISTIQUES DES ELEMENTS DE STRUCTURE
! IN  SDDYNA : SD DEDIEE A LA DYNAMIQUE (CF NDLECT)
! IN  SDDISC : SD DISCRETISATION
!
!
!
!
    integer :: ibid, jcesd, jcesl, n1, i, numins
    integer :: nbma, ima, iad, nbinst, nbmcfl
    real(kind=8) :: dtcou, valeur, phi, instin
    aster_logical :: booneg, boopos
    character(len=2) :: codret
    character(len=6) :: nompro
    character(len=8) :: mo, lpain(4), lpaout(1), stocfl, maicfl, mail
    character(len=19) :: chams, chvarc
    character(len=24) :: chgeom, ligrel, lchin(4), lchout(1), chcara(18)
    real(kind=8), pointer :: ditr(:) => null()
    real(kind=8), pointer :: cesv(:) => null()
!
! ---------------------------------------------------------------------
!
    call jemarq()
!
! --- INITIALISATIONS
!
    nompro ='OP0070'
    chvarc = '&&PASCOU.CH_VARC_R'
!
    call getvid(' ', 'MODELE', scal=mo, nbret=ibid)
!
    ligrel=mo//'.MODELE'
!
    lpain(1)='PMATERC'
    lchin(1)=mate
!
! --- RECUPERATION DU CHAMP GEOMETRIQUE
    call megeom(mo, chgeom)
!
    lpain(2)='PGEOMER'
    lchin(2)=chgeom
!
! --- CHAMP DES VARIABLES DE COMMANDE
    numins = 0
    instin = diinst(sddisc,numins)
    call vrcins(mo, mate, carele, instin, chvarc,&
                    codret)
    
    lpain(3)='PVARCPR'
    lchin(3)=chvarc(1:19)
!
! --- CHAMP DE CARACTERISTIQUES ELEMENTAIRES
    call mecara(carele(1:8), chcara)
!
    if (carele(1:8) .ne. ' ') then
        lpain(4)='PCACOQU'
        lchin(4)=chcara(7)
    endif
!
    lpaout(1)='PCOURAN'
    lchout(1)='&&'//nompro//'.PAS_COURANT'
!
    call calcul('S', 'PAS_COURANT', ligrel, 4, lchin,&
                lpain, 1, lchout, lpaout, 'V',&
                'OUI')
!
!     PASSAGE D'UN CHAM_ELEM EN UN CHAM_ELEM_S
    chams ='&&'//nompro//'.CHAMS'
!
    call celces(lchout(1), 'V', chams)
!
    call jeveuo(chams//'.CESD', 'L', jcesd)
!
    call jelira(mo//'.MAILLE', 'LONMAX', nbma)
    call jeveuo(chams//'.CESL', 'L', jcesl)
    call jeveuo(chams//'.CESV', 'L', vr=cesv)
!
!     INITIALISATION DE DTCOU
!
    dtcou = -1.d0
!
! A L'ISSUE DE LA BOUCLE :
! BOONEG=TRUE SI L'ON N'A PAS PU CALCULER DTCOU POUR AU MOINS UN ELMNT
! BOOPOS=TRUE SI L'ON A CALCULE DTCOU POUR AU MOINS UN ELEMENT
    booneg = .false.
    boopos = .false.
    nbmcfl = 1
    do ima = 1, nbma
        call cesexi('C', jcesd, jcesl, ima, 1,&
                    1, 1, iad)
        if (iad .gt. 0) then
            valeur = cesv(iad)
        else if (iad.eq.0) then
            goto 10
        endif
        if (valeur .lt. 0) then
            booneg = .true.
        else
            boopos = .true.
            if (dtcou .gt. 0) then
                if (valeur .le. dtcou) then
                    dtcou = valeur
                    nbmcfl = ima
                endif
            else
                dtcou = valeur
            endif
        endif
 10     continue
    end do
!
    call getvtx('SCHEMA_TEMPS', 'STOP_CFL', iocc=1, scal=stocfl, nbret=n1)
!
! BOOPOS=TRUE SI L'ON A CALCULE DTCOU POUR AU MOINS UN ELEMENT
    if (boopos) then
        if (booneg) then
            call utmess('A', 'DYNAMIQUE_3')
        endif
!
!       VERIFICATION DE LA CONFORMITE DE LA LISTE D'INSTANTS
        call utdidt('L', sddisc, 'LIST', 'NBINST',&
                    vali_ = nbinst)
        call jeveuo(sddisc//'.DITR', 'L', vr=ditr)
!
        call dismoi('NOM_MAILLA', mo, 'MODELE', repk=mail)
        call jenuno(jexnum(mail//'.NOMMAI', nbmcfl), maicfl)
!
!
        if (ndynlo(sddyna,'DIFF_CENT')) then
            dtcou = dtcou / (2.d0)
            call utmess('I', 'DYNAMIQUE_5', sk=maicfl, sr=dtcou)
        else
            if (ndynlo(sddyna,'TCHAMWA')) then
                phi=ndynre(sddyna,'PHI')
                dtcou = dtcou/(phi*2.d0)
                call utmess('I', 'DYNAMIQUE_6', sk=maicfl, sr=dtcou)
            else
                call utmess('F', 'DYNAMIQUE_1')
            endif
        endif
!
        do i = 1, nbinst-1
            if (ditr(i+1)-ditr(i) .gt. dtcou) then
                if (stocfl(1:3) .eq. 'OUI') then
                    call utmess('F', 'DYNAMIQUE_2')
                else
                    call utmess('A', 'DYNAMIQUE_2')
                endif
            endif
        end do
!
    else if (stocfl(1:3).eq.'OUI') then
        call utmess('F', 'DYNAMIQUE_4')
    else if (stocfl(1:3).eq.'NON') then
        call utmess('A', 'DYNAMIQUE_4')
    endif
!
    call jedema()
!
end subroutine
