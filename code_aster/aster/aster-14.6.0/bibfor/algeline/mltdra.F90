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

subroutine mltdra(nbloc, lgbloc, ncbloc, decal, seq,&
                  nbsn, nbnd, supnd, adress, global,&
                  lgsn, factol, factou, sm, x,&
                  invp, perm, ad, trav, typsym)
! person_in_charge: olivier.boiteau at edf.fr
! aslint: disable=W1304
    implicit none
#include "jeveux.h"
!
#include "asterfort/jedema.h"
#include "asterfort/jelibe.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnum.h"
#include "asterfort/sspmvb.h"
#include "blas/dgemv.h"
    integer :: nbsn, nbnd, nbloc, lgbloc(nbsn), ncbloc(nbnd), decal(nbsn)
    integer(kind=4) :: global(*)
    integer :: seq(nbsn), supnd(nbsn+1), lgsn(nbsn)
    integer :: adress(nbsn+1), invp(nbnd), perm(nbnd), ad(nbnd)
    integer :: typsym
    real(kind=8) :: sm(nbnd), x(nbnd), trav(nbnd)
    character(len=24) :: factol, factou, factor
    integer :: il, k0
    integer :: ib, nc, isnd, long, l, i, ndj
!
    integer :: deb1, incx, incy
    integer :: sni, k, j, deb, fin, adfac, ndk, gj, debndk, ifac
    integer :: seuin, seuik
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
    parameter(seuin=1500,seuik=300)
    integer :: lda, nn, kk
    real(kind=8) :: s, alpha, beta
    character(len=1) :: tra
!
    call jemarq()
!
    tra='N'
    alpha=-1.d0
    beta=1.d0
    incx=1
    incy=1
    k0=0
!
    do 110 j = 1, nbnd
        x(invp(j)) = sm(j)
110  end do
    do 120 j = 1, nbnd
        sm(j) = x(j)
120  end do
!     DESCENTE  L * Y = B
    isnd = 0
    do 180 ib = 1, nbloc
        call jeveuo(jexnum(factol, ib), 'L', ifac)
        adfac = ifac - 1
        do 170 nc = 1, ncbloc(ib)
            isnd = isnd + 1
            sni = seq(isnd)
            long = adress(sni+1) - adress(sni)
            l = lgsn(sni)
            k = 1
            do 130 i = adress(sni), adress(sni+1) - 1
                trav(k) = x(global(i))
                k = k + 1
130          continue
            ad(1) = decal(sni)
            ndj = supnd(sni) - 1
            do 150 j = 1, l - 1
                ndj = ndj + 1
!                 RANGEMENT DU TERME DIAGONAL
                sm(ndj) = zr(ifac-1+ad(j))
!
                k = 1
                do 140 i = j + 1, l
                    trav(i) = trav(i) - zr(ifac-1+ad(j)+k) *trav(j)
                    k = k + 1
140              continue
                ad(j+1) = ad(j) + long + 1
                ad(j) = ad(j) + l - j + 1
150          continue
            ndj = ndj + 1
!                 RANGEMENT DU TERME DIAGONAL
            sm(ndj) = zr(ifac-1+ ad(l))
            ad(l) = ad(l) + 1
            if (long .gt. l) then
                nn= long - l
                kk= l
                lda = long
                if (nn .lt. seuin .or. kk .lt. seuik) then
                    call sspmvb((long-l), l, zr(ifac), ad, trav,&
                                trav(l+1))
                else
                    call dgemv(tra, nn, kk, alpha, zr(ifac+ad(1)-1),&
                               lda, trav, incx, beta, trav(l+1),&
                               incy)
                endif
            endif
            k = 1
            do 160 i = adress(sni), adress(sni+1) - 1
                x(global(i)) = trav(k)
                k = k + 1
160          continue
170      continue
        call jelibe(jexnum(factol, ib))
180  end do
!
    if (typsym .ne. 0) then
        factor = factol
        deb1=1
    else
        factor = factou
        deb1 = nbnd
    endif
!=======================================================================
!     D * Z = Y
    do 190 j = deb1, nbnd
        x(j) = x(j)/sm(j)
190  continue
!=======================================================================
!     REMONTEE  U * X = Z
    isnd = nbsn + 1
    do 260 ib = nbloc, 1, -1
        call jeveuo(jexnum(factor, ib), 'L', ifac)
        if (ib .ne. nbloc) then
            adfac = lgbloc(ib) + ifac
        else
            adfac = lgbloc(ib) + ifac - lgsn(nbsn)
        endif
        do 250 nc = 1, ncbloc(ib)
            isnd = isnd - 1
            sni = seq(isnd)
            l = lgsn(sni)
            fin = adress(sni+1) - 1
            if (sni .eq. nbsn) then
                debndk = supnd(sni+1) - 2
                deb = adress(sni) + lgsn(sni) - 1
                il = l - 1
            else
                deb = adress(sni) + lgsn(sni)
                debndk = supnd(sni+1) - 1
                il = l
            endif
            if (l .gt. 1) then
                k = 1
                do 200 i = adress(sni), adress(sni+1) - 1
                    trav(k) = x(global(i))
                    k = k + 1
200              continue
                k0 = k
            endif
            do 230 ndk = debndk, supnd(sni), -1
                s = 0.d0
                if (l .gt. 1) then
                    k = k0
                    do 210 j = fin, deb, -1
                        adfac = adfac - 1
                        k = k - 1
                        s = s + zr(adfac)*trav(k)
210                  continue
                    deb = deb - 1
                    adfac = adfac - 1
                    trav(il) =trav(il) - s
                    if (typsym .eq. 0) trav(il) =trav(il) /zr(adfac)
! DECALAGE  POUR SGEMV
                    adfac = adfac - (ndk-supnd(sni))
                else
                    k = k0
                    do 220 j = fin, deb, -1
                        gj = global(j)
                        adfac = adfac - 1
                        k = k - 1
                        s = s + zr(adfac)*x(gj)
220                  continue
                    deb = deb - 1
                    adfac = adfac - 1
                    x(ndk) = x(ndk) - s
                    if (typsym .eq. 0) x(ndk) = x(ndk) /zr(adfac)
! DECALAGE  POUR SGEMV
                    adfac = adfac - (ndk-supnd(sni))
                endif
                il = il - 1
230          continue
            if (l .gt. 1) then
                k = 1
                do 240 i = adress(sni), adress(sni+1) - 1
                    x(global(i)) = trav(k)
                    k = k + 1
240              continue
            endif
250      continue
        call jelibe(jexnum(factor, ib))
260  end do
!     ON RANGE DANS SM  LA SOLUTION DANS LA NUMEROTATION INITIALE
    do 270 j = 1, nbnd
        sm(perm(j)) = x(j)
270  end do
    call jedema()
end subroutine
