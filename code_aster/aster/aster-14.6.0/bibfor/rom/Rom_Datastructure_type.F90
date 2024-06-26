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
! person_in_charge: mickael.abbas at edf.fr
!
module Rom_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
!
! --------------------------------------------------------------------------------------------------
!
! Model reduction
!
! Define types for datastructures
!
! --------------------------------------------------------------------------------------------------
!
! - Datastructure to select snapshots
!
    type ROM_DS_Snap
! ----- Results datastructure where snapshots are selected
        character(len=8)  :: result    = ' '
! ----- Number of snapshots
        integer           :: nb_snap   = 0
! ----- Name of JEVEUX object for list of snapshots
        character(len=24) :: list_snap = ' '
    end type ROM_DS_Snap
!
! - Parameters for lineic base numbering
!
    type ROM_DS_LineicNumb
! ----- Number of slices
        integer           :: nb_slice = 0
! ----- For each node => which slice ?
        integer, pointer  :: v_nume_pl(:) => null()
! ----- For each node => which IN slice ?
        integer, pointer  :: v_nume_sf(:) => null()
! ----- Tolerance for separating nodes
        real(kind=8)      :: tole_node = 1.d-7
! ----- Number of components by node
        integer           :: nb_cmp = 0
    end type ROM_DS_LineicNumb
!
! - Parameters for field
!
    type ROM_DS_Field
! ----- Name of field for read (NOM_CHAM)
        character(len=24)       :: field_name = ' '
! ----- A field for reference (to manipulate)
        character(len=24)       :: field_refe = ' '
! ----- Model
        character(len=8)        :: model = ' '
! ----- Mesh
        character(len=8)        :: mesh  = ' '
! ----- Components in the field
        integer, pointer          :: v_equa_type(:) => null()
        character(len=8), pointer :: v_list_cmp(:) => null()
        integer                   :: nb_cmp = 0
! ----- Flag if has Lagrange multipliers
        aster_logical           :: l_lagr = ASTER_FALSE
! ----- Number of nodes with dof
        integer                 :: nb_node = 0
! ----- Number of equations
        integer                 :: nb_equa = 0
    end type ROM_DS_Field
!
! - Datastructure for empiric base
    type ROM_DS_Empi
! ----- Name of empiric base to save
        character(len=8)        :: base = ' '
! ----- Name of table to save reduced coordinates
        character(len=19)       :: tabl_coor = ' '
! ----- Datastructure for mode
        type(ROM_DS_Field)      :: ds_mode
! ----- Type of reduced base
        character(len=8)        :: base_type = ' '
! ----- Direction of the linear model
        character(len=8)        :: axe_line = ' '
! ----- First section of the linear model
        character(len=24)       :: surf_num = ' '
! ----- Number of modes in base
        integer                 :: nb_mode = 0
! ----- Number of modes max 
        integer                 :: nb_mode_maxi = 0
! ----- Number of snapshots when created base
        integer                 :: nb_snap = 0
! ----- Datastructure for lineic base numbering
        type(ROM_DS_LineicNumb) :: ds_lineic
    end type ROM_DS_Empi
!
! - Parameters for REST_REDUIT_COMPLET operator
!
    type ROM_DS_ParaRRC
! ----- Phenomenon
        character(len=16) :: type_resu = ' '
! ----- Number of time steps
        integer           :: nb_store = 0
! ----- Reduced results datastructure to read
        character(len=8)  :: result_rom = ' '
! ----- Model for reduced model
        character(len=8)  :: model_rom = ' '
! ----- Complete results datastructure to create
        character(len=8)  :: result_dom = ' '
! ----- Model for complete model
        character(len=8)  :: model_dom = ' '
! ----- Datastructure for empiric modes (primal)
        type(ROM_DS_Empi) :: ds_empi_prim
! ----- Datastructure for empiric modes (dual)
        type(ROM_DS_Empi) :: ds_empi_dual
! ----- Table for reduced coordinates
        character(len=24) :: tabl_name = ' '
        character(len=24) :: coor_redu = '&&OP0054.COOR'
! ----- Flag for dual prevision
        aster_logical     :: l_prev_dual = ASTER_FALSE
! ----- Name of GROUP_NO of interface
        character(len=24) :: grnode_int = ' '
