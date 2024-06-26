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

subroutine op0150()
    implicit none
!
!     BUT:
!       LECTURE D'UN RESULTAT SUR FICHIER EXTERNE AU FORMAT :
!        * UNV (IDEAS)
!        * MED
!
! ......................................................................
!
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/getfac.h"
#include "asterc/getres.h"
#include "asterfort/assert.h"
#include "asterfort/carcha.h"
#include "asterfort/dismoi.h"
#include "asterfort/getvid.h"
#include "asterfort/getvis.h"
#include "asterfort/getvr8.h"
#include "asterfort/getvtx.h"
#include "asterfort/infmaj.h"
#include "asterfort/infniv.h"
#include "asterfort/jedema.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jenonu.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnom.h"
#include "asterfort/lect58.h"
#include "asterfort/lrcomm.h"
#include "asterfort/lrfmed.h"
#include "asterfort/lridea.h"
#include "asterfort/lrrefd.h"
#include "asterfort/lrvema.h"
#include "asterfort/lrvemo.h"
#include "asterfort/lxlgut.h"
#include "asterfort/refdaj.h"
#include "asterfort/rsadpa.h"
#include "asterfort/rscrsd.h"
#include "asterfort/rsexpa.h"
#include "asterfort/rsmode.h"
#include "asterfort/rsorac.h"
#include "asterfort/titre.h"
#include "asterfort/ulisop.h"
#include "asterfort/ulopen.h"
#include "asterfort/utmess.h"
#include "asterfort/uttrii.h"
#include "asterfort/wkvect.h"
!
    character(len=6) :: nompro
    parameter (nompro='OP0150')
    integer :: nto, nnu, jlist, nbordr, nbnoch, nvar
    integer :: nbvari, jnume, np, ich, nis
    integer :: iret, nfor, iexi
    integer :: i
    integer :: lordr, iord, nc
    integer :: ibid, nbv, nbtrou
    integer :: mfich, n1, precis, jinst
    integer :: ifm, nivinf
    real(kind=8) :: epsi
    character(len=3) :: prolz
    character(len=4) :: acce
    character(len=8) :: resu, noma, nomo, typcha
    character(len=8) :: crit, blan8
    character(len=8) :: chmat, carael, modele
    character(len=8) :: k8bid
    character(len=8) :: param, noraci
    character(len=10) :: acces
    character(len=16) :: nomcmd, concep, typres
    character(len=16) :: linoch(100), form, noch, k16nom
    character(len=19) :: listr8, listis, ligrel
    character(len=19) :: prchnd, resu19
    character(len=24) :: valk(2)
    character(len=24) :: option
    complex(kind=8) :: cbid
    real(kind=8) :: rbid
    character(len=64) :: nochmd
!
    character(len=8) :: nomgd
    integer :: n2
    integer :: nbcmpv, iaux, n3, nbordr_out
!
    integer :: iinst, nchar
!
    character(len=24) :: ncmpva, ncmpvm
    character(len=7) :: lcmpva
    parameter (lcmpva='NOM_CMP')
    character(len=11) :: lcmpvm
    parameter (lcmpvm='NOM_CMP_MED')
    integer :: jcmpva, jcmpvm
!
!
    aster_logical :: lprem
    character(len=8), pointer :: lgrf(:) => null()
! ----------------------------------------------------------------------
!
    call jemarq()
!
!              12345678
    blan8 = '        '
    chmat = blan8
    carael = blan8
    modele = blan8
!
    call getres(resu, concep, nomcmd)
    call getvtx(' ', 'TYPE_RESU', scal=typres, nbret=n1)
    ASSERT(typres.eq.concep)
!
    call infmaj()
    call infniv(ifm, nivinf)
!
!     --- FORMAT ---
    call getvtx(' ', 'FORMAT', scal=form, nbret=nfor)
    call getvis(' ', 'UNITE', scal=mfich, nbret=n1)
    if ((n1.gt.0) .and. (form.ne.'MED')) then
        k16nom = ' '
        if (ulisop(mfich,k16nom) .eq. 0) then
            call ulopen(mfich, ' ', ' ', 'NEW', 'O')
        endif
    endif
