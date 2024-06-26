! --------------------------------------------------------------------
! Copyright (C) 1991 - 2018 - EDF R&D - www.code-aster.org
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

subroutine modirepresu(resuou, resuin )
!
    implicit none
    character(len=19) :: resuou, resuin
!
! ----------------------------------------------------------------------
!
!     COMMANDE : MODI_REPERE / RESULTAT
!
! ----------------------------------------------------------------------
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/getfac.h"
#include "asterfort/gettco.h"
#include "asterfort/celces.h"
#include "asterfort/cescel.h"
#include "asterfort/cesfus.h"
#include "asterfort/chrpel.h"
#include "asterfort/chrpno.h"
#include "asterfort/copisd.h"
#include "asterfort/detrsd.h"
#include "asterfort/dismoi.h"
#include "asterfort/getvr8.h"
#include "asterfort/getvtx.h"
#include "asterfort/infmaj.h"
#include "asterfort/infniv.h"
#include "asterfort/jedema.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jerecu.h"
#include "asterfort/jeveuo.h"
#include "asterfort/refdcp.h"
#include "asterfort/rsadpa.h"
#include "asterfort/rscrsd.h"
#include "asterfort/rsexch.h"
#include "asterfort/rsinfo.h"
#include "asterfort/rslesd.h"
#include "asterfort/rsnoch.h"
#include "asterfort/rsnopa.h"
#include "asterfort/rsutnu.h"
#include "asterfort/titre.h"
#include "asterfort/utmess.h"
!
    integer :: n0, nbordr, iret, nocc, i, j, np, iordr
    integer :: n1, nbcmp, iord, ioc, ibid, nc
    integer :: jordr, nbnosy, jpa, iadin, iadou
    integer :: nbpara, nbac, nbpa, ifm, niv, nncp
    real(kind=8) :: prec
    real(kind=8) :: lcoer(2)
    complex(kind=8) :: lcoec(2)
    character(len= 8) :: crit, tych, nomma, modele
    character(len= 8) :: carele, exipla, exicoq
    character(len=16) :: option, tysd, type, type_cham, repere
    character(len=19) :: knum
    character(len=19) :: chams1, chams0, chafus, chs(2), ligrel
    character(len=24) :: nompar, champ0, champ1
    character(len=24) :: valk(2)
!
    aster_logical :: lreuse, lcumu(2), lcoc(2)
!
    data lcumu/.false.,.false./
    data lcoc/.false.,.false./
    data lcoer/1.d0,1.d0/
! ---------------------------------------------------------------------
    call jemarq()
!
    call infmaj()
    call infniv(ifm, niv)
!
!   LE CONCEPT EST REENTRANT SI REPERE = 'COQUE_INTR_UTIL' OU 'COQUE_UTIL_INTR' ou 'COQUE_UTIL_CYL'
!   DANS CE CAS ON CREE UNE SD RESULTAT TEMPORAIRE POUR LES CALCULS ET ENSUITE ON SURCHARGE
!   RESUIN PAR LES CHAMPS MODIFIES STOCKES DANS RESUOU
    lreuse = .false.
    if (resuin .eq. resuou) then
        lreuse = .true.
        resuou ='MODIREPE'
    endif