! ----- Access to equation in RID (dual) and out of interface
        integer           :: nb_equa_ridi = 0
        integer, pointer  :: v_equa_ridi(:) => null()
! ----- Access to equation in RID (dual)
        integer           :: nb_equa_ridd = 0
        integer, pointer  :: v_equa_ridd(:) => null()
! ----- Access to equation in RID (primal)
        integer           :: nb_equa_ridp = 0
        integer, pointer  :: v_equa_ridp(:) => null()
! ----- Flag for EF corrector?
        aster_logical     :: l_corr_ef = ASTER_FALSE
    end type ROM_DS_ParaRRC
!
! - Parameters for definition of multiparametric reduced problem - Evaluation
!
    type ROM_DS_EvalCoef
        integer                     :: nb_para = 0
        real(kind=8)                :: para_vale(5) = 0.d0
        character(len=16)           :: para_name(5) = ' '
    end type ROM_DS_EvalCoef
!
! - Parameters for definition of multiparametric reduced problem - Variations
!
    type ROM_DS_VariPara
        integer                     :: nb_vale_para = 0
        real(kind=8), pointer       :: para_vale(:) => null()
        character(len=16)           :: para_name = ' '
        real(kind=8)                :: para_init = 0.d0
    end type ROM_DS_VariPara
!
! - Parameters for definition of multiparametric reduced problem - Coefficients
!
    type ROM_DS_MultiCoef
! ----- Coefficient is function
        aster_logical               :: l_func = ASTER_FALSE
! ----- Coefficient is constant
        aster_logical               :: l_cste = ASTER_FALSE
! ----- Coefficient is complex
        aster_logical               :: l_cplx = ASTER_FALSE
! ----- Coefficient is real
        aster_logical               :: l_real = ASTER_FALSE
! ----- Value of coefficient if is complex and constant
        complex(kind=8)             :: coef_cste_cplx = dcmplx(0.d0, 0.d0)
! ----- Value of coefficient if is real and constant
        real(kind=8)                :: coef_cste_real = 0.d0
! ----- Value of coefficient if is function
        character(len=8)            :: func_name = ' '
! ----- Value of coefficient if is complex: need evaluation
        complex(kind=8), pointer    :: coef_cplx(:) => null()
! ----- Value of coefficient if is real: need evaluation
        real(kind=8), pointer       :: coef_real(:) => null()
    end type ROM_DS_MultiCoef
!
! - Parameters for definition of multiparametric reduced problem
!
    type ROM_DS_MultiPara
! ----- Type of system to solve
        character(len=1)                 :: syst_type = ' '
! ----- List of matrices for system
        integer                          :: nb_matr = 0
        character(len=8), pointer        :: matr_name(:) => null()
        character(len=8), pointer        :: matr_type(:) => null()
        type(ROM_DS_MultiCoef), pointer  :: matr_coef(:) => null()
! ----- List of vectors for system
        integer                          :: nb_vect = 0
        character(len=8), pointer        :: vect_name(:) => null()
        character(len=8), pointer        :: vect_type(:) => null()
        type(ROM_DS_MultiCoef), pointer  :: vect_coef(:) => null()
! ----- Products matrix by current mode
        character(len=24), pointer       :: matr_mode_curr(:) => null()
! ----- Products matrix by mode
        character(len=24), pointer       :: prod_matr_mode(:) => null()
! ----- Reduced Vector
        character(len=24), pointer       :: vect_redu(:) => null()
! ----- Reduced matrix
        character(len=24), pointer       :: matr_redu(:) => null()
! ----- Variation of coefficients: number (by mode)
        integer                          :: nb_vari_coef = 0
! ----- Variation of coefficients: type (DIRECT, ALEATOIRE, etc. )
        character(len=24)                :: type_vari_coef = ' '
! ----- Variation of coefficients: by parameter
        integer                          :: nb_vari_para = 0
        type(ROM_DS_VariPara), pointer   :: vari_para(:) => null()
! ----- Evaluation of coefficients
        type(ROM_DS_EvalCoef)            :: evalcoef
! ----- Reference field
        type(ROM_DS_Field)               :: field
    end type ROM_DS_MultiPara
