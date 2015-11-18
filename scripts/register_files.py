# -*- coding: utf-8 -*-
"""
Script to register files on a drive and reconcile duplicates

CommandLine:
    set PYTHONPATH=%PYTHONPATH%;%HOME%/local/scripts
    export PYTHONPATH=$PYTHONPATH:~/local/scripts
    python -m register_files --exec-register_drive --drives ~
    python %HOME%/local/scripts/register_files.py --exec-register_drive --drives D:/ E:/ F:/
"""
from __future__ import absolute_import, division, print_function, unicode_literals
import utool as ut
import six  # NOQA
import os
from os.path import join, exists, dirname
from os.path import islink
from os.path import splitext
from functools import partial
import functools
import numpy as np
import numpy as np  # NOQA
import vtool as vt  # NOQA
from six.moves import zip, range  # NOQA

if ut.WIN32:
    SystemErrors = (OSError, WindowsError)
else:
    SystemErrors = (OSError)


dryrun = not ut.get_argflag('--force')


def prog_(iter_, lbl, freq=1000, **kwargs):
    return ut.ProgressIter(iter_, freq=freq, lbl=lbl, **kwargs)


def build_multindex(list_):
    multiindex_dict_ = ut.ddict(list)
    for item, index in zip(list_, range(len(list_))):
        if item is not None:
            multiindex_dict_[item].append(index)
    return multiindex_dict_


def analyize_multiple_drives(drives):
    for drive in drives:
        drive.num_fpaths = len(drive.fpath_registry)

    for drive in drives:
        drive.fpath_idxs = list(range(drive.num_fpaths))

    for drive in drives:
        drive.fpath_exts = [splitext(fpath)[1].lower() for fpath in drive.fpath_registry]

    #for drive in drives:
    #    print(ut.dict_str(ut.dict_hist(drive.fpath_exts), key_order_metric='val'))

    #for drive in drives:
    #    drive.nbytes_to_idxs = ut.hierarchical_group_items(drive.fpath_idxs, [drive.fpath_exts, drive.fpath_bytes_list])

    for drive in drives:
        def build_multindex(list_):
            import utool as ut
            multiindex_dict_ = ut.ddict(list)
            for item, index in zip(list_, range(len(list_))):
                if item is not None:
                    multiindex_dict_[item].append(index)
            return multiindex_dict_
        multiindex_dict_ = build_multindex(drive.fpath_hashX_list)
        drive.hash_to_fpaths = dict(
            [(hash_, ut.take(drive.fpath_registry, idxs))
             for hash_, idxs in multiindex_dict_.items()])

    allhave = reduce(
        functools.partial(ut.dict_intersection, combine=True),
        [drive.hash_to_fpaths for drive in drives])
    print('allhave = %r' % (len(allhave),))
    #allhave = reduce(set.intersection, [set(drive.hash_to_fpaths.keys()) for drive in drives])

    for drive in drives:
        drive.hash_to_unique_fpaths = ut.delete_keys(
            drive.hash_to_fpaths.copy(), allhave.keys())

    for drive in drives:
        drive.rrr()
        print(drive.root_dpath)
        print(len(drive.hash_to_unique_fpaths))

    ut.embed()


@six.add_metaclass(ut.ReloadingMetaclass)
class Broadcaster(object):
    """
    objs = drives
    multidrive = Broadcaster(objs)
    multidrive.biggest_dirs()
    """
    def __init__(self, objs):
        self.objs = objs
        cls = objs[0].__class__
        self.cls = cls

        for attr in dir(cls):
            if attr.startswith('__'):
                continue
            setattr(self, attr, partial(self.broadcast, attr))

    def __getattribute__(self, attr):
        return partial(self.broadcast, attr)

    def broadcast(self, funcname, *args, **kwargs):
        return [getattr(obj, funcname)(*args, **kwargs) for obj in self.objs]


