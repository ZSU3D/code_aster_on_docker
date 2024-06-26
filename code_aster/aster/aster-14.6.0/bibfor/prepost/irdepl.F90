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

subroutine irdepl(chamno, ifi, form, titre,&
                  nomsd, nomsym, numord, lcor, nbnot,&
                  numnoe, nbcmp, nomcmp, lsup, borsup,&
                  linf, borinf, lmax, lmin, lresu,&
                  formr)
! aslint: disable=W1504
    implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/getres.h"
#include "asterfort/dismoi.h"
#include "asterfort/imprsd.h"
#include "asterfort/irccmp.h"
#include "asterfort/ircnc8.h"
#include "asterfort/ircnrl.h"
#include "asterfort/ircrrl.h"
#include "asterfort/irdesc.h"
#include "asterfort/irdesr.h"
#include "asterfort/irdrsr.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jenonu.h"
#include "asterfort/jenuno.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnom.h"
#include "asterfort/jexnum.h"
#include "asterfort/lxcaps.h"
#include "asterfort/lxlgut.h"
#include "asterfort/nbec.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"
#include "asterfort/as_deallocate.h"
#include "asterfort/as_allocate.h"
!
    character(len=*) :: chamno, form, titre, nomsd, nomsym
    character(len=*) :: nomcmp(*), formr
    integer :: nbnot, ifi, numnoe(*), nbcmp
    integer :: numord
    aster_logical :: lcor
    aster_logical :: lsup, linf, lmax, lmin
    aster_logical :: lresu
    real(kind=8) :: borsup, borinf
!_____________________________________________________________________
!        IMPRESSION D'UN CHAMNO A COMPOSANTES REELLES OU COMPLEXES
!         AU FORMAT IDEAS, ...
!     ENTREES:
!        CHAMNO : NOM DU CHAMNO A ECRIRE
!        IFI    : NUMERO LOGIQUE DU FICHIER DE SORTIE
!        FORM   : FORMAT DES SORTIES: IDEAS, RESULTAT
!        TITRE  : TITRE POUR IMPRESSION IDEAS
!        NOMSD  : NOM DU RESULTAT D'OU PROVIENT LE CHAMNO A IMPRIMER.
!        NOMSYM : NOM SYMBOLIQUE
!        NUMORD : NUMERO DE CALCUL, MODE,  CAS DE CHARGE
!        LCOR   : IMPRESSION DES COORDONNEES  .TRUE. IMPRESSION
!        NBNOT  : NOMBRE DE NOEUDS A IMPRIMER
!        NUMNOE : NUMEROS DES NOEUDS A IMPRIMER
!        NBCMP  : NOMBRE DE COMPOSANTES A IMPRIMER AU FORMAT RESULTAT
!        NOMCMP : NOMS DES COMPOSANTES A IMPRIMER AU FORMAT RESULTAT
!        LSUP   : =.TRUE. INDIQUE PRESENCE D'UNE BORNE SUPERIEURE
!        BORSUP : VALEUR DE LA BORNE SUPERIEURE
!        LINF   : =.TRUE. INDIQUE PRESENCE D'UNE BORNE INFERIEURE
!        BORINF : VALEUR DE LA BORNE INFERIEURE
!        LMAX   : =.TRUE. INDIQUE IMPRESSION VALEUR MAXIMALE
!        LMIN   : =.TRUE. INDIQUE IMPRESSION VALEUR MINIMALE
!        LRESU  : =.TRUE. INDIQUE IMPRESSION D'UN CONCEPT RESULTAT
!        FORMR  : FORMAT D'ECRITURE DES REELS SUR "RESULTAT"
!     ------------------------------------------------------------------
!
    character(len=1) :: type
    integer :: gd, lgconc, lgch16
    aster_logical :: lmasu
    character(len=8) :: nomsdr, nomma, nomgd, cbid, forma
    character(len=16) :: nomcmd, nosy16
    character(len=19) :: chamn
    character(len=24) :: nomnu
    character(len=24) :: valk(3)
    character(len=80) :: titmai
!     ------------------------------------------------------------------
!
!-----------------------------------------------------------------------
    integer :: iad, iaec, iaprno
    integer :: iavale, ibid, ino, iret, itype
    integer :: jncmp, nbcmpt
    integer :: nbno, nbnot2, nbtitr, ncmpmx, ndim, nec, num
    character(len=8), pointer :: nomnoe(:) => null()
    integer, pointer :: vnumnoe(:) => null()
    real(kind=8), pointer :: vale(:) => null()
    character(len=24), pointer :: refe(:) => null()
    real(kind=8), pointer :: coor(:) => null()
    integer, pointer :: desc(:) => null()
    character(len=80), pointer :: titr(:) => null()
    integer, pointer :: nueq(:) => null()
