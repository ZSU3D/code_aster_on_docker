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

subroutine op0104()
    implicit none
!     OPERATEUR: DEFI_GROUP
!     ------------------------------------------------------------------
!
#include "jeveux.h"
#include "asterc/getfac.h"
#include "asterc/getres.h"
#include "asterfort/cgrcbp.h"
#include "asterfort/cpclma.h"
#include "asterfort/detgnm.h"
#include "asterfort/getvem.h"
#include "asterfort/getvid.h"
#include "asterfort/getvtx.h"
#include "asterfort/infmaj.h"
#include "asterfort/jecrec.h"
#include "asterfort/jecreo.h"
#include "asterfort/jecroc.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeecra.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jenuno.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnom.h"
#include "asterfort/jexnum.h"
#include "asterfort/sscgma.h"
#include "asterfort/sscgno.h"
#include "asterfort/utmess.h"
!
!
    integer :: n1, n2, nbgrma, nbgmin, iret, nbgma, nbgrmn, i, j, nbma, jgg, jvg
    integer :: nbocc, nbgrno, iocc, nbgnin, nbgno, nbgrnn, nbno, n3
    character(len=8) :: k8b, ma, ma2
    character(len=16) :: nomcmd, typcon, option
    character(len=24) :: grpmai, grpnoe, grpmav, grpnov, gpptnm, gpptnn, nomg
    integer :: iarg
    aster_logical :: l_write
!     ------------------------------------------------------------------
    call jemarq()
    call infmaj()
!
    call getres(ma2, typcon, nomcmd)
    call getvid(' ', 'MAILLAGE', scal=ma, nbret=n1)
    if (n1 .eq. 0) then
        call getvid(' ', 'GRILLE', scal=ma, nbret=n1)
    endif
    if (ma .ne. ma2) then
        call utmess('F', 'SOUSTRUC_15')
    endif
    grpmai = ma//'.GROUPEMA'
    grpnoe = ma//'.GROUPENO'
    gpptnm = ma//'.PTRNOMMAI'
    gpptnn = ma//'.PTRNOMNOE'
    grpmav = '&&OP0104'//'.GROUPEMA'
    grpnov = '&&OP0104'//'.GROUPENO'
!
!
!     1. ON DETRUIT SI DEMANDE (DETR_GROUP_MA ET DETR_GROUP_NO):
!     ------------------------------------------------------------
    call getfac('DETR_GROUP_MA', n1)
    call getfac('DETR_GROUP_NO', n2)
    if (n1 .ne. 0 .or. n2 .ne. 0) then
        call detgnm(ma)
    endif
!
!
!
!     2. CREA_GROUP_MA :
!     ------------------------------------------------------------
!     --- ON COMPTE LE NOMBRE DE NOUVEAUX GROUP_MA :
    call getfac('CREA_GROUP_MA', nbgrma)
    if (nbgrma .eq. 0) goto 107
!
!     --- ON AGRANDIT LA COLLECTION SI NECESSAIRE :
    nbgmin = 0
    call jeexin(grpmai, iret)
    if (iret .eq. 0 .and. nbgrma .ne. 0) then
        call jedetr(gpptnm)
        call jecreo(gpptnm, 'G N K24')
        call jeecra(gpptnm, 'NOMMAX', nbgrma, ' ')
        call jecrec(grpmai, 'G V I', 'NO '//gpptnm, 'DISPERSE', 'VARIABLE',&
                    nbgrma)
    else if (iret .eq. 0 .and. nbgrma .eq. 0) then
    else
        call jelira(grpmai, 'NOMUTI', nbgma)
        nbgmin = nbgma
        nbgrmn = nbgma + nbgrma
        call cpclma(ma, '&&OP0104', 'GROUPEMA', 'V')
        call jedetr(grpmai)
        call jedetr(gpptnm)
        call jecreo(gpptnm, 'G N K24')
        call jeecra(gpptnm, 'NOMMAX', nbgrmn, ' ')
        call jecrec(grpmai, 'G V I', 'NO '//gpptnm, 'DISPERSE', 'VARIABLE',&
                    nbgrmn)
        do 100 i = 1, nbgma
            call jenuno(jexnum(grpmav, i), nomg)
            call jecroc(jexnom(grpmai, nomg))
            call jeveuo(jexnum(grpmav, i), 'L', jvg)
            call jelira(jexnum(grpmav, i), 'LONUTI', nbma)
            call jeecra(jexnom(grpmai, nomg), 'LONMAX', max(nbma, 1))
            call jeecra(jexnom(grpmai, nomg), 'LONUTI', nbma)
            call jeveuo(jexnom(grpmai, nomg), 'E', jgg)
            do 102 j = 0, nbma-1
                zi(jgg+j) = zi(jvg+j)
