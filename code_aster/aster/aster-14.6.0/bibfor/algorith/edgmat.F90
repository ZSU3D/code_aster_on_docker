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

subroutine edgmat(fami   , kpg   , ksp   , imat  , c1 ,&
                  zalpha , temp  , dt    , mum   , mu ,&
                  troiskm, troisk, ani   , m     , n  ,&
                  gamma  , zcylin)
!
implicit none
!
#include "asterfort/assert.h"
#include "asterfort/rcvalb.h"
#include "asterfort/utmess.h"
#include "asterfort/get_elas_para.h"
#include "asterfort/get_elas_id.h"
!
!
    character(len=*), intent(in) :: fami
    integer, intent(in) :: kpg
    integer, intent(in) :: ksp
    integer, intent(in) :: imat
    character(len=1), intent(in) :: c1
    real(kind=8), intent(in) :: zalpha
    real(kind=8), intent(in) :: temp
    real(kind=8), intent(in) :: dt
    real(kind=8), intent(out) :: mum
    real(kind=8), intent(out) :: mu
    real(kind=8), intent(out) :: troiskm
    real(kind=8), intent(out) :: troisk
    real(kind=8), intent(out) :: ani(6, 6)
    real(kind=8), intent(out) :: m(3)
    real(kind=8), intent(out) :: n(3)
    real(kind=8), intent(out) :: gamma(3)
    logical, intent(out) :: zcylin
!
! --------------------------------------------------------------------------------------------------
!
!    MODELE VISCOPLASTIQUE SANS SEUIL DE EDGAR
!    RECUPERATION DES CARACTERISTIQUES MATERIAUX
!  IN  FAMI :  FAMILLE DE POINT DE GAUSS (RIGI,MASS,...)
!  IN  KPG  :  NUMERO DU POINT DE GAUSS
!  IN  KSP  :  NUMERO DU SOUS-POINT DE GAUSS
!  IN  IMAT :  ADRESSE DU MATERIAU CODE
!  IN  C1   :  VAUT '-' SI RIGI VAUT '+' SINON
!
!  OUT MUM    : COEFFICIENT DE L ELASTICITE A L INSTANT MOINS
!  OUT MU     : COEFFICIENT DE L ELASTICITE A L INSTANT COURANT
!  OUT TROIKM : COEFFICIENT DE L ELASTICITE A L INSTANT MOINS
!  OUT TROISK : COEFFICIENT DE L ELASTICITE A L INSTANT COURANT
!  OUT ANI    : MATRICE D ANISOTROPIE DE HILL
!  OUT M, N ET GAMMA : COEFFICIENT DE VISCOSITE A L INSTANT COURANT
!
! --------------------------------------------------------------------------------------------------
!
    integer :: i, j, k
    real(kind=8) :: valres(27), a(3), q(3), fmel(3)
    real(kind=8) :: m11(2), m22(2), m33(2), m44(2), m55(2), m66(2)
    real(kind=8) :: m12(2), m13(2), m23(2)
    real(kind=8) :: young, nu, youngm, num
    integer :: icodre(27), elas_id
    character(len=8) :: nomc(27)
    character(len=16) :: elas_keyword
!
! --------------------------------------------------------------------------------------------------
!
    nomc(1:27)   = ' '
    valres(1:27) = 0.d0
    icodre(1:27) = 0
!
! - Get type of elasticity (Isotropic/Orthotropic/Transverse isotropic)
!
    call get_elas_id(imat, elas_id, elas_keyword)
!
! - Get elastic parameters (only isotropic elasticity)
!
    call get_elas_para(fami, imat, '-', kpg, ksp,&
                       elas_id  , elas_keyword,&
                       e = youngm, nu = num)
    ASSERT(elas_id.eq.1)
    mum     = youngm/(2.d0*(1.d0+num))
    troiskm = youngm/(1.d0-2.d0*num)
!
    call get_elas_para(fami, imat, c1, kpg, ksp,&
                       elas_id  , elas_keyword,&
                       e = young, nu = nu)
    ASSERT(elas_id.eq.1)
    mu      = young/(2.d0*(1.d0+nu))
    troisk  = young/(1.d0-2.d0*nu)