!
!-----------------------------------------------------------------------
    call jemarq()
!
    chamn = chamno(1:19)
    forma = form
    nosy16 = nomsym
    nbcmpt=0
    call jeveuo(chamn//'.REFE', 'L', vk24=refe)
!     --- NOM DU MAILLAGE
    nomma = refe(1) (1:8)
!     --- NOM DU PROFIL AUX NOEUDS ASSOCIE S'IL EXISTE
    nomnu = refe(2)
!
    call jelira(chamn//'.VALE', 'TYPE', cval=type)
    if (type(1:1) .eq. 'R') then
        itype = 1
    else if (type(1:1).eq.'C') then
        itype = 2
    else if (type(1:1).eq.'I') then
        itype = 3
    else if (type(1:1).eq.'K') then
        itype = 4
    else
        call getres(cbid, cbid, nomcmd)
        call utmess('A', 'PREPOST_97', sk=type(1:1))
        goto 999
    endif
!
    call jeveuo(chamn//'.VALE', 'L', iavale)
!
    call jeveuo(chamn//'.DESC', 'L', vi=desc)
    gd = desc(1)
    num = desc(2)
!
    call jenuno(jexnum('&CATA.GD.NOMGD', gd), nomgd)
!
!     --- NOMBRE D'ENTIERS CODES POUR LA GRANDEUR NOMGD
    nec = nbec(gd)
!
    call jeexin('&&IRDEPL.ENT_COD', iret)
    if (iret .ne. 0) call jedetr('&&IRDEPL.ENT_COD')
    call wkvect('&&IRDEPL.ENT_COD', 'V V I', nec, iaec)
    call jelira(jexnum('&CATA.GD.NOMCMP', gd), 'LONMAX', ncmpmx)
    call jeveuo(jexnum('&CATA.GD.NOMCMP', gd), 'L', iad)
    call wkvect('&&IRDEPL.NUM_CMP', 'V V I', ncmpmx, jncmp)
!
    if (nbcmp .ne. 0) then
!       - NOMBRE ET NOMS DES COMPOSANTES DE LA LISTE DES COMPOSANTES
!         DONT ON DEMANDE L'IMPRESSION PRESENTES DANS LA GRANDEUR NOMGD
        call irccmp(' ', nomgd, ncmpmx, zk8(iad), nbcmp,&
                    nomcmp, nbcmpt, jncmp)
!       - SI SELECTION SUR LES COMPOSANTES ET AUCUNE PRESENTE DANS LE
!       - CHAMP A IMPRIMER ALORS IL N'Y A RIEN A FAIRE
        if (nbcmpt .eq. 0) goto 9997
    endif
!
!     --- SI LE CHAMP EST A REPRESENTATION CONSTANTE: RIEN DE SPECIAL
!
!     --- SI LE CHAMP EST DECRIT PAR UN "PRNO":
    if (num .ge. 0) then
        call jeveuo(nomnu(1:19)//'.NUEQ', 'L', vi=nueq)
        call jenonu(jexnom(nomnu(1:19)//'.LILI', '&MAILLA'), ibid)
        call jeveuo(jexnum(nomnu(1:19)//'.PRNO', ibid), 'L', iaprno)
    endif
!
!     --- NOMBRE DE NOEUDS DU MAILLAGE: NBNO
    call dismoi('NB_NO_MAILLA', nomma, 'MAILLAGE', repi=nbno)
!
!     --- CREATION LISTES DES NOMS ET DES NUMEROS DES NOEUDS A IMPRIMER
    AS_ALLOCATE(vk8=nomnoe, size=nbno)
    AS_ALLOCATE(vi=vnumnoe, size=nbno)
    if (nbnot .eq. 0) then
!       - IL N'Y A PAS EU DE SELECTION SUR ENTITES TOPOLOGIQUES EN
!         OPERANDE DE IMPR_RESU => ON PREND TOUS LES NOEUDS DU MAILLAGE
        do ino = 1, nbno
            call jenuno(jexnum(nomma//'.NOMNOE', ino), nomnoe(ino))
            vnumnoe(ino) = ino
            nbnot2= nbno
        end do
!
    else
!       - IL Y A EU SELECTION SUR DES ENTITES TOPOLOGIQUES => ON NE
!         PREND QUE LES NOEUDS DEMANDES (APPARTENANT A UNE LISTE DE
!         NOEUDS, DE MAILLES, DE GPES DE NOEUDS OU DE GPES DE MAILLES)
        do ino = 1, nbnot
            vnumnoe(ino) = numnoe(ino)
            call jenuno(jexnum(nomma//'.NOMNOE', numnoe(ino)), nomnoe(ino))
        end do
        nbnot2= nbnot
    endif
! --- RECHERCHE DES COORDONNEES ET DE LA DIMENSION -----
    call dismoi('DIM_GEOM_B', nomma, 'MAILLAGE', repi=ndim)
    call jeveuo(nomma//'.COORDO    .VALE', 'L', vr=coor)
!
    if (form .eq. 'RESULTAT') then
        if (itype .eq. 1 .and. num .ge. 0) then
            call ircnrl(ifi, nbnot2, zi(iaprno), nueq, nec,&
                        zi(iaec), ncmpmx, zr(iavale), zk8(iad), nomnoe,&
                        lcor, ndim, coor, vnumnoe, nbcmpt,&
                        zi(jncmp), lsup, borsup, linf, borinf,&
                        lmax, lmin, formr)
        else if (itype.eq.1.and.num.lt.0) then
            call ircrrl(ifi, nbnot2, desc, nec, zi(iaec),&
                        ncmpmx, zr( iavale), zk8(iad), nomnoe, lcor,&
                        ndim, coor, vnumnoe, nbcmpt, zi(jncmp),&
                        lsup, borsup, linf, borinf, lmax,&
                        lmin, formr)
        else if (itype.eq.2.and.num.ge.0) then
            call ircnc8(ifi, nbnot2, zi(iaprno), nueq, nec,&
                        zi(iaec), ncmpmx, zc(iavale), zk8(iad), nomnoe,&
                        lcor, ndim, coor, vnumnoe, nbcmpt,&
                        zi(jncmp), lsup, borsup, linf, borinf,&
                        lmax, lmin, formr)
        else if (itype.eq.2.and.num.lt.0) then
            call utmess('E', 'PREPOST2_35', sk=forma)
        else if ((itype.eq.3).or.(itype.eq.4)) then
            call imprsd('CHAMP', chamno, ifi, nomsd)
        endif
!
    else if (form(1:5).eq.'IDEAS') then
!  ---  ON CHERCHE SI MAILLAGE IDEAS ---
        lmasu=.false.
        call jeexin(nomma//'           .TITR', iret)
        if (iret .ne. 0) then
            call jeveuo(nomma//'           .TITR', 'L', vk80=titr)
            call jelira(nomma//'           .TITR', 'LONMAX', nbtitr)
            if (nbtitr .ge. 1) then
                titmai=titr(1)
                if (titmai(10:31) .eq. 'AUTEUR=INTERFACE_IDEAS') then
                    lmasu=.true.
                endif
            endif
        endif
!
        if (itype .eq. 1 .and. num .ge. 0) then
            call irdesr(ifi, nbnot2, zi(iaprno), nueq, nec,&
                        zi(iaec), ncmpmx, zr(iavale), zk8(iad), titre,&
                        nomnoe, nomsd, nomsym, numord, vnumnoe,&
                        lmasu, nbcmp, zi(jncmp), nomcmp)
        else if (itype.eq.1.and.num.lt.0) then
            call irdrsr(ifi, nbnot2, desc, nec, zi(iaec),&
                        ncmpmx, zr( iavale), zk8(iad), titre, nomnoe,&
                        nomsd, nomsym, numord, vnumnoe, lmasu,&
                        nbcmp, zi(jncmp), nomcmp)
        else if (itype.eq.2.and.num.ge.0) then
            call irdesc(ifi, nbnot2, zi(iaprno), nueq, nec,&
                        zi(iaec), ncmpmx, zc(iavale), zk8(iad), titre,&
                        nomnoe, nomsd, nomsym, numord, vnumnoe,&
                        lmasu)
        else if (itype.eq.2.and.num.lt.0) then
            call utmess('E', 'PREPOST2_35', sk=forma)
        endif
!
    endif
    goto 9998
9997 continue
    lgch16=lxlgut(nosy16)
    if (.not.lresu) then
        valk(1) = nosy16(1:lgch16)
        valk(2) = nomgd
        call utmess('A', 'PREPOST2_40', nk=2, valk=valk)
    else
        nomsdr=nomsd
        lgconc=lxlgut(nomsdr)
        valk(1) = nosy16(1:lgch16)
        valk(2) = nomsdr(1:lgconc)
        valk(3) = nomgd
        call utmess('A', 'PREPOST2_41', nk=3, valk=valk)
    endif
9998 continue
    call jedetr('&&IRDEPL.ENT_COD')
    call jedetr('&&IRDEPL.NUM_CMP')
    AS_DEALLOCATE(vk8=nomnoe)
    AS_DEALLOCATE(vi=vnumnoe)
    AS_DEALLOCATE(vr=vale)
999 continue
    call jedema()
end subroutine
