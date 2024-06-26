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

subroutine op0046()
!
implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/r8vide.h"
#include "asterfort/allir8.h"
#include "asterfort/assert.h"
#include "asterfort/cochre.h"
#include "asterfort/copisd.h"
#include "asterfort/detmat.h"
#include "asterfort/dismoi.h"
#include "asterfort/fointe.h"
#include "asterfort/getvid.h"
#include "asterfort/getvr8.h"
#include "asterfort/getvtx.h"
#include "asterfort/gnomsd.h"
#include "asterfort/infdbg.h"
#include "asterfort/infmaj.h"
#include "asterfort/jedema.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/compStrx.h"
#include "asterfort/mecham.h"
#include "asterfort/mechti.h"
#include "asterfort/mestat.h"
#include "asterfort/nmlect.h"
#include "asterfort/rsexch.h"
#include "asterfort/rsnoch.h"
#include "asterfort/rssepa.h"
#include "asterfort/titre.h"
#include "asterfort/utmess.h"
#include "asterfort/vrcins.h"
#include "asterfort/vrcref.h"
#include "asterfort/compStress.h"
!

!
! --------------------------------------------------------------------------------------------------
!
! MECA_STATIQUE
!
! --------------------------------------------------------------------------------------------------
!
    integer :: nh, nbchre, n1, n4, n5, n7
    integer :: iordr, nbmax, nchar, jchar
    integer :: iocc, nfon, iret, i, nbuti
    integer :: ifm, niv, ier
    real(kind=8) :: temps, time, alpha
    real(kind=8) :: rundf
    character(len=1) :: base, typcoe
    character(len=2) :: codret
    character(len=8) :: k8bla, result, listps, nomode, noma
    character(len=8) :: nomfon, charep, kstr
    character(len=16) :: nosy
    character(len=19) :: solver, list_load, ligrel, lisch2
    character(len=19) :: matass
    character(len=24) :: model, cara_elem, charge, fomult
    character(len=24) :: chtime, chamgd
    character(len=24) :: chamel, chstrx
    character(len=24) :: chgeom, chcara(18), chharm
    character(len=24) :: chvarc, chvref
    character(len=24) :: mate, noobj, compor
    aster_logical :: exipou
    complex(kind=8) :: calpha
    real(kind=8), pointer :: vale(:) => null()
    integer, pointer :: ordr(:) => null()
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
    rundf=r8vide()
!
! -- TITRE
!
    call titre()
    call infmaj()
    call infdbg('MECA_STATIQUE', ifm, niv)
!
! -- INITIALISATIONS
!
    base ='G'
    matass = '&&OP0046.MATR_RIGI'
    chtime = ' '
    charge = ' '
    nh = 0
    typcoe = ' '
    charep = ' '
    k8bla = ' '
    chstrx = ' '
    alpha = 0.d0
    calpha = (0.d0 , 0.d0)
    nfon = 0
    chvarc='&&OP0046.VARC'
    chvref='&&OP0046.VREF'
!
! --- LECTURE DES OPERANDES DE LA COMMANDE
!
    call nmlect(result, model, mate, cara_elem,&
                list_load, solver)
!
! - For multifiber beams
!
    compor = mate(1:8)//'.COMPOR'
!
! -- ACCES A LA LISTE DES CHARGGES
!
    charge = list_load//'.LCHA'
    fomult = list_load//'.FCHA'
!
! -- ACCES A LA LISTE D'INSTANTS
!
    call getvid(' ', 'LIST_INST', scal=listps, nbret=n4)
    if (n4 .eq. 0) then
        call getvr8(' ', 'INST', scal=temps, nbret=n5)
        if (n5 .eq. 0) then
            temps = 0.d0
        endif
        listps = result
        call allir8('V', listps, 1, [temps])
    endif
!
! ---- CALCUL MECANIQUE
!
    call mestat(model, fomult, list_load, mate, cara_elem,&
                listps, solver, compor, matass)
!
! ---- CALCUL DE L'OPTION SIEF_ELGA OU RIEN
!
    nomode = model(1:8)
    ligrel = nomode//'.MODELE'
!
    call dismoi('NOM_MAILLA', nomode, 'MODELE', repk=noma)
    call dismoi('NB_CHAMP_MAX', result, 'RESULTAT', repi=nbmax)
    call getvtx(' ', 'OPTION', scal=nosy, nbret=n7)
    ASSERT(nosy.eq.'SIEF_ELGA'.or.nosy.eq.'SANS')
!
!   A-t-on des POU_D_EM qui utilisent le champ STRX_ELGA en lineaire
    call dismoi('EXI_STR2', nomode, 'MODELE', repk=kstr)
    if ((nosy.eq.'SANS') .and. (kstr(1:3).eq.'NON')) goto 999