@six.add_metaclass(ut.ReloadingMetaclass)
class Drive(object):
    """
    """

    def __init__(drive):
        """
        """
        pass

    def __str__(drive):
        return drive.root_dpath + ' - ' + ut.byte_str2(drive.total_bytes)

    def __repr__(drive):
        return '<Drive ' + drive.root_dpath + ' - ' + ut.byte_str2(drive.total_bytes) + '>'

    @property
    def total_bytes(drive):
        return np.nansum(drive.fpath_bytes_list)

    def biggest_files(drive):
        sortx = ut.list_argsort(drive.fpath_bytes_list)[::-1]
        sel = sortx[0:10]
        biggest_nbytes = ut.take(drive.fpath_bytes_list, sel)
        biggest_files = ut.take(drive.fpath_registry, sel)
        biginfo_list = list(zip(map(ut.byte_str2, biggest_nbytes), biggest_files))
        print(ut.list_str(biginfo_list, strvals=True))

    def biggest_dirs(drive):
        dpath_list = drive.dpath_registry
        #dpath_list = [ROOT_DPATH]
        fidxs_list = ut.dict_take(drive.dpath_to_fidx, dpath_list)
        unflat_dpath_bytes_list = ut.list_unflat_take(drive.fpath_bytes_list, fidxs_list)
        dpath_nbytes_list = list(map(sum, unflat_dpath_bytes_list))

        sortx = ut.list_argsort(dpath_nbytes_list)[::-1]
        sel = sortx[0:10]
        biggest_nbytes = ut.take(dpath_nbytes_list, sel)
        biggest_dpaths = ut.take(dpath_list, sel)
        biginfo_list = list(zip(map(ut.byte_str2, biggest_nbytes), biggest_dpaths))
        print(ut.list_str(biginfo_list, strvals=True))
        pass

    def fix_duplicates(drive):
        """
        for every duplicate file passing a (eg avi) filter,
        remove the file that is in the smallest directory. On a tie
        use the smallest dpath. This will filter all duplicate files in a folder into
        a single folder.

        but... need to look at non-duplicates in that folder and decide if they should be moved as well.
        So, should trigger on folders that have at least 50% duplicate.
        Might not want to move curated folders.
        """
        list_ = drive.fpath_hashX_list
        multiindex_dict_ = build_multindex(list_)
        duplicate_hashes = [
            key for key, val in six.iteritems(multiindex_dict_)
            if len(val) > 1]
        duplicate_idxs = ut.dict_take(multiindex_dict_, duplicate_hashes)
        unflat_fpaths = ut.list_unflat_take(drive.fpath_registry, duplicate_idxs)
        # Check if any dups have been removed
        still_exists = ut.unflat_map(exists, unflat_fpaths)
        unflat_idxs2 = ut.zipcompress(duplicate_idxs, still_exists)
        duplicate_idxs = [idxs for idxs in unflat_idxs2 if len(idxs) > 1]

        # Look at duplicate files
        unflat_fpaths = ut.list_unflat_take(drive.fpath_registry, duplicate_idxs)
        unflat_sizes = ut.list_unflat_take(drive.fpath_bytes_list, duplicate_idxs)

        # Find highly coupled directories
        if True:
            coupled_dirs = []
            for fpaths in unflat_fpaths:
                #basedir = ut.longest_existing_path(commonprefix(fpaths))
                dirs = sorted(list(map(dirname, fpaths)))
                def up_diag_prodx(num):
                    return [(n1, n2) for n1 in range(num) for n2 in range(num) if n1 < n2]
                idxs = up_diag_prodx(len(dirs))
                coupled_dirs.extend(list(map(tuple, ut.list_unflat_take(dirs, idxs))))
            hist_ = ut.dict_hist(coupled_dirs)
            coupled_idxs = ut.list_argsort(hist_.values())[::-1]
            most_coupled = ut.list_take(list(hist_.keys()), coupled_idxs[0:100])
            print('Coupled fpaths: ' + ut.list_str(most_coupled, nl=True))

        print('%d unique files are duplicated' % (len(unflat_sizes),))
        #print('Duplicate sizes: ' + ut.list_str(unflat_sizes[0:10], nl=True))
        #print('Duplicate fpaths: ' + ut.list_str(unflat_fpaths[0:10], nl=True))
        #print('Duplicate fpaths: ' + ut.list_str(unflat_fpaths[0::5], nl=True))
        print('Duplicate fpaths: ' + ut.list_str(unflat_fpaths, nl=True))

    def fix_empty_dirs(drive):
        # --- FIND EMPTY DIRECTORIES ---
        fidxs_list = ut.dict_take(drive.dpath_to_fidx, drive.dpath_registry)
        isempty_flags = [len(fidxs) == 0 for fidxs in fidxs_list]
        empty_dpaths = ut.compress(drive.dpath_registry, isempty_flags)

        def is_cplat_link(path_):
            try:
                if islink(path_):
                    return True
                os.listdir(d)
                return False
            except SystemErrors:
                return True
        valid_flags = [not is_cplat_link(d) for d  in empty_dpaths]
        if not all(valid_flags):
            print('Filtered windows links %r / %r' % (
                len(empty_dpaths) - sum(valid_flags), len(empty_dpaths)))
            #print(ut.list_str(empty_dpaths[0:10]))
            empty_dpaths = ut.compress(empty_dpaths, valid_flags)

        print('Found %r / %r empty_dpaths' % (len(empty_dpaths), len(drive.dpath_registry)))
        print(ut.list_str(empty_dpaths[0:10]))

        # Ensure actually still empty
        current_contents = [ut.glob(d, with_dirs=False)
                            for d in prog_(empty_dpaths, 'checking empty status')]
        current_lens = list(map(len, current_contents))
        assert not any(current_lens), 'some dirs are not empty'

        # n ** 2 check to get only the base directories
        isbase_dir = [
            not any([d.startswith(dpath_) and d != dpath_
                        for dpath_ in empty_dpaths])
            for d in prog_(empty_dpaths, 'finding base dirs')
        ]
        base_empty_dirs = ut.compress(empty_dpaths, isbase_dir)
        def list_only_files(dpath):
            # glob is too slow
            for root, dirs, fpaths in os.walk(dpath):
                for fpath in fpaths:
                    yield fpath
        base_current_contents = [
            list(list_only_files(d))
            for d in prog_(base_empty_dirs, 'checking emptyness', freq=10)]
        is_actually_empty = [len(fs) == 0 for fs in base_current_contents]
        not_really_empty = ut.compress(base_empty_dirs, ut.not_list(is_actually_empty))
        print('%d dirs are not actually empty' % (len(not_really_empty),))
        print('not_really_empty = %s' % (ut.list_str(not_really_empty[0:10]),))
        truly_empty_dirs = ut.compress(base_empty_dirs, is_actually_empty)

        def list_all(dpath):
            # glob is too slow
            for root, dirs, fpaths in os.walk(dpath):
                for dir_ in dirs:
                    yield dir_
                for fpath in fpaths:
                    yield fpath

        exclude_base_dirs = [join(drive.ROOT_DPATH, 'AppData')]
        exclude_end_dirs = ['__pycache__']
        truly_empty_dirs1 = truly_empty_dirs
        for ed in exclude_base_dirs:
            truly_empty_dirs1 = [
                d for d in truly_empty_dirs1
                if (
                    not any(d.startswith(ed) for ed in exclude_base_dirs) and
                    not any(d.endswith(ed) for ed in exclude_end_dirs)
                )
            ]
        # Ensure actually still empty (with recursive checks for hidden files)
        print('truly_empty_dirs1[::5] = %s' % (
            ut.list_str(truly_empty_dirs1[0::5], strvals=True),))
        #print('truly_empty_dirs1 = %s' % (ut.list_str(truly_empty_dirs1, strvals=True),))

        if not dryrun:
            # FIX PART
            #from os.path import normpath
            #for d in prog_(truly_empty_dirs):
            #    break
            #    if ut.WIN32:
            #        # http://www.sevenforums.com/system-security/53095-file-folder-read-only-attribute-wont-disable.html
            #        ut.cmd('attrib', '-r', '-s', normpath(d), verbose=False)
            #x = ut.remove_fpaths(truly_empty_dirs, strict=False)

            print('Deleting %d truly_empty_dirs1' % (len(truly_empty_dirs1),))

            for d in prog_(truly_empty_dirs1, 'DELETE empty dirs'):  # NOQA
                ut.delete(d, quiet=True)

            if ut.WIN32 and False:
                # remove file that failed removing
                flags = list(map(exists, truly_empty_dirs1))
                truly_empty_dirs1 = ut.compress(truly_empty_dirs1, flags)
                for d in prog_(truly_empty_dirs1, 'rming'):
                    ut.cmd('rmdir', d)

    #biggest_files(drive)
    #biggest_dirs(drive)
    #fix_empty_dirs(drive)
    #fix_duplicates(drive)


