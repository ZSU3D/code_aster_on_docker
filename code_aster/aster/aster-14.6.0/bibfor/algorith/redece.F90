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
! aslint: disable=W1306,W1504
!
subroutine redece(fami, kpg, ksp, ndim, typmod, l_epsi_varc,&
                  imate, compor, mult_comp, carcri, instam, instap,&
                  neps, epsdt, depst, nsig, sigd,&
                  vind, option, angmas, nwkin, wkin,&
                  cp, numlc, &
                  sigf, vinf, ndsde, dsde, nwkout,&
                  wkout, codret)
!
use calcul_module, only : ca_iredec_, ca_td1_, ca_tf1_, ca_timed1_, ca_timef1_
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/lc0000.h"
#include "asterfort/lceqve.h"
#include "asterfort/lceqvn.h"
#include "asterfort/lcprsm.h"
#include "asterfort/lcprsv.h"
#include "asterfort/lcsoma.h"
#include "asterfort/lcsove.h"
#include "asterfort/r8inir.h"
#include "asterfort/utmess.h"
!
! ======================================================================
!     INTEGRATION DES LOIS DE COMPORTEMENT NON LINEAIRE POUR LES
!     ELEMENTS ISOPARAMETRIQUES EN PETITES OU GRANDES DEFORMATIONS
! ======================================================================
! ROUTINE DE REDECOUPAGE LOCAL DU PAS dE TEMPS
! ----------------------------------------------------------------------
!       - SI CARCRI(5) = -N  EN CAS DE NON-CONVERGENCE LOCALE ON EFFECTU
!                          UN REDECOUPAGE DU PAS DE TEMPS EN N PALIERS
!                          L ORDRE D EXECUTION ETANT REMONTE EN ARGUMENT
!                          DANS REDECE, APPELE PAR NMCOMPOR AVANT PLASTI
!       - SI CARCRI(5) = -1,0,1  PAS DE REDECOUPAGE DU PAS DE TEMPS
!       - SI CARCRI(5) = +N  ON EFFECTUE UN REDECOUPAGE DU PAS DE TEMPS
!                          EN N PALIERS A CHAQUE APPEL DE REDECE
!                          LE PREMIER APPEL DE PLASTI SERT A
!                          L'INITIALISATION DE NVI
!       SI APRES REDECOUPAGE ON ABOUTIT A UN CAS DE NON CONVERGENCE, ON
!       REDECOUPE A NOUVEAU LE PAS DE TEMPS, EN 2*N PALIERS
!
!    ATTENTION  VIND    VARIABLES INTERNES A T MODIFIEES SI REDECOUPAGE
!
! ======================================================================
!     ARGUMENTS
! ======================================================================
!
! IN  FAMI,KPG,KSP  : FAMILLE ET NUMERO DU (SOUS)POINT DE GAUSS
!     NDIM    : DIMENSION DE L'ESPACE
!               3 : 3D , 2 : D_PLAN ,AXIS OU  C_PLAN
!     TYPMOD(2): MODELISATION ex: 1:3D, 2:INCO
!     IMATE   : ADRESSE DU MATERIAU CODE
!     COMPOR  : COMPORTEMENT :  (1) = TYPE DE RELATION COMPORTEMENT
!                               (2) = NB VARIABLES INTERNES / PG
!                               (3) = HYPOTHESE SUR LES DEFORMATIONS
!                               (4) etc... (voir grandeur COMPOR)
!     MULT_COMP : MULTI-COMPORTEMENT (pour POLYCRISTAL)
!     CARCRI  : CRITERES DE CONVERGENCE LOCAUX (voir grandeur CARCRI)
!     INSTAM  : INSTANT DU CALCUL PRECEDENT
!     INSTAP  : INSTANT DU CALCUL
!     NEPS    : NOMBRE DE CMP DE EPSDT ET DEPST (SUIVANT MODELISATION)
!     EPSDT   : DEFORMATIONS TOTALES A L'INSTANT DU CALCUL PRECEDENT
!     DEPST   : INCREMENT DE DEFORMATION TOTALE :
!                DEPST(T) = DEPST(MECANIQUE(T)) + DEPST(DILATATION(T))
!     NSIG    : NOMBRE DE CMP DE SIGD ET SIGF (SUIVANT MODELISATION)
!     SIGD    : CONTRAINTES AU DEBUT DU PAS DE TEMPS
!     VIND    : VARIABLES INTERNES AU DEBUT DU PAS DE TEMPS
!     OPTION  : OPTION DEMANDEE : RIGI_MECA_TANG , FULL_MECA , RAPH_MECA
!     ANGMAS  : LES TROIS ANGLES DU MOT_CLEF MASSIF (AFFE_CARA_ELEM),
!               + UN REEL QUI VAUT 0 SI NAUTIQUIES OU 2 SI EULER
!               + LES 3 ANGLES D'EULER
!     NWKIN   : DIMENSION DE WKIN
!     WKIN    : TABLEAU DE TRAVAIL EN ENTREE(SUIVANT MODELISATION)
!     CP      : LOGIQUE = VRAI EN CONTRAINTES PLANES DEBORST
!     NUMLC   : NUMERO DE LOI DE COMPORTEMENT ISSUE DU CATALOGUE DE LC
!
! OUT SIGF    : CONTRAINTES A LA FIN DU PAS DE TEMPS
! VAR VINF    : VARIABLES INTERNES
!                IN  : ESTIMATION (ITERATION PRECEDENTE OU LAG. AUGM.)
!                OUT : A LA FIN DU PAS DE TEMPS T+
!     NDSDE   : DIMENSION DE DSDE
!     DSDE    : OPERATEUR TANGENT DSIG/DEPS OU DSIG/DF
!     NWKOUT  : DIMENSION DE WKOUT
!     WKOUT   : TABLEAU DE TRAVAIL EN SORTIE (SUIVANT MODELISATION)
!     CODRET  : CODE RETOUR LOI DE COMPORMENT :
!               CODRET=0 : TOUT VA BIEN
!               CODRET=1 : ECHEC DANS L'INTEGRATION DE LA LOI
!               CODRET=3 : SIZZ NON NUL (CONTRAINTES PLANES DEBORST)
!
! PRECISIONS :
! -----------
!  LES TENSEURS ET MATRICES SONT RANGES DANS L'ORDRE :
!         XX YY ZZ SQRT(2)*XY SQRT(2)*XZ SQRT(2)*YZ
!
! -SI DEFORMATION = SIMO_MIEHE
!   EPSDT(3,3)    GRADIENT DE LA TRANSFORMATION EN T-
!   DEPST(3,3)    GRADIENT DE LA TRANSFORMATION DE T- A T+
!
!  OUTPUT SI RESI (RAPH_MECA, FULL_MECA_*)
!   VINF      VARIABLES INTERNES EN T+
!   SIGF(6)  CONTRAINTE DE KIRCHHOFF EN T+ RANGES DANS L'ORDRE
!         XX YY ZZ SQRT(2)*XY SQRT(2)*XZ SQRT(2)*YZ
!
!  OUTPUT SI RIGI (RIGI_MECA_*, FULL_MECA_*)
!   DSDE(6,3,3)   MATRICE TANGENTE D(TAU)/D(FD) * (FD)T
!                 (AVEC LES RACINES DE 2)
!
! -SINON (DEFORMATION = PETIT OU PETIT_REAC OU GDEF_...)
!   EPSDT(6), DEPST(6)  SONT LES DEFORMATIONS TOTALES
!                      (LINEARISEES OU GREEN OU ..)
!
! ----------------------------------------------------------------------
!
    integer :: imate, ndim, ndt, ndi, nvi, kpg, ksp, numlc
    integer :: neps, nsig, nwkin, nwkout, ndsde
    aster_logical, intent(in) :: l_epsi_varc
    real(kind=8) :: carcri(*), angmas(*)
    real(kind=8) :: instam, instap
    real(kind=8) :: wkin(nwkin), wkout(nwkout)
    real(kind=8) :: epsdt(neps), depst(neps)
    real(kind=8) :: sigd(nsig), sigf(nsig)
    real(kind=8) :: vind(*), vinf(*)
    real(kind=8) :: dsde(ndsde)