!
    call jelira(resuin//'.DESC', 'NOMMAX', nbnosy)
    if (nbnosy .eq. 0) goto 999
!
    call gettco(resuin, tysd)
!   RECUPERATION DU NOMBRE DE CHAMPS SPECIFIE
    call getfac('MODI_CHAM', nocc)
!
!   DEFINITION DU REPERE UTILISE
    call getvtx(' ', 'REPERE', scal=repere, nbret=i)
    
    if ( lreuse ) then  
       if ( i .eq. 0) then 
          call utmess('F', 'MODELISA3_14')
       endif
       if (repere .ne. 'COQUE_INTR_UTIL' .and. repere .ne. 'COQUE_UTIL_INTR' ) then
          call utmess('F', 'MODELISA3_15', nk=1, valk=repere )
       endif 
    endif
!
!   RECUPERATION DES NUMEROS D'ORDRE DE LA STRUCTURE DE DONNEES DE TYPE RESULTAT RESU A PARTIR
!   DES VARIABLES D'ACCES UTILISATEUR 'NUME_ORDRE','FREQ','INST','NOEUD_CMP'
!   (VARIABLE D'ACCES 'TOUT_ORDRE' PAR DEFAUT)
    knum = '&&OP0191.NUME_ORDRE'
    call getvr8(' ', 'PRECISION', scal=prec, nbret=np)
    call getvtx(' ', 'CRITERE', scal=crit, nbret=nc)
    call rsutnu(resuin, ' ', 1, knum, nbordr, prec, crit, iret)
    if (iret .eq. 10) then
        call utmess('F', 'CALCULEL4_8', sk=resuin)
    endif
    if (iret .ne. 0) then
        call utmess('F', 'ALGORITH3_41')
    endif
    call jeveuo(knum, 'L', jordr)
    call rscrsd('G', resuou, tysd, nbordr)
!
    do ioc = 1, nocc
        call getvtx('MODI_CHAM', 'NOM_CHAM', iocc=ioc, scal=option, nbret=n0)
        call getvtx('MODI_CHAM', 'TYPE_CHAM', iocc=ioc, scal=type_cham, nbret=n0)
        call getvtx('MODI_CHAM', 'NOM_CMP', iocc=ioc, nbval=0, nbret=n1)
        nbcmp = - n1
        do iord = 1, nbordr
            call jemarq()
            call jerecu('V')
            iordr = zi(jordr-1+iord)
            call rsexch('F', resuin, option, iordr, champ0, iret)
            call dismoi('NOM_MAILLA', champ0(1:19), 'CHAMP', repk=nomma)
            call dismoi('TYPE_CHAMP', champ0, 'CHAMP', repk=tych, arret='C', ier=iret)
            call rsexch(' ', resuou, option, iordr, champ1, iret)
!           CHAMP1 SERA ENSUITE RECREE SUR LA BASE GLOBALE
            call copisd('CHAMP_GD', 'V', champ0, champ1)
!           RECUPERATION DU MODELE ASSOCIE AU CHAMP
            call rslesd(resuin(1:8), iordr, model_ = modele, cara_elem_ = carele)
            if (modele .ne. '') then
                call dismoi('EXI_PLAQUE', modele, 'MODELE', repk=exipla)
                call dismoi('EXI_COQUE', modele, 'MODELE', repk=exicoq)
                if ( ((exipla(1:3).eq.'OUI').or.(exicoq(1:3).eq.'OUI')) .and.&
                     ((type_cham.eq.'TENS_2D').or.(type_cham.eq.'TENS_3D')) .and.&
                     (repere.eq.'UTILISATEUR') ) then
                    call utmess('F', 'ALGORITH3_7')
                endif
            endif
!
!           RECUPERATION DE LA NATURE DES CHAMPS (CHAM_NO OU CHAM_ELEM)
            if (tych(1:4) .eq. 'NOEU') then
                call chrpno(champ1, repere, nbcmp, ioc, type_cham)
            else if (tych(1:2).eq.'EL') then
                call chrpel(champ1, repere, nbcmp, ioc, type_cham,&
                            option, modele, carele)
            else
                valk(1) = tych
                valk(2) = champ1
                call utmess('A', 'ALGORITH9_69', nk=2, valk=valk)
            endif
            call rsnoch(resuou, option, iordr)
            call jedema()
        enddo
    enddo
!
    nompar = '&&OP0191.NOMS_PARA'
    call rsnopa(resuin, 2, nompar, nbac, nbpa)
    nbpara = nbac + nbpa
    call jeveuo(nompar, 'L', jpa)
    do iord = 1, nbordr
        iordr = zi(jordr-1+iord)
        do j = 1, nbpara
            call rsadpa(resuin, 'L', 1, zk16(jpa+j-1), iordr, 1, sjv=iadin, styp=type, istop=0)
            call rsadpa(resuou, 'E', 1, zk16(jpa+j-1), iordr, 1, sjv=iadou, styp=type)
            if (type(1:1) .eq. 'I') then
                zi(iadou) = zi(iadin)
            else if (type(1:1).eq.'R') then
                zr(iadou) = zr(iadin)
            else if (type(1:1).eq.'C') then
                zc(iadou) = zc(iadin)
            else if (type(1:3).eq.'K80') then
                zk80(iadou) = zk80(iadin)
            else if (type(1:3).eq.'K32') then
                zk32(iadou) = zk32(iadin)
            else if (type(1:3).eq.'K24') then
                zk24(iadou) = zk24(iadin)
            else if (type(1:3).eq.'K16') then
                zk16(iadou) = zk16(iadin)
            else if (type(1:2).eq.'K8') then
                zk8(iadou) = zk8(iadin)
            endif
        enddo
    enddo
!
    call titre()
    if (niv .eq. 2) call rsinfo(resuou, ifm)
!
999 continue
!
!   CREATION DE L'OBJET .REFD SI NECESSAIRE :
    call refdcp(resuin, resuou)
!
!   TRAITEMENT DU CAS OU IL Y A REENTRANCE
!   UTILISE SI LE MOT CLE REPERE VAUT 'COQUE_INTR_UTIL' OU 'COQUE_UTIL_INTR'
    if (lreuse) then
        do ioc = 1, nocc
            call getvtx('MODI_CHAM', 'NOM_CHAM', iocc=ioc, scal=option, nbret=n0)
            do iord = 1, nbordr
                call jemarq()
                call jerecu('V')
                iordr = zi(jordr-1+iord)
                call rsexch('F', resuin, option, iordr, champ0,iret)
                call rsexch(' ', resuou, option, iordr, champ1,iret)
                chams0='&&CHRPEL.CHAMS0'
                chams1='&&CHRPEL.CHAMS1'
                chafus='&&CHRPEL.CHAFUS'
                chs(1) =chams0
                chs(2) =chams1
                call celces(champ0, 'V', chams0)
                call celces(champ1, 'V', chams1)
                call cesfus(2, chs, lcumu, lcoer, lcoec, lcoc(1), 'V', chafus)
                call dismoi('NOM_LIGREL', champ0, 'CHAM_ELEM', repk=ligrel)
                call cescel(chafus, ligrel, option, ' ', 'NAN', nncp, 'G', champ0, 'F', ibid)
                call detrsd('CHAMP', champ1)
                call jedema()
            enddo
        enddo
        call detrsd('CHAMP', chams0)
        call detrsd('CHAMP', chams1)
        call detrsd('CHAMP', chafus)
        call detrsd('RESULTAT', resuou)
    endif
!
    call jedema()
end subroutine
