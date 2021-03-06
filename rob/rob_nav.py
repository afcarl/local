#from rob_interface import *
from os.path import split, relpath, join, isdir, isfile
import os
import fnmatch
import re
from rob_interface import robos
import rob_util as rutil
try:
    import six
except ImportError:
    pass

HS_EXCLUDE = ['_graveyard',
              '_broken',
              'CompilerIdCXX',
              'CompilerIdC',
              'build',
              'old',
              #'vim',
              #'src',
              ]
__DEBUG__ = True


def find_in_list(str_, tofind_list, agg_fn=all, case_insensitive=True):
    if len(tofind_list) == 0:
        return True
    if case_insensitive:
        str_ = str_.lower()
        tofind_list = [tofind.lower() for tofind in tofind_list]
    found_list = [str_.find(tofind) > -1 for tofind in tofind_list]
    return agg_fn(found_list)

# TODO: this grep stuff can be written nicer


def __grepfile(fpath, tofind_list, case_insensitive=True, verbose=False):
    with open(fpath, 'r') as file:
        lines = file.readlines()
        found = []
        # Search each line for the desired strings
        for lx, line in enumerate(lines):
            if find_in_list(line, tofind_list, any, case_insensitive):
                found.append((lx, line))
        # Print the results (if any)
        if len(found) > 0:
            ret = 'Found %d line(s) in %r: ' % (len(found), fpath)
            if verbose:
                print('----------------------')
                print(ret)
            name = split(fpath)[1]
            max_line = len(lines)
            ndigits = str(len(str(max_line)))
            fmt_str = '%s : %' + ndigits + 'd |%s'
            for (lx, line) in iter(found):
                line = line.replace('\n', '')
                if verbose:
                    print(fmt_str % (name, lx, line))
            return ret
    return None


def __regex_grepfile(fpath, regexpr, verbose=True):
    ret = None
    with open(fpath, 'r') as file:
        lines = file.readlines()
        #found = []
        found_lines = []
        found_lxs = []
        # Search each line for the desired regexpr
        for lx, line in enumerate(lines):
            match_object = re.search(regexpr, line)
            if match_object is not None:
                found_lines.append(line)
                found_lxs.append(lx)
                #found.append((lx, line))
        found = list(zip(found_lxs, found_lines))
        # Print the results (if any)
        if len(found) > 0:
            rel_fpath = relpath(fpath, os.getcwd())
            ret = 'Found %d line(s) in %r: ' % (len(found), rel_fpath)
            if verbose:
                print('----------------------')
                print(ret)
            name = split(fpath)[1]
            max_line = len(lines)
            ndigits = str(len(str(max_line)))
            fmt_str = '%s : %' + ndigits + 'd |%s'
            for (lx, line) in iter(found):
                line = line.replace('\n', '')
                if verbose:
                    print(fmt_str % (name, lx, line))
    return ret


def extend_regex(regexpr):
    regex_map = {
        r'\<': r'\b(?=\w)',
        r'\>': r'\b(?!\w)',
        ('UNSAFE', r'\x08'): r'\b',
    }
    for key, repl in six.iteritems(regex_map):
        if isinstance(key, tuple):
            search = key[1]
        else:
            search = key
        if regexpr.find(search) != -1:
            if isinstance(key, tuple):
                print('WARNING! Unsafe regex with: %r' % (key,))
            regexpr = regexpr.replace(search, repl)
    return regexpr