def register_drive(root_drive):
    r"""

    Ignore:
        >>> # ENABLE_DOCTEST
        >>> import sys
        >>> from os.path import *
        >>> from register_files import *  # NOQA
        >>> sys.path.append(normpath(expanduser('~/local/scripts')))

    Example:
        >>> from register_files import *  # NOQA
        >>> dpaths = ut.get_argval('--drives', type_=list, default=[])
        >>> drives = [register_drive(root_drive) for root_drive in dpaths]
        >>> analyize_multiple_drives(drives)

        #>>> result = register_drive('D:/')
        #>>> result = register_drive('E:/')
        #>>> result = register_drive('F:/')
    """
    root_drive = ut.ensure_unicode(root_drive)
    drive = Drive()

    # BUILD INFO ABOUT A SPECIFIC DIRECTORY

    #dpath = ut.truepath('~/local')
    #ROOT_DPATH = ut.truepath('F:/')
    #ROOT_DPATH = ut.truepath('D:/')
    #ROOT_DPATH = ut.truepath('E:/')
    #ROOT_DPATH = ut.truepath('~')
    ROOT_DPATH = ut.truepath(root_drive)
    drive.root_dpath = root_drive
    print('Registering %s' % (ROOT_DPATH,))
    #cfgstr = ut.hashstr27(ROOT_DPATH)

    cache_fname = join(ROOT_DPATH, 'ut_pathreg_cache.shelf')
    cache = ut.ShelfCacher(cache_fname)

    try:
        fpath_registry = cache.load('fpath_registry')
        dpath_registry = cache.load('dpath_registry')
    except ut.CacheMissException:
        fpath_gen_list = []
        dpath_gen_list = []
        for root, dname_list, fname_list in prog_(os.walk(ROOT_DPATH), 'walking'):
            # Ignore hidden directories
            dname_list[:] = [d for d in dname_list if not d.startswith('.')]
            fpath_gen_list.append((root, fname_list))
            dpath_gen_list.append((root, dname_list))
        fpath_registry = [join(root, f) for root, fs in fpath_gen_list for f in fs]
        dpath_registry =  [join(root, d) for root, ds in dpath_gen_list for d in ds]
        dpath_registry = [ROOT_DPATH] + dpath_registry
        print('Regsitering %d files and %d directories' % (len(fpath_registry), len(dpath_registry)))
        cache.save('fpath_registry', fpath_registry)
        cache.save('dpath_registry', dpath_registry)
    print('Loaded %d files and %d directories' % (len(fpath_registry), len(dpath_registry)))
    drive.fpath_registry = fpath_registry
    drive.dpath_registry = dpath_registry

    if False:
        # Update existing files
        fpath_exists_list = list(map(exists, prog_(fpath_registry, 'checkexist fpath')))
        dpath_exists_list = list(map(exists, prog_(dpath_registry, 'checkexist dpath')))
        if all(fpath_exists_list):
            print('No change in file structure')
        else:
            print('%d/%d files no longer exist' % (len(fpath_registry) - sum(fpath_exists_list), len(fpath_registry)))
            removed_fpaths = ut.compress(fpath_registry, ut.not_list(fpath_exists_list))
            print('removed_fpaths = %s' % (ut.list_str(removed_fpaths),))
        if all(dpath_exists_list):
            print('No change in dpath structure')
        else:
            print('%d/%d dirs no longer exist' % (len(dpath_registry) - sum(dpath_exists_list), len(dpath_registry)))
            removed_dpaths = ut.compress(dpath_registry, ut.not_list(dpath_exists_list))
            print('removed_dpaths = %s' % (ut.list_str(removed_dpaths),))

        fpath_registry = ut.compress(fpath_registry, fpath_exists_list)
        dpath_registry = ut.compress(dpath_registry, dpath_exists_list)
        cache.save('fpath_registry', fpath_registry)
        cache.save('dpath_registry', dpath_registry)

    try:
        fpath_bytes_list = cache.load('fpath_bytes_list')
        assert len(fpath_bytes_list) == len(fpath_registry)
        #print(len(fpath_bytes_list))
    except ut.CacheMissException:
        def tryread_nbytes(fpath):
            try:
                return ut.file_bytes(fpath)
            except SystemErrors:
                return np.nan

        fpath_bytes_list = [
            tryread_nbytes(fpath)
            for fpath in prog_(fpath_registry, 'reading size')
        ]
        assert len(fpath_registry) == len(fpath_registry)
        cache.save('fpath_bytes_list', fpath_bytes_list)
    drive.fpath_bytes_list = fpath_bytes_list

    fpath_bytes_arr = np.array(fpath_bytes_list)
    print('Loaded filesize for %d / %d files' % ((~np.isnan(fpath_bytes_arr)).sum(), len(fpath_bytes_arr)))

    if True:
        try:
            fpath_hashX_list = cache.load('fpath_hashX_list')
        except ut.CacheMissException:
            def bytes_based_hash(fpath, nbytes):
                try:
                    if nbytes > 2 ** 30:
                        return None
                    elif nbytes > (2 ** 20):
                        return ut.get_file_hash(fpath, stride=256)
                    else:
                        return ut.get_file_hash(fpath, stride=1)
                except IOError:
                    return None

            fpath_hashX_list = [None] * len(fpath_registry)

            assert len(fpath_bytes_list) == len(fpath_registry)

            nbytes_tiers = [
                np.inf, 2 ** 32, 2 ** 30,
                2 ** 29, 2 ** 28, 2 ** 25,
                2 ** 20, 2 ** 10, 0, -np.inf,
            ]
            tier_windows = list(ut.itertwo(nbytes_tiers))

            print('Tier Windows')
            for tier, (high, low) in enumerate(tier_windows):
                print('tier = %r' % (tier,))
                print('tier_windows = %s - %s' % (ut.byte_str2(high), ut.byte_str2(low)))

            tier_flags = [
                np.logical_and.reduce([fpath_bytes_arr <= high, fpath_bytes_arr > low])
                for high, low in tier_windows
            ]
            tier_fpaths = [ut.compress(fpath_registry, flags) for flags in tier_flags]

            for tier, fpaths in enumerate(tier_fpaths):
                print('tier = %r' % (tier,))
                high, low = tier_windows[tier]
                print('tier_windows = %s - %s' % (ut.byte_str2(high), ut.byte_str2(low)))
                print('len(fpaths) = %r' % (len(fpaths),))

            def tryhash(fpath_, stride=1):
                try:
                    return ut.get_file_hash(fpath_, stride=stride)
                except IOError:
                    return None

            #for tier, fpaths in enumerate(tier_fpaths):
            for tier in [5, 4, 3]:
                window = np.array(tier_windows[tier])
                minbytes = window[np.isfinite(window)].min()
                stride = max(1, minbytes // (2 ** 20))
                fpaths = tier_fpaths[tier]

                tier_hashes = [
                    tryhash(fpath, stride) for fpath in
                    prog_(fpaths, 'tier=%r hashes' % (tier,), freq=100)
                ]
                tier_idxs = np.where(tier_flags[tier])[0]

                for idx, hash_ in zip(tier_idxs, tier_hashes):
                    fpath_hashX_list[idx] = hash_

            cache.save('fpath_hashX_list', fpath_hashX_list)
        drive.fpath_hashX_list = fpath_hashX_list

    # Create mapping from directory to subfiles
    try:
        dpath_to_fidx = cache.load('dpath_to_fidx')
        assert len(dpath_to_fidx) <= len(dpath_registry)
    except ut.CacheMissException:
        dpath_to_fidx = ut.ddict(list)
        for fidx, fpath in prog_(enumerate(fpath_registry), 'making dpath fidx map', freq=10000, nTotal=len(fpath_registry)):
            current_path = fpath
            #last_dpath = None
            while True:
                #current_path != last_dpath:
                #last_dpath = current_path
                current_path = dirname(current_path)
                dpath_to_fidx[current_path].append(fidx)
                if current_path == ROOT_DPATH:
                    break
        cache.save('dpath_to_fidx', dpath_to_fidx)
    drive.dpath_to_fidx = dpath_to_fidx
    return drive


if __name__ == '__main__':
    r"""
    CommandLine:
        set PYTHONPATH=%PYTHONPATH%;C:/Users/joncrall/local/scripts
        python -B %HOME%/local/scripts/register_files.py
        python -B %HOME%/local/scripts/register_files.py --allexamples
    """
    import multiprocessing
    multiprocessing.freeze_support()  # for win32
    import utool as ut  # NOQA
    ut.doctest_funcs()
