! --------------------------------------------------------------------
! Copyright (C) 1991 - 2018 - EDF R&D - www.code-aster.org
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

!> This module manages the global values stored during the execution.
!
module superv_module
!
! person_in_charge: mathieu.courtois@edf.fr

! dummy argument because of ifdef
! aslint: disable=W0104

    use calcul_module, only: calcul_init
    implicit none
    private

#include "asterf_types.h"
#include "threading_interfaces.h"
#include "asterc/gtopti.h"
#include "asterc/asmpi_comm.h"
#include "asterfort/assert.h"
#include "asterfort/check_aster_allocate.h"
#include "asterfort/detmat.h"
#include "asterfort/foint0.h"
#include "asterfort/jedetv.h"
#include "asterfort/jelibz.h"
#include "asterfort/jerecu.h"
#include "asterfort/jereou.h"
#include "asterfort/jermxd.h"
#include "asterfort/utgtme.h"
#include "asterfort/utmess.h"
#include "asterfort/utptme.h"

    logical :: first = .true.
    integer :: initMaxThreads = 0

    public :: superv_before, superv_after
    public :: asthread_getmax, asthread_setnum, asthread_blasset, asthread_getnum

contains

!>  Initialize the values or reinitialize them between before executing an operator
!
!>  @todo Remove treatments from execop.
    subroutine superv_before()
        mpi_int :: world, current
        integer :: maxThreads, iret
        real(kind=8) :: rval(6), v0
        character(len=8) :: k8tab(6)

!   Check MPI communicators: must be equal between operators
        call asmpi_comm('GET_WORLD', world)
        call asmpi_comm('GET', current)
        ASSERT( world == current )
!   OpenMP variables
        if ( first ) then
            first = .false.
            call gtopti('numthreads', maxThreads, iret)
            initMaxThreads = maxThreads
        endif
        call asthread_setnum( initMaxThreads, blas_max=1 )
!   Memory allocation
!       Adjust Jeveux parameters
        k8tab(1) = 'LIMIT_JV'
        k8tab(2) = 'MEM_TOTA'
        k8tab(3) = 'VMSIZE'
        k8tab(4) = 'CMAX_JV'
        k8tab(5) = 'RLQ_MEM'
        k8tab(6) = 'COUR_JV'
        call utgtme(6, k8tab, rval, iret)
        if ( rval(3) .gt. 0 .and. rval(3) - rval(6) .lt. rval(5) ) then
!           the remaining memory decreased: adjust it
            call utptme('RLQ_MEM ', rval(3) - rval(6), iret)
        endif
        if (rval(2) - rval(5) .ge. 0) then
            v0 = rval(1)
            if ((rval(2) - rval(5)) .gt. v0) then
!               reduce memory limit
                call jermxd((rval(2) - rval(5)) * 1024 * 1024, iret)
                if (iret .eq. 0) then
                    k8tab(1) = 'RLQ_MEM'
                    k8tab(2) = 'LIMIT_JV'
                    call utgtme(2, k8tab, rval, iret)
                    if (abs(rval(2) - v0) .gt. v0 * 0.1d0) then
                       call utmess('I', 'JEVEUX1_73', nr=2, valr=rval)
                    endif
                endif
            endif
        endif
!       Reinit calcul mark in case of exception
        call calcul_init()
!       Reinitialize counter for as_[de]allocate
        call check_aster_allocate(init=0)
!       Reset commons used for function interpolation
        call foint0()
    end subroutine superv_before


!>  Initialize the values or reinitialize them between before executing an operator
!
!>  This subroutine is called after the execution of each operator to clean
!>  the memory of temporary objects (volatile), matrix...
!
!>  @param[in] exception tell if an exception/error will be raised
    subroutine superv_after(exception)
        logical, optional :: exception
        logical :: exc
        exc = .false.
        if ( present(exception) ) then
            exc = exception
        endif
!   Memory allocation
!       Check for not deallocated vectors
!       Do not add another error message if an error has been raised
        if (.not. exc) then
            call check_aster_allocate()
        endif
!       Delete matrix and their mumps/petsc associated instances
        call detmat()
!       Free objects kept in memory using jeveut
        call jelibz('G')
!       Delete objects on the volatile database
        call jedetv()
        call jereou('V', 0.01d0)
        call jerecu('G')
    end subroutine superv_after

!>  Return the current maximum number of available threads
!
!>  @return current number of threads
    function asthread_getmax()
        implicit none
        integer :: asthread_getmax
#ifdef _USE_OPENMP
        asthread_getmax = omp_get_max_threads()
#else
        asthread_getmax = 1
#endif
    end function asthread_getmax


!>  Set the maximum number of threads for OpenMP and Blas
!
!>  @param[in] nbThreads new maximum number of threads
    subroutine asthread_setnum( nbThreads, blas_max )
        implicit none
        integer, intent(in) :: nbThreads
        integer, intent(in), optional :: blas_max
#ifdef _USE_OPENMP
        call omp_set_num_threads( nbThreads )
#endif
        if (present(blas_max)) then
            if (blas_max .eq. 1) then
                call asthread_blasset( initMaxThreads )
            endif
        endif
    end subroutine asthread_setnum


!>  Set the maximum number of threads for Blas functions
!
!>  @param[in] nbThreads new maximum number of threads for Blas
    subroutine asthread_blasset( nbThreads )
        implicit none
        integer, intent(in) :: nbThreads
#ifdef _USE_OPENMP
# ifdef _USE_OPENBLAS
        call openblas_set_num_threads( nbThreads )
# endif
# ifdef _USE_MKL
        call mkl_set_num_threads( nbThreads )
# endif
#endif
    end subroutine asthread_blasset


!>  Return the current thread id
!
!>  @return the current thread id
    function asthread_getnum()
        implicit none
        integer :: asthread_getnum
#ifdef _USE_OPENMP
        asthread_getnum = omp_get_thread_num()
#else
        asthread_getnum = 0
#endif
    end function asthread_getnum

end module superv_module