!
!   A-t-on des VARC
    call dismoi('EXI_VARC', mate, 'CHAM_MATER', repk=k8bla)
!   On interdit provisoirement les POU_D_EM avec les VARC
    if ((k8bla(1:3).eq.'OUI') .and. (kstr(1:3).eq.'OUI')) then
        call utmess('F', 'MECASTATIQUE_1')
    endif
!
    exipou = .false.
    call dismoi('EXI_POUX', model, 'MODELE', repk=k8bla)
    if (k8bla(1:3) .eq. 'OUI') exipou = .true.
    call jelira(charge, 'LONMAX', nchar)
!
    if (exipou) then
        call jeveuo(charge, 'L', jchar)
        call cochre(zk24(jchar), nchar, nbchre, iocc)
        if (nbchre .gt. 1) then
            call utmess('F', 'MECASTATIQUE_25')
        endif
!
        typcoe = 'R'
        alpha = 1.d0
        if (iocc .gt. 0) then
            call getvid('EXCIT', 'CHARGE', iocc=iocc, scal=charep, nbret=n1)
            call getvid('EXCIT', 'FONC_MULT', iocc=iocc, scal=nomfon, nbret=nfon)
        endif
    endif
!
    call jeveuo(listps//'           .VALE', 'L', vr=vale)
    do iordr = 1, nbmax
        call rsexch(' ', result, 'DEPL', iordr, chamgd,&
                    iret)
        if (iret .gt. 0) goto 13
!
        call mecham(nosy, nomode, cara_elem, nh, chgeom,&
                    chcara, chharm, iret)
        if (iret .ne. 0) goto 13
        time = vale(iordr)
        call mechti(chgeom(1:8), time, rundf, rundf, chtime)
        call vrcins(model, mate, cara_elem, time, chvarc(1:19),&
                    codret)
        call vrcref(model(1:8), mate(1:8), cara_elem(1:8), chvref(1:19))
!
        if (exipou .and. nfon .ne. 0) then
            call fointe('F ', nomfon, 1, ['INST'], [time],&
                        alpha, ier)
        endif
!
        if (kstr(1:3) .eq. 'OUI') then
            call rsexch(' ', result, 'STRX_ELGA', iordr, chstrx,&
                        iret)
!         -- SI LE CHAMP A DEJE ETE CALCULE :
            if (iret .eq. 0) goto 62
            call compStrx(nomode, ligrel, compor,&
                          chamgd, chgeom, mate  , chcara ,&
                          chvarc, chvref, &
                          base  , chstrx, iret  ,&
                          exipou, charep, typcoe, alpha, calpha)
!
            call rsnoch(result, 'STRX_ELGA', iordr)
        endif
 62     continue
        if (nosy .eq. 'SIEF_ELGA') then
            call rsexch(' ', result, nosy, iordr, chamel,&
                        iret)
!           -- SI LE CHAMP A DEJE ETE CALCULE :
            if (iret .eq. 0) goto 13
            call compStress(nomode, ligrel, compor,&
                            chamgd, chgeom, mate  ,&
                            chcara, chtime, chharm,&
                            chvarc, chvref, chstrx,&
                            base  , chamel, iret  )
            call rsnoch(result, nosy, iordr)
        endif
 13     continue
!
!
    end do
!
!
999 continue
!
!     ----------------------------------------------------------------
! --- STOCKAGE POUR CHAQUE NUMERO D'ORDRE DU MODELE, DU CHAMP MATERIAU
!     DES CARACTERISTIQUES ELEMENTAIRES ET DES CHARGES DANS LA SD RESU
!     ----------------------------------------------------------------
!             12345678    90123    45678901234
    noobj ='12345678'//'.1234'//'.EXCIT.INFC'
    call gnomsd(' ', noobj, 10, 13)
    lisch2 = noobj(1:19)
    call dismoi('NB_CHAMP_UTI', result, 'RESULTAT', repi=nbuti)
    call jeveuo(result//'           .ORDR', 'L', vi=ordr)
    do i = 1, nbuti
        iordr=ordr(i)
        call rssepa(result, iordr, model(1:8), mate(1:8), cara_elem(1:8),&
                    lisch2(1:19))
    end do
!
!     -----------------------------------------------
! --- COPIE DE LA SD INFO_CHARGE DANS LA BASE GLOBALE
!     -----------------------------------------------
    call copisd(' ', 'G', list_load, lisch2(1:19))
!
!     -----------------------------------------------
! --- MENAGE FINAL
!     -----------------------------------------------
!
! --- DESTRUCTION DE TOUTES LES MATRICES CREEES
!
    call detmat()
!
    call jedema()
!
end subroutine