def _sed(r, regexpr, repl, force=False, recursive=False, dpath_list=None):
    if True:
        import utool as ut
        force = ut.smart_cast2(force)
        include_patterns = ['*.py', '*.cxx', '*.cpp', '*.hxx', '*.hpp', '*.c', '*.h', '*.pyx', '*.pxi', '*.cmake', 'CMakeLists.txt']
        ut.sed(regexpr, repl, force=force, recursive=recursive,
               dpath_list=dpath_list, verbose=True, include_patterns=include_patterns)
        return
    else:
        #_grep(r, [repl], dpath_list=dpath_list, recursive=recursive)
        force = rutil.cast(force, bool)
        recursive = rutil.cast(recursive, bool)
        import utool as ut
        pyext = ut.get_argflag('--pyext')
        if pyext:
            include_patterns = ['*.py']
        else:
            include_patterns = ['*.py', '*.cxx', '*.cpp', '*.hxx', '*.hpp', '*.c', '*.h', '*.pyx', '*.pxi', '*.cmake', 'CMakeLists.txt']
        if ut.get_argflag('--all'):
            include_patterns = ['*']
        #if ut.get_argflag('--tex'):
        include_patterns = ['*.tex']
        if dpath_list is None:
            dpath_list = [os.getcwd()]
        regexpr = extend_regex(regexpr)
        #import re
        print('sed-ing %r' % (dpath_list,))
        print(' * regular include_patterns : %r' % (include_patterns,))
        print(' * (orig) regular expression : %r' % (regexpr,))
        print(' * (origstr) regular expression : %s' % (regexpr,))
        #regexpr = re.escape(regexpr)
        print(' * regular expression : %r' % (regexpr,))
        print(' * (str)regular expression : %s' % (regexpr,))
        print(' * replacement        : %r' % (repl,))
        print(' * recursive: %r' % (recursive,))
        print(' * force: %r' % (force,))
        if '\x08' in regexpr:
            print('Remember \\x08 != \\b')
            print('subsituting for you for you')
            regexpr = regexpr.replace('\x08', '\\b')
            print(' * regular expression : %r' % (regexpr,))

        # Walk through each directory recursively
        num_changed = 0
        for fpath in _matching_fnames(dpath_list, include_patterns, recursive=recursive):
            num_changed += len(__regex_sedfile(fpath, regexpr, repl, force))
        print('total lines changed = %r' % (num_changed,))


def _grep(r, tofind_list, recursive=True, case_insensitive=True, regex=False,
          dpath_list=None, invert=False):
    include_patterns = ['*.py', '*.cxx', '*.cpp', '*.hxx', '*.hpp', '*.c',
                        '*.h', '*.vim']  # , '*.txt']
    exclude_dirs = HS_EXCLUDE
    # ensure list input
    if isinstance(include_patterns, str):
        include_patterns = [include_patterns]
    if dpath_list is None:
        dpath_list = [os.getcwd()]
    recursive = rutil.cast(recursive, bool)
    recursive_stat_str = ['flat', 'recursive'][recursive]
    print('Greping (%s) %r for %r' % (recursive_stat_str, dpath_list, tofind_list))
    found_filestrs = []
    found_fpaths = []
    # Walk through each directory recursively
    for fpath in _matching_fnames(dpath_list, include_patterns, exclude_dirs,
                                  recursive=recursive):
        if regex:
            if len(tofind_list) > 1:
                print('WARNING IN ROB NAV 133')
            #import re
            regexpr = extend_regex(tofind_list[0])
            regexpr = tofind_list[0]
            #regexpr = re.escape(regexpr)
            ret = __regex_grepfile(fpath, regexpr, verbose=not invert)
        else:
            ret = __grepfile(fpath, tofind_list, case_insensitive,
                             verbose=not invert)
        if ret is None and invert:
            found_filestrs.append(fpath)  # regular matching
        elif ret is not None and not invert:
            found_filestrs.append(ret)  # inverse matching
        if ret is not None:
            found_fpaths.append(fpath)

    print('====================')
    print('====================')
    print('\n'.join(found_filestrs))

    print('')
    print('gvim -o ' + ' '.join(found_fpaths))
    return found_filestrs


def fnmatch_any(path, exclude_list):
    return any([fnmatch.fnmatch(path, exclude)
                for exclude in exclude_list])


def ls2(r):
    exclude_list = ['*.pyc', '.*']
    cwd = os.getcwd()
    to_list_files = []
    to_list_dirs  = []
    for root, path_list, dir_list in os.walk(cwd):
        for path in path_list:
            if root.find('.git') > 0 or root.find('.git') > 0:
                continue
            print(join(root, path))
            if not fnmatch_any(path, exclude_list):
                if isdir(path):
                    to_list_dirs += [path]
                if isfile(path):
                    to_list_files += [path]
    def sort_fn(x):
        return x.lower()
    to_list_dirs.sort(key=sort_fn)
    to_list_files.sort(key=sort_fn)

    to_list = to_list_dirs + ['-------'] + to_list_files
    for path in iter(to_list):
        print(path)