!
    character(len=16) :: compor(*), option
    character(len=16), intent(in) :: mult_comp
    character(len=8) :: typmod(*)
    character(len=*) :: fami
    aster_logical :: cp
!
!       ----------------------------------------------------------------
!       VARIABLES LOCALES POUR LE REDECOUPAGE DU PAS DE TEMPS
!               TD      INSTANT T
!               TF      INSTANT T+DT
!               TEMD    TEMPERATURE A T
!               TEMF    TEMPERATURE A T+DT
!               EPS     DEFORMATION TOTALE A T
!               DEPS    INCREMENT DE DEFORMATION TOTALE
!               SD      CONTRAINTE A T
!               VD      VARIABLES INTERNES A T    + INDICATEUR ETAT T
!               DSDELO MATRICE DE COMPORTEMENT TANGENT A T+DT OU T
!               NPAL            NOMBRE DE PALIER POUR LE REDECOUPAGE
!               ICOMP           COMPORTEUR POUR LE REDECOUPAGE DU PAS DE
!                                    TEMPS
!               RETURN1 EN CAS DE NON CONVERGENCE LOCALE
!       ----------------------------------------------------------------
!
    integer :: icomp, npal, ipal, codret, k
    real(kind=8) :: eps(neps), deps(neps), sd(nsig)
    real(kind=8) :: dsdelo(ndsde)
    real(kind=8) :: deltat, td, tf
