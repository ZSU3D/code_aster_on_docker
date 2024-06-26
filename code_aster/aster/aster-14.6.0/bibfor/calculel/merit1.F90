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

subroutine merit1(modele, nchar, lchar, mate, cara,&
                  time, matel, nh, prefch, numero,&
                  base)
    implicit none
!
!
!     ARGUMENTS:
!     ----------
#include "jeveux.h"
#include "asterfort/calcul.h"
#include "asterfort/codent.h"
#include "asterfort/exisd.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeexin.h"
#include "asterfort/jemarq.h"
#include "asterfort/mecara.h"
#include "asterfort/megeom.h"
#include "asterfort/meharm.h"
#include "asterfort/memare.h"
#include "asterfort/reajre.h"
    character(len=8) :: modele, cara, lcharz
    character(len=19) :: matel, prefch
    character(len=*) :: lchar(*), mate
    character(len=24) :: time
    character(len=1) :: base
    integer :: nchar, numero
! ----------------------------------------------------------------------
!
!     CALCUL DES MATRICES ELEMENTAIRES DE RIGIDITE THERMIQUE (1)
!            ( ISO     , 'RIGI_THER'  )
!            ( CAL_TI  , 'THER_DDLM_R')
!
!     LES RESUELEM PRODUITS S'APPELLENT :
!           PREFCH(1:8).ME000I , I=NUMERO+1,NUMERO+N
!
!     ENTREES:
!
!     LES NOMS QUI SUIVENT SONT LES PREFIXES UTILISATEUR K8:
!        MODELE : NOM DU MODELE
!        NCHAR  : NOMBRE DE CHARGES
!        LCHAR  : LISTE DES CHARGES
!        MATE   : CHAMP DE MATERIAUX
!        CARA   : CHAMP DE CARAC_ELEM
!        MATEL  : NOM DU MATR_ELEM (N RESUELEM) PRODUIT
!        PREFCH : PREFIXE DES NOMS DES RESUELEM STOCKES DANS MATEL
!        NUMERO : NUMERO D'ORDRE A PARTIR DUQUEL ON NOMME LES RESUELEM
!        TIME   : CHAMPS DE TEMPSR
!
!     SORTIES:
!        MATEL  : EST REMPLI.
!
! ----------------------------------------------------------------------
!
!     FONCTIONS EXTERNES:
!     -------------------
!
!     VARIABLES LOCALES:
!     ------------------
    character(len=8) :: lpain(6), lpaout(1)
    character(len=16) :: option
    character(len=24) :: chgeom, chharm, lchin(6), lchout(1)
    character(len=24) :: ligrmo, ligrch, chcara(18)
!
!-----------------------------------------------------------------------
    integer :: icha, ilires, iret, nh
!-----------------------------------------------------------------------
    call jemarq()
!
!     -- ON VERIFIE LA PRESENCE PARFOIS NECESSAIRE DE CARA_ELEM
!        ET CHAM_MATER :
    call megeom(modele, chgeom)
    call mecara(cara, chcara)
    call meharm(modele, nh, chharm)
!
    call jeexin(matel//'.RERR', iret)
    if (iret .gt. 0) then
        call jedetr(matel//'.RERR')
        call jedetr(matel//'.RELR')
    endif
    call memare('V', matel, modele, mate, cara,&
                'RIGI_THER')
!
    lpaout(1) = 'PMATTTR'
    lchout(1) = prefch(1:8)//'.ME000'
    ilires = 0
    if (modele .ne. '       ') then
        lpain(1) = 'PGEOMER'
        lchin(1) = chgeom
        lpain(2) = 'PMATERC'
        lchin(2) = mate(1:24)
        lpain(3) = 'PCACOQU'
        lchin(3) = chcara(7)
        lpain(4) = 'PTEMPSR'
        lchin(4) = time
        lpain(5) = 'PHARMON'
        lchin(5) = chharm
        lpain(6) = 'PCAMASS'
        lchin(6) = chcara(12)
        ligrmo = modele//'.MODELE'
        option = 'RIGI_THER'
        ilires=ilires+1
        call codent(ilires+numero, 'D0', lchout(1) (12:14))
        call calcul('S', option, ligrmo, 6, lchin,&
                    lpain, 1, lchout, lpaout, base,&
                    'OUI')
        call reajre(matel, lchout(1), base)
    endif
    if (lchar(1) (1:8) .ne. '        ') then
        do 10 icha = 1, nchar
            lpain(1) = 'PDDLMUR'
            lcharz = lchar(icha)
            call exisd('CHAMP_GD', lcharz//'.CHTH.CMULT', iret)
            if (iret .eq. 0) goto 10
            lchin(1) = lchar(icha)//'.CHTH.CMULT     '
            ilires=ilires+1
            call codent(ilires+numero, 'D0', lchout(1) (12:14))
            ligrch = lchar(icha)//'.CHTH.LIGRE'
            option = 'THER_DDLM_R'
            call calcul('S', option, ligrch, 1, lchin,&
                        lpain, 1, lchout, lpaout, base,&
                        'OUI')
            call reajre(matel, lchout(1), base)
10      continue
    endif
!
    call jedema()
end subroutine