def ls(r):
    exclude_list = ['*.pyc', '.*']
    cwd = os.getcwd()
    to_list_files = []
    to_list_dirs  = []
    for path in os.listdir(cwd):
        if not fnmatch_any(path, exclude_list):
            if isdir(path):
                to_list_dirs += [path]
            if isfile(path):
                to_list_files += [path]

    def sort_fn(x):
        return x.lower()
    to_list_dirs.sort(key=sort_fn)
    to_list_files.sort(key=sort_fn)

    to_list = to_list_dirs + ['-------'] + to_list_files
    for path in iter(to_list):
        print(path)


def _matching_fnames(dpath_list, include_patterns, exclude_dirs=None, recursive=True):
    if isinstance(dpath_list, (str)):
        dpath_list = [dpath_list]
    recursive = rutil.cast(recursive, bool)
    if exclude_dirs is None:
        exclude_dirs = HS_EXCLUDE
    if __DEBUG__:
        print('Excluding: %r' % (exclude_dirs,))
        #exclude_dirs = HS_EXCLUDE
        #exclude_dirs = []
    #fname_list = []
    for dpath in dpath_list:
        for root, dname_list, fname_list in os.walk(dpath):
            # Look at all subdirs
            subdirs = relpath(root, dpath).replace('\\', '/').split('/')
            greater_exclude_dirs = [
                'lib.linux-x86_64-2.7',
                'lib.linux-x86_64-3.4',
                'lib',
                'bundle',
            ]
            if any([dir_ in greater_exclude_dirs for dir_ in subdirs]):
                continue
            # Look at one subdir
            if split(root)[1] in exclude_dirs:
                continue
            for name in fname_list:
                # For the filesnames which match the patterns
                if any([fnmatch.fnmatch(name, pat) for pat in include_patterns]):
                    yield join(root, name)
                    #fname_list.append((root, name))
            if not recursive:
                break
    #return fname_list


def __regex_sedfile(fpath, regexpr, repl, force=False):
    path, name = split(fpath)
    new_file_lines = []
    with open(fpath, 'r') as file:
        file_lines = file.readlines()
        # Search each line for the desired regexpr
        new_file_lines = [re.sub(regexpr, repl, line) for line in file_lines]

    changed_lines = [(newline, line)
                     for newline, line in zip(new_file_lines, file_lines)
                     if  newline != line]
    nChanged = len(changed_lines)
    if nChanged > 0:
        rel_fpath = relpath(fpath, os.getcwd())
        print(' * %s changed %d lines in %r ' %
              (['(dry-run)', '(real-run)'][force], nChanged, rel_fpath))
        print(' * --------------------')
        new_file = ''.join(new_file_lines)
        prefixold = ' * old (%d, %r):  \n | ' % (nChanged, name)
        prefixnew = ' * new (%d, %r):  \n | ' % (nChanged, name)
        #print(new_file.replace('\n','\n))
        changed_new, changed_old = zip(*changed_lines)
        print(prefixold + (' | '.join(changed_old)).strip('\n'))
        print(' * ____________________')
        print(prefixnew + (' | '.join(changed_new)).strip('\n'))
        print(' * --------------------')
        print(' * =====================================================')
        if force:
            print(' ! WRITING CHANGES')
            with open(fpath, 'w') as file:
                file.write(new_file)
        return changed_lines
    return []


def win32_default(r, assisted=False):
    #robos.default_envvars(r)
    #robos.default_path(r)
    robos.default_registry(r)
    print('Finished defaulting regisitry')
    os.system('%PORT_SETTINGS%/install_ipython.bat')
    if assisted:
        robos.default_assisted(r)
    else:
        print("win32_default: Run this command with True as an argument to get assisted options")