!       ----------------------------------------------------------------
    common /tdim/   ndt  , ndi
!       ----------------------------------------------------------------
!       ----------------------------------------------------------------
!       -- POUR LES VARIABLES DE COMMANDE :
    ca_iredec_=1
    ca_timed1_=instam
    ca_timef1_=instap
    ca_td1_=instam
    ca_tf1_=instap
!
!
    ipal   = nint(carcri(5))
    codret = 0
!
! - No step cutting (elastic matrix or KIT_DDI behaviour)
!
    if (option(1:9) .eq. 'RIGI_MECA' .or. numlc .ge. 8000)  then
        ipal=0
    endif
!
! - Get number of internal variables
!
    read (compor(2),'(I16)') nvi
!
! IPAL = 0  1 OU -1 -> PAS DE REDECOUPAGE DU PAS DE TEMPS
!
    if (ipal .eq. 0 .or. ipal .eq. 1 .or. ipal .eq. -1) then
        ipal = 0
        npal = 0
        icomp = 2
!
! IPAL < -1 -> REDECOUPAGE DU PAS DE TEMPS EN CAS DE NON CONVERGENCE
!
    else if (ipal .lt. -1) then
        npal = -ipal
        icomp = 0
!
! IPAL > 1 -> REDECOUPAGE IMPOSE DU PAS DE TEMPS
!
    else if (ipal .gt. 1) then
        npal = ipal
        icomp = -1
    endif
!
    call lc0000(fami, kpg, ksp, ndim, typmod, l_epsi_varc,&
                imate, compor, mult_comp, carcri, instam, instap,&
                neps, epsdt, depst, nsig, sigd,&
                vind, option, angmas, nwkin, wkin,&
                cp, numlc, &
                sigf, vinf, ndsde, dsde, icomp,&
                nvi, nwkout, wkout, codret)
!
    if (codret .eq. 1) then
        goto 1
    else if (codret .eq. 2) then
        goto 2
    endif
!
! -->   IPAL > 0 --> REDECOUPAGE IMPOSE DU PAS DE TEMPS
! -->   REDECOUPAGE IMPOSE ==>  RETURN DANS PLASTI APRES RECHERCHE
!       DES CARACTERISTIQUES DU MATERIAU A (T) ET (T+DT)
    if (ipal .le. 0) goto 999
    if (icomp .eq. -1) icomp = 0
!
! --    CAS DE NON CONVERGENCE LOCALE / REDECOUPAGE DU PAS DE TEMPS
!
  1 continue
!
    if (npal .eq. 0) then
        goto 2
    else
        if (typmod(2).eq.'GRADVARI') then
            call utmess('A', 'COMPOR2_10', sk=typmod(2))
        endif
    endif
!
    if (icomp .gt. 3) then
        call utmess('A', 'ALGORITH10_35')
        goto 2
    endif
!
    if (icomp .ge. 1) npal = 2 * npal
    icomp = icomp + 1
!
    do k = 1, npal
! --       INITIALISATION DES VARIABLES POUR LE REDECOUPAGE DU PAS
        if (k .eq. 1) then
            td = instam
            ca_td1_ = td
            deltat = (instap - instam) / npal
            tf = td + deltat
            ca_tf1_=tf
            if (option(1:9) .eq. 'RIGI_MECA' .or. option(1:9) .eq. 'FULL_MECA') then
                call r8inir(ndsde, 0.d0, dsde, 1)
            endif
            call lceqve(epsdt, eps)
            call lceqve(depst, deps)
            call lcprsv(1.d0/npal, deps, deps)
            call lceqvn(ndt, sigd, sd)
!
! --        REACTUALISATION DES VARIABLES POUR L INCREMENT SUIVANT
        else if (k .gt. 1) then
            td = tf
            ca_td1_=td
            tf = tf + deltat
            ca_tf1_=tf
            call lcsove(eps, deps, eps)
            call lceqvn(ndt, sigf, sd)
            call lceqvn(nvi, vinf, vind)
        endif
!
!
        call lc0000(fami, kpg, ksp, ndim, typmod, l_epsi_varc,&
                    imate, compor, mult_comp, carcri, td, tf,&
                    neps, eps, deps, nsig, sd,&
                    vind, option, angmas, nwkin, wkin,&
                    cp, numlc, &
                    sigf, vinf, ndsde, dsdelo, icomp,&
                    nvi, nwkout, wkout, codret)
!
        if (codret .eq. 1) then
            goto 1
        else if (codret .eq. 2) then
            goto 2
        endif
!
        if (option(1:9) .eq. 'RIGI_MECA' .or. option(1:9) .eq. 'FULL_MECA') then
            call lcprsm(1.d0/npal, dsdelo, dsdelo)
            call lcsoma(dsde, dsdelo, dsde)
        endif
!
    end do
    goto 999
!
  2 continue
    goto 999
!
999 continue
end subroutine