!
! - Parameters to solve systems
!
    type ROM_DS_Solve
        character(len=1)         :: syst_type      = ' '
        character(len=1)         :: syst_matr_type = ' '
        character(len=1)         :: syst_2mbr_type = ' '
        character(len=19)        :: syst_matr      = ' '
        character(len=19)        :: syst_2mbr      = ' '
        character(len=19)        :: syst_solu      = ' '
        character(len=19)        :: vect_zero      = ' '
        integer                  :: syst_size      = 0
    end type ROM_DS_Solve
!
! - Parameters for DEFI_BASE_REDUITE operator - About (non-linear) results datastructure
!
    type ROM_DS_Result
! ----- Name of datastructure
        character(len=8)        :: name  = ' '
! ----- Model
        character(len=8)        :: model = ' '
! ----- Mesh
        character(len=8)        :: mesh  = ' '
! ----- Field saved in
        type(ROM_DS_Field)      :: field
    end type ROM_DS_Result
!
! - Parameters for DEFI_BASE_REDUITE operator (POD)
!
    type ROM_DS_ParaDBR_POD
! ----- Datastructure for result datastructures to read
        type(ROM_DS_Result)     :: ds_result_in
! ----- Name of field for read (NOM_CHAM)
        character(len=24)       :: field_name = ' '
! ----- Model from user
        character(len=8)        :: model_user = ' '
! ----- Type of reduced base
        character(len=8)        :: base_type = ' '
! ----- Direction of the linear model
        character(len=8)        :: axe_line = ' '
! ----- First section of the linear model
        character(len=24)       :: surf_num = ' '
! ----- Tolerance for SVD
        real(kind=8)            :: tole_svd = 0.d0
! ----- Tolerance for incremental POD
        real(kind=8)            :: tole_incr = 0.d0
! ----- Flag if table is given by user
        aster_logical           :: l_tabl_user = ASTER_FALSE
        character(len=19)       :: tabl_user = ' '
! ----- Maximum number of modes
        integer                 :: nb_mode_maxi = 0
! ----- Datastructure for snapshot selection
        type(ROM_DS_Snap)       :: ds_snap

    end type ROM_DS_ParaDBR_POD
!
! - Algorithm Greedy
!
    type ROM_DS_AlgoGreedy
! ----- List of reduced components
        character(len=24)       :: coef_redu = ' '
! ----- For residual
        character(len=1)        :: resi_type = ' '
        character(len=24)       :: resi_vect = ' '
        real(kind=8), pointer   :: resi_norm(:) => null()
        real(kind=8)            :: resi_refe = 0.d0
! ----- To solve complete system
        type(ROM_DS_Solve)      :: solveROM
! ----- To solve reduced system
        type(ROM_DS_Solve)      :: solveDOM
! ----- Index of components FSI transient problem
        integer                 :: nume_pres = 0
        integer                 :: nume_phi  = 0
    end type ROM_DS_AlgoGreedy
!
! - Parameters for DEFI_BASE_REDUITE operator (RB)
!
    type ROM_DS_ParaDBR_RB
! ----- Datastructure for solver's parameters
        character(len=19)       :: solver       = ' '
! ----- Datastructure for multiparametric problem
        type(ROM_DS_MultiPara)  :: multipara
! ----- Maximum number of modes
        integer                 :: nb_mode_maxi = 0
! ----- Flag to orthogonalize the basis 
        aster_logical           :: l_ortho_base = ASTER_FALSE
! ----- Flag to stabilize the basis for FSI transient problem
        aster_logical           :: l_stab_fsi   = ASTER_FALSE
! ----- Tolerance for greedy algorithm
        real(kind=8)            :: tole_greedy  = 0.d0
! ----- Datastructure for greedy algorithm
        type(ROM_DS_AlgoGreedy) :: algoGreedy
    end type ROM_DS_ParaDBR_RB
!
! - Parameters for DEFI_BASE_REDUITE operator (TRUNCATION)
!
    type ROM_DS_ParaDBR_TR
! ----- Base to truncate
        character(len=8)        :: base_init = ' '
! ----- Datastructure for empiric modes
        type(ROM_DS_Empi)       :: ds_empi_init
! ----- Model for truncation
        character(len=8)        :: model_rom = ' '
