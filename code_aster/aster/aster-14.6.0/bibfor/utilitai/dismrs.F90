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

subroutine dismrs(questi, nomobz, repi, repkz, ierd)
    implicit none
!     --     DISMOI(RESULTAT)
!     ARGUMENTS:
!     ----------
#include "jeveux.h"
#include "asterfort/assert.h"
#include "asterfort/dismcp.h"
#include "asterfort/dismrc.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnum.h"
#include "asterfort/rsadpa.h"
#include "asterfort/rsdocu.h"
#include "asterfort/rslipa.h"
#include "asterfort/rsexch.h"
#include "asterfort/rsorac.h"
#include "asterfort/utmess.h"
!
    integer :: repi, ierd
    character(len=*) :: questi
    character(len=32) :: repk
    character(len=19) :: nomob
    character(len=*) :: nomobz, repkz
! ----------------------------------------------------------------------
!     IN:
!       QUESTI : TEXTE PRECISANT LA QUESTION POSEE
!       NOMOBZ : NOM D'UN OBJET DE TYPE RESULTAT
!     OUT:
!       REPI   : REPONSE ( SI ENTIERE )
!       REPKZ  : REPONSE ( SI CHAINE DE CARACTERES )
!       IERD   : CODE RETOUR (0--> OK, 1 --> PB)
!
! ----------------------------------------------------------------------
!     VARIABLES LOCALES:
!     ------------------
    character(len=24) :: objdes
    character(len=4) :: docu
    character(len=24) :: valk(2)
    character(len=8) :: k8bid
    character(len=19) :: nomch
    complex(kind=8) :: cbid
    integer :: ibid
    real(kind=8) :: rbid
    integer, pointer :: ordr(:) => null()
!
!-----------------------------------------------------------------------
    integer :: i, iad, iatach, ico, iexi, iret, j
    integer :: jlipar, k, n1, nbch, nbdyn, nbmod(1), nbstat,icode
    integer :: nbsy
!-----------------------------------------------------------------------
    call jemarq()
    nomob = nomobz
    repi = 0
    repk = ' '
    ierd = 0
!
!
    if (questi .eq. 'TYPE_RESU') then
