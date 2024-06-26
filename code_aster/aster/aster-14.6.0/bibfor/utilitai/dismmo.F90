! --------------------------------------------------------------------
! Copyright (C) 1991 - 2020 - EDF R&D - www.code-aster.org
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

subroutine dismmo(questi, nomobz, repi, repkz, ierd)
    implicit none
#include "jeveux.h"
!
#include "asterfort/assert.h"
#include "asterfort/dismlg.h"
#include "asterfort/dismma.h"
#include "asterfort/dismqu.h"
#include "asterfort/dismte.h"
#include "asterfort/dismzc.h"
#include "asterfort/jedema.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jenuno.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnum.h"
    integer :: repi, ierd
    character(len=*) :: questi, nomobz, repkz
!     --     DISMOI(MODELE)
!    IN:
!       QUESTI : TEXTE PRECISANT LA QUESTION POSEE
!       NOMOBZ : NOM D'UN OBJET DE TYPE LIGREL
!    OUT:
!       REPI   : REPONSE ( SI ENTIERE )
!       REPKZ  : REPONSE ( SI CHAINE DE CARACTERES )
!       IERD   : CODE RETOUR (0--> OK, 1 --> PB)
! ----------------------------------------------------------------------
!
    integer :: ialiel,  ico, igrel
    integer :: iret, itypel, nbgrel, nel
!
    character(len=4) :: tytm
    character(len=8) :: ma, nomob
    character(len=16) :: nomte, nomodl, nomod2
    character(len=19) :: nolig
    character(len=32) :: repk
    character(len=8), pointer :: lgrf(:) => null(), k8cond(:) => null()
    integer, pointer :: nfis(:) => null()
! DEB ------------------------------------------------------------------
!
    call jemarq()
    repk = ' '
    repi = 0
    ierd = 0
!
    nomob=nomobz
    nolig=nomob//'.MODELE'
