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

subroutine gcpc(m, in, ip, ac, inpc, perm,&
                ippc, acpc, bf, xp, r,&
                rr, p, irep, niter, epsi,&
                criter, solveu, matas, istop,&
                iret)
!     RESOLUTION D'UN SYSTEME LINEAIRE SYMETRIQUE PAR UNE METHODE DE
!     GRADIENT CONJUGUE PRECONDITIONNE
!               LA MATRICE EST STOCKEE SOUS FORME COMPACTE (IN,IP,AC)
!    -------------------------------------------------------------------
!    . M             -->   NOMBRE DE COLONNES DE LA MATRICE
!    . IN            -->   POINTEUR DE FIN DE COLONNE DE LA MATRICE
!    . IP            -->   TABLEAU DES NUMEROS DE LIGNE
!    . AC            -->   TABLEAU DES COEFFICIENTS DE LA MATRICE
!
!    . INPC          -->   IDEM IN POUR MATRICE DE PRECOND.
!    . IPPC          -->   IDEM IP POUR MATRICE DE PRECOND.
!    . ACPC          -->   IDEM AC POUR MATRICE DE PRECOND.
!    . BF            -->   VECTEUR SECOND MEMBRE
!    . XP           <-->   VECTEUR SOLUTION
!    . R            <--    VECTEUR RESIDU
!    . RR           <--    DIRECTION DE DESCENTE AVANT CONJUGAISON
!    . P            <--    DIRECTION DE DESCENTE APRES CONJUGAISON
!    -------------------------------------------------------------------
!    . IREP          -->    0  XP INITIAL MIS A ZERO
!                           1  XP INITIAL DONNEE DE GCPC
!    -------------------------------------------------------------------
!    . NITER         -->   NOMBRE MAXIMUM D'ITERATIONS
!    . EPSI          -->   CRITERE DE CONVERGENCE
!    . CRITER        -->   SD_CRITER (CRITERES DE CONVERGENCE)
!    -------------------------------------------------------------------
!    . SOLVEU        -->   SD_SOLVEUR (POUR LDLT_SP)
!    . MATASS        -->   MATRICE ASSEMBLEE DU SYSTEME (POUR LDLT_SP)
!     ------------------------------------------------------------------
!     - PRECAUTIONS D'EMPLOI:  XP PEUT ETRE EVENTUELLEMENT CONFONDU
!                              AVEC BF SI MEME ARGUMENT
!     ------------------------------------------------------------------
! CORPS DU PROGRAMME
! aslint: disable=W1304
    implicit none
!
! DECLARATION PARAMETRES D'APPELS
#include "jeveux.h"
#include "asterc/matfpe.h"
#include "asterfort/amumph.h"
#include "asterfort/assert.h"
#include "asterfort/crsmsp.h"
#include "asterfort/detrsd.h"
#include "asterfort/gcax.h"
#include "asterfort/gcldm1.h"
#include "asterfort/infniv.h"
#include "asterfort/jedema.h"
#include "asterfort/jeexin.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/r8inir.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"
#include "asterfort/as_allocate.h"
#include "asterfort/as_deallocate.h"
#include "blas/daxpy.h"
#include "blas/dcopy.h"
#include "blas/ddot.h"
#include "blas/dnrm2.h"
#include "blas/dscal.h"

    integer(kind=4) :: ip(*), ippc(*)
    integer :: m, in(m), inpc(m), irep, niter, perm(m)
    real(kind=8) :: ac(m), acpc(m), bf(m), xp(m), r(m), rr(m), p(m), epsi
    character(len=19) :: criter, matas, solveu
    integer :: istop, iret

! -----------------------------------------------------------------
    real(kind=8) :: zero, bnorm, anorm, epsix, anormx, rrri, gama, rrrim1
    real(kind=8) :: paraaf, anorxx, rau, valr(2)
    integer :: ifm, niv, jcri, jcrr, jcrk, iter, ier, vali, pcpiv
    character(len=24) :: precon, solvbd, usersm
    complex(kind=8) :: cbid
    integer, pointer :: slvi(:) => null()
    character(len=24), pointer :: slvk(:) => null()
    real(kind=8), pointer :: xtrav(:) => null()
    real(kind=8), pointer :: ytrav(:) => null()
! -----------------------------------------------------------------
!
    cbid=(0.d0,0.d0)
    call jemarq()
!
    call matfpe(-1)
    iter=0
