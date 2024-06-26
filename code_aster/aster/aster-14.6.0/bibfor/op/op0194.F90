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

subroutine op0194()
    implicit none
!
!      OPERATEUR :     CALC_META
!
! ----------------------------------------------------------------------
!
#include "jeveux.h"
#include "asterc/getfac.h"
#include "asterfort/gettco.h"
#include "asterfort/calcop.h"
#include "asterfort/chpver.h"
#include "asterfort/copisd.h"
#include "asterfort/detrsd.h"
#include "asterfort/getvid.h"
#include "asterfort/getvis.h"
#include "asterfort/getvr8.h"
#include "asterfort/getvtx.h"
#include "asterfort/infmaj.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/medom1.h"
#include "asterfort/modopt.h"
#include "asterfort/mtdorc.h"
#include "asterfort/rsexch.h"
#include "asterfort/rsorac.h"
#include "asterfort/smevol.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"
!
    character(len=6) :: nompro
    parameter(nompro='OP0194')
!
    integer :: ibid, iret, n1, n2, n3, num, numpha
    integer :: nbordt, nbtrou, ier, jopt, nbopt, nb, nchar, iopt
    integer :: nbordr, jordr, nuord, vali, tord(1)
!
    real(kind=8) :: inst, prec
    real(kind=8) :: valr, r8b
!
    complex(kind=8) :: c16b
    character(len=4) :: ctyp
    character(len=8) :: k8b, crit, temper, temper2, modele, cara
    character(len=16) :: tysd, option
    character(len=19) :: kordre, kcha, compor
    character(len=24) :: chmeta, phasin, mate
    character(len=24) :: valk
    character(len=24) :: lesopt
    character(len=16) :: keywordfact
    integer :: i_comp, nbocc
    character(len=16) :: phase_type
!
! ----------------------------------------------------------------------
!
    call jemarq()
    call infmaj()
!
    lesopt='&&'//nompro//'.LES_OPTION'
    kordre='&&'//nompro//'.NUME_ORDRE'
    kcha = '&&'//nompro//'.CHARGES   '
    compor = '&&'//nompro//'.COMPOR'
!
    call getvid(' ', 'RESULTAT', scal=temper, nbret=n1)
    call gettco(temper, tysd)
!
    call rsorac(temper, 'LONUTI', 0, r8b, k8b,&
                c16b, r8b, k8b, tord, 1,&
                ibid)
    nbordr=tord(1)     

    if (nbordr .lt. 2) then
        call utmess('F', 'META1_1')
    endif       
    call wkvect(kordre, 'V V I', nbordr, jordr)
    call rsorac(temper, 'TOUT_ORDRE', 0, r8b, k8b,&
                c16b, r8b, k8b, zi(jordr), nbordr,&
                ibid)
    nuord = zi(jordr)
!
    call medom1(modele, mate, cara, kcha, nchar,&
                ctyp, temper, nuord)
!
    call getvtx(' ', 'OPTION', nbval=0, nbret=nb)
    nbopt = -nb
    call wkvect(lesopt, 'V V K16', nbopt, jopt)
    call getvtx(' ', 'OPTION', nbval=nbopt, vect=zk16(jopt), nbret=nb)
    call jeveuo(lesopt, 'L', jopt)
!
    do iopt = 1, nbopt
!
        option=zk16(jopt+iopt-1)
!
        if (option .eq. 'META_ELNO') then
!
            call mtdorc(modele, compor)
!
! ----- ETAT INITIAL
            numpha = 0
            call getvid('ETAT_INIT', 'META_INIT_ELNO', iocc=1, scal=chmeta, nbret=n3)
            if (n3 .gt. 0) then
                phasin = '&&SMEVOL_ZINIT'
                call chpver('F', chmeta(1:19), 'CART', 'VAR2_R', ier)
                call copisd('CHAMP_GD', 'V', chmeta, phasin(1:19))
            else
                call getvid('ETAT_INIT', 'EVOL_THER', iocc=1, scal=temper2, nbret=n1)
                if (temper2 .ne. temper) then
                    call utmess('F', 'META1_2')
                endif
                call getvis('ETAT_INIT', 'NUME_INIT', iocc=1, scal=num, nbret=n2)
                if (n2 .eq. 0) then
                    call getvr8('ETAT_INIT', 'INST_INIT', iocc=1, scal=inst, nbret=n3)
                    call getvr8('ETAT_INIT', 'PRECISION', iocc=1, scal=prec, nbret=n3)
                    call getvtx('ETAT_INIT', 'CRITERE', iocc=1, scal=crit, nbret=n3)
                    nbordt = 1
                    call rsorac(temper, 'INST', ibid, inst, k8b,&
                                c16b, prec, crit, tord, nbordt,&
                                nbtrou)
                    num=tord(1)            
                    if (nbtrou .eq. 0) then
                        valk = temper
                        valr = inst
                        call utmess('F', 'UTILITAI6_51', sk=valk, sr=valr)
                    else if (nbtrou.gt.1) then
                        valk = temper
                        valr = inst
                        vali = nbtrou
                        call utmess('F', 'UTILITAI6_52', sk=valk, si=vali, sr=valr)
                    endif
                endif
                call rsexch('F', temper, 'META_ELNO', num, phasin,&
                            iret)
                numpha = num
            endif
!
            call smevol(temper(1:8), modele, mate, compor, option,&
                        phasin, numpha)
!
            call detrsd('CARTE', '&&NMDORC.COMPOR')
!
        else
            nbocc        = 0
            keywordfact  = 'COMPORTEMENT'
            call getfac(keywordfact, nbocc)
            do i_comp = 1, nbocc
                call getvtx(keywordfact, 'RELATION', iocc = i_comp, scal = phase_type, nbret=iret)
                if (iret .ne. 0) then
                    if (phase_type(1:5) .ne. 'ACIER' .and. option.eq.'DURT_ELNO') then
                        call utmess('F', 'META1_3', sk=phase_type)
                    endif
                endif
            end do
!         PASSAGE CALC_CHAMP
            call calcop(option, lesopt, temper, temper, kordre,&
                        nbordr, ctyp, tysd, iret)
            if (iret .eq. 0) goto 100
!
        endif
100      continue
!
    end do
!
    call jedema()
end subroutine