! ----- List of equations into RID
        integer, pointer        :: v_equa_rom(:) => null()
! ----- Profile of nodal field
        character(len=24)       :: prof_chno_rom = ' '
! ----- Number of equation for RID
        integer                 :: nb_equa_rom = 0
! ----- Index of GRANDEUR
        integer                 :: idx_gd = 0
    end type ROM_DS_ParaDBR_TR
!
! - Parameters for DEFI_BASE_REDUITE operator
!
    type ROM_DS_ParaDBR
! ----- Type of operation (POD, POD_INCR, GREEDY, ...)
        character(len=16)        :: operation = ' '
! ----- Name of empiric base to save
        character(len=8)         :: result_out = ' '
! ----- Identificator for field in result datastructure
        character(len=24)        :: field_iden = ' '
! ----- Parameters for POD/POD_INCR method
        type(ROM_DS_ParaDBR_POD) :: para_pod
! ----- Parameters for RB method
        type(ROM_DS_ParaDBR_RB ) :: para_rb
! ----- Parameters for truncation method
        type(ROM_DS_ParaDBR_TR ) :: para_tr
! ----- Datastructure for empiric modes
        type(ROM_DS_Empi)        :: ds_empi
! ----- If operator is "reuse"
        aster_logical            :: l_reuse = ASTER_FALSE
    end type ROM_DS_ParaDBR
!
! - Parameters for DEFI_DOMAINE_REDUIT operator
!
    type ROM_DS_ParaDDR
! ----- Mesh
        character(len=8)  :: mesh = ' '
! ----- Datastructure for empiric modes (primal)
        type(ROM_DS_Empi) :: ds_empi_prim
! ----- Datastructure for empiric modes (dual)
        type(ROM_DS_Empi) :: ds_empi_dual
! ----- Name of group of elements for RID
        character(len=24) :: grelem_rid = ' '
! ----- Number of layers in the construction of RID
        integer           :: nb_layer_rid = 0
! ----- The RID in a restricted domain?
        aster_logical     :: l_rid_maxi = ASTER_FALSE
! ----- List of elements restricted
        integer, pointer  :: v_rid_maxi(:) => null()
! ----- Number of elements restricted
        integer           :: nb_rid_maxi = 0
! ----- Name of group of nodes for interface
        character(len=24) :: grnode_int = ' '
! ----- Flag for EF corrector?
        aster_logical     :: l_corr_ef = ASTER_FALSE
! ----- Name of group of nodes for outside area of EF corrector
        character(len=24) :: grnode_sub = ' '
! ----- Number of layer in the construction of outside area
        integer           :: nb_layer_sub = 0
        integer           :: nb_rid_mini = 0
! ----- List of nodes for minimal rid
        integer, pointer  :: v_rid_mini(:) => null()
    end type ROM_DS_ParaDDR
!
! - Parameters for non_linear operator
!
    type ROM_DS_AlgoPara
! ----- Empiric modes
        type(ROM_DS_Empi) :: ds_empi
! ----- Pointer to list of equations for interface nodes
        integer, pointer  :: v_equa_int(:) => null()
! ----- Pointer to list of equation for internal interface nodes
        integer, pointer  :: v_equa_sub(:) => null()
! ----- Flag for reduced model
        aster_logical     :: l_rom = ASTER_FALSE
! ----- Flag for hyper-reduced model
        aster_logical     :: l_hrom = ASTER_FALSE
! ----- Flag for hyper-reduced model with EF correction
        aster_logical     :: l_hrom_corref = ASTER_FALSE
! ----- Phase of computation when EF correction
        character(len=24) :: phase = ' '
! ----- Name of GROUP_NO of interface
        character(len=24) :: grnode_int = ' '
! ----- Name of GROUP_NO of internal interface
        character(len=24) :: grnode_sub = ' '
! ----- Table for reduced coordinates
        character(len=24) :: tabl_name = ' '
! ----- Object to save reduced coordinates
        character(len=24) :: gamma = ' '
! ----- Identificator for field
        character(len=24) :: field_iden = ' '
! ----- Penalisation parameter for EF correction
        real(kind=8)      :: vale_pena = 0.d0
    end type ROM_DS_AlgoPara
!
end module