!
!-----RECUPERATION DU NIVEAU D'IMPRESSION
    call infniv(ifm, niv)


!
!-----PARAMETRE D'AFFICHAGE DE LA DECROISSANCE DU RESIDU
!     (SI ON GAGNE PARAAF * 100%)
    paraaf = 0.1d0
!
!-----INITS DIVERS
    iret = 0
    zero = 0.d0
    ASSERT(irep.eq.0 .or. irep.eq.1)
!
!-----RECUPERATION DU PRECONDITIONNEUR
!  -- CREATION DE LA SD SOLVEUR MUMPS SIMPLE PRECISION
!  -- (A DETRUIRE A LA SORTIE)
    call jeveuo(solveu//'.SLVK', 'L', vk24=slvk)
    call jeveuo(solveu//'.SLVI', 'L', vi=slvi)
    precon=slvk(2)
    usersm=slvk(9)
    pcpiv=slvi(7)
    if (precon .eq. 'LDLT_SP') then
        solvbd = slvk(3)
        call crsmsp(solvbd, matas, pcpiv, usersm )
    endif


!-----Pour tenir compte de la renumerotation de la matrice de preconditionnement (LDLT):
    if (precon .eq. 'LDLT_INC') then
        AS_ALLOCATE(vr=xtrav, size=m)
        AS_ALLOCATE(vr=ytrav, size=m)
    endif
!
!-----CALCULS PRELIMINAIRES
!
!      ---- CALCUL DE NORME DE BF
    bnorm = dnrm2(m,bf,1)
    if (bnorm .eq. zero) then
        call r8inir(m, zero, xp, 1)
!        WRITE (IFM,*)'>>>>>>> SECOND MEMBRE = 0 DONC SOLUTION = 0 '
        goto 80
    endif
!
    if (irep .eq. 0) then
!       ---- INITIALISATION X1 = 0    ===>   CALCUL DE R1 = A*X0 - B
        call r8inir(m, zero, xp, 1)
        call dcopy(m, bf, 1, r, 1)
        call dscal(m, -1.d0, r, 1)
        anorm = bnorm
        epsix = epsi*anorm
        if (niv .eq. 2) write (ifm,101) anorm,epsix,epsi
    else
!       ---- INITIALISATION PAR X PRECEDENT: CALCUL DE R1 = A*X1 - B
        call gcax(m, in, ip, ac, xp,&
                  r)
        call daxpy(m, -1.d0, bf, 1, r,&
                   1)
        anorm = dnrm2(m,r,1)
        epsix = epsi*anorm
        if (niv .eq. 2) write (ifm,102) anorm,epsix,epsi
    endif
!
    call jeexin(criter//'.CRTI', ier)
    if (ier .eq. 0) then
        if (criter .ne. ' ') then
            call wkvect(criter//'.CRTI', 'V V I', 1, jcri)
            call wkvect(criter//'.CRTR', 'V V R8', 1, jcrr)
            call wkvect(criter//'.CRDE', 'V V K16', 2, jcrk)
            zk16(jcrk) = 'ITER_GCPC'
            zk16(jcrk+1) = 'RESI_GCPC'
        else
            jcri=0
        endif
    else
        call jeveuo(criter//'.CRTI', 'E', jcri)
        call jeveuo(criter//'.CRTR', 'E', jcrr)
    endif
!
! ---- ITERATIONS
    anormx = anorm
    anorxx = anorm
!
    do iter = 1, niter
!       ---- PRECONDITIONNEMENT DU RESIDU:
!                                             ZK = (LDLT)-1. RK
!                                                   RK <--- R()
!                                                  ZK <--- RR()
        if (precon .eq. 'LDLT_INC') then
            call gcldm1(m, inpc, ippc, acpc, r, rr, perm, xtrav, ytrav)
        else if (precon.eq.'LDLT_SP') then
          call dcopy(m, r, 1, rr, 1)
!         ON PASSE ' ' AU LIEU DE VCINE, DEJA PRIS EN COMPTE DANS RESGRA
            call amumph('RESOUD', solvbd, matas, rr, [cbid],&
                        ' ', 1, ier, .true._1)
        else
            ASSERT(.false.)
        endif
!
!                                             RRRI <--- (RK,ZK)
        rrri = ddot(m,r,1,rr,1)
!       ---- NOUVELLE DIRECTION DE DESCENTE:
!                                    BETAK = (RK,ZK)/(RK-1,ZK-1)
!                                               BETAK <--- GAMA
!                                        PK = BETAK * PK-1 + ZK
!                                                   PK <--- P()
        if (iter .gt. 1) then
            gama = rrri/rrrim1
            call dscal(m, gama, p, 1)
            call daxpy(m, 1.d0, rr, 1, p,&
                       1)
        else
            call dcopy(m, rr, 1, p, 1)
        endif
        rrrim1 = rrri
!
!       ---- NOUVEAUX RESIDU ET DEPLACEMENT:
!                       ZZK = A.PK ET ALPHAK = -(RK,ZK)/(PK,ZZK)
!                                       XK+1 = XK + ALPHAK * PK
!                                      RK+1 = RK + ALPHAK * ZZK
!                                                 ZZK <--- RR()
!                                                 XK  <--- XP()
        call gcax(m, in, ip, ac, p,&
                  rr)
        rau = -rrri/ddot(m,p,1,rr,1)
        call daxpy(m, rau, p, 1, xp,&
                   1)
        call daxpy(m, rau, rr, 1, r,&
                   1)
!
!       ---- CALCUL TEST D'ARRET ET AFFICHAGE
        anorm = dnrm2(m,r,1)
        if (anorm .le. anormx*paraaf) then
            if (niv .eq. 2) write (*,104) iter,anorm,anorm/anorxx
            anormx = anorm
        endif
        if (niv .eq. 3) write (ifm,104) iter,anorm,anorm/anorxx
!
!       --- TEST DE CONVERGENCE
        if (anorm .lt. epsix) then
            if (niv .eq. 2) write (ifm,103) anorxx,anorm,anorm/anorxx
            if (niv .eq. 2) write (ifm,105) iter
            if (jcri .ne. 0) then
                zi(jcri) = iter
                zr(jcrr) = anorm
            endif
            goto 80
        endif
    end do
!
!

!        ---  NON CONVERGENCE
    vali = iter
    valr (1) = anorm/anorxx
    valr (2) = epsi
    if ( istop == 0 ) then
!            ERREUR <F>
        select case (precon)
        case('LDLT_INC')
            call utmess('F', 'ALGELINE4_3', si=vali, nr=2, valr=valr)
        case('LDLT_SP')
            call utmess('F', 'ALGELINE4_6', si=vali, nr=2, valr=valr)
        case default
            ASSERT(.false.)
        end select
    elseif ( istop == 2 ) then
!            ON CONTINUE EN RETOURNANT UN CODE D'ERREUR IRET=1
        iret = 1
        goto 80
    else
        ASSERT(.false.)
    endif
!    -----------
    101 format (/'   * GCPC   NORME DU RESIDU =',d11.4,&
     &       '  (INITIALISATION PAR X = ZERO)',/,&
     &'   *        NORME DU RESIDU A ATTEINDRE EN ABS/RELA=',&
     &d11.4,d11.4,/)
    102 format (/'   * GCPC   NORME DU RESIDU =',d11.4,&
     &       '  (INITIALISATION PAR X PRECEDENT)',/,&
     & '   *        NORME DU RESIDU A ATTEINDRE EN ABS/RELA=',&
     & d11.4,d11.4)
    103 format ('   * NORME DU RESIDU INITIAL/FINAL/RELATIF=',&
     &         d11.4,d11.4,d11.4)
    104 format ('   * ITERATION',i5,' NORME DU RESIDU EN ABS/RELA =',&
     &         d11.4,d11.4)
    105 format (1x,/,2x,32 ('*')/'  * CONVERGENCE EN ',i4,&
     &       ' ITERATIONS'/2x,32 ('*'),/)
!    -----------
80  continue
!
! --  DESTRUCTION DE LA SD SOLVEUR MUMPS SIMPLE PRECISION
    if (precon .eq. 'LDLT_SP') then
        call detrsd('SOLVEUR', solvbd)
!       ON STOCKE LE NOMBRE D'ITERATIONS DU GCPC
        call jeveuo(solveu//'.SLVI', 'E', vi=slvi)
        slvi(5)=iter
    endif
!
    call matfpe(1)
!
    if (precon .eq. 'LDLT_INC') then
        AS_DEALLOCATE(vr=xtrav)
        AS_DEALLOCATE(vr=ytrav)
    endif
    call jedema()
!
end subroutine
