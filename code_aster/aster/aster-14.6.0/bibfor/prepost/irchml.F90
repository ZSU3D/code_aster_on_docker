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

subroutine irchml(chamel, ifi, form, titre,&
                  loc, nomsd, nomsym, numord, lcor,&
                  nbnot, numnoe, nbmat, nummai, nbcmp,&
                  nomcmp, lsup, borsup, linf, borinf,&
                  lmax, lmin, formr, ncmp,&
                  nucmp)
! aslint: disable=W1504
    implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/celcel.h"
#include "asterfort/celces.h"
#include "asterfort/celver.h"
#include "asterfort/cesimp.h"
#include "asterfort/cncinv.h"
#include "asterfort/detrsd.h"
#include "asterfort/dismoi.h"
#include "asterfort/getvis.h"
#include "asterfort/i2trgi.h"
#include "asterfort/imprsd.h"
#include "asterfort/iradhs.h"
#include "asterfort/irccmp.h"
#include "asterfort/ircecl.h"
#include "asterfort/ircecs.h"
#include "asterfort/ircerl.h"
#include "asterfort/ircers.h"
#include "asterfort/irsspt.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jenuno.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexatr.h"
#include "asterfort/jexnum.h"
#include "asterfort/lxcaps.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"
!
    character(len=*) :: chamel, nomcmp(*), form, titre, loc, nomsd, nomsym
    character(len=*) :: formr
    real(kind=8) :: borsup, borinf
    integer :: nbnot, numnoe(*), nbmat, nummai(*), nbcmp, ifi, numord, ncmp
    integer :: nucmp(*)
    aster_logical :: lcor, lsup, linf, lmax, lmin
!        IMPRESSION D'UN CHAM_ELEM A COMPOSANTES REELLES OU COMPLEXES
!         AU FORMAT IDEAS, RESULTAT
!  ENTREES:
!     CHAMEL : NOM DU CHAM_ELEM A ECRIRE
!     IFI    : NUMERO LOGIQUE DU FICHIER DE SORTIE
!     FORM   : FORMAT DES SORTIES: IDEAS, RESULTAT
!     TITRE  : TITRE POUR IDEAS
!     LOC    : LOCALISATION DES VALEURS ( ELNO OU ELGA)
!     NOMSD  : NOM DU RESULTAT
!     NOMSYM : NOM SYMBOLIQUE
!     NUMORD : NUMERO D'ORDRE DU CHAMP DANS LE RESULTAT_COMPOSE.
!     LCOR   : =.TRUE.  IMPRESSION DES COORDONNES DE NOEUDS DEMANDEE
!     NBNOT  : NOMBRE DE NOEUDS A IMPRIMER
!     NUMNOE : NUMEROS DES NOEUDS A IMPRIMER
!     NBMAT  : NOMBRE DE MAILLES A IMPRIMER
!     NUMMAI : NUMEROS DES MAILLES A IMPRIMER
!     NBCMP  : NOMBRE DE COMPOSANTES A IMPRIMER
!     NOMCMP : NOMS DES COMPOSANTES A IMPRIMER
!     LSUP   : =.TRUE.  INDIQUE PRESENCE D'UNE BORNE SUPERIEURE
!     BORSUP : VALEUR DE LA BORNE SUPERIEURE
!     LINF   : =.TRUE.  INDIQUE PRESENCE D'UNE BORNE INFERIEURE
!     BORINF : VALEUR DE LA BORNE INFERIEURE
!     LMAX   : =.TRUE.  INDIQUE IMPRESSION VALEUR MAXIMALE
!     LMIN   : =.TRUE.  INDIQUE IMPRESSION VALEUR MINIMALE
!     FORMR  : FORMAT D'ECRITURE DES REELS SUR "RESULTAT"
! ----------------------------------------------------------------------
!
    character(len=1) :: type
    integer :: gd, jcelv, iprem
    integer :: vali(2), versio
    character(len=8) :: nomma, nomgd, nomel, nomno
    character(len=16) :: nomsy2
    character(len=19) :: chame, chames
    character(len=24) :: nolili, nconec, ncncin, valk(2)
    character(len=80) :: titmai
    aster_logical :: lmasu
    integer :: iad, iadr, iel
    integer :: im, in, ino, iret, itype
    integer :: jcncin, jcnx, jcoor, jdrvlc, jliste
    integer :: jlongr, jnbnm, jncmp, jnmn, jnoel
    integer :: jpnt, jtypm, kk, libre, lon1
    integer :: maxnod, n, n2, nbcmpt, nbel, nbgrel, nbm
    integer :: nbmac, nbn, nbno, nbtitr, nbtma, ncmpmx
    integer :: ndim, ngr
    integer, pointer :: permuta(:) => null()
    character(len=8), pointer :: lgrf(:) => null()
    integer, pointer :: celd(:) => null()
    integer, pointer :: liel(:) => null()
    character(len=80), pointer :: titr(:) => null()
    character(len=24), pointer :: celk(:) => null()