!
!     ---  LISTE DES CHAMPS A LIRE ---
    call getfac('FORMAT_MED', n1)
    if (n1 .gt. 0) then
        nbnoch = n1
        if (nbnoch .gt. 100) then
            nbnoch = -nbnoch
        else
            do i = 1, nbnoch
                call getvtx('FORMAT_MED', 'NOM_CHAM', iocc=i, scal=linoch(i), nbret=n1)
            end do
        endif
    else
        call getvtx(' ', 'NOM_CHAM', nbval=100, vect=linoch, nbret=nbnoch)
    endif
    if (nbnoch .lt. 0) then
        call utmess('F', 'UTILITAI2_86')
    endif
!
!     --- NOMBRE DE VARIABLES INTERNES A LIRE ---
    call getvis(' ', 'NB_VARI', scal=nbvari, nbret=nvar)
!
!     --- MAILLAGE ---
    call getvid(' ', 'MAILLAGE', scal=noma, nbret=nbv)
!
!     --- MODELE ---
    call getvid(' ', 'MODELE', scal=nomo, nbret=nbv)
    if (nbv .ne. 0) then
        ligrel = nomo//'.MODELE'
        call jeveuo(ligrel//'.LGRF', 'L', vk8=lgrf)
        noma = lgrf(1)
    endif
!
!     --- QUELS SONT LES INSTANTS A RELIRE ---
    nnu=0
    nis=0
    call getvtx(' ', 'TOUT_ORDRE', scal=k8bid, nbret=nto)
    if (nto .ne. 0) then
        acces  = 'TOUT_ORDRE'
        nbordr = 100
        iinst  = 0
        goto 20
    endif
!
    call getvis(' ', 'NUME_ORDRE', nbval=0, nbret=nnu)
    if (nnu .ne. 0) then
        acces = 'NUME_ORDRE'
        listis = '&&'//nompro
        nbordr = -nnu
        call wkvect(listis//'.VALE', 'V V I', nbordr, jnume)
        call getvis(' ', 'NUME_ORDRE', nbval=nbordr, vect=zi(jnume), nbret=n1)
!       ICI ON TRIE POUR QUE LE .ORDR DE LA SD_RESULTAT
!       PRODUITE SOIT STRICTEMENT CROISSANT
        call uttrii(zi(jnume), nbordr)
        iinst=0
        goto 20
    endif
!
    call getvid(' ', 'LIST_ORDRE', scal=listis, nbret=nnu)
    if (nnu .ne. 0) then
        acces = 'LIST_ORDRE'
        iinst=0
        call jeveuo(listis//'.VALE', 'L', jnume)
        call jelira(listis//'.VALE', 'LONMAX', nbordr)
        call uttrii(zi(jnume), nbordr)
        goto 20
    endif
!
    call getvr8(' ', 'INST', nbval=0, nbret=nis)
    if (nis .ne. 0) then
        acces = 'INST'
        listr8 = '&&'//nompro
        nbordr = -nis
        iinst=1
        call wkvect(listr8//'.VALE', 'V V R', nbordr, jlist)
        call getvr8(' ', 'INST', nbval=nbordr, vect=zr(jlist), nbret=n1)
        goto 20
    endif
!
    call getvid(' ', 'LIST_INST', scal=listr8, nbret=nis)
    if (nis .ne. 0) then
        acces = 'LIST_INST'
        iinst=1
        call jeveuo(listr8//'.VALE', 'L', jlist)
        call jelira(listr8//'.VALE', 'LONMAX', nbordr)
        goto 20
    endif
!
    call getvr8(' ', 'FREQ', nbval=0, nbret=nis)
    if (nis .ne. 0) then
        acces = 'FREQ'
        listr8 = '&&'//nompro
        nbordr = -nis
        iinst=1
        call wkvect(listr8//'.VALE', 'V V R', nbordr, jlist)
        call getvr8(' ', 'FREQ', nbval=nbordr, vect=zr(jlist), nbret=n1)
        goto 20
    endif
!
    call getvid(' ', 'LIST_FREQ', scal=listr8, nbret=nis)
    if (nis .ne. 0) then
        acces = 'LIST_FREQ'
        iinst=1
        call jeveuo(listr8//'.VALE', 'L', jlist)
        call jelira(listr8//'.VALE', 'LONMAX', nbordr)
        goto 20
    endif
!
 20 continue
!
!     --- LECTURE DE LA PRECISION ET DU CRITERE ---
    call getvr8(' ', 'PRECISION', scal=epsi, nbret=np)
    call getvtx(' ', 'CRITERE', scal=crit, nbret=nc)
    precis = 0
    if (np .ne. 0) precis = 1
!
!     --- NOMBRE DE VARIABLES INTERNES A LIRE ---
    call getvis(' ', 'NB_VARI', scal=nbvari, nbret=nvar)
!
!     --- CREATION DE LA STRUCTURE DE DONNEES RESULTAT ---
    call rscrsd('G', resu, typres, nbordr)
!
    acce = 'INST'
    call rsexpa(resu, 0, 'FREQ', iret)
    if (iret .gt. 0) acce = 'FREQ'
!
!- ON VERIFIE SI LE CHAMP DEMANDE EST COMPATIBLE AVEC LE TYPE DE RESUTAT
    do ich = 1, nbnoch
        resu19=resu
        call jenonu(jexnom(resu19//'.DESC', linoch(ich)), iexi)
        if (iexi .eq. 0) then
            valk (1) = typres
            valk (2) = linoch(ich)
            call utmess('F', 'UTILITAI8_24', nk=2, valk=valk)
        endif
    end do
!
!
    if (form .eq. 'IDEAS') then
!     =========================
!
!     --- LECTURE
!
        call lridea(resu, typres, linoch, nbnoch, nomcmd,&
                    listr8, listis, precis, crit, epsi,&
                    acces, mfich, noma, ligrel, nbvari)
        nbordr_out = nbnoch
!
!     --- FIN LECTURE
!
    else if (form.eq.'IDEAS_DS58') then
!     ================================
!
!     --- LECTURE
!
        call lect58(mfich, resu, noma, typres, acces,&
                    listr8, listis, precis, crit, epsi,&
                    linoch, nbnoch)
        nbordr_out = nbnoch
!
!     --- FIN LECTURE
!
    else if (form.eq.'MED') then
!     =============================
!
!       ON VERIFIE QUE LE PHENOMENE DU MODELE FOURNI EST COHERENT AVEC
!       LA SD RESULTAT
        call getvid(' ', 'MODELE', scal=nomo, nbret=nbv)
        if (nbv .eq. 1) then
            call lrvemo(nomo)
        endif
!
!       CREATION DE L'OBJET .REFD DANS LES MODE_MECA
        if ((typres.eq.'MODE_MECA') .or. (typres.eq.'MODE_MECA_C')) then
            call lrrefd(resu, prchnd)
        endif
!
        lprem = .true.
        do i = 1, nbnoch
            option = ' '
            param = ' '
!
            call getvtx('FORMAT_MED', 'NOM_CHAM', iocc=i, scal=noch, nbret=n1)
!
            call carcha(noch, nomgd, typcha, option, param)
!
!         NOM DU CHAMP MED
            call getvtx('FORMAT_MED', 'NOM_CHAM_MED', iocc=i, scal=nochmd, nbret=n1)
            if (n1 .eq. 0) then
                nochmd='________________________________'//'________________________________'
                call getvtx('FORMAT_MED', 'NOM_RESU', iocc=i, scal=noraci, nbret=n2)
                nchar=lxlgut(noraci)
                nochmd(1:nchar)=noraci(1:nchar)
                nchar=lxlgut(noch)
                nochmd(9:8+nchar)=noch(1:nchar)
                nochmd(9+nchar:64)=' '
            endif
!
!         ON NE FAIT LA VERIFICATION DU MAILLAGE QU'UNE FOIS AU
!         PREMIER PASSAGE
            if (lprem) then
                call lrvema(noma, mfich, nochmd)
                lprem = .false.
            endif
!
!         NOM DES COMPOSANTES VOULUES
            ncmpva = '&&'//nompro//'.'//lcmpva
            ncmpvm = '&&'//nompro//'.'//lcmpvm
!         NOM_CMP ASTER ?
            nbcmpv=0
            call getvtx('FORMAT_MED', lcmpva, iocc=i, nbval=0, nbret=iaux)
            if (iaux .lt. 0) then
                nbcmpv = -iaux
            endif
!
!         NOM_CMP MED ?
            call getvtx('FORMAT_MED', lcmpvm, iocc=i, nbval=0, nbret=iaux)
            if (-iaux .ne. nbcmpv) then
                valk(1) = lcmpva
                valk(2) = lcmpvm
                call utmess('F', 'UTILITAI2_95', nk=2, valk=valk)
            endif
            if (nbcmpv .gt. 0) then
                call wkvect(ncmpva, 'V V K8', nbcmpv, jcmpva)
                call getvtx('FORMAT_MED', lcmpva, iocc=i, nbval=nbcmpv, vect=zk8(jcmpva),&
                            nbret=iaux)
                call wkvect(ncmpvm, 'V V K16', nbcmpv, jcmpvm)
                call getvtx('FORMAT_MED', lcmpvm, iocc=i, nbval=nbcmpv, vect=zk16( jcmpvm),&
                            nbret=iaux)
            endif
!
!         PROLONGEMENT PAR ZERO OU NOT A NUMBER
            call getvtx(' ', 'PROL_ZERO', scal=prolz, nbret=iaux)
            if (prolz .ne. 'OUI') then
                prolz = 'NAN'
            endif
            call lrfmed(resu, i, mfich, nomgd, typcha,&
                        option, param, nochmd, acces, nbordr,&
                        nnu, nis, nto, jnume, jlist,&
                        noma, nbcmpv, ncmpva, ncmpvm, prolz,&
                        iinst, crit, epsi, linoch, acce,&
                        nbordr_out)
        end do
!
!     POUR LES FORMATS NON PREVUS
!     ===========================
    else
        ASSERT(ASTER_FALSE)
    endif
!
! - STOCKAGE EVENTUEL : MODELE, CHAM_MATER, CARA_ELEM, EXCIT
!   --------------------------------------------------------
    call getvid(' ', 'CHAM_MATER', nbval=0, nbret=n1)
    call getvid(' ', 'CARA_ELEM', nbval=0, nbret=n2)
    call getvid(' ', 'MODELE', nbval=0, nbret=n3)
!
    if (((n1.ne.0).or.(n2.ne.0).or.(n3.ne.0)) .and. ((typres.eq.'EVOL_CHAR'))) then
        goto 265
    endif
!
    if (n1 .ne. 0) then
        call getvid(' ', 'CHAM_MATER', scal=chmat, nbret=iret)
    endif
    if (n2 .ne. 0) then
        call getvid(' ', 'CARA_ELEM', scal=carael, nbret=iret)
    endif
    if (n3 .ne. 0) then
        call getvid(' ', 'MODELE', scal=modele, nbret=iret)
    endif
!
    call lrcomm(resu, typres, nbordr, chmat, carael,&
                modele, noch, .true._1)
!
265 continue
!
!     -- MESSAGE D'INFORMATION SUR CE QU'ON A LU :
!     --------------------------------------------
    if (nivinf .ge. 2) then
        write (ifm,*) ' LECTURE DES CHAMPS:'
        do ich = 1, nbnoch
            write (ifm,*) '    CHAMP : ',linoch(ich)
        end do
        call wkvect('&&'//nompro//'.NUME_ORDR', 'V V I', nbordr_out, lordr)
        call rsorac(resu, 'TOUT_ORDRE', ibid, rbid, k8bid,&
                    cbid, epsi, crit, zi(lordr), nbordr_out,&
                    nbtrou)
        do iord = 1, nbordr_out
            call rsadpa(resu, 'L', 1, acce, zi(lordr+iord-1), 0, sjv=jinst)
                        write (ifm,*) '    NUMERO D''ORDRE : ',zi(lordr+iord-1),&
     &        '    '//acces//' : ',zr(jinst)
        end do
    endif
!
    call titre()
!
!
!     -- CREATION D'UN .REFD VIDE SI NECESSAIRE :
!     ---------------------------------------------------
    if (typres .eq. 'DYNA_TRANS' .or. typres .eq. 'DYNA_HARMO' .or. typres(1:9) .eq.&
        'MODE_MECA') then
        call jeexin(resu//'           .REFD', iret)
        if (iret .eq. 0) call refdaj(' ', resu, -1, ' ', 'INIT',&
                                     ' ', iret)
    endif
!
!     -- SI NECESSAIRE, ON MET LES CHAMPS DE DEPL_R/C DANS
!        LA NUMEROTATION DU NUME_DDL DU .REFD :
!     -----------------------------------------------------
    call rsmode(resu)
!
    call jedema()
end subroutine