!
    call jeveuo(nolig//'.LGRF', 'L', vk8=lgrf)
    ma=lgrf(1)
!
!     --------------------------------
    if (questi .eq. 'NOM_LIGREL') then
!     --------------------------------
        repk=nolig
!
!     -----------------------------------
    else if (questi.eq.'Z_CST') then
!     -----------------------------------
        call dismzc(questi, nolig, repi, repk, ierd)
!
!     -----------------------------------
    elseif ((questi.eq.'DIM_GEOM') .or. (questi.eq.'NB_SM_MAILLA')&
            .or. (questi.eq.'NB_SS_ACTI') .or. (questi.eq.'NB_NL_MAILLA')&
            .or. (questi.eq.'AXIS') .or. (questi.eq.'EXI_AXIS')&
            .or. (questi.eq.'CALC_RIGI') .or. (questi.eq.'PHENOMENE')&
            .or. (questi.eq.'EXI_AMOR') .or. (questi.eq.'EXI_RDM')&
            .or. (questi.eq.'EXI_POUX') .or. (questi(1:7).eq.'EXI_THM')&
            .or. (questi.eq.'EXI_TUYAU') .or. (questi.eq.'EXI_COQ3D')&
            .or. (questi.eq.'EXI_COQ1D') .or. (questi.eq.'EXI_PLAQUE')&
            .or. (questi.eq.'EXI_COQUE') .or. (questi.eq.'EXI_GRILLE')&
            .or. (questi.eq.'EXI_STRX') .or. (questi.eq.'EXI_STR2')&
            .or. (questi.eq.'PARTITION')) then
!     -----------------------------------
        call dismlg(questi, nolig, repi, repk, ierd)
!
!     -----------------------------------------
    else if (questi.eq.'ELEM_VOLU_QUAD') then
!     -----------------------------------------
        call dismqu(questi, nolig, repi, repk, ierd)
!
!     -------------------------------------
    else if (questi.eq.'NOM_MAILLA') then
!     -------------------------------------
        repk=ma
!
!     -------------------------------------------
    else if (questi.eq.'MODELISATION') then
!     -------------------------------------------
        call jeexin(nolig//'.LIEL', iret)
        if (iret .eq. 0) goto 20
        call jelira(nolig//'.LIEL', 'NUTIOC', nbgrel)
        if (nbgrel .le. 0) goto 20
!
        ico=0
        nomodl=' '
!
        do 10,igrel=1,nbgrel
        call jeveuo(jexnum(nolig//'.LIEL', igrel), 'L', ialiel)
        call jelira(jexnum(nolig//'.LIEL', igrel), 'LONMAX', nel)
        itypel=zi(ialiel-1+nel)
        call jenuno(jexnum('&CATA.TE.NOMTE', itypel), nomte)
        call dismte('MODELISATION', nomte, repi, repk, ierd)
        nomod2=repk(1:16)
!
!           -- ON ESPERE QUE LES NOMTE '#PLUSIEURS' SONT DES ELEMENTS
!              DE BORD ET QUE L'ON PEUT LES IGNORER ET QU'IL EN RESTE
!              D'AUTRES PLUS SIGNIFICATIFS :
        if (nomod2 .ne. '#PLUSIEURS') then
            if (nomodl .ne. nomod2) then
                ico=ico+1
                nomodl=nomod2
            endif
        endif
10      continue
        ASSERT(ico.ge.1)
!
        if (ico .eq. 1) then
            repk=nomodl
        else if (ico.gt.1) then
            repk='#PLUSIEURS'
        endif
        goto 30
!
20      continue
        repk='#AUCUNE'
!
30      continue
!
!     ------------------------------------------
    elseif ((questi.eq.'NB_NO_MAILLA') .or. (questi.eq.'NB_MA_MAILLA')&
            .or. (questi.eq.'NB_NO_SS_MAX')) then
!     ------------------------------------------
        call dismma(questi, ma, repi, repk, ierd)
!
!     ------------------------------------
    else if (questi.eq.'NB_FISS_XFEM') then
!     ------------------------------------
        call jeexin(nomob//'.NFIS', iret)
        if (iret .gt. 0) then
            call jeveuo(nomob//'.NFIS', 'L', vi=nfis)
            repi=nfis(1)
        else
            repi=0
        endif
!
!     ------------------------------------
    else if (questi.eq.'PRE_COND_XFEM') then
!     ------------------------------------
        call jeexin(nomob//'.PRE_COND', iret)
        if (iret .gt. 0) then
            call jeveuo(nomob//'.PRE_COND', 'L', vk8=k8cond)
            repk=k8cond(1)
        else
            repk='NON'
        endif
!
!     ------------------------------------
    else if (questi.eq.'EXI_ELEM') then
!     ------------------------------------
        repk='NON'
        call jeexin(nolig//'.LIEL', iret)
        if (iret .gt. 0) repk='OUI'
!
!     ----------------------------------------
    else if (questi.eq.'BESOIN_MATER') then
!     ----------------------------------------
        call jeexin(nolig//'.LIEL', iret)
        if (iret .gt. 0) then
            call jelira(nolig//'.LIEL', 'NUTIOC', nbgrel)
            repk='NON'
            do 40,igrel=1,nbgrel
            call jeveuo(jexnum(nolig//'.LIEL', igrel), 'L', ialiel)
            call jelira(jexnum(nolig//'.LIEL', igrel), 'LONMAX', nel)
            itypel=zi(ialiel-1+nel)
            call jenuno(jexnum('&CATA.TE.NOMTE', itypel), nomte)
            call dismte('MODELISATION', nomte, repi, repk, ierd)
            nomodl=repk(1:16)
            if ((nomodl(1:4) .ne. 'DIS_') .and. (nomodl(1:4) .ne. '2D_DIS_')) then
                repk='OUI'
                goto 70
!
            endif
40          continue
        else
            repk='NON'
        endif

    else if (questi.eq.'SI_CABLE') then
        !     ----------------------------------------
        call jeexin(nolig//'.LIEL', iret)
        if (iret .gt. 0) then
            call jelira(nolig//'.LIEL', 'NUTIOC', nbgrel)
            repk='NON'
            do 90,igrel=1,nbgrel
            call jeveuo(jexnum(nolig//'.LIEL', igrel), 'L', ialiel)
            call jelira(jexnum(nolig//'.LIEL', igrel), 'LONMAX', nel)
            itypel=zi(ialiel-1+nel)
            call jenuno(jexnum('&CATA.TE.NOMTE', itypel), nomte)

            if (nomte(1:7) .eq. 'MECABL2') then
                repk='OUI'
                goto 70
        !
            endif
90          continue
        else
            repk='NON'
        endif        
!
!     --------------------------------------
    else if (questi.eq.'EXI_ELTVOL') then
!     --------------------------------------
!          (EXISTENCE D'ELEMENTS DONT LA MAILLE EST VOLUMIQUE)
!
        call jeexin(nolig//'.LIEL', iret)
        if (iret .gt. 0) then
            call jelira(nolig//'.LIEL', 'NUTIOC', nbgrel)
            repk='NON'
            do 50,igrel=1,nbgrel
            call jeveuo(jexnum(nolig//'.LIEL', igrel), 'L', ialiel)
            call jelira(jexnum(nolig//'.LIEL', igrel), 'LONMAX', nel)
            itypel=zi(ialiel-1+nel)
            call jenuno(jexnum('&CATA.TE.NOMTE', itypel), nomte)
            call dismte('TYPE_TYPMAIL', nomte, repi, tytm, ierd)
            if (tytm .eq. 'VOLU') then
                repk='OUI'
                goto 70
!
            endif
50          continue
        else
            repk='NON'
        endif
!
    else
!     ----
        goto 60
!
    endif
!
    goto 70
!
!
!     -- SORTIE ERREUR :
!     ------------------
60  continue
    ierd=1
    goto 80
!
!     -- SORTIE NORMALE :
!     ------------------
70  continue
    ierd=0
    repkz=repk
!
!
80  continue
    call jedema()
end subroutine
