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

subroutine ccchno(option, numord, resuin, resuou, lichou,&
                  mesmai, nomail, modele, carael, basopt,&
                  ligrel, ligmod, codret)
    implicit none
!     --- ARGUMENTS ---
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/ccvrrl.h"
#include "asterfort/celces.h"
#include "asterfort/cescns.h"
#include "asterfort/cesred.h"
#include "asterfort/cnscno.h"
#include "asterfort/detrsd.h"
#include "asterfort/dismoi.h"
#include "asterfort/exisd.h"
#include "asterfort/inigrl.h"
#include "asterfort/jedema.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/rsexc1.h"
#include "asterfort/rsexch.h"
#include "asterfort/utmess.h"
!
    integer :: numord, codret
    character(len=1) :: basopt
    character(len=8) :: resuin, resuou, nomail, modele, carael
    character(len=16) :: option
    character(len=24) :: lichou(2), mesmai, ligrel
    aster_logical :: ligmod
!  CALC_CHAMP - CALCUL D'UN CHAMP AUX NOEUDS
!  -    -                   --        --
! ----------------------------------------------------------------------
!
!  ROUTINE DE CALCUL D'UN CHAMP AUX NOEUDS DE CALC_CHAMP
!
! IN  :
!   OPTION  K16  NOM DE L'OPTION A CALCULER
!   NUMORD  I    NUMERO D'ORDRE COURANT
!   RESUIN  K8   NOM DE LA STRUCUTRE DE DONNEES RESULTAT IN
!   RESUOU  K8   NOM DE LA STRUCUTRE DE DONNEES RESULTAT OUT
!   MESMAI  K24  NOM DU VECTEUR CONTENANT LES MAILLES SUR LESQUELLES
!                LE CALCUL EST DEMANDE
!   NOMAIL  K8   NOM DU MAILLAGE SUR LEQUEL LE CALCUL EST REALISE
!   MODELE  K8   NOM DU MODELE
!   CARAEL  K8   NOM DU CARAEL
!   BASOPT  K1   BASE SUR LAQUELLE DOIT ETRE CREE LE CHAMP DE SORTIE
!   LIGREL  K24  NOM DU LIGREL
!
! IN/OUT :
!   LICHOU  K8*  LISTE DES CHAMPS OUT
! ----------------------------------------------------------------------
! person_in_charge: nicolas.sellenet at edf.fr
    integer :: ier, nbma, jmai, ngr, igr, nmaxob, iret
    parameter    (nmaxob=30)
    integer :: adobj(nmaxob), nbobj, nbsp
!
    character(len=8) :: k8b, erdm
    character(len=19) :: valk(4)
    character(len=19) :: optele, nochou, chams0, chams1
    character(len=24) :: chelem, noobj(nmaxob)
!
!
    call jemarq()
!
    call jeexin(mesmai, ier)
    if (ier .ne. 0) then
        call jeveuo(mesmai, 'L', jmai)
        call jelira(mesmai, 'LONMAX', nbma)
    else
        nbma = 0
    endif
!
    chams0 = '&&CALCOP.CHAMS0'
    chams1 = '&&CALCOP.CHAMS1'
    optele = option(1:5)//'ELNO'
!
    call rsexc1(resuou, option, numord, nochou)
    lichou(1) = nochou
!
    call rsexch(' ', resuin, optele, numord, chelem, ier)
    if (ier .ne. 0) then
        call rsexch(' ', resuou, optele, numord, chelem, ier)
    endif
!
    call exisd('CHAMP_GD', chelem, ier)
    if (ier .eq. 0) then
        lichou=' '
        valk(1)=optele
        valk(2)=option
        valk(3)=resuin
        valk(4)=resuou
        call utmess('A', 'CALCCHAMP_2', nk=4, valk=valk, si=numord)
        goto 999
    endif
    call celces(chelem, 'V', chams0)
    if (nbma .ne. 0) then
        call cesred(chams0, nbma, zi(jmai), 0, [k8b], 'V', chams0)
    endif
!
!   VERIFICATION DES REPERES LOCAUX
    erdm = 'NON'
    call dismoi('EXI_RDM', ligrel, 'LIGREL', repk=erdm)
!   cette vérification ne doit être faite que dans le cas ou le modèle contient des éléments
!   de structure et que pour certains champs qui sont en repère local
    if ((erdm.eq.'OUI').and. &
        ((option(1:4).eq.'EPSI').or.(option(1:4).eq.'SIGM').or.&
         (option(1:4).eq.'SIEF').or. &
         (option(1:4).eq.'DEGE').or.(option(1:4).eq.'EFGE'))) then
        if (ligmod) then
!           pour les coques 3d certaines initialisations sont nécessaires pour pouvoir utiliser
!           les routines de changement de repère propres aux coques 3d
            call dismoi('EXI_COQ3D', ligrel, 'LIGREL', repk=erdm)
            if (erdm .eq. 'OUI' .and. ligmod) then
                call jelira(ligrel(1:19)//'.LIEL', 'NUTIOC', ngr)
                do igr = 1, ngr
                    call inigrl(ligrel, igr, nmaxob, adobj, noobj,nbobj)
                enddo
            endif
        endif
        if (carael .ne. ' ') then
            call ccvrrl(nomail, modele, carael, mesmai, chams0,'A', codret)
        else
            valk(1) = option(1:4)
            call utmess('A', 'CALCULEL4_2', nk=1, valk=valk)
        endif
    endif
!
    call cescns(chams0, ' ', 'V', chams1, 'A', codret)
    call cnscno(chams1, ' ', 'NON', basopt, nochou, ' ', iret)
!
!   VERIFICATION POUR LES CHAMPS A SOUS-POINT
    call dismoi('MXNBSP', chelem, 'CHAM_ELEM', repi=nbsp)
    if ((nbsp.gt.1) .and. (iret.eq.1)) then
        valk(1)=optele
        valk(2)=option
        call utmess('F', 'CALCULEL4_16', nk=2, valk=valk)
    endif
!
    call detrsd('CHAM_ELEM_S', chams0)
    call detrsd('CHAM_NO_S', chams1)
!
999 continue
    call jedema()
!
end subroutine