102          continue
100      continue
    endif
107  continue
!
!
!     3. CREA_GROUP_NO :
!     ------------------------------------------------------------
!     --- ON COMPTE LE NOMBRE DE NOUVEAUX GROUP_NO :
    call getfac('CREA_GROUP_NO', nbocc)
    nbgrno = 0
    do 10 iocc = 1, nbocc
        call getvtx('CREA_GROUP_NO', 'TOUT_GROUP_MA', iocc=iocc, nbval=0, nbret=n1)
        if (n1 .ne. 0) then
            call jelira(grpmai, 'NMAXOC', nbgma)
            nbgrno = nbgrno + nbgma
            goto 10
        endif
        call getvem(ma, 'GROUP_MA', 'CREA_GROUP_NO', 'GROUP_MA', iocc,&
                    iarg, 0, k8b, n2)
        if (n2 .ne. 0) then
            nbgrno = nbgrno - n2
            goto 10
        endif
        call getvtx('CREA_GROUP_NO', 'OPTION', iocc=iocc, nbval=0, nbret=n3)
        if (n3 .ne. 0) then
            call getvtx('CREA_GROUP_NO', 'OPTION', iocc=iocc, scal=option, nbret=n3)
            if (option.eq.'RELA_CINE_BP')then
                l_write = .false.
                call cgrcbp('CREA_GROUP_NO', iocc, ma, l_write, nbgma)
                nbgrno = nbgrno + nbgma
                goto 10
            endif
        endif
!        -- ON CREE UN GROUP_NO PAR MOT CLE FACTEUR --
        nbgrno = nbgrno + 1
10  end do
    if (nbgrno .eq. 0) goto 207
!
!
!     --- ON AGRANDIT LA COLLECTION SI NECESSAIRE :
    call jeexin(grpnoe, iret)
    nbgnin = 0
    if (iret .eq. 0 .and. nbgrno .ne. 0) then
        call jedetr(gpptnn)
        call jecreo(gpptnn, 'G N K24')
        call jeecra(gpptnn, 'NOMMAX', nbgrno, ' ')
        call jecrec(grpnoe, 'G V I', 'NO '//gpptnn, 'DISPERSE', 'VARIABLE',&
                    nbgrno)
    else if (iret .eq. 0 .and. nbgrno .eq. 0) then
    else
        call jelira(grpnoe, 'NOMUTI', nbgno)
        nbgrnn = nbgno + nbgrno
        nbgnin = nbgno
        call cpclma(ma, '&&OP0104', 'GROUPENO', 'V')
        call jedetr(grpnoe)
        call jedetr(gpptnn)
        call jecreo(gpptnn, 'G N K24')
        call jeecra(gpptnn, 'NOMMAX', nbgrnn, ' ')
        call jecrec(grpnoe, 'G V I', 'NO '//gpptnn, 'DISPERSE', 'VARIABLE',&
                    nbgrnn)
        do 200 i = 1, nbgno
            call jenuno(jexnum(grpnov, i), nomg)
            call jecroc(jexnom(grpnoe, nomg))
            call jeveuo(jexnum(grpnov, i), 'L', jvg)
            call jelira(jexnum(grpnov, i), 'LONUTI', nbno)
            call jeecra(jexnom(grpnoe, nomg), 'LONMAX', max(nbno, 1))
            call jeecra(jexnom(grpnoe, nomg), 'LONUTI', nbno)
            call jeveuo(jexnom(grpnoe, nomg), 'E', jgg)
            do 202 j = 0, nbno-1
                zi(jgg+j) = zi(jvg+j)
202          continue
200      continue
    endif
207  continue
!
!     --- TRAITEMENT DU MOT CLEF CREA_GROUP_MA :
    if (nbgrma .gt. 0) call sscgma(ma, nbgrma, nbgmin)
!
!     --- TRAITEMENT DU MOT CLEF CREA_GROUP_NO :
    if (nbgrno .gt. 0) call sscgno(ma, nbgnin)
!
!
    call jedema()
end subroutine