!
! 2 - MATRICE D ANISOTROPIE
! 2.1 - TEST POUR SAVOIR SI ON EST EN COORDONNEES
!       CARTESIENNES OU CYLINDRIQUES
    zcylin=.true.
    nomc(16)= 'F_MRR_RR'
    call rcvalb(fami, kpg, ksp, c1, imat,&
                ' ', 'META_LEMA_ANI', 0, ' ', [0.d0],&
                1, nomc(16), valres(16), icodre(16), 0)
    if (icodre(16).eq.0) then
        m11(1)=valres(16)
    else
        nomc(16)= 'F_MXX_XX'
        call rcvalb(fami, kpg, ksp, c1, imat,&
                    ' ', 'META_LEMA_ANI', 0, ' ', [0.d0],&
                    1, nomc(16), valres(16), icodre(16), 0)
        if (icodre(16).eq.0) then
            m11(1)=valres(16)
            zcylin=.false.
        else
            call utmess('F', 'ALGORITH17_42')
        endif
    endif


! 2.2 - DONNEES UTILISATEUR - UNIQUEMENT LA PHASE FROIDE ET CHAUDE
!       PHASE FROIDE => INDICE 1
!       PHASE CHAUDE => INDICE 2
!
    if (zcylin) then
        nomc(17)= 'C_MRR_RR'
        nomc(18)= 'F_MTT_TT'
        nomc(19)= 'C_MTT_TT'
        nomc(20)= 'F_MZZ_ZZ'
        nomc(21)= 'C_MZZ_ZZ'
        nomc(22)= 'F_MRT_RT'
        nomc(23)= 'C_MRT_RT'
        nomc(24)= 'F_MRZ_RZ'
        nomc(25)= 'C_MRZ_RZ'
        nomc(26)= 'F_MTZ_TZ'
        nomc(27)= 'C_MTZ_TZ'
!
        call rcvalb(fami, kpg, ksp, c1, imat,&
                    ' ', 'META_LEMA_ANI', 0, ' ', [0.d0],&
                    11, nomc(17), valres(17), icodre(17), 2)
!
        m22(1)=valres(18)
        m33(1)=valres(20)
        m44(1)=valres(22)
        m55(1)=valres(24)
        m66(1)=valres(26)
!
        m11(2)=valres(17)
        m22(2)=valres(19)
        m33(2)=valres(21)
        m44(2)=valres(23)
        m55(2)=valres(25)
        m66(2)=valres(27)
    else
        nomc(17)= 'C_MXX_XX'
        nomc(18)= 'F_MYY_YY'
        nomc(19)= 'C_MYY_YY'
        nomc(20)= 'F_MZZ_ZZ'
        nomc(21)= 'C_MZZ_ZZ'
        nomc(22)= 'F_MXY_XY'
        nomc(23)= 'C_MXY_XY'
        nomc(24)= 'F_MXZ_XZ'
        nomc(25)= 'C_MXZ_XZ'
        nomc(26)= 'F_MYZ_YZ'
        nomc(27)= 'C_MYZ_YZ'
!
        call rcvalb(fami, kpg, ksp, c1, imat,&
                    ' ', 'META_LEMA_ANI', 0, ' ', [0.d0],&
                    11, nomc(17), valres(17), icodre(17), 2)
!
        m22(1)=valres(18)
        m33(1)=valres(20)
        m44(1)=valres(22)
        m55(1)=valres(24)
        m66(1)=valres(26)
!
        m11(2)=valres(17)
        m22(2)=valres(19)
        m33(2)=valres(21)
        m44(2)=valres(23)
        m55(2)=valres(25)
        m66(2)=valres(27)
    endif

!
! 2.3 - ON COMPLETE LA MATRICE MIJ(1) ET MIJ(2)
!
    do k = 1, 2
        m12(k)=(-m11(k)-m22(k)+m33(k))/2.d0
        m13(k)=(-m11(k)+m22(k)-m33(k))/2.d0
        m23(k)=( m11(k)-m22(k)-m33(k))/2.d0
    end do
!
! 2.4 - ON CONSTRUIT ANI(I,J) SUIVANT LE % DE PHASE FROIDE
! SI 0   <ZALPHA<0.01 => ANI(I,J)=MIJ(2)
! SI 0.01<ZALPHA<0.99 => ANI(I,J)=ZALPHA*MIJ(1)+(1-ZALPHA)*MIJ(2)
! SI 0.99<ZALPHA<1    => ANI(I,J)=MIJ(1)
!
    do i = 1, 6
        do j = 1, 6
            ani(i,j)=0.d0
        end do
    end do
!
    if (zalpha .le. 0.01d0) then
        ani(1,1)=m11(2)
        ani(2,2)=m22(2)
        ani(3,3)=m33(2)
        ani(1,2)=m12(2)
        ani(2,1)=m12(2)
        ani(1,3)=m13(2)
        ani(3,1)=m13(2)
        ani(2,3)=m23(2)
        ani(3,2)=m23(2)
        ani(4,4)=m44(2)
        ani(5,5)=m55(2)
        ani(6,6)=m66(2)
    endif