!-----------------------------------------------------------------------
    data iprem /0/
!
    call jemarq()
    jcoor=1
    iprem=iprem+1
    chame = chamel(1:19)
    nomsy2 = nomsym
    nbcmpt=0
    call jelira(chame//'.CELV', 'TYPE', cval=type)
    if (type(1:1) .eq. 'R') then
        itype = 1
    else if (type(1:1).eq.'C') then
        itype = 2
    else if (type(1:1).eq.'I') then
        itype = 3
    else if (type(1:1).eq.'K') then
        itype = 4
    else
        call utmess('A', 'PREPOST_97', sk=type(1:1))
        goto 999
    endif
!
!
!     -- ON VERIFIE QUE LE CHAM_ELEM N'EST PAS TROP DYNAMIQUE :
!        SINON ON LE REMET SOUS SON ANCIENNE FORME :
!     ----------------------------------------------------------
    call celver(chame, 'NBVARI_CST', 'COOL', kk)
    if (kk .eq. 1) then
        if (iprem .eq. 1) then
            call utmess('I', 'PREPOST_2')
        endif
        call celcel('NBVARI_CST', chame, 'V', '&&IRCHML.CHAMEL1')
        chame= '&&IRCHML.CHAMEL1'
    endif
!
!     LES CHAMPS A SOUS-POINTS SONT TRAITES DIFFEREMMENT:
    call celver(chame, 'NBSPT_1', 'COOL', kk)
    if (kk .eq. 1) then
        if (form .eq. 'RESULTAT') then
            chames='&&IRCHML_CES'
            call celces(chame, 'V', chames)
!         SI VALE_MAX/VALE_MIN EST PRESENTE, ON IMPRIME LES MIN/MAX
            if (lmax .or. lmin) then
                call irsspt(chames, ifi, nbmat, nummai, nbcmp,&
                            nomcmp, lsup, linf, lmax, lmin,&
                            borinf, borsup)
            else
!           SINON ON IMPRIME LE CHAMP TEL QUEL
                call utmess('I', 'PREPOST_98', sk=nomsy2)
                call cesimp('&&IRCHML_CES', ifi, nbmat, nummai)
            endif
            call detrsd('CHAM_ELEM_S', chames)
            goto 999
        else
            call utmess('I', 'PREPOST_99', sk=nomsy2)
        endif
        call celcel('PAS_DE_SP', chame, 'V', '&&IRCHML.CHAMEL2')
        chame= '&&IRCHML.CHAMEL2'
    endif
!
    call jeveuo(chame//'.CELD', 'L', vi=celd)
    gd = celd(1)
    ngr = celd(2)
    call jenuno(jexnum('&CATA.GD.NOMGD', gd), nomgd)
    call jelira(jexnum('&CATA.GD.NOMCMP', gd), 'LONMAX', ncmpmx)
    call jeveuo(jexnum('&CATA.GD.NOMCMP', gd), 'L', iad)
    call wkvect('&&IRCHML.NUM_CMP', 'V V I', ncmpmx, jncmp)
    if (nbcmp .ne. 0 .and. nomgd .ne. 'VARI_R') then
        call irccmp(' ', nomgd, ncmpmx, zk8(iad), nbcmp,&
                    nomcmp, nbcmpt, jncmp)
    endif
    call jeveuo(chame//'.CELK', 'L', vk24=celk)
    nolili = celk(1)
    call jeveuo(nolili(1:19)//'.LGRF', 'L', vk8=lgrf)
    nomma = lgrf(1)
!     RECHERCHE DU NOMBRE D'ELEMENTS : NBEL
    call jelira(nomma//'.NOMMAI', 'NOMMAX', nbel)
    call dismoi('NB_NO_MAILLA', nomma, 'MAILLAGE', repi=nbno)
    call wkvect('&&IRCHML.NOMMAI', 'V V K8', nbel, jnoel)
    call wkvect('&&IRCHML.NBNOMA', 'V V I', nbel, jnbnm)
    do iel = 1, nbel
        call jenuno(jexnum(nomma//'.NOMMAI', iel), nomel)
        zk8(jnoel-1+iel) = nomel
        call jelira(jexnum(nomma//'.CONNEX', iel), 'LONMAX', nbn)
        zi(jnbnm-1+iel) = nbn
    end do
    call jeveuo(chame//'.CELV', 'L', jcelv)
    call jeveuo(nolili(1:19)//'.LIEL', 'L', vi=liel)
    call jelira(nolili(1:19)//'.LIEL', 'NUTIOC', nbgrel)
    call jeveuo(jexatr(nolili(1:19)//'.LIEL', 'LONCUM'), 'L', jlongr)
    if (ngr .ne. nbgrel) then
        vali(1) = ngr
        vali(2) = nbgrel
        valk(1) = chame
        valk(2) = nolili
        call utmess('F', 'CALCULEL_19', nk=2, valk=valk, ni=2,&
                    vali=vali)
    endif
! ---------------------------------------------------------------------
!                    F O R M A T   R E S U L T A T
! ---------------------------------------------------------------------
    if (form .eq. 'RESULTAT') then
!
        if (nbmat .eq. 0 .and. nbnot .ne. 0) then
            nconec = nomma//'.CONNEX'
            call jelira(nconec, 'NMAXOC', nbtma)
            call wkvect('&&IRCHML.MAILLE', 'V V I', nbtma, jliste)
            ncncin = '&&IRCHML.CONNECINVERSE  '
            call jeexin(ncncin, n2)
            if (n2 .eq. 0) call cncinv(nomma, [0], 0, 'V', ncncin)
            libre = 1
            call jeveuo(jexatr(ncncin, 'LONCUM'), 'L', jdrvlc)
            call jeveuo(jexnum(ncncin, 1), 'L', jcncin)
            do in = 1, nbnot, 1
                n = numnoe(in)
                nbm = zi(jdrvlc + n+1-1) - zi(jdrvlc + n-1)
                iadr = zi(jdrvlc + n-1)
                call i2trgi(zi(jliste), zi(jcncin+iadr-1), nbm, libre)
            end do
            nbmac = libre - 1
        else
            nbmac = nbmat
            jliste = 1
            if (nbmat .ne. 0) then
                call wkvect('&&IRCHML.MAILLE', 'V V I', nbmac, jliste)
                do im = 1, nbmac
                    zi(jliste+im-1) = nummai(im)
                end do
            endif
        endif
!
        jcnx = 1
        if (loc .eq. 'ELNO') then
            call wkvect('&&IRCHML.NOMNOE', 'V V K8', nbno, jnmn)
            do ino = 1, nbno
                call jenuno(jexnum(nomma//'.NOMNOE', ino), nomno)
                zk8(jnmn-1+ino) = nomno
            end do
            call jeveuo(nomma//'.CONNEX', 'L', jcnx)
            call jeveuo(jexatr(nomma//'.CONNEX', 'LONCUM'), 'L', jpnt)
! --
! --  RECHERCHE DES COORDONNEES ET DE LA DIMENSION
!
            if (lcor) then
                call dismoi('DIM_GEOM_B', nomma, 'MAILLAGE', repi=ndim)
                call jeveuo(nomma//'.COORDO    .VALE', 'L', jcoor)
            endif
        else
            jnmn=1
            jpnt=1
        endif
!
        if (itype .eq. 1) then
            call ircerl(ifi, nbel, liel, nbgrel, zi(jlongr),&
                        ncmpmx, zr(jcelv), zk8(iad), zk8(jnoel), loc,&
                        celd, zi(jcnx), zi( jpnt), zk8(jnmn), nbcmpt,&
                        zi(jncmp), nbnot, numnoe, nbmac, zi( jliste),&
                        lsup, borsup, linf, borinf, lmax,&
                        lmin, lcor, ndim, zr( jcoor), nolili(1:19),&
                        formr, ncmp, nucmp)
        else if (itype.eq.2) then
            call ircecl(ifi, nbel, liel, nbgrel, zi(jlongr),&
                        ncmpmx, zc(jcelv), zk8(iad), zk8(jnoel), loc,&
                        celd, zi(jcnx), zi( jpnt), zk8(jnmn), nbcmpt,&
                        zi(jncmp), nbnot, numnoe, nbmac, zi( jliste),&
                        lsup, borsup, linf, borinf, lmax,&
                        lmin, lcor, ndim, zr( jcoor), nolili(1:19),&
                        formr, ncmp, nucmp)
        else if ((itype.eq.3).or.(itype.eq.4)) then
            call imprsd('CHAMP', chamel, ifi, nomsd)
        endif
!
        if (loc .eq. 'ELNO') call jedetr('&&IRCHML.NOMNOE')
        call jedetr('&&IRCHML.MAILLE')
! ---------------------------------------------------------------------
!                    F O R M A T   I D E A S
! ---------------------------------------------------------------------
    else if (form(1:5).eq.'IDEAS') then
        lmasu = .false.
        call jeexin(nomma//'           .TITR', iret)
        if (iret .ne. 0) then
            call jeveuo(nomma//'           .TITR', 'L', vk80=titr)
            call jelira(nomma//'           .TITR', 'LONMAX', nbtitr)
            if (nbtitr .ge. 1) then
                titmai=titr(1)
                if (titmai(10:31) .eq. 'AUTEUR=INTERFACE_IDEAS') lmasu= .true.
            endif
        endif
        call jeveuo(nomma//'.TYPMAIL', 'L', jtypm)
        call getvis(' ', 'VERSION', scal=versio, nbret=iret)
        call jeexin('&IRCHML.PERMUTA', iret)
        if (iret .eq. 0) call iradhs(versio)
        call jeveuo('&&IRADHS.PERMUTA', 'L', vi=permuta)
        call jelira('&&IRADHS.PERMUTA', 'LONMAX', lon1)
        maxnod=permuta(lon1)
        if (itype .eq. 1) then
            call ircers(ifi, liel, nbgrel, zi(jlongr), ncmpmx,&
                        zr(jcelv), nomgd, zk8(iad), titre, zk8(jnoel),&
                        loc, celd, zi(jnbnm), permuta, maxnod,&
                        zi(jtypm), nomsd, nomsym, numord, nbmat,&
                        nummai, lmasu, ncmp, nucmp, nbcmp,&
                        zi(jncmp), nomcmp)
        else if (itype.eq.2) then
            call ircecs(ifi, liel, nbgrel, zi(jlongr), ncmpmx,&
                        zc(jcelv), zk8(iad), titre, zk8(jnoel), loc,&
                        celd, zi( jnbnm), permuta, maxnod, zi(jtypm),&
                        nomsd, nomsym, numord, nbmat, nummai,&
                        lmasu, ncmp, nucmp)
        endif
        call jedetr('&&IRADHS.PERMUTA')
        call jedetr('&&IRADHS.CODEGRA')
        call jedetr('&&IRADHS.CODEPHY')
        call jedetr('&&IRADHS.CODEPHD')
    endif

    call jedetr('&&IRCHML.NUM_CMP')
    call jedetr('&&IRCHML.NOMMAI')
    call jedetr('&&IRCHML.NBNOMA')
    call jedetr('&&IRCHML.MAILLE')
    call jedetr('&&IRCHML.NOMNOE')
    call jedetr('&&IRCHML.VALE')
    call detrsd('CHAM_ELEM', '&&IRCHML.CHAMEL1')
    call detrsd('CHAM_ELEM', '&&IRCHML.CHAMEL2')
999 continue
    call jedema()
end subroutine
