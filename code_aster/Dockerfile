FROM aster_zs_base:latest
LABEL maintainer "Tianyi Li <tianyikillua@gmail.com>"

# Variables
ENV HDF5_VER=1.10.3
ENV MED_VER=4.0.0
ENV METIS_VER=5.1.0
ENV PARMETIS_VER=4.0.3
ENV SCOTCH_VER=6.0.4
ENV MUMPS_VER=5.1.2
ENV MFRONT_VER=3.2.1
ENV PETSC_VER=3.19.6
ENV SCALAPACK_VER=2.0.2
ENV ASTER_VER=14.6

ENV SCOTCH_SRC="scotch-${SCOTCH_VER}-aster7.tar.gz"
ENV MUMPS_SRC="mumps-${MUMPS_VER}-aster7.tar.gz"
ENV ASTER_SRC="aster-${ASTER_VER}.0.tgz"
ENV ASTER_FULL_SRC=aster-full-src-14.6.0-1.noarch.tar.gz

ENV ASTER_ROOT=/home/aster/aster
ENV PUBLIC=$ASTER_ROOT/public

USER aster
WORKDIR /tmp

# Extract and install
COPY --chown=aster:aster aster/${ASTER_FULL_SRC} /tmp
RUN mkdir aster_full && tar xf ${ASTER_FULL_SRC} -C aster_full --strip-components 1
RUN cd aster_full  && \
    python3 setup.py install --prefix ${ASTER_ROOT} --noprompt && \
    mv SRC/${SCOTCH_SRC} SRC/${MUMPS_SRC} SRC/${ASTER_SRC} /tmp && \
    rm -rf /tmp/aster_full.tar.gz /tmp/aster_full && \
    cd ${PUBLIC}/tfel-${MFRONT_VER}/bin && \
    ln -s mfront-3.2.1 mfront

# Build ptscotch
RUN mkdir ptscotch && tar xf ${SCOTCH_SRC} -C ptscotch --strip-components 1 && \
    cd ptscotch/src && \
    make scotch esmumps ptscotch ptesmumps CCD=mpicc && \
    mkdir ${PUBLIC}/ptscotch-${SCOTCH_VER} && \
    make install prefix=${PUBLIC}/ptscotch-${SCOTCH_VER} && \
    rm -rf /tmp/${SCOTCH_SRC} /tmp/ptscotch

# Build parmetis
# Patch from https://bitbucket.org/code_aster/parmetis/src/parmetis_aster/
COPY --chown=aster:aster data/parmetis.patch /tmp/parmetis.patch
COPY --chown=aster:aster aster/parmetis-${PARMETIS_VER}.tar.gz /tmp/parmetis.tar.gz
RUN  mkdir parmetis && tar xf parmetis.tar.gz -C parmetis --strip-components 1 && \
    patch -s -p0 < parmetis.patch && \
    cd parmetis && \
    make config prefix=${PUBLIC}/parmetis-${PARMETIS_VER} && \
    make && \
    make install && \
    rm -rf /tmp/parmetis.tar.gz /tmp/parmetis.patch /tmp/parmetis

# Build scalapack
COPY --chown=aster:aster aster/scalapack-${SCALAPACK_VER}.tgz /tmp/scalapack.tgz
RUN mkdir scalapack && tar xf scalapack.tgz -C scalapack --strip-components 1 && \
    cd scalapack && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=${PUBLIC}/scalapack-${SCALAPACK_VER} -DBUILD_SHARED_LIBS=ON .. && \
    make && \
    make install && \
    cd ${PUBLIC}/scalapack-${SCALAPACK_VER}/lib && \
    cp libscalapack.so libblacs.so && \
    rm -rf /tmp/scalapack.tgz /tmp/scalapack

# Build parallel mumps
RUN mkdir mumps && tar xf ${MUMPS_SRC} -C mumps --strip-components 1 && \
    cd mumps && \
    export INCLUDES="${PUBLIC}/metis-${METIS_VER}/include \
    ${PUBLIC}/parmetis-${PARMETIS_VER}/include \
    ${PUBLIC}/ptscotch-${SCOTCH_VER}/include" && \
    export LIBPATH="${PUBLIC}/metis-${METIS_VER}/lib \
    ${PUBLIC}/parmetis-${PARMETIS_VER}/lib \
    ${PUBLIC}/ptscotch-${SCOTCH_VER}/lib \
    ${PUBLIC}/scalapack-${SCALAPACK_VER}/lib" && \
    python3 waf configure --prefix=${PUBLIC}/mumps-${MUMPS_VER}_mpi --install-tests --enable-mpi && \
    python3 waf build --jobs=1 && \
    python3 waf install --jobs=1 && \
    rm -rf /tmp/${MUMPS_SRC} /tmp/mumps

