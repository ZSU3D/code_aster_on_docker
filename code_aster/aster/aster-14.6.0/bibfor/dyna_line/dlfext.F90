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

subroutine dlfext(nveca, nchar, temps, neq, liad,&
                  lifo, charge, infoch, fomult, modele,&
                  mate, carele, numedd, f)
!
implicit none
!
#include "jeveux.h"
#include "asterc/r8prem.h"
#include "asterc/r8vide.h"
#include "asterfort/asasve.h"
#include "asterfort/ascova.h"
#include "asterfort/assert.h"
#include "asterfort/fext.h"
#include "asterfort/getvtx.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/r8inir.h"
#include "asterfort/utmess.h"
#include "asterfort/vechme.h"
#include "asterfort/vedime.h"
#include "blas/dcopy.h"
!
integer :: nveca, nchar, neq, liad(*)
real(kind=8) :: temps, f(*)
character(len=24) :: lifo(*), infoch, fomult
character(len=24) :: modele, carele, charge, mate, numedd
!
! --------------------------------------------------------------------------------------------------
!
!  CALCUL DU SECOND MEMBRE F* A PARTIR DE :
!      - VECT_ASSE
!      - CHARGE
!
! --------------------------------------------------------------------------------------------------
!
!  INPUT:
!        NVECA    : NOMBRE D'OCCURENCES DU MOT CLE VECT_ASSE
!        NCHAR    : NOMBRE D'OCCURENCES DU MOT CLE CHARGE
!        TEMPS    : INSTANT DE CALCUL
!        NEQ      : NOMBRE D'EQUATIONS (D.D.L. ACTIFS)
!        LIAD     : LISTE DES ADRESSES DES VECTEURS CHARGEMENT (NVECT)
!        LIFO     : LISTE DES NOMS DES FONCTIONS EVOLUTION (NVECT)
!        CHARGE   : LISTE DES CHARGES
!        INFOCH   : INFO SUR LES CHARGES
!        FOMULT   : LISTE DES FONC_MULT ASSOCIES A DES CHARGES
!        MODELE   : NOM DU MODELE
!        MATE     : NOM DU CHAMP DE MATERIAU
!        CARELE   : CARACTERISTIQUES DES POUTRES ET COQUES
!        NUMEDD   : NUME_DDL DE LA MATR_ASSE RIGID
!
!  OUTPUT:
!        F        : VECTEUR FORCE EXTERIEURE (NEQ)
!
! --------------------------------------------------------------------------------------------------
!
    integer :: jinf, lonch
    integer :: iret, ieq
    integer :: n1
    real(kind=8) :: partps(3)
    character(len=4) :: typmat, para
    character(len=16) :: method
    character(len=19) :: lischa
    character(len=24) :: vechmp, vachmp, cnchmp
    real(kind=8), pointer :: f1(:) => null()
    real(kind=8), pointer :: f2(:) => null()
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
!
    typmat = 'R'
    para = 'INST'
    lischa = charge(1:19)
    ASSERT(lischa.eq.infoch(1:19))
!
    partps(1:3) = [temps, r8vide(), r8vide()]
!
    vechmp = ' '
    vachmp = ' '
    cnchmp = ' '
!
! --- METHODE D'INTEGRATION
!
    call getvtx('SCHEMA_TEMPS', 'SCHEMA', iocc=1, scal=method, nbret=n1)
!
!
! 2.1. ==> --- CAS D'UN CHARGEMENT DEFINI PAR VECT_ASSE ---
!
    if (nveca .ne. 0) then
!
        call fext(temps, neq, nveca, liad, lifo, f)
!
! 2.2. ==> --- CAS D'UN CHARGEMENT DEFINI PAR CHARGE ---
!
    else if (nchar.ne.0) then
!
! 2.2.1 ==>
!
        call jeveuo(infoch, 'L', jinf)
        nchar = zi(jinf)
        call vechme('S', modele, charge, infoch, partps,&
                    carele, mate, vechmp)
        call asasve(vechmp, numedd, typmat, vachmp)
        call ascova('D', vachmp, fomult, 'INST', temps,&
                    typmat, cnchmp)
        call jelira(cnchmp(1:19)//'.VALE', 'LONMAX', lonch)
        call jeveuo(cnchmp(1:19)//'.VALE', 'E', vr=f1)
!
        call dcopy(neq, f1, 1, f, 1)
!
! 2.2.2. ==> -- LES DIRICHLETS
!
        call vedime(modele, charge, infoch, temps, typmat,&
                    vechmp)
        call asasve(vechmp, numedd, typmat, vachmp)
        call ascova('D', vachmp, fomult, para, temps,&
                    typmat, cnchmp)
        call jelira(cnchmp(1:19)//'.VALE', 'LONMAX', lonch)
        call jeveuo(cnchmp(1:19)//'.VALE', 'L', vr=f2)
!
! -- TEST DE PRESENCE DE CHARGEMENT DIRICHLET (DEPL IMPOSE NON NUL)
        iret = 0
        do ieq = 1, lonch
            if (abs(f2(ieq)) .gt. r8prem()) iret = 1
        enddo
        if ((iret.eq.1) .and. (method.ne.'NEWMARK')) then
            call utmess('F', 'DYNALINE1_20')
        endif
!
        do ieq = 1, lonch
            f(ieq) = f(ieq) + f2(ieq)
        enddo
!
    else
        call r8inir(neq, 0.d0, f, 1)
    endif
!
    call jedetr(cnchmp)
!
    call jedema()
!
end subroutine
