# coding=utf-8
# --------------------------------------------------------------------
# Copyright (C) 1991 - 2019 - EDF R&D - www.code-aster.org
# This file is part of code_aster.
#
# code_aster is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# code_aster is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with code_aster.  If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------

"""
script pour surcharger les catalogues officiels

ce script fabrique un fichier .ojb  contenant l'info présente dans l'ENSEMBLE
des catalogues (+surcharge)
"""

import sys
import os
import os.path as osp
import traceback
import tempfile
import shutil
import optparse


def parse_args(argv=None):
    'Parse the command line and return surch, unigest, nom_capy_offi, resu_ojb'

    usage = ('This script build an .ojb file that contains the overall '
             'information included in all given catalogs')
    parser = optparse.OptionParser(usage=usage)
    parser.add_option('--bibpyt', dest='rep_scripts', metavar='FOLDER',
                      help='path to Code_Aster python source files')
    parser.add_option('-s', '--surch', dest='surch', metavar='FILE',
                      help='big file with overloaded element catalogs')
    parser.add_option('-u', '--unigest', dest='unigest', metavar='FILE',
                      help='unigest file (only CATSUPPR lines are used)')
    parser.add_option('-i', '--input', dest='nom_capy_offi', metavar='FILE',
                      help='pickled catalog file that shall be overwritten')
    parser.add_option('-o', '--output', dest='resu_ojb', metavar='FILE',
                      help='output object file')

    opts, args = parser.parse_args(argv)
    if len(args) == 6 and opts.nom_capy_offi is None:  # legacy style
        opts.rep_scripts = args[0]
        opts.surch = args[2]
        opts.unigest = args[3]
        opts.nom_capy_offi = args[4]
        opts.resu_ojb = args[5]
    if opts.rep_scripts is not None:
        sys.path.insert(0, osp.abspath(opts.rep_scripts))
    if opts.nom_capy_offi is None or not osp.isfile(opts.nom_capy_offi):
        parser.error('You must provide the input (--help for help)')

    return opts.surch, opts.unigest, opts.nom_capy_offi, opts.resu_ojb

#


def main(surch, unigest, nom_capy_offi, resu_ojb):
    """
    Script pour surcharger les catalogues officiels
    (Il travaille dans un sandbox)
    """
    abspath = lambda path: path and osp.abspath(path)
    surch, unigest, nom_capy_offi, resu_ojb = list(map(abspath,
                                                 (surch, unigest, nom_capy_offi, resu_ojb)))

    trav = tempfile.mkdtemp(prefix='make_surch_offi_')
    dirav = os.getcwd()
    os.chdir(trav)
    try:
        _main(nom_capy_offi, resu_ojb)
    except:
        print(60 * '-' + ' debut trace back')
        traceback.print_exc(file=sys.stdout)
        print(60 * '-' + ' fin   trace back')
        raise
    finally:
        os.chdir(dirav)
        shutil.rmtree(trav)


def _main(nom_capy_offi, resu_ojb):

    shutil.copy(nom_capy_offi,resu_ojb)


if __name__ == '__main__':
    main(*parse_args())
