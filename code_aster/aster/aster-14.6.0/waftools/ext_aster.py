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

import os.path as osp
from waflib import Configure, Logs

###############################################################################
# Add OPTLIB_FLAGS support
from waflib.Tools import fc, c, cxx, ccroot
# original run_str command line is store as hcode
for lang in ('c', 'cxx', 'fc'):
    for feature in ('', 'program', 'shlib'):
        ccroot.USELIB_VARS[lang + feature].add('OPTLIB_FLAGS')

class fcprogram(fc.fcprogram):
    """Link object files into a fortran program, add optional OPTLIB_FLAGS at the end"""
    run_str = fc.fcprogram.hcode.decode() + ' ${OPTLIB_FLAGS}'

class cprogram(c.cprogram):
    """Link object files into a C program, add optional OPTLIB_FLAGS at the end"""
    run_str = c.cprogram.hcode.decode() + ' ${OPTLIB_FLAGS}'

class cxxprogram(cxx.cxxprogram):
    """Link object files into a C program, add optional OPTLIB_FLAGS at the end"""
    run_str = cxx.cxxprogram.hcode.decode() + ' ${OPTLIB_FLAGS}'

###############################################################################
def customize_configure_output():
    """Customize the output of configure"""
    from waflib.Context import Context
    def start_msg40(self, *k, **kw):
        """Force output on 40 columns. See :py:meth:`waflib.Context.Context.msg`"""
        if kw.get('quiet', None):
            return

        msg = kw.get('msg', None) or k[0]
        try:
            if self.in_msg:
                self.in_msg += 1
                return
        except AttributeError:
            self.in_msg = 0
        self.in_msg += 1

        self.line_just = 40 # <--- here is the change
        for x in (self.line_just * '-', msg):
            self.to_log(x)
        Logs.pprint('NORMAL', "%s :" % msg.ljust(self.line_just), sep='')
    Context.start_msg = start_msg40

customize_configure_output()
###############################################################################
from waflib.Task import Task, CRASHED, MISSING

SRCWIDTH = 120
def format_error(self):
    """Write task details into a file. Print only the first line in console.
    See :py:meth:`waflib.Task.Task.format_error`"""
    text = Task.format_error(self)
    if self.hasrun == CRASHED:
        msg = getattr(self, 'last_cmd', '')
        name = getattr(self.generator, 'name', '')
        bldlog = osp.join(self.generator.bld.path.get_bld().abspath(), '%s.log' % name)
        slog = ''
        try:
            open(bldlog, 'w').write('task: %r\nlast command:\n%r\n' % (self, msg))
        except (OSError, IOError) as exc:
            slog = '\ncan not write the log file: %s' % str(exc)
        text = text.splitlines()[0] \
             + '\n    task details in: {0}{1}'.format(bldlog, slog)
    return text

cprogram.format_error = format_error
cxxprogram.format_error = format_error
fcprogram.format_error = format_error

###############################################################################
# support for the "dynamic_source" attribute
from waflib import Build, Utils, TaskGen

@TaskGen.feature('c', 'cxx')
@TaskGen.before('process_source', 'process_rule')
def dynamic_post(self):
    """
    bld(dynamic_source='*.c', ...)
        will search for source files to add to the attribute 'source'.

    bld(dynamic_source='*.c', dynamic_incpaths='include', ...)
        will search for 'include' in the parent of every new source and
        add it in INCLUDES paths.
    """
    if not getattr(self, 'dynamic_source', None):
        return
    self.source = Utils.to_list(self.source)
    get_srcs = self.path.get_bld().ant_glob
    added = get_srcs(self.dynamic_source, remove=False, quiet=True)
    self.source.extend(added)
    for node in added:
        node.sig = Utils.h_file(node.abspath())
        if getattr(self, 'dynamic_incpaths', None):
            incpath = node.parent.find_node(self.dynamic_incpaths)
            if incpath:
                incpath.sig = incpath.abspath()
                self.env.append_value('INCLUDES', [incpath.abspath()])
                incs = incpath.get_bld().ant_glob('**/*.h*', quiet=True)
                for node in incs:
                    node.sig = Utils.h_file(node.abspath())

###############################################################################
@Configure.conf
def safe_remove(self, var, value):
    """Remove 'value' from the variable, remove duplicates"""
    self.env[var] = self.remove_duplicates(self.env[var])
    while value in self.env[var]:
        self.env[var].remove(value)

@Configure.conf
def remove_optflags(self, type_flags):
    """Remove optimisation flags from the `type_flags`/* variables,
    remove duplicates"""
    for var in self.env:
        if var.startswith(type_flags):
            self.env[var] = self.remove_duplicates(self.env[var])
            self.env[var] = [i for i in self.env[var] if not i.startswith("-O")]

@Configure.conf
def remove_duplicates(self, list_in):
    """Return the list by removing the duplicated elements
    and by keeping the order. It ignores empty values."""
    dset = set()
    # relies on the fact that dset.add() always returns None.
    return [path for path in list_in
            if path not in dset and not dset.add(path) ]

# Force static libs
CHECK = '_check'

@Configure.conf
def _force_stlib(self, *args, **kwargs):
    """Always use 'stlib' keyword argument"""
    kwargs = kwargs.copy()
    stlib = kwargs.get('stlib') or kwargs.get('lib')
    if stlib:
        kwargs['stlib'] = stlib
    try:
        del kwargs['lib']
    except KeyError:
        pass
    return getattr(self, CHECK)(*args, **kwargs)

@Configure.conf
def static_lib_pref(self):
    """Change temporarly the 'check' method"""
    if not self.options.embed_all:
        return
    if getattr(self, CHECK, None) is None:
        setattr(self, CHECK, self.check)
    self.check = self._force_stlib

@Configure.conf
def revert_lib_pref(self):
    """Restore original method"""
    if not self.options.embed_all:
        return
    self._force_stlib = getattr(self, CHECK)