!
    if ((zalpha.gt.0.01d0) .and. (zalpha.le.0.99d0)) then
        ani(1,1)=zalpha*m11(1)+(1.d0-zalpha)*m11(2)
        ani(2,2)=zalpha*m22(1)+(1.d0-zalpha)*m22(2)
        ani(3,3)=zalpha*m33(1)+(1.d0-zalpha)*m33(2)
        ani(1,2)=zalpha*m12(1)+(1.d0-zalpha)*m12(2)
        ani(2,1)=ani(1,2)
        ani(1,3)=zalpha*m13(1)+(1.d0-zalpha)*m13(2)
        ani(3,1)=ani(1,3)
        ani(2,3)=zalpha*m23(1)+(1.d0-zalpha)*m23(2)
        ani(3,2)=ani(2,3)
        ani(4,4)=zalpha*m44(1)+(1.d0-zalpha)*m44(2)
        ani(5,5)=zalpha*m55(1)+(1.d0-zalpha)*m55(2)
        ani(6,6)=zalpha*m66(1)+(1.d0-zalpha)*m66(2)
    endif
!
    if (zalpha .gt. 0.99d0) then
        ani(1,1)=m11(1)
        ani(2,2)=m22(1)
        ani(3,3)=m33(1)
        ani(1,2)=m12(1)
        ani(2,1)=m12(1)
        ani(1,3)=m13(1)
        ani(3,1)=m13(1)
        ani(2,3)=m23(1)
        ani(3,2)=m23(1)
        ani(4,4)=m44(1)
        ani(5,5)=m55(1)
        ani(6,6)=m66(1)
    endif
!
! 3 - CARACTERISTIQUES PLASTIQUES
! 3.1 - DONNEES UTILISATEUR
!
    nomc(4) = 'F1_A    '
    nomc(5) = 'F2_A    '
    nomc(6) = 'C_A     '
    nomc(7) = 'F1_M    '
    nomc(8) = 'F2_M    '
    nomc(9) = 'C_M     '
    nomc(10)= 'F1_N    '
    nomc(11)= 'F2_N    '
    nomc(12)= 'C_N     '
    nomc(13)= 'F1_Q    '
    nomc(14)= 'F2_Q    '
    nomc(15)= 'C_Q     '
!
    call rcvalb(fami, kpg, ksp, c1, imat,&
                ' ', 'META_LEMA_ANI', 0, ' ', [0.d0],&
                12, nomc(4), valres(4), icodre(4), 2)
!
    do k = 1, 3
        a(k)=valres(4+k-1)
        m(k)=valres(7+k-1)
        n(k)=1.d0/valres(10+k-1)
        q(k)=valres(13+k-1)
    end do
!
! 3.2 - LOI DES MELANGES FMEL SUR LA CONTRAINTE VISQUEUSE
!
    if (zalpha .le. 0.01d0) then
        fmel(1)=0.d0
        fmel(2)=0.d0
        fmel(3)=1.d0
    endif
!
    if ((zalpha.gt.0.01d0) .and. (zalpha.le.0.1d0)) then
        fmel(1)=0.d0
        fmel(2)=1.d0-((0.1d0-zalpha)/0.09d0)
        fmel(3)=(0.1d0-zalpha)/0.09d0
    endif
!
    if ((zalpha.gt.0.1d0) .and. (zalpha.le.0.9d0)) then
        fmel(1)=0.d0
        fmel(2)=1.d0
        fmel(3)=0.d0
    endif
!
    if ((zalpha.gt.0.9d0) .and. (zalpha.le.0.99d0)) then
        fmel(1)=(zalpha-0.9d0)/0.09d0
        fmel(2)=1.d0-((zalpha-0.9d0)/0.09d0)
        fmel(3)=0.d0
    endif
!
    if (zalpha .gt. 0.99d0) then
        fmel(1)=1.d0
        fmel(2)=0.d0
        fmel(3)=0.d0
    endif
!
! 3.3 - PARAMETRE INTERVENANT DANS LA CONTRAINTE VISQUEUSE
!
    do k = 1, 3
        gamma(k)=fmel(k)*a(k)
        if (gamma(k) .ne. 0.d0) then
            gamma(k)=log(gamma(k))-log(2.d0*mu)-n(k)*log(dt)
            gamma(k)=gamma(k)+(n(k)*q(k)/(temp+273.d0))
            gamma(k)=exp(gamma(k))
        endif
    end do
!
end subroutine