!         ---------------------
        call jeexin(nomob//'.DESC', ibid)
        if (ibid .gt. 0) then
            objdes=nomob//'.DESC'
        else
            objdes=nomob//'.CELD'
        endif
!
        call jelira(objdes, 'GENR', cval=k8bid)
        if (k8bid(1:1) .eq. 'N') then
            call jelira(objdes, 'DOCU', cval=docu)
            call rsdocu(docu, repk, iret)
            if (iret .ne. 0) then
                valk(1) = docu
                valk(2) = nomob
                call utmess('F', 'UTILITAI_68', nk=2, valk=valk)
                ierd=1
                goto 9999
            endif
        else
            repk = 'CHAMP'
        endif



    else if (questi.eq.'COMPOR_1') then
!   ----------------------------------
        call jeveuo(nomob//'.ORDR', 'L', vi=ordr)
        call jelira(nomob//'.ORDR', 'LONUTI', n1)

        repk=' '
        do k = 1, n1
            call rsexch(' ', nomob, 'COMPORTEMENT', ordr(k), nomch, icode)
            if (icode.ne.0) cycle
            if (nomch.ne.' ') then
                if (repk.eq.' ') then
                    repk=nomch
                    exit
                endif
            endif
        enddo


    else if ((questi.eq.'NOM_MODELE').or. (questi.eq.'MODELE').or.&
             (questi.eq.'MODELE_1').or. (questi.eq.'CHAM_MATER').or.&
             (questi.eq.'CHAM_MATER_1').or. (questi.eq.'CARA_ELEM').or.&
             (questi.eq.'CARA_ELEM_1')) then
!     ------------------------------------------
        if ((questi.eq.'NOM_MODELE') .or. (questi(1:6).eq.'MODELE')) then
            call rslipa(nomob, 'MODELE', '&&DISMRS.LIPAR', jlipar, n1)
        else if (questi(1:9).eq.'CARA_ELEM') then
            call rslipa(nomob, 'CARAELEM', '&&DISMRS.LIPAR', jlipar, n1)
        else if (questi(1:10).eq.'CHAM_MATER') then
            call rslipa(nomob, 'CHAMPMAT', '&&DISMRS.LIPAR', jlipar, n1)
        endif
        ASSERT(n1.ge.1)
        repk=' '
        ico=0
        do 10, k=1,n1
        if (zk8(jlipar-1+k) .ne. ' ') then
            if (zk8(jlipar-1+k) .ne. repk) then
                ico=ico+1
                repk=zk8(jlipar-1+k)
            endif
        endif
10      continue
        if (ico .eq. 0) repk='#AUCUN'
        if (ico .gt. 1) then
            if ((questi.eq.'MODELE_1') .or. (questi.eq.'CARA_ELEM_1') .or.&
                (questi.eq.'CHAM_MATER_1')) then
!           REPK=REPK
            else
                repk='#PLUSIEURS'
            endif
        endif
        call jedetr('&&DISMRS.LIPAR')



    else if (questi.eq.'NOM_MAILLA') then
!     ------------------------------------------
        call jelira(jexnum(nomob//'.TACH', 1), 'LONMAX', nbch)
        call jeveuo(jexnum(nomob//'.TACH', 1), 'L', iatach)
        do 1, i=1,nbch
        nomch=zk24(iatach-1+i)(1:19)
        if (nomch(1:1) .ne. ' ') then
            call dismcp(questi, nomch, repi, repk, ierd)
            goto 9999
        endif
 1      continue
!
!        -- SINON ON PARCOURT TOUS LES CHAMPS DU RESULTAT :
        call jelira(nomob//'.TACH', 'NMAXOC', nbsy)
        do 2, j=2,nbsy
        call jelira(jexnum(nomob//'.TACH', j), 'LONMAX', nbch)
        call jeveuo(jexnum(nomob//'.TACH', j), 'L', iatach)
        do 3, i=1,nbch
        nomch=zk24(iatach-1+i)(1:19)
        if (nomch(1:1) .ne. ' ') then
            call dismcp(questi, nomch, repi, repk, ierd)
            goto 9999
        endif
 3      continue
 2      continue
        call utmess('F', 'UTILITAI_69')
        ierd=1
!
!
    else if (questi.eq.'EXI_CHAM_ELEM') then
!     ------------------------------------------
        call jelira(nomob//'.TACH', 'NMAXOC', nbsy)
        do 21, j=2,nbsy
        call jelira(jexnum(nomob//'.TACH', j), 'LONMAX', nbch)
        call jeveuo(jexnum(nomob//'.TACH', j), 'L', iatach)
        do 31, i=1,nbch
        nomch=zk24(iatach-1+i)(1:19)
        if (nomch(1:1) .ne. ' ') then
            call jeexin(nomch//'.CELD', iexi)
            if (iexi .gt. 0) then
                repk='OUI'
                goto 9999
            endif
        endif
31      continue
21      continue
        repk='NON'
!
!
!
        else if ( (questi.eq.'NB_CHAMP_MAX') .or. (&
    questi.eq.'NB_CHAMP_UTI')) then
!     ------------------------------------------
        call jelira(nomob//'.DESC', 'GENR', cval=k8bid)
        if (k8bid(1:1) .eq. 'N') then
            call dismrc(questi, nomob, repi, repk, ierd)
        else
            repi = 1
        endif
!
!
    else if (questi.eq.'NB_MODES_TOT') then
!     ------------------------------------------
        call rsorac(nomob, 'LONUTI', 0, rbid, k8bid,&
                    cbid, rbid, k8bid, nbmod, 1,&
                    ibid)
        repi = nbmod(1)
        repk='NON'
!
    else if (questi.eq.'NB_MODES_STA') then
!     ------------------------------------------
        nbstat=0
        call rsorac(nomob, 'LONUTI', 0, rbid, k8bid,&
                    cbid, rbid, k8bid, nbmod, 1,&
                    ibid)
!
        do 41, i=1,nbmod(1)
        call rsadpa(nomob, 'L', 1, 'TYPE_MODE', i,&
                    0, sjv=iad, styp=k8bid)
        nomch = zk16(iad)(1:16)
        if (nomch(1:8) .eq. 'MODE_STA') then
            nbstat=nbstat+1
        endif
41      continue
        repi = nbstat
        repk='NON'
!
    else if (questi.eq.'NB_MODES_DYN') then
!     ------------------------------------------
        nbdyn=0
        call rsorac(nomob, 'LONUTI', 0, rbid, k8bid,&
                    cbid, rbid, k8bid, nbmod, 1,&
                    ibid)
!
        do 51, i=1,nbmod(1)
        call rsadpa(nomob, 'L', 1, 'TYPE_MODE', i,&
                    0, sjv=iad, styp=k8bid)
        nomch = zk16(iad)(1:16)
        if ((nomch(1:9).eq.'MODE_DYN')) then
            nbdyn=nbdyn+1
        endif
51      continue
        repi = nbdyn
        repk='NON'
!
    else
        ierd=1
    endif
!
9999  continue
    repkz = repk
    call jedema()
end subroutine