# Build parallel PETSc (optional - currently not workink)
# Patch from https://hitoricae.com/2019/11/10/code_aster-14-4-with-petsc/
#COPY --chown=aster:aster data/petsc.patch /tmp/petsc.patch
#RUN wget --no-check-certificate --quiet ${PETSC_SRC} -O petsc.tar.gz && \
# use local sources instead of downloading
#COPY --chown=aster:aster aster/petsc-${PETSC_VER}.tar.gz  /tmp/petsc.tar.gz
# RUN mkdir petsc && tar xf petsc.tar.gz -C petsc --strip-components 1 && \
#     patch -s -p0 < petsc.patch && \
#     cd petsc && \
#     ./configure --COPTFLAGS="-O2" \
#     --CXXOPTFLAGS="-O2" \
#     --FOPTFLAGS="-O2" \
#     --with-debugging=0 \
#     --with-shared-libraries=1 \
#     --with-scalapack-dir=${PUBLIC}/scalapack-${SCALAPACK_VER} \
#     --with-mumps-dir=${PUBLIC}/mumps-${MUMPS_VER}_mpi \
#     --with-metis-dir=${PUBLIC}/metis-${METIS_VER} \
#     --with-parmetis-dir=${PUBLIC}/parmetis-${PARMETIS_VER} \
#     --with-ptscotch-dir=${PUBLIC}/ptscotch-${SCOTCH_VER} \
#     --download-hypre \
#     --download-ml \
#     --LIBS="-lgomp" \
#     --prefix=${PUBLIC}/petsc-${PETSC_VER} && \
#     make all && \
#     make install && \
#     rm -rf /tmp/petsc.tar.gz /tmp/petsc

# Build parallel aster
COPY --chown=aster:aster data/cfg.py /tmp/cfg.py
# This line copies the path file into the temp folder that is created
COPY --chown=aster:aster data/aster_zs.patch /tmp/aster_zs.patch
RUN . ${ASTER_ROOT}/${ASTER_VER}/share/aster/profile_mfront.sh && \
    . ${ASTER_ROOT}/etc/codeaster/profile.sh && \
    mkdir aster && tar xf ${ASTER_SRC} -C aster --strip-components 1 && \
    #This line applies the changes as a patch 
    patch -s -p0 < aster_zs.patch && \   
    cd aster && \
    export INCLUDES="/usr/include/superlu \
    ${PUBLIC}/hdf5-${HDF5_VER}/include \
    ${PUBLIC}/med-${MED_VER}/include \
    ${PUBLIC}/metis-${METIS_VER}/include \
    ${PUBLIC}/parmetis-${PARMETIS_VER}/include \
    ${PUBLIC}/ptscotch-${SCOTCH_VER}/include \
    ${PUBLIC}/mumps-${MUMPS_VER}_mpi/include \
    ${PUBLIC}/tfel-${MFRONT_VER}/include" && \
    export LIBPATH="${PUBLIC}/hdf5-${HDF5_VER}/lib \
    ${PUBLIC}/med-${MED_VER}/lib \
    ${PUBLIC}/metis-${METIS_VER}/lib \
    ${PUBLIC}/parmetis-${PARMETIS_VER}/lib \
    ${PUBLIC}/ptscotch-${SCOTCH_VER}/lib \
    ${PUBLIC}/scalapack-${SCALAPACK_VER}/lib \
    ${PUBLIC}/mumps-${MUMPS_VER}_mpi/lib \
    ${PUBLIC}/tfel-${MFRONT_VER}/lib" && \
    export METISDIR=${PUBLIC}/metis-${METIS_VER} && \
    export TFELHOME=${PUBLIC}/tfel-${MFRONT_VER} && \
    export GMSH_BIN_DIR=${PUBLIC}/gmsh-3.0.6-Linux64/bin && \
    export HOMARD_ASTER_ROOT_DIR=${PUBLIC}/homard-11.12 && \
    ./waf configure && \
    # FIXME: currently not working
    # --use-config-dir=/tmp --use-config=cfg --prefix=${ASTER_ROOT}/${ASTER_VER}_mpi --install-tests --enable-mpi && \
    ./waf build && \
    ./waf install 
#This is commented to not remove the temp folder so that i can check if the changes were done
# to go to tmp folder type "cd /tmp/"
# RUN  rm -rf /tmp/*

# Add a welcome message and a script for testcases
WORKDIR /home/aster
COPY --chown=aster:aster WELCOME /home/aster/WELCOME
COPY --chown=aster:aster run_tests.sh /home/aster/run_tests.sh

RUN echo "vers : stable_mpi:${ASTER_ROOT}/${ASTER_VER}_mpi/share/aster" >> ${ASTER_ROOT}/etc/codeaster/aster && \
    echo "localhost" > ${ASTER_ROOT}/etc/codeaster/mpi_hostfile && \
    echo "mpi_get_procid_cmd : echo \$PMI_RANK" >> ${ASTER_ROOT}/etc/codeaster/asrun && \
    echo "" >> .bashrc && \
    echo "source ${ASTER_ROOT}/etc/codeaster/profile.sh" >> .bashrc && \
    echo "source ${ASTER_ROOT}/${ASTER_VER}/share/aster/profile_mfront.sh" >> .bashrc && \
    echo "cat ~/WELCOME" >> .bashrc && \
    echo "echo" >> .bashrc

USER root
