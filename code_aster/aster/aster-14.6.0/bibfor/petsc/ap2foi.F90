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

subroutine ap2foi(kptsc, mpicou, nosolv, lmd, indic,&
   its)
#include "asterf_types.h"
#include "asterf_petsc.h"
! person_in_charge: natacha.bereux at edf.fr
use aster_petsc_module
use petsc_data_module
use lmp_module, only : lmp_destroy

implicit none
#include "jeveux.h"
#include "asterf_petsc.h"
#include "asterc/asmpi_comm.h"
#include "asterfort/apksp.h"
#include "asterfort/appcpr.h"
#include "asterfort/appcrs.h"
#include "asterfort/assert.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jedema.h"
#include "asterfort/utmess.h"
#include "asterfort/uttcpu.h"

!
!--------------------------------------------------------------
! But :
!  * recalculer un nouveau pre-conditionneur pour LDLT_SP
!  * faire une resolution avec ce nouveau preconditionneur
!---------------------------------------------------------------
!
#ifdef _HAVE_PETSC
  !
  integer :: kptsc
  mpi_int :: mpicou
  character(len=19) :: nosolv
  aster_logical :: lmd, lmp_is_active
  KSPConvergedReason :: indic
  PetscInt :: its
  !----------------------------------------------------------------
  !
  !     VARIABLES LOCALES
  integer, dimension(:), pointer :: slvi => null()
  character(len=24), dimension(:), pointer :: slvk => null()
  PetscErrorCode ::  ierr
  KSP :: ksp
  PC :: pc_lmp
  !----------------------------------------------------------------

!
!   -- bascule pour la mesure du temps CPU : RESOUD -> PRERES :
    call uttcpu('CPU.RESO.5', 'FIN', ' ')
    call uttcpu('CPU.RESO.4', 'DEBUT', ' ')
!
!
!   -- avant de refabriquer une matrice de preconditionnement,
!      il faut reinitialiser quelques variables :
!   -----------------------------------------------------------
    spmat=' '
    spsolv=' '
    call KSPDestroy(kp(kptsc), ierr)
    call KSPCreate(mpicou, kp(kptsc), ierr)
    ksp=kp(kptsc)
    ASSERT(ierr.eq.0)
    call KSPSetOperators(kp(kptsc), ap(kptsc), ap(kptsc), ierr)
    ASSERT(ierr.eq.0)
  !
  !   slvi(5) = nombre d'itérations pour atteindre la convergence du solveur linéaire.
  !   si :
  !   - slvi(5) = 0 (on résout pour la première fois),
  !   - slvi(5) > reac_precond (la résolution linéaire précédente a demandé
  !                            "trop" d'itérations),
  !   alors il faut effectuer le calcul du préconditionneur LDLT_SP (voir pcmump)
  !
  call jeveuo(nosolv//'.SLVI', 'E', vi=slvi)
  slvi(5) = 0
  ! Attention ! s'il y avait un LMP actif, on le détruit
  call jeveuo(nosolv//'.SLVK', 'L', vk24=slvk)
  lmp_is_active = slvk(6)=='GMRES_LMP'
  if ( lmp_is_active ) then
     call lmp_destroy( pc_lmp, ierr )
     ASSERT( ierr == 0 )
     call KSPSetComputeRitz(kp(kptsc), petsc_true, ierr)
     ASSERT( ierr == 0 )
  endif
  !
  !
  !   -- calcul du nouveau preconditionneur :
  !   ---------------------------------------
  call appcpr(kptsc)
  !
  !   -- 2eme resolution :
  !   ---------------------
  call VecDestroy(xlocal, ierr)
  ASSERT( ierr == 0 )
#if PETSC_VERSION_LT(3,8,0) 
  xlocal = PETSC_NULL_OBJECT
#else
  xlocal = PETSC_NULL_VEC
#endif
  call VecDestroy(xglobal, ierr)
  ASSERT( ierr == 0 )
#if PETSC_VERSION_LT(3,8,0) 
  xglobal = PETSC_NULL_OBJECT
#else
  xglobal = PETSC_NULL_VEC
#endif
  call VecScatterDestroy(xscatt, ierr)
  ASSERT( ierr == 0 )
#if PETSC_VERSION_LT(3,8,0) 
  xscatt = PETSC_NULL_OBJECT
#else
  xscatt = PETSC_NULL_VECSCATTER
#endif
  call apksp(kptsc)
  call appcrs(kptsc, lmd)
  call KSPSolve(ksp, b, x, ierr)
  ASSERT(ierr.eq.0)
  call KSPGetConvergedReason(ksp, indic, ierr)
  ASSERT(ierr.eq.0)
  call KSPGetIterationNumber(ksp, its, ierr)
  ASSERT(ierr.eq.0)
  !
  !
  !   -- bascule pour la mesure du temps CPU : PRERES -> RESOUD :
  call uttcpu('CPU.RESO.4', 'FIN', ' ')
  call uttcpu('CPU.RESO.5', 'DEBUT', ' ')

  !
#else
  integer :: kptsc
  integer :: mpicou
  character(len=19) :: nosolv
  aster_logical :: lmd
  integer :: indic
  integer :: its

  !
  character(len=1) :: kdummy
  integer :: idummy
  kdummy = nosolv(1:1)
  idummy = kptsc
  idummy = mpicou
  idummy = indic
  if (lmd) idummy = its
#endif
  !
end subroutine ap2foi
